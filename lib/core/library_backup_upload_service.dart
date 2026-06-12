import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/core/export_db.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Uploads library backup (.enc) to the authhub user-backup API.
class LibraryBackupUploadService {
  LibraryBackupUploadService._();

  /// Wait until Home/splash DB work finishes before reading library tables.
  static const Duration _deferAfterLaunch = Duration(seconds: 60);

  static bool _uploadInProgress = false;
  static bool _downloadInProgress = false;

  static Future<String?> _loggedInUserId() async {
    final id = await CacheNotifier().readCache(key: 'userid');
    if (id == null) return null;
    final value = id.toString().trim();
    return value.isEmpty ? null : value;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${_two(now.month)}-${_two(now.day)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static Future<void> _clearBackupFailureFlag() async {
    await SharPreferences.setBoolean(SharPreferences.lastCloudBackupFailed, false);
    await SharPreferences.setString(
        SharPreferences.lastCloudBackupFailureReason, '');
  }

  static Future<void> _setBackupFailureFlag(String reason) async {
    await SharPreferences.setBoolean(SharPreferences.lastCloudBackupFailed, true);
    await SharPreferences.setString(
        SharPreferences.lastCloudBackupFailureReason, reason);
  }

  static String _failureReasonFromError(Object e) {
    final message = e.toString().toLowerCase();
    if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('host')) {
      return 'No internet';
    }
    if (message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized')) {
      return 'Sign-in expired';
    }
    return 'Upload failed';
  }

  /// Wraps the local .enc backup in a .zip for cloud upload only.
  static Future<File> _zipEncBackupForUpload(File encFile) async {
    final encBytes = await encFile.readAsBytes();
    final encName = encFile.uri.pathSegments.isNotEmpty
        ? encFile.uri.pathSegments.last
        : '${BibleInfo.bible_shortName}_Backup.enc';
    final archive = Archive()
      ..addFile(ArchiveFile(encName, encBytes.length, encBytes));
    final zipBytes = ZipEncoder().encode(archive);
    final zipName = encName.endsWith('.enc')
        ? '${encName.substring(0, encName.length - 4)}.zip'
        : '${BibleInfo.bible_shortName}_Backup.zip';
    final zipFile = File('${encFile.parent.path}/$zipName');
    await zipFile.writeAsBytes(zipBytes);
    return zipFile;
  }

  /// Uploads cloud backup (.zip containing the .enc file). Local export stays .enc.
  static Future<bool> uploadBackupFile(File file) async {
    if (_uploadInProgress) return false;
    final userId = await _loggedInUserId();
    if (userId == null) return false;
    if (!await file.exists()) return false;

    _uploadInProgress = true;
    File? zipFile;
    try {
      zipFile = await _zipEncBackupForUpload(file);

      final uploadUrl = AppApiConstant.userBackupUploadUrl;
      final appId = BibleInfo.appID.toString();
      final fileName = zipFile.uri.pathSegments.isNotEmpty
          ? zipFile.uri.pathSegments.last
          : '${BibleInfo.bible_shortName}_Backup.zip';
      final fileBytes = await zipFile.length();
      final authtoken = await CacheNotifier().readCache(key: 'authtoken');

      debugPrint('========== Library backup upload ==========');
      debugPrint('POST URL: $uploadUrl');
      debugPrint('app_id: $appId');
      debugPrint('user_id: $userId');
      debugPrint('local .enc path: ${file.path}');
      debugPrint('backup_file path: ${zipFile.path}');
      debugPrint('backup_file name: $fileName');
      debugPrint('backup_file size: $fileBytes bytes');
      debugPrint(
          'Authorization: ${authtoken != null && authtoken.toString().isNotEmpty ? "Bearer (set)" : "missing"}');

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      if (authtoken != null && authtoken.toString().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${authtoken.toString()}';
      }
      request.fields['app_id'] = appId;
      request.fields['user_id'] = userId;
      request.files.add(
        await http.MultipartFile.fromPath(
          'backup_file',
          zipFile.path,
          filename: fileName,
        ),
      );

      debugPrint('Sending multipart POST...');
      final streamed = await request
          .send()
          .timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      debugPrint('========== End library backup upload ==========');
      log('Library backup upload: ${response.statusCode} ${response.body}');

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (ok) {
        final now = DateTime.now().toIso8601String();
        await SharPreferences.setString(
            SharPreferences.lastCloudBackupDate, now);
        await SharPreferences.setString(
            SharPreferences.lastExportedDate, now);
        await _clearBackupFailureFlag();
      } else {
        await _setBackupFailureFlag(
          response.statusCode == 401 || response.statusCode == 403
              ? 'Sign-in expired'
              : 'Upload failed',
        );
      }
      return ok;
    } catch (e, st) {
      log('Library backup upload failed: $e $st');
      debugPrint('Library backup upload failed: $e');
      await _setBackupFailureFlag(_failureReasonFromError(e));
      return false;
    } finally {
      if (zipFile != null && await zipFile.exists()) {
        try {
          await zipFile.delete();
        } catch (_) {}
      }
      _uploadInProgress = false;
    }
  }

  static Future<File?> _createTempBackupFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory('${tempDir.path}/library_backup');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return ExportDb.writeBackupFileToDirectory(dir);
    } catch (e, st) {
      log('createTempBackupFile: $e $st');
      return null;
    }
  }

  /// Creates a fresh backup and uploads it (login + scheduled flows).
  static Future<bool> backupToCloud({bool markScheduled = false}) async {
    final userId = await _loggedInUserId();
    if (userId == null) return false;

    final file = await _createTempBackupFile();
    if (file == null) return false;

    final ok = await uploadBackupFile(file);
    if (ok && markScheduled) {
      await SharPreferences.setString(
        SharPreferences.lastScheduledCloudBackupDate,
        _todayKey(),
      );
    }
    return ok;
  }

  /// Runs once after successful sign-in (does not block navigation).
  static void runAfterLogin() {
    Future.delayed(_deferAfterLaunch, () {
      unawaited(backupToCloud());
    });
  }

  /// Schedules [runScheduledBackupIfNeeded] after launch so it does not
  /// contend with splash/Home Bible DB loading.
  static void scheduleDeferredBackupCheck() {
    Future.delayed(_deferAfterLaunch, () {
      unawaited(runScheduledBackupIfNeeded());
    });
  }

  static Future<http.MultipartRequest> _downloadRequest() async {
    final userId = await _loggedInUserId();
    if (userId == null) {
      throw Exception('Please sign in to download cloud backup');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppApiConstant.userBackupDownloadUrl),
    );
    final authtoken = await CacheNotifier().readCache(key: 'authtoken');
    if (authtoken != null && authtoken.toString().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${authtoken.toString()}';
    }
    request.fields['app_id'] = BibleInfo.appID.toString();
    request.fields['user_id'] = userId;
    return request;
  }

  static Future<File?> _encFileFromDownloadBytes(
    List<int> bytes,
    Directory dir,
  ) async {
    if (bytes.isEmpty) return null;

    if (bytes.first == 0x7b) {
      try {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is Map && decoded['status'] == false) {
          final msg = decoded['message']?.toString() ?? 'Download failed';
          throw Exception(msg);
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
    }

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final name = entry.name.split('/').last;
        if (!name.endsWith('.enc')) continue;
        final out = File('${dir.path}/$name');
        await out.writeAsBytes(List<int>.from(entry.content));
        return out;
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    final enc = File('${dir.path}/${BibleInfo.bible_shortName}_Backup.enc');
    await enc.writeAsBytes(bytes);
    return enc;
  }

  /// Downloads cloud backup (.zip with .enc inside) and restores library DB.
  static Future<bool> downloadAndImportFromCloud() async {
    if (_downloadInProgress) return false;
    final userId = await _loggedInUserId();
    if (userId == null) {
      Constants.showToast('Please sign in to restore cloud backup');
      return false;
    }

    _downloadInProgress = true;
    File? encFile;
    File? zipFile;
    try {
      final downloadUrl = AppApiConstant.userBackupDownloadUrl;
      final appId = BibleInfo.appID.toString();

      debugPrint('========== Library backup download ==========');
      debugPrint('POST URL: $downloadUrl');
      debugPrint('app_id: $appId');
      debugPrint('user_id: $userId');

      final request = await _downloadRequest();
      final streamed =
          await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      debugPrint('Download status: ${response.statusCode}');
      debugPrint(
          'Download bytes: ${response.bodyBytes.length}, content-type: ${response.headers['content-type']}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Download body: ${response.body}');
        Constants.showToast(
            'Could not download backup (${response.statusCode})');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final dir = Directory('${tempDir.path}/library_backup_download');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);

      zipFile = File('${dir.path}/${BibleInfo.bible_shortName}_Backup.zip');
      await zipFile.writeAsBytes(response.bodyBytes);

      encFile = await _encFileFromDownloadBytes(response.bodyBytes, dir);
      if (encFile == null || !await encFile.exists()) {
        Constants.showToast('No backup file found on server');
        return false;
      }

      debugPrint('Restoring from: ${encFile.path}');
      final result = await ExportDb.restoreBackupFromFile(encFile);
      debugPrint('========== End library backup download ==========');
      return result == null;
    } catch (e, st) {
      log('Library backup download failed: $e $st');
      debugPrint('Library backup download failed: $e');
      Constants.showToast(e.toString());
      return false;
    } finally {
      if (zipFile != null && await zipFile.exists()) {
        try {
          await zipFile.delete();
        } catch (_) {}
      }
      _downloadInProgress = false;
    }
  }

  /// Daily cloud backup after 2:00 AM local time (first app open after 2 AM).
  static Future<void> runScheduledBackupIfNeeded() async {
    final userId = await _loggedInUserId();
    if (userId == null) return;

    final now = DateTime.now();
    if (now.hour < 2) return;

    final last = await SharPreferences.getString(
        SharPreferences.lastScheduledCloudBackupDate);
    if (last == _todayKey()) return;

    unawaited(backupToCloud(markScheduled: true));
  }
}
