import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:biblebookapp/view/screens/chat/chat_translations.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';

class PrayerGuidanceScreen extends StatefulWidget {
  const PrayerGuidanceScreen({super.key});

  @override
  State<PrayerGuidanceScreen> createState() => _PrayerGuidanceScreenState();
}

class _PrayerGuidanceScreenState extends State<PrayerGuidanceScreen> {
  static const String _baseUrl =
      'https://my-backend-one-eta.vercel.app/api/gemini';

  final ScrollController _scrollController = ScrollController();
  final List<_GuidanceMessage> _messages = [];
  bool _isLoading = false;
  final TextEditingController _customPrayerController = TextEditingController();

  // Audio player for background music
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  bool _isAudioMuted = false;

  // AMEN toast overlay (shown slightly above bottom so it won't cover AMEN button)
  OverlayEntry? _amenToastEntry;
  Timer? _amenToastTimer;

  // Ad service for interstitial ads
  final AdService _adService = AdService();

  // Counter for AMEN button taps (show ad every 10 taps)
  int _amenTapCount = 0;

  // Background music asset path (without 'assets/' prefix as AssetSource adds it automatically)
  static const String _backgroundMusicUrl =
      'music/christian-rock-for-jesus-christ-always-301257.mp3';

  // Category translation keys (English keys for prompts, translated titles)
  final List<Map<String, String>> _categoryKeys = const [
    {
      'titleKey': 'prayer_thanksgiving',
      'prompt':
          'Write a short prayer of thanksgiving to God. Include 1-2 Geneva Bible verse references.',
    },
    {
      'titleKey': 'prayer_forgiveness',
      'prompt':
          'Help me pray for forgiveness and to forgive others. Include 1-2 Geneva Bible verse references.',
    },
    {
      'titleKey': 'prayer_guidance',
      'prompt':
          'Give me a prayer asking God for guidance and wisdom for decisions. Include 1-2 Geneva Bible verse references.',
    },
    {
      'titleKey': 'prayer_anxiety_peace',
      'prompt':
          'Give me a prayer for peace when I feel anxious. Include 1-2 Geneva Bible verse references.',
    },
    {
      'titleKey': 'prayer_healing',
      'prompt':
          'Give me a prayer for healing (body and heart). Include 1-2 Geneva Bible verse references.',
    },
    {
      'titleKey': 'prayer_family',
      'prompt':
          'Give me a prayer for family unity and protection. Include 1-2 Geneva Bible verse references.',
    },
    {
      'titleKey': 'prayer_strength',
      'prompt':
          'Give me a prayer for strength and courage during difficult times. Include 1-2 Geneva Bible verse references.',
    },
    {
      'titleKey': 'prayer_protection',
      'prompt':
          'Give me a prayer for protection and safety. Include 1-2 Geneva Bible verse references.',
    },
  ];

  // Get categories with translated titles
  List<_GuidanceCategory> get _categories => _categoryKeys
      .map((cat) => _GuidanceCategory(
            title: ChatTranslations.get(
                cat['titleKey']!, AppApiConstant.chatLanguage),
            prompt: cat['prompt']!,
          ))
      .toList();

