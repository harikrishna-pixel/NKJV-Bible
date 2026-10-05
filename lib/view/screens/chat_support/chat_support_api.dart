import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Support chat calls. No auth header.
class ChatSupportApi {
  ChatSupportApi._();

  static const String baseUrl = 'https://api.biblehi.com';
  static const String _deviceUserKey = 'support_chat_user_id';

  /// Same id every time: the login id, or one stored on the device.
  static Future<String> resolveUserId() async {
    final cached =
        (await CacheNotifier().readCache(key: 'userid') ?? '').toString().trim();
    if (cached.isNotEmpty) return cached;

    final firebase = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (firebase.isNotEmpty) return firebase;

    final prefs = await SharedPreferences.getInstance();
    final stored = (prefs.getString(_deviceUserKey) ?? '').trim();
    if (stored.isNotEmpty) return stored;

    final created = 'user-${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_deviceUserKey, created);
    return created;
  }

  static Map<String, String> _jsonHeaders() {
    return const {'Content-Type': 'application/json'};
  }

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on SocketException {
      throw ChatSupportException(
        'Could not reach Chat Support. Check your connection and try again.',
      );
    } on http.ClientException {
      throw ChatSupportException(
        'Could not reach Chat Support. Check your connection and try again.',
      );
    } on TimeoutException {
      throw ChatSupportException('Support server did not respond.');
    }
  }

  /// Newest first from the server. The screen reverses this for the chat.
  static Future<List<SupportQuestion>> fetchQuestions(String userId) {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/api/questions').replace(
        queryParameters: {'userId': userId},
      );
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 20));
      final body = _asMap(response.body);
      if (response.statusCode != 200) {
        throw ChatSupportException(_message(body, 'Could not load questions'));
      }
      final data = body['data'];
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => SupportQuestion.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  static Future<String> uploadImage(String path) {
    return _guard(() async {
      final ext = _allowedExt(path);
      if (ext == null) {
        throw ChatSupportException(
          'Only jpeg, png, webp, and gif images are allowed',
        );
      }
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        path,
        filename: 'upload.$ext',
        contentType: _mediaType(ext),
      ));
      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final raw = await streamed.stream.bytesToString();
      final body = _asMap(raw);
      if (streamed.statusCode != 200) {
        throw ChatSupportException(_message(body, 'Image upload failed'));
      }
      final data = body['data'];
      final url = data is Map ? data['objectUrl']?.toString().trim() ?? '' : '';
      if (!url.startsWith('http')) {
        throw ChatSupportException(_message(body, 'Image upload failed'));
      }
      return url;
    });
  }

  static Future<SupportQuestion> ask({
    required String userId,
    required String question,
    String imageUrl = '',
  }) {
    return _guard(() async {
      final info = await PackageInfo.fromPlatform();
      final appName = info.appName.trim().isNotEmpty
          ? info.appName.trim()
          : BibleInfo.bible_shortName;
      final bundleId = info.packageName.trim().isNotEmpty
          ? info.packageName.trim()
          : (Platform.isIOS
              ? BibleInfo.ios_Bundle_Id
              : BibleInfo.android_Package_Name);
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/questions'),
            headers: _jsonHeaders(),
            body: jsonEncode({
              'userId': userId,
              'appName': appName,
              'bundleId': bundleId,
              'question': question,
              'imageUrl': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 25));
      print(
        'Chat Support response ${response.statusCode}: ${response.body}',
      );
      final body = _asMap(response.body);
      if (response.statusCode != 201) {
        throw ChatSupportException(_message(body, 'Could not send question'));
      }
      final data = body['data'];
      final resolvedBy =
          data is Map ? data['resolvedBy']?.toString() ?? '' : '';
      final rawQuestion = data is Map ? data['userQuestion'] : null;
      if (rawQuestion is Map) {
        return SupportQuestion.fromJson(
          Map<String, dynamic>.from(rawQuestion),
          resolvedBy: resolvedBy,
        );
      }
      return SupportQuestion(
        id: '',
        question: question,
        answer: '',
        status: resolvedBy == 'ai' ? 'closed' : 'open',
        answeredBy: resolvedBy == 'ai' ? 'ai' : 'human',
        imageUrl: imageUrl,
        resolvedBy: resolvedBy,
      );
    });
  }

  static Future<SupportQuestion> escalate({
    required String userId,
    required String questionId,
  }) {
    return _guard(() async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/questions/$questionId/escalate'),
            headers: _jsonHeaders(),
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 20));
      final body = _asMap(response.body);
      if (response.statusCode != 200) {
        throw ChatSupportException(_message(body, 'Could not contact support'));
      }
      final data = body['data'];
      final rawQuestion = data is Map ? data['userQuestion'] : null;
      if (rawQuestion is Map) {
        return SupportQuestion.fromJson(
          Map<String, dynamic>.from(rawQuestion),
          resolvedBy: 'human',
        );
      }
      return SupportQuestion(
        id: questionId,
        question: '',
        answer: '',
        status: 'open',
        answeredBy: 'human',
        imageUrl: '',
        resolvedBy: 'human',
      );
    });
  }

  static String? _allowedExt(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'png' ||
        ext == 'webp' ||
        ext == 'gif') {
      return ext == 'jpg' ? 'jpeg' : ext;
    }
    return null;
  }

  static MediaType _mediaType(String ext) {
    if (ext == 'png') return MediaType('image', 'png');
    if (ext == 'webp') return MediaType('image', 'webp');
    if (ext == 'gif') return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  static Map<String, dynamic> _asMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  static String _message(Map<String, dynamic> body, String fallback) {
    final message = body['message']?.toString().trim() ?? '';
    if (message.isNotEmpty) return message;
    final error = body['error']?.toString().trim() ?? '';
    return error.isEmpty ? fallback : error;
  }
}

class SupportQuestion {
  const SupportQuestion({
    required this.id,
    required this.question,
    required this.answer,
    required this.status,
    required this.answeredBy,
    required this.imageUrl,
    this.resolvedBy = '',
  });

  final String id;
  final String question;
  final String answer;
  final String status;
  final String answeredBy;
  final String imageUrl;
  final String resolvedBy;

  bool get showAiAnswer =>
      status == 'closed' && answeredBy == 'ai' && answer.trim().isNotEmpty;

  bool get showHumanAnswer =>
      status == 'closed' && answeredBy == 'human' && answer.trim().isNotEmpty;

  bool get waitingForReply => !showAiAnswer && !showHumanAnswer;

  factory SupportQuestion.fromJson(
    Map<String, dynamic> json, {
    String resolvedBy = '',
  }) {
    return SupportQuestion(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      answeredBy: json['answeredBy']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      resolvedBy: resolvedBy,
    );
  }
}

class ChatSupportException implements Exception {
  ChatSupportException(this.message);
  final String message;

  @override
  String toString() => message;
}