  // Show insufficient credits toast with "Add Credits" button
  void _showInsufficientCreditsDialog() {
    // Show a styled snackbar with action button
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white.withOpacity(0.9),
              size: 22,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Insufficient credits. Please add credits.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6D4C41),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        action: SnackBarAction(
          label: 'Add Credits',
          textColor: const Color(0xFFFFF3E0),
          backgroundColor: const Color(0xFF8D6E63),
          disabledBackgroundColor: Colors.grey,
          onPressed: () {
            Get.to(() => const WalletScreen());
          },
        ),
      ),
    );
  }

  Future<void> _sendPrayerRequest(int categoryIndex) async {
    if (_isLoading) return;

    // Check internet connection
    final isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      Constants.showToast("No Internet Connection", 5000);
      return;
    }

    // Credits check (same as Chat)
    final chatCost = await WalletService.getChatCost();
    final hasCredits = await WalletService.getCredits() >= chatCost;
    if (!hasCredits) {
      _showInsufficientCreditsDialog();
      return;
    }

    final category = _categories[categoryIndex];

    setState(() {
      _messages.add(_GuidanceMessage(text: category.title, isUser: true));
      _isLoading = true;
    });

    try {
      final url = Uri.parse(_baseUrl);

      // Answer length instruction (same as ChatScreen)
      final answerLength = await WalletService.getAnswerLength();
      String answerLengthInstruction = '';
      switch (answerLength) {
        case 'small':
          answerLengthInstruction =
              'IMPORTANT: Provide a SHORT and concise answer. Keep your response brief (2-3 sentences maximum). Be direct and to the point.';
          break;
        case 'medium':
          answerLengthInstruction =
              'IMPORTANT: Provide a MEDIUM-length answer. Give a balanced response with some context and explanation (4-6 sentences). Include relevant details but stay focused.';
          break;
        case 'large':
          answerLengthInstruction =
              'IMPORTANT: Provide a FULL and comprehensive answer. Give a detailed response with thorough context, explanations, and relevant information (8+ sentences). Include historical context, theological meanings, and practical applications when relevant.';
          break;
        default:
          answerLengthInstruction =
              'Provide an appropriate answer based on the question.';
      }

      // Determine language instruction based on chatLanguage
      String languageInstruction = '';
      switch (AppApiConstant.chatLanguage) {
        case 'HI':
          languageInstruction =
              'IMPORTANT: Respond in HINDI language. Use Hindi script (Devanagari) for your entire response.';
          break;
        case 'TN':
          languageInstruction =
              'IMPORTANT: Respond in TAMIL language. Use Tamil script for your entire response.';
          break;
        default: // EN
          languageInstruction = 'IMPORTANT: Respond in ENGLISH language.';
      }

      final prompt = '''
You are a respectful assistant for the Geneva Bible. Always respond in plain text without asterisks (*) or markdown.
${languageInstruction}
${answerLengthInstruction}

Task:
${category.prompt}
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      String responseText = 'Sorry, I could not generate a response.';
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['output'] != null && responseData['output'] is Map) {
            final output = responseData['output'] as Map;
            if (output['candidates'] is List &&
                (output['candidates'] as List).isNotEmpty) {
              final candidate = (output['candidates'] as List)[0];
              if (candidate is Map &&
                  candidate['content'] is Map &&
                  candidate['content']['parts'] is List &&
                  (candidate['content']['parts'] as List).isNotEmpty) {
                final part = (candidate['content']['parts'] as List)[0];
                if (part is Map && part['text'] != null) {
                  responseText = part['text'].toString();
                }
              }
            }
          } else if (responseData['response'] != null) {
            responseText = responseData['response'].toString();
          } else if (responseData['text'] != null) {
            responseText = responseData['text'].toString();
          } else if (responseData['message'] != null) {
            responseText = responseData['message'].toString();
          }
        } catch (_) {}
      } else {
        responseText =
            'Error: Failed to get response (Status: ${response.statusCode})';
      }

      setState(() {
        _messages.add(_GuidanceMessage(text: responseText, isUser: false));
        _isLoading = false;
      });

      // Deduct credits only if we got a non-error response (same behavior as chat)
      final isErrorResponse =
          responseText.toLowerCase().contains('sorry, i could not generate') ||
              responseText.toLowerCase().startsWith('error:');
      if (!isErrorResponse) {
        await WalletService.deductCredits(chatCost);
        // Automatically unmute and play background music when prayer is generated
        _isAudioMuted = false;
        await _playBackgroundMusic();
      }

      _scrollToTop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_GuidanceMessage(
            text: 'Error: Something went wrong. Please try again.',
            isUser: false));
        _isLoading = false;
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _showRotatingAmenMessage() async {
    // Rotating AMEN messages
    final amenMessages = [
      "Your prayer has been heard.",
      "May your heart feel lighter.",
      "Grace covers every word spoken.",
    ];

    // Get current message index
    final messageIndex =
        await SharPreferences.getInt(SharPreferences.prayerAmenMessageIndex) ??
            0;

    // Get the message for this tap
    final message = amenMessages[messageIndex % amenMessages.length];

    // Show toast (slightly above bottom so it won't cover AMEN button)
    _showAmenOverlayToast(message);

    // Rotate to next message index for next tap
    final nextIndex = (messageIndex + 1) % amenMessages.length;
    await SharPreferences.setInt(
        SharPreferences.prayerAmenMessageIndex, nextIndex);
  }

  void _showAmenOverlayToast(String message) {
    if (!mounted) return;

    _amenToastTimer?.cancel();
    _amenToastEntry?.remove();
    _amenToastEntry = null;

    final overlay = Overlay.of(context);

    final bottomSafe = MediaQuery.of(context).padding.bottom;
    // Keep it above the bottom button area.
    final bottomOffset = bottomSafe + 90;

    _amenToastEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: bottomOffset,
        child: IgnorePointer(
          ignoring: true,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF745248).withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_amenToastEntry!);
    _amenToastTimer = Timer(const Duration(milliseconds: 2500), () {
      _amenToastEntry?.remove();
      _amenToastEntry = null;
    });
  }

  Future<void> _sendCustomPrayerRequest(String customRequest) async {
    if (_isLoading) return;
    if (customRequest.trim().isEmpty) {
      Constants.showToast("Please enter your prayer request", 3000);
      return;
    }

    // Check internet connection
    final isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      Constants.showToast("No Internet Connection", 5000);
      return;
    }

    // Credits check (same as Chat)
    final chatCost = await WalletService.getChatCost();
    final hasCredits = await WalletService.getCredits() >= chatCost;
    if (!hasCredits) {
      _showInsufficientCreditsDialog();
      return;
    }

    setState(() {
      _messages.add(_GuidanceMessage(text: customRequest, isUser: true));
      _isLoading = true;
    });

    try {
      final url = Uri.parse(_baseUrl);

      // Answer length instruction (same as ChatScreen)
      final answerLength = await WalletService.getAnswerLength();
      String answerLengthInstruction = '';
      switch (answerLength) {
        case 'small':
          answerLengthInstruction =
              'IMPORTANT: Provide a SHORT and concise answer. Keep your response brief (2-3 sentences maximum). Be direct and to the point.';
          break;
        case 'medium':
          answerLengthInstruction =
              'IMPORTANT: Provide a MEDIUM-length answer. Give a balanced response with some context and explanation (4-6 sentences). Include relevant details but stay focused.';
          break;
        case 'large':
          answerLengthInstruction =
              'IMPORTANT: Provide a FULL and comprehensive answer. Give a detailed response with thorough context, explanations, and relevant information (8+ sentences). Include historical context, theological meanings, and practical applications when relevant.';
          break;
        default:
          answerLengthInstruction =
              'Provide an appropriate answer based on the question.';
      }

      // Determine language instruction based on chatLanguage
      String languageInstruction = '';
      switch (AppApiConstant.chatLanguage) {
        case 'HI':
          languageInstruction =
              'IMPORTANT: Respond in HINDI language. Use Hindi script (Devanagari) for your entire response.';
          break;
        case 'TN':
          languageInstruction =
              'IMPORTANT: Respond in TAMIL language. Use Tamil script for your entire response.';
          break;
        default: // EN
          languageInstruction = 'IMPORTANT: Respond in ENGLISH language.';
      }

      final prompt = '''
You are a respectful assistant for the Geneva Bible. Always respond in plain text without asterisks (*) or markdown.
${languageInstruction}
${answerLengthInstruction}

Task:
Write a prayer based on the following request: ${customRequest.trim()}
Include 1-2 Geneva Bible verse references that relate to the request.
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      String responseText = 'Sorry, I could not generate a response.';
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['output'] != null && responseData['output'] is Map) {
            final output = responseData['output'] as Map;
            if (output['candidates'] is List &&
                (output['candidates'] as List).isNotEmpty) {
              final candidate = (output['candidates'] as List)[0];
              if (candidate is Map &&
                  candidate['content'] is Map &&
                  candidate['content']['parts'] is List &&
                  (candidate['content']['parts'] as List).isNotEmpty) {
                final part = (candidate['content']['parts'] as List)[0];
                if (part is Map && part['text'] != null) {
                  responseText = part['text'].toString();
                }
              }
            }
          } else if (responseData['response'] != null) {
            responseText = responseData['response'].toString();
          } else if (responseData['text'] != null) {
            responseText = responseData['text'].toString();
          } else if (responseData['message'] != null) {
            responseText = responseData['message'].toString();
          }
        } catch (_) {}
      } else {
        responseText =
            'Error: Failed to get response (Status: ${response.statusCode})';
      }

      setState(() {
        _messages.add(_GuidanceMessage(text: responseText, isUser: false));
        _isLoading = false;
      });

      // Deduct credits only if we got a non-error response (same behavior as chat)
      final isErrorResponse =
          responseText.toLowerCase().contains('sorry, i could not generate') ||
              responseText.toLowerCase().startsWith('error:');
      if (!isErrorResponse) {
        await WalletService.deductCredits(chatCost);
        // Automatically unmute and play background music when prayer is generated
        _isAudioMuted = false;
        await _playBackgroundMusic();
      }

      _scrollToTop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_GuidanceMessage(
            text: 'Error: Something went wrong. Please try again.',
            isUser: false));
        _isLoading = false;
      });
      _scrollToTop();
    }
  }

  void _showCustomPrayerDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: CommanColor.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Custom Prayer Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CommanColor.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _customPrayerController.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customPrayerController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter your prayer request...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF8B6F47)
                            : const Color(0xFFD4A574),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: TextStyle(
                    color: CommanColor.black,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final request = _customPrayerController.text.trim();
                      Navigator.of(context).pop();
                      _customPrayerController.clear();
                      if (request.isNotEmpty) {
                        _sendCustomPrayerRequest(request);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF8B6F47)
                          : const Color(0xFFD4A574),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Send Prayer Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF5C4033),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
        });
      }
    });

    // Load AMEN tap counter from SharedPreferences
    _loadAmenTapCount();

    // Load interstitial ad for AMEN button
    _loadInterstitialAd();
  }

  // Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    debugPrint('🔍 PRAYER AD: Loading interstitial ad...');
    _adService.loadInterstitialAd(() {
      debugPrint('✅ PRAYER AD: Interstitial ad loaded successfully');
      if (mounted) setState(() {});
    });
  }

  // Load AMEN tap counter
  Future<void> _loadAmenTapCount() async {
    final count =
        await SharPreferences.getInt(SharPreferences.prayerAmenAdCounter) ?? 0;
    setState(() {
      _amenTapCount = count;
    });
    debugPrint('🔍 AMEN: Loaded tap count = $_amenTapCount');
  }

  // Save AMEN tap counter
  Future<void> _saveAmenTapCount() async {
    await SharPreferences.setInt(
        SharPreferences.prayerAmenAdCounter, _amenTapCount);
    debugPrint('🔍 AMEN: Saved tap count = $_amenTapCount');
  }

  @override
  void dispose() {
    _amenToastTimer?.cancel();
    _amenToastEntry?.remove();
    _amenToastEntry = null;
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _customPrayerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    // Only play music when there are messages (responses displayed)
    if (_messages.isEmpty || _isAudioMuted) return;

    try {
      // Get current player state
      final currentState = _audioPlayer.state;

      // If already playing, don't restart
      if (currentState == PlayerState.playing) {
        return;
      }

      // Stop any existing playback first
      if (currentState != PlayerState.stopped) {
        await _audioPlayer.stop();
      }

      // Set the source from local asset
      await _audioPlayer.setSource(AssetSource(_backgroundMusicUrl));

      // Wait a moment for the source to be ready
      await Future.delayed(const Duration(milliseconds: 200));

      // Seek to beginning to ensure it starts from the start
      await _audioPlayer.seek(Duration.zero);

      // Resume/play the audio - this should work after setSourceUrl
      await _audioPlayer.resume();

      // State will be updated by the onPlayerStateChanged listener
    } catch (e) {
      debugPrint('Error playing background music: $e');
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
        });
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_isAudioMuted) {
      // Unmute - resume playing if it was playing
      _isAudioMuted = false;
      if (_isAudioPlaying) {
        await _audioPlayer.resume();
      } else {
        await _playBackgroundMusic();
      }
    } else {
      // Mute - pause the audio
      _isAudioMuted = true;
      await _audioPlayer.pause();
    }

    if (mounted) {
      setState(() {});
    }
  }

  // Show interstitial ad and wait for dismissal
  Future<void> _showInterstitialAdAndWait() async {
    final completer = Completer<void>();

    // Check if ad is available
    final ad = _adService.interstitialAd;
    debugPrint(
        '🔍 AD CHECK: _adService.interstitialAd = ${ad != null ? "LOADED" : "NULL"}');
    if (ad == null) {
      debugPrint('⚠️ AD: No ad loaded, skipping...');
      completer.complete(); // No ad available, proceed immediately
      return completer.future;
    }

    debugPrint('✅ AD: Showing interstitial ad now...');

    // Set up callback to complete when ad is dismissed
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) async {
        await SharPreferences.setString('OpenAd', '1');
        ad.dispose();
        debugPrint('✅ AD: Ad dismissed, reloading for next time...');
        _loadInterstitialAd(); // Reload ad for next time
        if (!completer.isCompleted) {
          completer.complete(); // Ad dismissed, proceed
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('❌ AD: Ad failed to show: $error, reloading...');
        _loadInterstitialAd(); // Reload ad for next time
        if (!completer.isCompleted) {
          completer.complete(); // Ad failed, proceed
        }
      },
      onAdShowedFullScreenContent: (ad) async {
        await SharPreferences.setString('OpenAd', '1');
        debugPrint('✅ AD: Ad is now showing...');
      },
    );

    // Show the ad
    ad.show();

    // Wait for ad to be dismissed or fail (with timeout)
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.complete(); // Timeout - proceed anyway
        }
      },
    );
  }

  // Build rich text with clickable verse references
  Widget _buildMessageWithVerseLinks(
      String text, bool isUser, Size size, bool isDark) {
    // Regex to match verse references like "Genesis 1:1", "John 3:16", "1 Corinthians 13:4-8"
    final versePattern = RegExp(
      r'(\d?\s?[A-Za-z]+\s+\d+:\d+(?:-\d+)?)',
      caseSensitive: false,
    );

    final matches = versePattern.allMatches(text);
    if (matches.isEmpty) {
      // No verse references, return regular text
      return Text(
        text,
        style: TextStyle(
          fontSize: size.width > 450 ? 18 : 16,
          height: 1.5,
          color: isUser ? Colors.white : CommanColor.whiteBlack(context),
          fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
        ),
      );
    }

    // Build text spans with clickable verse references
    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
        ));
      }

      // Add clickable verse reference
      final verseRef = match.group(0)!;
      spans.add(TextSpan(
        text: verseRef,
        style: TextStyle(
          color: isUser
              ? Colors.white
              : (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2)),
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Constants.showToast("Verse reference: $verseRef");
            // You can add navigation to the verse here if needed
          },
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after last match
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: size.width > 450 ? 18 : 16,
          height: 1.5,
          color: isUser ? Colors.white : CommanColor.whiteBlack(context),
          fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return WillPopScope(
      onWillPop: () async {
        // If viewing responses, go back to category selection view
        if (_messages.isNotEmpty) {
          debugPrint(
              '🔙 BACK BUTTON: System back pressed, clearing messages...');
          setState(() {
            _messages.clear();
            _isLoading = false;
            _customPrayerController.clear();
          });
          // Stop audio when going back to category view
          if (_isAudioPlaying) {
            await _audioPlayer.stop();
            setState(() {
              _isAudioPlaying = false;
            });
          }
          return false; // Stay on screen, just clear messages
        }
        // If on category selection view, close the screen
        debugPrint('🔙 BACK BUTTON: System back pressed, closing screen...');
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Images.bgImage(context)),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          // If viewing responses, go back to category selection view
                          if (_messages.isNotEmpty) {
                            debugPrint(
                                '🔙 BACK BUTTON: Back arrow pressed, clearing messages...');
                            setState(() {
                              _messages.clear();
                              _isLoading = false;
                              _customPrayerController.clear();
                            });
                            // Stop audio when going back to category view
                            if (_isAudioPlaying) {
                              await _audioPlayer.stop();
                              setState(() {
                                _isAudioPlaying = false;
                              });
                            }
                            return;
                          }
                          // If on category selection view, close the screen
                          debugPrint(
                              '🔙 BACK BUTTON: Back arrow pressed, closing screen...');
                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.arrow_back_ios,
                            color: CommanColor.whiteBlack(context), size: 18),
                      ),
                      const Spacer(),
                      // Audio ON/OFF toggle button - only show when responses are displayed
                      if (_messages.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          child: IconButton(
                            onPressed: _toggleAudio,
                            icon: Icon(
                              _isAudioMuted
                                  ? Icons.volume_off
                                  : Icons.music_note,
                              color: CommanColor.whiteBlack(context),
                              size: 22,
                            ),
                            tooltip: _isAudioMuted ? 'Audio Off' : 'Audio On',
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                ChatTranslations.get('prayer_guidance_title',
                                    AppApiConstant.chatLanguage),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CommanColor.whiteBlack(context)
                                      .withOpacity(0.7),
                                  fontSize: size.width > 450 ? 26 : 23,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text(
                                  ChatTranslations.get('get_guidance_need',
                                      AppApiConstant.chatLanguage),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: CommanColor.whiteBlack(context)
                                        .withOpacity(0.5),
                                    fontSize: size.width > 450 ? 16 : 15,
                                  ),
                                ),
                              ),
                              // Category cards in grid - 2 per row, each card triggers AI directly
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: size.width > 450 ? 16 : 12,
                                  mainAxisSpacing: size.width > 450 ? 16 : 12,
                                  childAspectRatio:
                                      size.width > 450 ? 1.4 : 1.3,
                                ),
                                itemCount: _categories.length + 1,
                                itemBuilder: (context, index) {
                                  // Check if this is the Custom Prayer card (first item)
                                  if (index == 0) {
                                    // Custom Prayer card
                                    final paperColor = isDark
                                        ? const Color(0xFF8B6F47)
                                        : const Color(0xFFD4A574);

                                    return InkWell(
                                      onTap: () {
                                        _showCustomPrayerDialog(context);
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              size.width > 450 ? 16 : 12,
                                          vertical: size.width > 450 ? 24 : 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: paperColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF6B5638)
                                                : const Color(0xFFB8956A),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.edit_note,
                                              size: size.width > 450 ? 32 : 28,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF5C4033),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              ChatTranslations.get(
                                                  'custom_prayer',
                                                  AppApiConstant.chatLanguage),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize:
                                                    size.width > 450 ? 17 : 15,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF5C4033),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // Regular category cards (adjust index since Custom Prayer is at 0)
                                  final categoryIndex = index - 1;
                                  // Get icon for each category
                                  IconData categoryIcon;

                                  switch (categoryIndex % 8) {
                                    case 0: // Thanksgiving
                                      categoryIcon = Icons.celebration;
                                      break;
                                    case 1: // Forgiving
                                      categoryIcon = Icons.favorite;
                                      break;
                                    case 2: // Guidance
                                      categoryIcon = Icons.lightbulb;
                                      break;
                                    case 3: // Anxiety & Peace
                                      categoryIcon = Icons.self_improvement;
                                      break;
                                    case 4: // Healing
                                      categoryIcon = Icons.healing;
                                      break;
                                    case 5: // Family
                                      categoryIcon = Icons.family_restroom;
                                      break;
                                    case 6: // Strength
                                      categoryIcon = Icons.fitness_center;
                                      break;
                                    default: // Protection
                                      categoryIcon = Icons.shield;
                                      break;
                                  }

                                  // Old paper/brown color
                                  final paperColor = isDark
                                      ? const Color(0xFF8B6F47)
                                      : const Color(0xFFD4A574);

                                  return InkWell(
                                    onTap: () {
                                      _sendPrayerRequest(categoryIndex);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: size.width > 450 ? 16 : 12,
                                        vertical: size.width > 450 ? 24 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: paperColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF6B5638)
                                              : const Color(0xFFB8956A),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            categoryIcon,
                                            size: size.width > 450 ? 32 : 28,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF5C4033),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _categories[categoryIndex].title,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  size.width > 450 ? 17 : 15,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF5C4033),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, idx) {
                            if (_isLoading && idx == _messages.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Please wait...',
                                    style: TextStyle(
                                      color: CommanColor.whiteBlack(context)
                                          .withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final message = _messages[idx];
                            final isUser = message.isUser;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Align(
                                alignment: isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: size.width * 0.78,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? CommanColor.lightDarkPrimary(context)
                                        : (isDark
                                            ? CommanColor.darkPrimaryColor
                                                .withOpacity(0.6)
                                            : Colors.white.withOpacity(0.85)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: !isUser && isDark
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: !isUser && isDark ? 1.2 : 0,
                                    ),
                                  ),
                                  child: _buildMessageWithVerseLinks(
                                    message.text,
                                    isUser,
                                    size,
                                    isDark,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // AMEN button at the bottom - only show when there are messages (responses)
                if (_messages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Increment AMEN tap counter
                          _amenTapCount++;
                          await _saveAmenTapCount(); // Save to SharedPreferences
                          debugPrint(
                              '🔍 AMEN: Tap count = $_amenTapCount / 10');

                          // Check if user is subscribed
                          final downloadProvider =
                              Provider.of<DownloadProvider>(context,
                                  listen: false);
                          final subscriptionPlan =
                              await downloadProvider.getSubscriptionPlan();
                          final isSubscribed = subscriptionPlan != null &&
                              subscriptionPlan.isNotEmpty &&
                              ['platinum', 'gold', 'silver']
                                  .contains(subscriptionPlan.toLowerCase());

                          debugPrint(
                              '🔍 AMEN: subscriptionPlan=$subscriptionPlan, isSubscribed=$isSubscribed');

                          // Show interstitial ad only for non-subscribed users AND every 10th tap (starting from tap 1)
                          if (!isSubscribed && _amenTapCount % 10 == 1) {
                            debugPrint(
                                '🔍 AMEN: 10th rotation reached (tap 1, 11, 21...)! User not subscribed, showing ad...');
                            try {
                              final hasInternet =
                                  await InternetConnection().hasInternetAccess;
                              if (hasInternet) {
                                // Check connection type
                                final connectivityResult =
                                    await Connectivity().checkConnectivity();
                                final isMobileOnly = connectivityResult
                                        .contains(ConnectivityResult.mobile) &&
                                    !connectivityResult
                                        .contains(ConnectivityResult.wifi) &&
                                    !connectivityResult
                                        .contains(ConnectivityResult.ethernet);

                                // Show ad if online with wifi/ethernet
                                if (!isMobileOnly) {
                                  debugPrint(
                                      '🔍 AMEN: Attempting to show ad...');
                                  try {
                                    await _showInterstitialAdAndWait();
                                    debugPrint(
                                        '🔍 AMEN: Ad shown successfully');
                                  } catch (e) {
                                    debugPrint('❌ AMEN: Error showing ad: $e');
                                  }
                                } else {
                                  debugPrint(
                                      '🔍 AMEN: Skipping ad (mobile-only connection)');
                                }
                              }
                            } catch (e) {
                              debugPrint(
                                  'Error checking subscription/internet: $e');
                            }
                          } else if (!isSubscribed) {
                            debugPrint(
                                '🔍 AMEN: Skipping ad (not 10th tap yet)');
                          } else {
                            debugPrint(
                                '🔍 AMEN: Skipping ad (user is subscribed)');
                          }

                          // Show Amen message after ad (or immediately if no ad)
                          _showRotatingAmenMessage();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF8B6F47)
                              : const Color(0xFFD4A574),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          ChatTranslations.get(
                              'amen_button', AppApiConstant.chatLanguage),
                          style: TextStyle(
                            fontSize: size.width > 450 ? 18 : 16,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF5C4033),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidanceCategory {
  final String title;
  final String prompt;

  const _GuidanceCategory({required this.title, required this.prompt});
}

class _GuidanceMessage {
  final String text;
  final bool isUser;

  const _GuidanceMessage({required this.text, required this.isUser});
}
