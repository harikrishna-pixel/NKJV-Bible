import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/main.dart';
import 'package:biblebookapp/services/smart_notification_helper.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/milestone_lifetime_paywall_coordinator.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:biblebookapp/view/screens/chat/chat_translations.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/setting_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/post_prayer_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:biblebookapp/view/widget/ai_gemini_privacy_banner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerGuidanceScreen extends StatefulWidget {
  const PrayerGuidanceScreen({super.key});

  @override
  State<PrayerGuidanceScreen> createState() => _PrayerGuidanceScreenState();
}

class _PrayerGuidanceScreenState extends State<PrayerGuidanceScreen>
    with SingleTickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  static const String _baseUrl =
      'https://my-backend-one-eta.vercel.app/api/gemini';

  final ScrollController _scrollController = ScrollController();
  final List<_GuidanceMessage> _messages = [];
  bool _isLoading = false;
  /// Invalidates in-flight API responses after back / community navigation.
  int _prayerRequestGeneration = 0;
  /// Category or custom title for the response header (not the AI body).
  String? _responseHeaderTitle;
  final TextEditingController _customPrayerController = TextEditingController();

  // Audio player for background music
  late AudioPlayer _audioPlayer;
  late AnimationController _musicSpinController;
  bool _isAudioPlaying = false;
  bool _isAudioMuted = false;

  // AMEN toast overlay (shown slightly above bottom so it won't cover AMEN button)
  OverlayEntry? _amenToastEntry;
  Timer? _amenToastTimer;

  // Track which AI responses have already shown an AMEN toast using a content hash
  final Set<int> _amenShownForResponseHashes = {};

  // Ad service for interstitial ads
  final AdService _adService = AdService();

  // Prevent back-button interstitial from firing multiple times (one ad per leave)
  bool _isClosingWithAd = false;

  // Counter for AMEN button taps (show ad every 10 taps)
  int _amenTapCount = 0;

  // Wallet credits (same as Chat screen)
  int _currentCredits = 0;
  Timer? _creditsTimer;

  // Intro answer length selection (shared with Chat intro behaviour)
  String _introAnswerLength = 'small';

  // Small subtitle lines for the UI (visual only, does not affect logic)
  final List<String> _categorySubtitles = const [
    'Give thanks & praise',
    'Seek & give grace',
    'Clarity & direction',
    'Find calm & rest',
    'Healing & strength',
    'Protection & unity',
    'Strength & courage',
    'Provision & wisdom',
    'Faith & encouragement',
    'Peace & comfort',
  ];

  /// Longer header lines on the prayer response screen (visual only).
  final List<String> _categoryInstructionalSubtitles = const [
    'Give thanks and praise to God for His goodness.',
    'Seek His forgiveness and extend grace to others.',
    'Ask God for wisdom and direction in your decisions.',
    'Bring your worries to God and receive His peace.',
    'Pray for healing in body, mind, and spirit.',
    'Lift your family to God for unity and protection.',
    'Ask God for strength and courage in hard times.',
    'Seek God\'s protection and safety in every season.',
    'Bring your feelings honestly before the Lord.',
    'Offer praise and worship to our faithful God.',
  ];

  static const Color _kPrayerCardCream = Color(0xFFFFFAF4);
  static const Color _kPrayerCardBorder = Color(0xFFE6D8C8);
  static const Color _kPrayerBrownDark = Color(0xFF4E342E);
  static const Color _kPrayerBrownMid = Color(0xFF6D4C41);

  Color _categoryAccentColor(int categoryIndex) {
    switch (categoryIndex) {
      case 0: // Thanksgiving
        return const Color(0xFFD4A017);
      case 1: // Forgiveness
        return const Color(0xFF1976D2);
      case 2: // Guidance
        return const Color(0xFF7B1FA2);
      case 3: // Anxiety & Peace
        return const Color(0xFFEF6C00);
      case 4: // Healing
        return const Color(0xFF388E3C);
      case 5: // Family
        return const Color(0xFF795548);
      default:
        return const Color(0xFF6D4C41);
    }
  }

  // UI mode: true => Pray for Me view (search + categories). Community navigates to PrayerWallScreen.
  int _communityPrayerCount = 0;
  bool _communityPrayerCountLoaded = false;
  late Future<bool> _showPrayerReminderPromptFuture;

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<bool> _shouldShowPrayerReminderPrompt() async {
    final status = await Permission.notification.status;
    final permitted =
        status.isGranted || status.isLimited || status.isProvisional;
    if (!permitted) return true;

    final hasNotificationsEnabled =
        await SmartNotificationHelper.userHasManualNotificationEnabled();
    return !hasNotificationsEnabled;
  }

  void _refreshPrayerReminderPrompt() {
    setState(() {
      _showPrayerReminderPromptFuture = _shouldShowPrayerReminderPrompt();
    });
  }

  Widget _buildDailyPrayerReminderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.42) : _kPrayerCardCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.22) : _kPrayerCardBorder,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: _kPrayerBrownDark.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : _kPrayerBrownMid.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month,
              color: isDark ? Colors.white : _kPrayerBrownMid,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Prayer Reminder',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF3D2914),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Set a reminder to keep\nyour prayer life strong.',
                  style: TextStyle(
                    color: (isDark ? Colors.white : const Color(0xFF3D2914))
                        .withOpacity(0.78),
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              await Get.to(
                () => const SettingScreen(notificationValue: false),
              );
              if (mounted) _refreshPrayerReminderPrompt();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kPrayerBrownMid,
                    _kPrayerBrownDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Set Reminder',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Background music asset path (without 'assets/' prefix as AssetSource adds it automatically)
  static const String _backgroundMusicUrl =
      'music/christian-rock-for-jesus-christ-always-301257.mp3';

  // Category translation keys (English keys for prompts, translated titles)
  final List<Map<String, String>> _categoryKeys = const [
    {
      'titleKey': 'prayer_thanksgiving',
      'prompt':
          'Write a short prayer of thanksgiving to God. Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_forgiveness',
      'prompt':
          'Help me pray for forgiveness and to forgive others. Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_guidance',
      'prompt':
          'Give me a prayer asking God for guidance and wisdom for decisions. Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_anxiety_peace',
      'prompt':
          'Give me a prayer for peace when I feel anxious. Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_healing',
      'prompt':
          'Give me a prayer for healing (body and heart). Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_family',
      'prompt':
          'Give me a prayer for family unity and protection. Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_strength',
      'prompt':
          'Give me a prayer for strength and courage during difficult times. Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_protection',
      'prompt':
          'Give me a prayer for protection and safety. Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_feelings',
      'prompt':
          'Give me a prayer to bring my feelings and emotions before God. Include 1-2 Bible verse references.',
    },
    {
      'titleKey': 'prayer_praise',
      'prompt':
          'Write a short prayer of praise and worship to God. Include 1-2 Bible verse references.',
    },
  ];

  String? _prayerHeaderTitle() {
    if (_responseHeaderTitle != null && _responseHeaderTitle!.isNotEmpty) {
      return _responseHeaderTitle;
    }
    for (final m in _messages) {
      if (m.isUser) return m.text;
    }
    return null;
  }

  void _resetPrayerChatView() {
    _prayerRequestGeneration++;
    _responseHeaderTitle = null;
    _customPrayerController.clear();
    if (!mounted) {
      _messages.clear();
      _isLoading = false;
      return;
    }
    setState(() {
      _messages.clear();
      _isLoading = false;
    });
    if (_isAudioPlaying) {
      _audioPlayer.stop();
      setState(() {
        _isAudioPlaying = false;
      });
    }
  }

  // Get categories with English titles only (do not translate)
  List<_GuidanceCategory> get _categories => _categoryKeys
      .map((cat) => _GuidanceCategory(
            title: ChatTranslations.get(cat['titleKey']!, 'EN'),
            prompt: cat['prompt']!,
          ))
      .toList();

  void _showInsufficientCreditsDialog() {
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

  String _sanitizePrayerResponseText(String text) {
    return text.replaceAll(
      RegExp(r'\s*\(Geneva(?:\s+Bible)?\)', caseSensitive: false),
      '',
    );
  }

  String _buildShareText(String text) {
    final androidLink =
        "https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}";
    final iosLink = "https://itunes.apple.com/app/id${BibleInfo.apple_AppId}";
    final storeLink = Platform.isIOS ? iosLink : androidLink;
    return "$text\n\nRead more at: $storeLink";
  }

  Future<void> _sendPrayerRequest(int categoryIndex) async {
    if (_isLoading) return;

    // Stop any currently playing prayer audio so only one audio plays at a time
    await _audioPlayer.stop();

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
    final requestId = ++_prayerRequestGeneration;

    setState(() {
      _responseHeaderTitle = category.title;
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
        case 'PT':
          languageInstruction =
              'IMPORTANT: Respond in PORTUGUESE language. Use Portuguese for your entire response.';
          break;
        case 'SQ':
          languageInstruction =
              'IMPORTANT: Respond in ALBANIAN language. Use Albanian for your entire response.';
          break;
        case 'AM':
          languageInstruction =
              'IMPORTANT: Respond in AMHARIC language. Use Amharic script for your entire response.';
          break;
        case 'AR':
          languageInstruction =
              'IMPORTANT: Respond in ARABIC language. Use Arabic script for your entire response.';
          break;
        case 'BN':
          languageInstruction =
              'IMPORTANT: Respond in BENGALI language. Use Bengali script for your entire response.';
          break;
        case 'ZH':
          languageInstruction =
              'IMPORTANT: Respond in CHINESE language. Use Chinese for your entire response.';
          break;
        case 'FR':
          languageInstruction =
              'IMPORTANT: Respond in FRENCH language. Use French for your entire response.';
          break;
        case 'DE':
          languageInstruction =
              'IMPORTANT: Respond in GERMAN language. Use German for your entire response.';
          break;
        case 'EL':
          languageInstruction =
              'IMPORTANT: Respond in GREEK language. Use Greek for your entire response.';
          break;
        case 'HE':
          languageInstruction =
              'IMPORTANT: Respond in HEBREW language. Use Hebrew script for your entire response.';
          break;
        case 'IG':
          languageInstruction =
              'IMPORTANT: Respond in IGBO language. Use Igbo for your entire response.';
          break;
        case 'ID':
          languageInstruction =
              'IMPORTANT: Respond in INDONESIAN language. Use Indonesian for your entire response.';
          break;
        case 'IT':
          languageInstruction =
              'IMPORTANT: Respond in ITALIAN language. Use Italian for your entire response.';
          break;
        case 'JA':
          languageInstruction =
              'IMPORTANT: Respond in JAPANESE language. Use Japanese for your entire response.';
          break;
        case 'KI':
          languageInstruction =
              'IMPORTANT: Respond in KIKUYU language. Use Kikuyu for your entire response.';
          break;
        case 'RW':
          languageInstruction =
              'IMPORTANT: Respond in KINYARWANDA language. Use Kinyarwanda for your entire response.';
          break;
        case 'KO':
          languageInstruction =
              'IMPORTANT: Respond in KOREAN language. Use Korean for your entire response.';
          break;
        case 'ML':
          languageInstruction =
              'IMPORTANT: Respond in MALAYALAM language. Use Malayalam script for your entire response.';
          break;
        case 'MY':
          languageInstruction =
              'IMPORTANT: Respond in BURMESE language. Use Burmese script for your entire response.';
          break;
        case 'NE':
          languageInstruction =
              'IMPORTANT: Respond in NEPALI language. Use Nepali (Devanagari) for your entire response.';
          break;
        case 'ES':
          languageInstruction =
              'IMPORTANT: Respond in SPANISH language. Use Spanish for your entire response.';
          break;
        case 'PA':
        case 'PN':
        case 'PAN':
        case 'PUN':
        case 'Punjabi':
        case 'PUNJABI':
          languageInstruction =
              'IMPORTANT: Respond in PUNJABI language. Use Punjabi (Gurmukhi) for your entire response.';
          break;
        case 'RO':
        case 'RM':
        case 'ROM':
        case 'Roman':
        case 'ROMAN':
        case 'Romanian':
        case 'ROMANIAN':
          languageInstruction =
              'IMPORTANT: Respond in ROMANIAN language. Use Romanian for your entire response.';
          break;
        case 'RU':
        case 'RUS':
        case 'Russian':
        case 'RUSSIAN':
          languageInstruction =
              'IMPORTANT: Respond in RUSSIAN language. Use Russian for your entire response.';
          break;
        case 'SW':
          languageInstruction =
              'IMPORTANT: Respond in SWAHILI language. Use Swahili for your entire response.';
          break;
        case 'SV':
          languageInstruction =
              'IMPORTANT: Respond in SWEDISH language. Use Swedish for your entire response.';
          break;
        case 'TL':
          languageInstruction =
              'IMPORTANT: Respond in TAGALOG language. Use Tagalog for your entire response.';
          break;
        case 'TE':
          languageInstruction =
              'IMPORTANT: Respond in TELUGU language. Use Telugu script for your entire response.';
          break;
        case 'TW':
          languageInstruction =
              'IMPORTANT: Respond in TWI language. Use Twi for your entire response.';
          break;
        case 'UK':
          languageInstruction =
              'IMPORTANT: Respond in UKRAINIAN language. Use Ukrainian for your entire response.';
          break;
        case 'UR':
          languageInstruction =
              'IMPORTANT: Respond in URDU language. Use Urdu script for your entire response.';
          break;
        case 'VI':
          languageInstruction =
              'IMPORTANT: Respond in VIETNAMESE language. Use Vietnamese for your entire response.';
          break;
        case 'YO':
          languageInstruction =
              'IMPORTANT: Respond in YORUBA language. Use Yoruba for your entire response.';
          break;
        case 'ZU':
          languageInstruction =
              'IMPORTANT: Respond in ZULU language. Use Zulu for your entire response.';
          break;
        default: // EN
          languageInstruction = 'IMPORTANT: Respond in ENGLISH language.';
      }

      final prompt = '''
You are a respectful assistant for the ${BibleInfo.bible_shortName}. Always respond in plain text without asterisks (*) or markdown.
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
      print(response.body);
      print(response.statusCode);

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

      responseText = _sanitizePrayerResponseText(responseText);

      if (!mounted || requestId != _prayerRequestGeneration) return;
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
        if (mounted && requestId == _prayerRequestGeneration) {
          final prefs = await SharedPreferences.getInstance();
          final creditDebitShown =
              prefs.getBool('prayer_credit_debit_shown') ?? false;
          if (!creditDebitShown) {
            Constants.showToast(
                'Used $chatCost credits for this response', 1500);
            await prefs.setBool('prayer_credit_debit_shown', true);
          }
          _loadCreditsFromLocal();
        }
        if (requestId == _prayerRequestGeneration) {
        await updateBiblePrayerWidget(prayerText: responseText);
        }
        // Prayer milestone paywall: keep bg music silent during dialog → lifetime offer.
        if (mounted && requestId == _prayerRequestGeneration) {
          if (_isAudioPlaying) {
            await _audioPlayer.stop();
            setState(() => _isAudioPlaying = false);
          }
          final prefs = await SharedPreferences.getInstance();
          const milestoneDoneKey = 'milestone_prayer_10_flow_done_v1';
          final milestoneDoneBefore =
              prefs.getBool(milestoneDoneKey) ?? false;
        await MilestoneLifetimePaywallCoordinator
            .onPrayerGuidanceAiResponseSuccess(context);
          if (!mounted || requestId != _prayerRequestGeneration) return;
          final milestoneDoneAfter =
              prefs.getBool(milestoneDoneKey) ?? false;
          if (milestoneDoneBefore || !milestoneDoneAfter) {
            await _playBackgroundMusic();
          }
        }
      }

      _scrollToTop();
    } catch (e) {
      if (!mounted || requestId != _prayerRequestGeneration) return;
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

    // Stop any currently playing prayer audio so only one audio plays at a time
    await _audioPlayer.stop();

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

    final requestId = ++_prayerRequestGeneration;
    final headerTitle = customRequest.trim().length <= 80
        ? customRequest.trim()
        : '${customRequest.trim().substring(0, 80)}...';

    setState(() {
      _responseHeaderTitle = headerTitle;
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
        case 'PT':
          languageInstruction =
              'IMPORTANT: Respond in PORTUGUESE language. Use Portuguese for your entire response.';
          break;
        case 'SQ':
          languageInstruction =
              'IMPORTANT: Respond in ALBANIAN language. Use Albanian for your entire response.';
          break;
        case 'AM':
          languageInstruction =
              'IMPORTANT: Respond in AMHARIC language. Use Amharic script for your entire response.';
          break;
        case 'AR':
          languageInstruction =
              'IMPORTANT: Respond in ARABIC language. Use Arabic script for your entire response.';
          break;
        case 'BN':
          languageInstruction =
              'IMPORTANT: Respond in BENGALI language. Use Bengali script for your entire response.';
          break;
        case 'ZH':
          languageInstruction =
              'IMPORTANT: Respond in CHINESE language. Use Chinese for your entire response.';
          break;
        case 'FR':
          languageInstruction =
              'IMPORTANT: Respond in FRENCH language. Use French for your entire response.';
          break;
        case 'DE':
          languageInstruction =
              'IMPORTANT: Respond in GERMAN language. Use German for your entire response.';
          break;
        case 'EL':
          languageInstruction =
              'IMPORTANT: Respond in GREEK language. Use Greek for your entire response.';
          break;
        case 'HE':
          languageInstruction =
              'IMPORTANT: Respond in HEBREW language. Use Hebrew script for your entire response.';
          break;
        case 'IG':
          languageInstruction =
              'IMPORTANT: Respond in IGBO language. Use Igbo for your entire response.';
          break;
        case 'ID':
          languageInstruction =
              'IMPORTANT: Respond in INDONESIAN language. Use Indonesian for your entire response.';
          break;
        case 'IT':
          languageInstruction =
              'IMPORTANT: Respond in ITALIAN language. Use Italian for your entire response.';
          break;
        case 'JA':
          languageInstruction =
              'IMPORTANT: Respond in JAPANESE language. Use Japanese for your entire response.';
          break;
        case 'KI':
          languageInstruction =
              'IMPORTANT: Respond in KIKUYU language. Use Kikuyu for your entire response.';
          break;
        case 'RW':
          languageInstruction =
              'IMPORTANT: Respond in KINYARWANDA language. Use Kinyarwanda for your entire response.';
          break;
        case 'KO':
          languageInstruction =
              'IMPORTANT: Respond in KOREAN language. Use Korean for your entire response.';
          break;
        case 'ML':
          languageInstruction =
              'IMPORTANT: Respond in MALAYALAM language. Use Malayalam script for your entire response.';
          break;
        case 'MY':
          languageInstruction =
              'IMPORTANT: Respond in BURMESE language. Use Burmese script for your entire response.';
          break;
        case 'NE':
          languageInstruction =
              'IMPORTANT: Respond in NEPALI language. Use Nepali (Devanagari) for your entire response.';
          break;
        case 'ES':
          languageInstruction =
              'IMPORTANT: Respond in SPANISH language. Use Spanish for your entire response.';
          break;
        case 'PA':
        case 'PN':
        case 'PAN':
        case 'PUN':
        case 'Punjabi':
        case 'PUNJABI':
          languageInstruction =
              'IMPORTANT: Respond in PUNJABI language. Use Punjabi (Gurmukhi) for your entire response.';
          break;
        case 'RO':
        case 'RM':
        case 'ROM':
        case 'Roman':
        case 'ROMAN':
        case 'Romanian':
        case 'ROMANIAN':
          languageInstruction =
              'IMPORTANT: Respond in ROMANIAN language. Use Romanian for your entire response.';
          break;
        case 'RU':
        case 'RUS':
        case 'Russian':
        case 'RUSSIAN':
          languageInstruction =
              'IMPORTANT: Respond in RUSSIAN language. Use Russian for your entire response.';
          break;
        case 'SW':
          languageInstruction =
              'IMPORTANT: Respond in SWAHILI language. Use Swahili for your entire response.';
          break;
        case 'SV':
          languageInstruction =
              'IMPORTANT: Respond in SWEDISH language. Use Swedish for your entire response.';
          break;
        case 'TL':
          languageInstruction =
              'IMPORTANT: Respond in TAGALOG language. Use Tagalog for your entire response.';
          break;
        case 'TE':
          languageInstruction =
              'IMPORTANT: Respond in TELUGU language. Use Telugu script for your entire response.';
          break;
        case 'TW':
          languageInstruction =
              'IMPORTANT: Respond in TWI language. Use Twi for your entire response.';
          break;
        case 'UK':
          languageInstruction =
              'IMPORTANT: Respond in UKRAINIAN language. Use Ukrainian for your entire response.';
          break;
        case 'UR':
          languageInstruction =
              'IMPORTANT: Respond in URDU language. Use Urdu script for your entire response.';
          break;
        case 'VI':
          languageInstruction =
              'IMPORTANT: Respond in VIETNAMESE language. Use Vietnamese for your entire response.';
          break;
        case 'YO':
          languageInstruction =
              'IMPORTANT: Respond in YORUBA language. Use Yoruba for your entire response.';
          break;
        case 'ZU':
          languageInstruction =
              'IMPORTANT: Respond in ZULU language. Use Zulu for your entire response.';
          break;
        default: // EN
          languageInstruction = 'IMPORTANT: Respond in ENGLISH language.';
      }

      final prompt = '''
You are a respectful assistant for the ${BibleInfo.bible_shortName}. Always respond in plain text without asterisks (*) or markdown.
${languageInstruction}
${answerLengthInstruction}

Task:
Write a prayer based on the following request: ${customRequest.trim()}
Include 1-2 ${BibleInfo.bible_shortName} verse references that relate to the request.
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

      responseText = _sanitizePrayerResponseText(responseText);

      if (!mounted || requestId != _prayerRequestGeneration) return;
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
        if (mounted && requestId == _prayerRequestGeneration) {
          final prefs = await SharedPreferences.getInstance();
          final creditDebitShown =
              prefs.getBool('prayer_credit_debit_shown') ?? false;
          if (!creditDebitShown) {
            Constants.showToast(
                'Used $chatCost credits for this response', 1500);
            await prefs.setBool('prayer_credit_debit_shown', true);
          }
          _loadCreditsFromLocal();
        }
        if (requestId == _prayerRequestGeneration) {
        await updateBiblePrayerWidget(prayerText: responseText);
        }
        // Prayer milestone paywall: keep bg music silent during dialog → lifetime offer.
        if (mounted && requestId == _prayerRequestGeneration) {
          if (_isAudioPlaying) {
            await _audioPlayer.stop();
            setState(() => _isAudioPlaying = false);
          }
          final prefs = await SharedPreferences.getInstance();
          const milestoneDoneKey = 'milestone_prayer_10_flow_done_v1';
          final milestoneDoneBefore =
              prefs.getBool(milestoneDoneKey) ?? false;
        await MilestoneLifetimePaywallCoordinator
            .onPrayerGuidanceAiResponseSuccess(context);
          if (!mounted || requestId != _prayerRequestGeneration) return;
          final milestoneDoneAfter =
              prefs.getBool(milestoneDoneKey) ?? false;
          if (milestoneDoneBefore || !milestoneDoneAfter) {
            await _playBackgroundMusic();
          }
        }
      }

      _scrollToTop();
    } catch (e) {
      if (!mounted || requestId != _prayerRequestGeneration) return;
      setState(() {
        _messages.add(_GuidanceMessage(
            text: 'Error: Something went wrong. Please try again.',
            isUser: false));
        _isLoading = false;
      });
      _scrollToTop();
    }
  }

  String _derivedPrayerTitleForWall(String request) {
    final firstLine = request.split(RegExp(r'\r?\n')).first.trim();
    if (firstLine.isEmpty) return 'My prayer';
    if (firstLine.length <= 120) return firstLine;
    return firstLine.substring(0, 120);
  }

  /// After custom prayer text is entered: user chooses Prayer Wall vs existing chat flow.
  Future<void> _showPublishOrChatChoice(String request) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final bg = isDark
        ? CommanColor.darkPrimaryColor
        : const Color(0xFFF5F0E6);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Share your prayer',
            style: TextStyle(
              color: isDark ? Colors.white : brown,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Publish to the Prayer Wall for others to pray with you, or continue here for guidance in chat.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade800,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _sendCustomPrayerRequest(request);
              },
              child: Text(
                'Chat here',
                style: TextStyle(
                  color: isDark ? Colors.white70 : brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                final nav = Navigator.of(context);
                final posted = await nav.push<bool>(
                  MaterialPageRoute(
                    builder: (_) => PostPrayerScreen(
                      initialTitle: _derivedPrayerTitleForWall(request),
                      initialDescription: request,
                      initialCategory: 'Others',
                    ),
                  ),
                );
                if (!mounted) return;
                if (posted == true) {
                  await nav.push(
                    MaterialPageRoute(
                      builder: (_) => const PrayerWallScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
              ),
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomPrayerDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final bgColor = isDark
        ? CommanColor.darkPrimaryColor
        : const Color(0xFFF5F0E6);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top row: back only (wallet already shown in main header)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: isDark ? Colors.white : const Color(0xFF3D2914),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _customPrayerController.clear();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Praying hands, title, subtitle
                    Icon(
                      Icons.volunteer_activism,
                      size: 48,
                      color: isDark ? Colors.white70 : const Color(0xFF5C4033),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'My Prayer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF3D2914),
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ChatTranslations.get('get_guidance_need', 'EN'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF6D6D6D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Card: What's on your heart, description, field, button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white24 : const Color(0xFFE0D5C8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "What's on your heart today?",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF3D2914),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Let your prayer begin with a thought or feeling.",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : const Color(0xFF6D6D6D),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _customPrayerController,
                            maxLines: 4,
                            maxLength: 300,
                            decoration: InputDecoration(
                              hintText: 'Speak from the soul...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF8B6F47)
                                      : const Color(0xFF5C4033),
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                              counterText: '',
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : CommanColor.black,
                              fontSize: 15,
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _customPrayerController,
                            builder: (context, value, _) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${value.text.length}/300',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _customPrayerController,
                              builder: (context, value, _) {
                                final hasText = value.text.trim().isNotEmpty;
                                return ElevatedButton(
                                  onPressed: hasText
                                      ? () async {
                                          final isConnected =
                                              await InternetConnection()
                                                  .hasInternetAccess;
                                          if (!isConnected) {
                                            Constants.showToast(
                                                'No internet connection',
                                                5000);
                                            return;
                                          }
                                          final request =
                                              _customPrayerController.text.trim();
                                          Navigator.of(dialogContext).pop();
                                          _customPrayerController.clear();
                                          if (request.isNotEmpty && mounted) {
                                            await _showPublishOrChatChoice(
                                                request);
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? CommanColor.darkPrimaryColor
                                        : const Color(0xFFD4A574),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Get Prayer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF5C4033),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _syncMusicIconAnimation() {
    if (_isAudioMuted || !_isAudioPlaying) {
      if (_musicSpinController.isAnimating) {
        _musicSpinController.stop();
      }
    } else if (!_musicSpinController.isAnimating) {
      _musicSpinController.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _musicSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
        });
        _syncMusicIconAnimation();
      }
    });

    // Load AMEN tap counter from SharedPreferences
    _loadAmenTapCount();

    // Load interstitial ad for AMEN button
    _loadInterstitialAd();

    // Refresh chat language so UI reflects app language
    AppApiConstant.loadChatLanguage().then((_) {
      if (mounted) setState(() {});
    });

    // Load credits and refresh periodically (same as Chat screen)
    _loadCreditsFromLocal();
    _creditsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadCreditsFromLocal();
    });

    WidgetsBinding.instance.addObserver(this);
    _showPrayerReminderPromptFuture = _shouldShowPrayerReminderPrompt();

    // Show shared answer-length intro if needed (same behaviour as Chat).
    _showPrayerIntroIfNeeded();
    _refreshCommunityLiveIndicator();
    _loadPersistedMusicMuted();
  }

  Future<void> _loadPersistedMusicMuted() async {
    final muted = await SharPreferences.getBoolean(
            SharPreferences.streakFlowMusicMuted) ??
        false;
    if (!mounted) return;
    setState(() => _isAudioMuted = muted);
    if (muted) {
      try {
        await _audioPlayer.pause();
      } catch (_) {}
    }
  }

  Future<void> _refreshCommunityLiveIndicator() async {
    try {
      final online = await InternetConnection().hasInternetAccess;
      if (mounted) {
        setState(() {
          _communityPrayerCountLoaded = false;
          if (!online) _communityPrayerCount = 0;
        });
      }
      if (!online) return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _communityPrayerCountLoaded = false;
          _communityPrayerCount = 0;
        });
      }
      return;
    }

    try {
      final prayers = await PrayerWallService.fetchPrayers();
      final seenIds = await PrayerWallLocalStore.loadSeenPrayerIds();
      if (!mounted) return;
      setState(() {
        _communityPrayerCount =
            prayers.where((p) => !seenIds.contains(p.id)).length;
        _communityPrayerCountLoaded = true;
      });
    } catch (_) {
      // Keep live dot when online; count fetch failed.
    }
  }

  Future<void> _loadCreditsFromLocal() async {
    try {
      final credits = await WalletService.getCredits();
      if (mounted && credits != _currentCredits) {
        setState(() {
          _currentCredits = credits;
        });
      }
    } catch (e) {
      debugPrint('redits load error: $e');
    }
  }

  /// Show the shared "Select Answer Length" intro once, same as Chat screen.
  Future<void> _showPrayerIntroIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('chat_intro_seen') ?? false;
    if (seenIntro || !mounted) return;

    final length = await WalletService.getAnswerLength();
    if (!mounted) return;
    setState(() {
      _introAnswerLength = length;
    });
    if (!mounted) return;
    await _showPrayerIntroDialog();
  }

  Future<void> _showPrayerIntroDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final initialCredits = await WalletService.getCredits();
    final noticeSeen = await SharPreferences.getBoolean(
            SharPreferences.aiGeminiPrivacyNoticeSeen) ??
        false;
    var showGeminiBanner = !noticeSeen;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        reverseDuration: Duration(milliseconds: 400),
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? CommanColor.darkPrimaryColor : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with gradient (styled like provided mock)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CommanColor.lightDarkPrimary(context),
                                CommanColor.lightDarkPrimary(context)
                                    .withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth > 450 ? 28 : 24,
                            horizontal: screenWidth > 450 ? 24 : 20,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                size: screenWidth > 450 ? 40 : 36,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Welcome to Bible Guidance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      screenWidth > 450 ? 22 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose your preferred answer style',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize:
                                      screenWidth > 450 ? 15 : 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      screenWidth > 450 ? 16 : 14,
                                  vertical:
                                      screenWidth > 450 ? 10 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.white,
                                      size:
                                          screenWidth > 450 ? 20 : 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'You have $initialCredits credits',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth > 450
                                            ? 15
                                            : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Padding(
                          padding: EdgeInsets.all(
                              screenWidth > 450 ? 24 : 20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : CommanColor.lightDarkPrimary(
                                              context)
                                          .withOpacity(0.05),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : CommanColor
                                                .lightDarkPrimary(
                                                    context)
                                            .withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.12)
                                            : CommanColor.lightDarkPrimary(
                                                    context)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: isDark
                                            ? Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.35),
                                                width: 1,
                                              )
                                            : null,
                                      ),
                                      child: Icon(
                                      Icons.lightbulb_outline,
                                        color: isDark
                                            ? const Color(0xFFFFD54F)
                                            : CommanColor.lightDarkPrimary(
                                              context),
                                      size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Each response uses credits. You can change this anytime in your Wallet.',
                                        style: TextStyle(
                                          color: CommanColor
                                                  .whiteBlack(context)
                                              .withOpacity(0.8),
                                          fontSize: screenWidth > 450
                                              ? 14
                                              : 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Select Answer Length',
                                style: TextStyle(
                                  color: CommanColor
                                      .whiteBlack(context),
                                  fontSize: screenWidth > 450
                                      ? 17
                                      : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPrayerIntroAnswerLengthOption(
                                context: context,
                                screenWidth: screenWidth,
                                isDark: isDark,
                                length: 'small',
                                title: 'Short Answer',
                                description: 'Quick & concise response',
                                cost: '20 Credits',
                                setBottomSheetState: setBottomSheetState,
                              ),
                              const SizedBox(height: 12),
                              _buildPrayerIntroAnswerLengthOption(
                                context: context,
                                screenWidth: screenWidth,
                                isDark: isDark,
                                length: 'medium',
                                title: 'Medium Answer',
                                description: 'Balanced explanation',
                                cost: '50 Credits',
                                setBottomSheetState: setBottomSheetState,
                              ),
                              const SizedBox(height: 12),
                              _buildPrayerIntroAnswerLengthOption(
                                context: context,
                                screenWidth: screenWidth,
                                isDark: isDark,
                                length: 'large',
                                title: 'Full Study',
                                description: 'Detailed & comprehensive',
                                cost: '100 Credits',
                                setBottomSheetState: setBottomSheetState,
                              ),
                            ],
                          ),
                            ),
                          ),
                        ),
                        if (showGeminiBanner)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              screenWidth > 450 ? 24 : 20,
                              8,
                              screenWidth > 450 ? 24 : 20,
                              0,
                            ),
                            child: AiGeminiPrivacyBanner(
                              onNoticeSeen: () {
                                setBottomSheetState(() {
                                  showGeminiBanner = false;
                                });
                              },
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            screenWidth > 450 ? 24 : 20,
                            10,
                            screenWidth > 450 ? 24 : 20,
                            MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                      side: isDark
                                          ? const BorderSide(
                                          color: Colors.white, width: 1.5)
                                          : BorderSide.none,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () async {
                                    final prefs =
                                    await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                        'chat_intro_seen', true);
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Ink(
                                    decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF763201),
                                          Color(0xFFD5821F),
                                          Color(0xFF763201),
                                        ],
                                      ),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.symmetric(
                                    vertical:
                                        screenWidth > 450 ? 16 : 14,
                                      ),
                                      child: Text(
                                        'Continue',
                                        style: TextStyle(
                                          color: Colors.white,
                                      fontSize:
                                          screenWidth > 450 ? 17 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
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
      },
    );
  }

  Widget _buildPrayerIntroAnswerLengthOption({
    required BuildContext context,
    required double screenWidth,
    required bool isDark,
    required String length,
    required String title,
    required String description,
    required String cost,
    required StateSetter setBottomSheetState,
  }) {
    final isSelected = _introAnswerLength == length;

    return InkWell(
      onTap: () async {
        await WalletService.setAnswerLength(length);
        if (mounted) {
          setState(() {
            _introAnswerLength = length;
          });
          setBottomSheetState(() {
            _introAnswerLength = length;
          });
          Constants.showToast('$title selected', 5000);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withOpacity(0.14)
                  : CommanColor.lightDarkPrimary(context).withOpacity(0.08))
              : (isDark
                  ? Colors.black.withOpacity(0.22)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark
                    ? const Color(0xFFFFD54F)
                    : CommanColor.lightDarkPrimary(context))
                : (isDark
                    ? Colors.white.withOpacity(0.22)
                    : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark
                          ? Colors.white
                          : CommanColor.lightDarkPrimary(context))
                      : (isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.grey.shade400),
                  width: 2,
                ),
                color: isSelected
                    ? (isDark
                        ? Colors.white
                        : CommanColor.lightDarkPrimary(context))
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF3D2914)
                              : Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context),
                      fontSize: screenWidth > 450 ? 16 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context)
                          .withOpacity(0.6),
                      fontSize: screenWidth > 450 ? 13 : 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 450 ? 12 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? const Color(0xFFFFD54F)
                        : CommanColor.lightDarkPrimary(context))
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : CommanColor.lightDarkPrimary(context)
                            .withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cost,
                style: TextStyle(
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF3D2914)
                          : Colors.white)
                      : (isDark
                          ? Colors.white.withOpacity(0.88)
                          : CommanColor.lightDarkPrimary(context)),
                  fontSize: screenWidth > 450 ? 14 : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPopNext() {
    _refreshPrayerReminderPrompt();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPrayerReminderPrompt();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _creditsTimer?.cancel();
    _amenToastTimer?.cancel();
    _amenToastEntry?.remove();
    _amenToastEntry = null;
    _musicSpinController.dispose();
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

    await SharPreferences.setBoolean(
        SharPreferences.streakFlowMusicMuted, _isAudioMuted);

    if (mounted) {
      setState(() {});
      _syncMusicIconAnimation();
    }
  }

  /// Show interstitial for unsubscribed users then pop. Call when user taps Back to leave the screen.
  /// Guarded so only one interstitial shows per leave (no repeated triggers).
  Future<void> _maybeShowInterstitialAndPop() async {
    if (_isClosingWithAd) {
      if (mounted) Get.back();
      return;
    }
    _isClosingWithAd = true;

    // Prefer a smooth back animation: only wait for an interstitial if it is
    // already loaded. Never block on network/subscription checks.
    final adReady = _adService.interstitialAd != null;
    if (adReady && mounted) {
      try {
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);
        final subscriptionPlan = await downloadProvider
            .getSubscriptionPlan()
            .timeout(const Duration(milliseconds: 200), onTimeout: () => null);
    final isSubscribed = subscriptionPlan != null &&
        subscriptionPlan.isNotEmpty &&
            ['platinum', 'gold', 'silver']
                .contains(subscriptionPlan.toLowerCase());
    if (!isSubscribed) {
        final lastStr = await SharPreferences.getString(
            SharPreferences.lastBackInterstitialTime);
        final now = DateTime.now();
        final canShowByTime = lastStr == null ||
            lastStr.isEmpty ||
            now.difference(DateTime.tryParse(lastStr) ?? now).inMinutes >= 3;
        if (canShowByTime) {
              await _showInterstitialAdAndWait();
              await SharPreferences.setString(
                  SharPreferences.lastBackInterstitialTime,
                  now.toIso8601String());
          }
        }
      } catch (_) {}
    }

    if (mounted) Get.back();
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

  // Parse verse reference to extract book, chapter, and verse
  Map<String, dynamic>? _parseVerseReference(String verseRef) {
    try {
      // Pattern to match verse references like "John 3:16", "Genesis 1:1", "1 Corinthians 13:4"
      final pattern = RegExp(
        r'\b([1-3]?\s?[A-Za-z]{2,})\s+(\d{1,3}):(\d{1,3})',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(verseRef);
      if (match != null) {
        String bookName = match.group(1)?.trim() ?? '';
        final chapter = int.tryParse(match.group(2) ?? '');
        final verse = int.tryParse(match.group(3) ?? '');
        if (chapter != null && verse != null && bookName.isNotEmpty) {
          // Capitalize first letter of each word in book name
          bookName = bookName
              .split(' ')
              .map((word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '')
              .join(' ');

          return {
            'bookName': bookName,
            'chapter': chapter,
            'verse': verse,
          };
        }
      }
    } catch (e) {
      debugPrint('Error parsing verse reference: $e');
    }
    return null;
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
    final baseFontSize = size.width > 450 ? 18.0 : 16.0;

    if (matches.isEmpty) {
      // No verse references, return regular text
      return Text(
        text,
        style: TextStyle(
          fontSize: baseFontSize,
          height: 1.6,
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

      // Add verse reference (no underline)
      final verseRef = match.group(0)!;
      spans.add(TextSpan(
        text: verseRef,
        style: TextStyle(
          color: isUser
              ? Colors.white
              : (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2)),
          fontWeight: FontWeight.w600,
        ),
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
          fontSize: baseFontSize,
          height: 1.6,
          color: isUser ? Colors.white : CommanColor.whiteBlack(context),
          fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
        ),
        children: spans,
      ),
    );
  }

  bool _prayerGuidanceIsMainScreen() => _messages.isEmpty;

  bool _prayerGuidanceHasAiResponse() =>
      _messages.any((message) => !message.isUser);

  bool _isPrayerGenerationError(String text) {
    final lower = text.trim().toLowerCase();
    return lower.contains('sorry, i could not generate') ||
        lower.contains('could not generate a prayer') ||
        lower.startsWith('error:');
  }

  bool _prayerGuidanceHasValidPrayerContent() => _messages.any(
        (message) =>
            !message.isUser && !_isPrayerGenerationError(message.text),
      );

  static const Color _kPrayerGuidanceInk = Color(0xFF3D2914);
  static const Color _kPrayerGuidanceGold = Color(0xFFC59434);
  static const Color _kPrayerGuidanceCream = Color(0xFFF8F4EE);
  static const String _kPrayerGuidanceBg = 'assets/prayer_gudiance-bg.png';
  static const String _kPrayerCreatingBg = 'assets/creating_prayer.png';

  bool _prayerGuidanceIsCreatingView() =>
      _isLoading && !_prayerGuidanceHasAiResponse();

  String? _categoryIconAsset(int categoryIndex) {
    switch (categoryIndex) {
      case 0:
        return 'assets/prayer_guidance_icons/Thanksgiving.png';
      case 1:
        return 'assets/prayer_guidance_icons/Forgiveness.png';
      case 2:
        return 'assets/prayer_guidance_icons/guidance.png';
      case 3:
        return 'assets/prayer_guidance_icons/Anxiety.png';
      case 4:
        return 'assets/prayer_guidance_icons/Healing.png';
      case 5:
        return 'assets/prayer_guidance_icons/family.png';
      default:
        return null;
    }
  }

  Widget _prayerGuidanceHomeHeaderIcon(Size size, {required bool isDark}) {
    final iconSize = size.width > 450 ? 52.0 : 48.0;
    return Icon(
      Icons.volunteer_activism,
      size: iconSize,
      color: isDark ? Colors.white70 : const Color(0xFF5C4033),
    );
  }

  Widget _prayerGuidanceReadableCaption(
    String text, {
    required bool isDark,
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.4)
            : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withOpacity(0.94)
                : const Color(0xFF3D2914),
          ),
        ),
      ),
    );
  }

  Widget _prayerGuidanceHomeSubtitle(
    String subtitle,
    bool isDark, {
    String? secondLine,
  }) {
    final text = secondLine == null ? subtitle : '$subtitle\n$secondLine';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: isDark
              ? Colors.white.withOpacity(0.94)
              : const Color(0xFF3D2914).withOpacity(0.82),
        ),
      ),
    );
  }

  Widget _prayerGuidanceActionIcon(
    String assetPath, {
    required Color tintColor,
    double scale = 1.0,
  }) {
    // Full icon visible — do not scale past the box (ClipRect + scale caused half icons).
    final size = 40.0 * scale;
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: tintColor,
        colorBlendMode: BlendMode.srcIn,
      ),
    );
  }

  Widget _prayerGuidanceActionCardBody({
    required Widget icon,
    required String title,
    required String subtitleFirstLine,
    required String subtitleSecondLine,
    required Color titleColor,
    required Color subtitleColor,
    double titleSize = 13.5,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: titleSize,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$subtitleFirstLine\n$subtitleSecondLine',
                maxLines: 2,
                style: TextStyle(
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _prayerGuidanceSceneBackground({
    required double imageHeightFactor,
    double imageTop = 0,
    Alignment imageAlignment = Alignment.topCenter,
    bool isDark = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxHeight * imageHeightFactor;
        final baseColor =
            isDark ? CommanColor.darkPrimaryColor : _kPrayerGuidanceCream;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: baseColor),
            Positioned(
              top: imageTop,
              left: 0,
              right: 0,
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _kPrayerGuidanceBg,
                    fit: BoxFit.cover,
                    alignment: imageAlignment,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                Colors.black.withOpacity(0.55),
                                Colors.black.withOpacity(0.28),
                                Colors.transparent,
                                baseColor.withOpacity(0.55),
                                baseColor,
                              ]
                            : [
                                Colors.white.withOpacity(0.62),
                                Colors.white.withOpacity(0.22),
                                Colors.transparent,
                                _kPrayerGuidanceCream.withOpacity(0.45),
                                _kPrayerGuidanceCream,
                              ],
                        stops: const [0.0, 0.22, 0.42, 0.72, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: constraints.maxHeight * 0.36,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              Colors.black.withOpacity(0.72),
                              Colors.black.withOpacity(0.42),
                              Colors.black.withOpacity(0.12),
                              Colors.transparent,
                            ]
                          : [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.62),
                              Colors.white.withOpacity(0.18),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 0.38, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _prayerInstructionalSubtitle(String title) {
    final index = _categories.indexWhere((category) => category.title == title);
    if (index >= 0 && index < _categoryInstructionalSubtitles.length) {
      return _categoryInstructionalSubtitles[index];
    }
    return 'Words of hope from God\'s Word for your heart.';
  }

  Color _guidanceResponseTextColor(BuildContext context, bool isDark) {
    return _kPrayerGuidanceInk;
  }

  Widget _prayerGuidanceResponseSubtitleBanner(String subtitle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _prayerGuidanceReadableCaption(
        subtitle,
        isDark: isDark,
      ),
    );
  }

  Widget _prayerGuidanceGoldDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: _kPrayerGuidanceGold.withOpacity(0.75),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.favorite,
              size: 12,
              color: _kPrayerGuidanceGold,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: _kPrayerGuidanceGold.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }


  Widget _prayerCreatingStepConnector({bool compact = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 3),
      child: CustomPaint(
        size: Size(2, compact ? 18 : 26),
        painter: _PrayerCreatingDashedLinePainter(
          color: _kPrayerGuidanceGold.withOpacity(0.38),
        ),
      ),
    );
  }

  Widget _prayerLoadingStepRow({
    required IconData icon,
    required String label,
    required bool showSpinner,
    required bool showConnector,
    bool compact = false,
  }) {
    final iconSize = compact ? 36.0 : 40.0;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
          decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.72),
                  border: Border.all(
                    color: _kPrayerGuidanceGold.withOpacity(0.42),
                  ),
                ),
                child: Icon(icon, color: _kPrayerGuidanceGold, size: compact ? 17 : 19),
              ),
              if (showConnector) _prayerCreatingStepConnector(compact: compact),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: compact ? 6 : 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 14 : 15,
                  fontWeight:
                      showSpinner ? FontWeight.w600 : FontWeight.w500,
                  color: _kPrayerGuidanceInk.withOpacity(
                    showSpinner ? 1 : 0.88,
                  ),
                  fontFamily: 'Georgia',
                  height: 1.35,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: showSpinner
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: _kPrayerGuidanceGold,
                    ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kPrayerGuidanceInk.withOpacity(0.16),
                        width: 1.5,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCreatingView(BuildContext context, Size size, bool isDark) {
    final horizontalPad = size.width > 450 ? 28.0 : 20.0;
    final isCompact = size.width < 390 || size.height < 750;
    final heroSize = size.width > 450 ? 96.0 : (isCompact ? 68.0 : 80.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            isCompact ? 2 : 4,
            horizontalPad,
            isCompact ? 10 : 14,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/welcome_prayer.png',
                    width: heroSize,
                    height: heroSize,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),
                Text(
                  'Creating your prayer...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.width > 450 ? 26 : (isCompact ? 21 : 23),
                    fontWeight: FontWeight.w700,
                    color: _kPrayerGuidanceInk,
                    fontFamily: 'Georgia',
                    height: 1.1,
                  ),
                ),
                SizedBox(height: isCompact ? 6 : 8),
                _prayerGuidanceGoldDivider(),
                SizedBox(height: isCompact ? 6 : 8),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width > 450 ? 12 : 4,
                  ),
                  child: Text(
                    "We're searching God's Word and preparing words of hope for you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width > 450 ? 15 : (isCompact ? 13 : 14),
                      color: _kPrayerGuidanceInk.withOpacity(0.88),
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      _prayerLoadingStepRow(
                        icon: Icons.search,
                        label: 'Finding the right Scriptures',
                        showSpinner: true,
                        showConnector: true,
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 2 : 4),
                      _prayerLoadingStepRow(
                        icon: Icons.menu_book_outlined,
                        label: 'Understanding your need',
                        showSpinner: true,
                        showConnector: true,
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 2 : 4),
                      _prayerLoadingStepRow(
                        icon: Icons.favorite_border,
                        label: 'Preparing your prayer',
                        showSpinner: true,
                        showConnector: false,
                        compact: isCompact,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    isCompact ? 10 : 14,
                    18,
                    isCompact ? 10 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.52),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.78),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrayerBrownDark.withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“',
                        style: TextStyle(
                          fontSize: size.width > 450 ? 32 : (isCompact ? 24 : 28),
                          height: 0.9,
                          color: _kPrayerGuidanceGold,
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Call to Me, and I will answer you, and show you great and mighty things.',
                        style: TextStyle(
                          fontSize: size.width > 450 ? 17 : (isCompact ? 13.5 : 14.5),
                          height: isCompact ? 1.35 : 1.45,
                          color: _kPrayerGuidanceInk,
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isCompact ? 8 : 10),
                      Text(
                        'Jeremiah 33:3',
                        style: TextStyle(
                          fontSize: isCompact ? 13 : 14,
                          color: _kPrayerGuidanceInk.withOpacity(0.82),
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _prayerGuidanceMainHeroHeight(BuildContext context) {
    // Match paywall hero sizing so the top image coverage feels consistent.
    final size = MediaQuery.sizeOf(context);
    return (size.height * 0.40).clamp(280.0, 360.0);
  }

  Widget _prayerGuidanceMainScreenTopHero(BuildContext context) {
    final heroHeight = _prayerGuidanceMainHeroHeight(context);
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final fadeColor =
        isDark ? CommanColor.darkPrimaryColor : const Color(0xFFFDFBF7);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/back1.png',
              fit: BoxFit.cover,
            alignment: const Alignment(0, -0.15),
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
          if (isDark)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.28),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: heroHeight * 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    fadeColor.withOpacity(0.25),
                    fadeColor.withOpacity(0.82),
                    fadeColor,
                  ],
                  stops: const [0.0, 0.4, 0.78, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerGuidanceBackgroundLayer(BuildContext context) {
    if (_prayerGuidanceIsCreatingView()) {
      return Positioned.fill(
        child: Image.asset(
          _kPrayerCreatingBg,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      );
    }
    final systemIsDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    // Main category screen stays light scenic; response view uses dark scrim
    // so white title/subtitle remain readable in dark mode.
    final useDarkScrim =
        !_prayerGuidanceIsMainScreen() && systemIsDark;
    return Positioned.fill(
      child: _prayerGuidanceSceneBackground(
        imageHeightFactor: 0.45,
        imageTop: -1,
        imageAlignment: const Alignment(0, -0.65),
        isDark: useDarkScrim,
      ),
    );
  }

  Widget _prayerGuidanceMainScreenOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.18),
                Colors.transparent,
                Colors.black.withOpacity(0.32),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _prayerModeSelectorDecoration({
    required bool isSelected,
    required bool isDark,
    required bool isWhiteLight,
    required Color accentFill,
  }) {
    return BoxDecoration(
      color: isSelected
          ? accentFill
          : (isDark ? Colors.black.withOpacity(0.38) : Colors.white),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: isSelected
            ? Colors.transparent
            : (isDark
                ? Colors.white.withOpacity(0.55)
                : (isWhiteLight
                    ? Colors.grey.shade300
                    : const Color(0xFFD4C4B0))),
        width: isDark && !isSelected ? 1.2 : 1,
      ),
      boxShadow: isDark && !isSelected
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  TextStyle _prayerModeSelectorTextStyle({
    required bool isSelected,
    required bool isDark,
    required Color titleInk,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      color: isSelected
          ? Colors.white
          : (isDark ? Colors.white.withOpacity(0.96) : titleInk),
      fontWeight: isSelected ? FontWeight.w700 : fontWeight,
      shadows: isDark && !isSelected
          ? const [
              Shadow(
                color: Colors.black54,
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ]
          : null,
    );
  }

  Widget _prayerGuidanceResponseHeaderIcon(Size size, {bool compact = false}) {
    final iconSize = compact
        ? (size.width > 450 ? 128.0 : 112.0)
        : (size.width > 450 ? 140.0 : 124.0);
    return Image.asset(
      'assets/welcome_prayer.png',
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
    );
  }

  Widget _guidanceResponseContentBox(
      BuildContext context, bool isDark, Widget child) {
    return child;
  }

  List<TextSpan> _guidanceResponseSpansForSegment(
    String segment,
    Color textColor,
    RegExp versePattern,
  ) {
    final spans = <TextSpan>[];
    final matches = versePattern.allMatches(segment);
    if (matches.isEmpty) {
      spans.add(TextSpan(text: segment));
      return spans;
    }
    var lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: segment.substring(lastMatchEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0)!,
        style: const TextStyle(
          color: _kPrayerGuidanceGold,
          fontWeight: FontWeight.w600,
        ),
      ));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < segment.length) {
      spans.add(TextSpan(text: segment.substring(lastMatchEnd)));
    }
    return spans;
  }

  Widget _buildGuidanceResponseBody(String text, Size size, bool isDark) {
    final textColor = _guidanceResponseTextColor(context, isDark);
    final fontSize = size.width > 450 ? 17.0 : 16.0;
    final versePattern = RegExp(
      r'(\d?\s?[A-Za-z]+\s+\d+:\d+(?:-\d+)?)',
      caseSensitive: false,
    );
    final closingPattern = RegExp(
      r'(In Jesus.+?Amen\.?)',
      caseSensitive: false,
      dotAll: true,
    );
    final closingMatch = closingPattern.firstMatch(text);
    final bodyText = closingMatch == null
        ? text.trimRight()
        : text.substring(0, closingMatch.start).trimRight();
    final closingText =
        closingMatch?.group(0) ?? "In Jesus' Name, Amen.";

    final baseStyle = TextStyle(
      fontSize: fontSize,
      height: 1.65,
      color: textColor,
      fontFamily: 'Georgia',
      fontWeight: FontWeight.w400,
    );

    final spans = <TextSpan>[];
    if (bodyText.isNotEmpty) {
      spans.addAll(
        _guidanceResponseSpansForSegment(bodyText, textColor, versePattern),
      );
    }
    if (closingText.isNotEmpty) {
      if (spans.isNotEmpty) {
        spans.add(const TextSpan(text: '\n\n'));
      }
      spans.add(
        TextSpan(
          text: closingText,
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      );
    }

    if (spans.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.left,
        style: baseStyle,
      );
    }

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  ({String quote, String reference})? _prayerResponseInsightFromText(
      String text) {
    final versePattern = RegExp(
      r'(\d?\s?[A-Za-z]+\s+\d+:\d+(?:-\d+)?)',
      caseSensitive: false,
    );
    final matches = versePattern.allMatches(text).toList();
    if (matches.isEmpty) return null;

    final match = matches.length >= 2 ? matches[1] : matches.first;
    final reference = match.group(0)!;
    final refStart = match.start;
    final before = text.substring(0, refStart);
    final sentenceStart = before.lastIndexOf('.');
    final start = sentenceStart >= 0 ? sentenceStart + 1 : 0;
    final afterRef = match.end;
    final nextPeriod = text.indexOf('.', afterRef);
    final end = nextPeriod >= 0 ? nextPeriod + 1 : text.length;
    var quote = text.substring(start, end).trim();
    quote = quote.replaceAll(reference, '').trim();
    if (quote.length < 12) {
      quote =
          'Give thanks in all circumstances; for this is the will of God in Christ Jesus for you.';
    }
    return (quote: quote, reference: reference);
  }

  Widget _buildPrayerResponseInsightBox(String aiText, Size size) {
    final insight = _prayerResponseInsightFromText(aiText);
    if (insight == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _kPrayerGuidanceGold.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPrayerGuidanceGold.withOpacity(0.18),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: _kPrayerGuidanceGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.quote,
                  style: TextStyle(
                    fontSize: size.width > 450 ? 15 : 14,
                    height: 1.45,
                    color: _kPrayerGuidanceInk,
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight.reference,
                  style: TextStyle(
                    fontSize: size.width > 450 ? 14 : 13,
                    color: _kPrayerGuidanceGold,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerResponseCard(String aiText, Size size, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '“',
              style: TextStyle(
                fontSize: size.width > 450 ? 44 : 40,
                height: 0.85,
                color: _kPrayerGuidanceGold,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          _buildGuidanceResponseBody(aiText, size, isDark),
          const SizedBox(height: 16),
          _prayerGuidanceGoldDivider(),
          const SizedBox(height: 14),
          _buildPrayerResponseInsightBox(aiText, size),
        ],
      ),
    );
  }

  Future<void> _copyPrayerResponse(String messageText) async {
    await Clipboard.setData(ClipboardData(text: messageText));
    Constants.showToast(
      ChatTranslations.get('copied', AppApiConstant.chatLanguage),
    );
  }

  Future<void> _sharePrayerResponse(String messageText) async {
    final screenSize = MediaQuery.of(context).size;
    final sharePositionOrigin = Rect.fromLTWH(
      screenSize.width / 2 - 50,
      screenSize.height / 2 - 50,
      100,
      100,
    );
    await Share.share(
      _buildShareText(messageText),
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Widget _buildPrayerResponseCopyShareRow(String messageText, Size size) {
    Widget pill({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.white,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _kPrayerGuidanceInk.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: size.width > 450 ? 14 : 13,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: _kPrayerGuidanceInk.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: size.width > 450 ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrayerGuidanceInk.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(
          icon: Icons.copy_rounded,
          label: 'Copy',
          onTap: () => _copyPrayerResponse(messageText),
        ),
        const SizedBox(width: 12),
        pill(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () => _sharePrayerResponse(messageText),
        ),
      ],
    );
  }

  Widget _buildPrayerResponseView(
      BuildContext context, Size size, bool isDark, Color accentFill) {
    final title = _prayerHeaderTitle() ?? '';
    String? aiText;
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isUser) {
        aiText = _messages[i].text;
        break;
      }
    }
    final headerColor = isDark ? Colors.white : _kPrayerGuidanceInk;

    if (_isLoading && aiText == null) {
      return _buildPrayerCreatingView(context, size, isDark);
    }

    final instructional = title.isNotEmpty
        ? _prayerInstructionalSubtitle(title)
        : 'Words of hope from God\'s Word for your heart.';

    final horizontalPad = size.width > 450 ? 20.0 : 16.0;

    // Title / subtitle stay fixed; only the prayer card scrolls.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 450 ? 40 : 28,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.width > 450 ? 28 : 26,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                    fontFamily: 'Georgia',
                    height: 1.1,
                    shadows: isDark
                        ? const [
                            Shadow(
                              color: Color(0xCC000000),
                              blurRadius: 10,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _prayerGuidanceGoldDivider(),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 450 ? 46 : 34,
                ),
                child: Text(
                  instructional,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.width > 450 ? 15 : 14,
                    height: 1.35,
                    color: isDark ? Colors.white : _kPrayerGuidanceInk,
                    fontWeight: FontWeight.w700,
                    shadows: isDark
                        ? const [
                            Shadow(
                              color: Color(0xCC000000),
                              blurRadius: 8,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : const [
                            Shadow(
                              color: Color(0x66FFFFFF),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              horizontalPad,
              0,
              horizontalPad,
              8,
            ),
            child: _guidanceResponseContentBox(
              context,
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (aiText != null) ...[
                    _buildPrayerResponseCard(aiText, size, isDark),
                    if (!_isPrayerGenerationError(aiText)) ...[
                      const SizedBox(height: 12),
                      _buildPrayerResponseCopyShareRow(aiText, size),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isAmenHeartFilled() {
    for (int idx = _messages.length - 1; idx >= 0; idx--) {
      if (!_messages[idx].isUser) {
        return _amenShownForResponseHashes
            .contains(_messages[idx].text.hashCode);
      }
    }
    return false;
  }

  Widget _buildPrayerAmenButton(Size size, {required VoidCallback onPressed}) {
    final heartFilled = _isAmenHeartFilled();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: size.width > 450 ? 22 : 18,
            vertical: size.width > 450 ? 14 : 12,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFD4AF37),
                Color(0xFFC89B3C),
                Color(0xFFB8893A),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _kPrayerGuidanceGold.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                heartFilled ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
                size: size.width > 450 ? 24 : 22,
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amen',
                    style: TextStyle(
                      fontSize: size.width > 450 ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Georgia',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'I have prayed this prayer',
                    style: TextStyle(
                      fontSize: size.width > 450 ? 13 : 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _prayerGuidanceTopBarReservedHeight(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    if (_prayerGuidanceIsCreatingView()) {
      return topInset + 48 + 2;
    }
    if (_prayerGuidanceIsMainScreen()) {
      return topInset + 44;
    }
    final responseExtra = 18.0;
    return topInset + responseExtra + 48 + 4;
  }

  Widget _buildPrayerGuidanceTopBar(
      BuildContext context, Size size, bool isDark) {
    final musicIconColor = isDark ? Colors.white : _kPrayerGuidanceInk;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.paddingOf(context).top +
            ((_prayerGuidanceIsMainScreen() || _prayerGuidanceIsCreatingView())
                ? 0
                : 18),
        12,
        _prayerGuidanceIsMainScreen() ? 2 : 4,
      ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        onPressed: () async {
              if (_messages.isNotEmpty ||
                  _isLoading ||
                  _responseHeaderTitle != null) {
                            debugPrint(
                                '🔙 BACK BUTTON: Back arrow pressed, clearing messages...');
                _resetPrayerChatView();
                            return;
                          }
                          debugPrint(
                              '🔙 BACK BUTTON: Back arrow pressed, closing screen...');
                          await _maybeShowInterstitialAndPop();
                        },
            icon: Icon(
              Icons.arrow_back_ios,
              color: _prayerGuidanceIsMainScreen()
                  ? _kPrayerGuidanceInk
                  : (isDark ? Colors.white : _kPrayerGuidanceInk),
              size: 18,
            ),
          ),
          const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width > 450 ? 12 : 10,
                              vertical: size.width > 450 ? 6 : 5,
                            ),
                            decoration: BoxDecoration(
                  color: isDark
                      ? (_prayerGuidanceHasAiResponse()
                          ? Colors.black.withOpacity(0.55)
                          : CommanColor.darkPrimaryColor.withOpacity(0.55))
                                  : const Color(0xFFF6F1E9).withOpacity(0.65),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.28)
                        : const Color(0xFF8D6E63).withOpacity(0.18),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                Get.to(
                                  () => const WalletScreen(),
                                  transition: Transition.cupertinoDialog,
                      duration: const Duration(milliseconds: 300),
                                )?.then((_) {
                                  _loadCreditsFromLocal();
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    size: size.width > 450 ? 22 : 20,
                        color: _prayerGuidanceIsMainScreen()
                            ? (isDark
                                        ? Colors.white
                                : const Color(0xFF8D6E63))
                            : (isDark ? Colors.white : _kPrayerGuidanceInk),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_currentCredits',
                                    style: TextStyle(
                          color: _prayerGuidanceIsMainScreen()
                              ? (isDark
                                          ? Colors.white
                                  : const Color(0xFF8D6E63))
                              : (isDark ? Colors.white : _kPrayerGuidanceInk),
                          fontSize: size.width > 450 ? 14 : 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: size.width > 450 ? 12 : 10),
                          if (_messages.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                    color: isDark
                        ? Colors.black.withOpacity(0.45)
                        : Colors.grey.withOpacity(0.2),
                              ),
                              child: IconButton(
                                onPressed: _toggleAudio,
                    icon: _isAudioMuted || !_isAudioPlaying
                        ? Icon(
                                  _isAudioMuted
                                      ? Icons.music_off
                                      : Icons.music_note,
                            color: musicIconColor,
                            size: 22,
                          )
                        : RotationTransition(
                            turns: _musicSpinController,
                            child: Icon(
                              Icons.music_note,
                              color: musicIconColor,
                                  size: 22,
                                ),
                          ),
                    tooltip: _isAudioMuted ? 'Audio Off' : 'Audio On',
                              ),
                            )
                          else
                            const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompactPhone = size.width < 390 || size.height < 750;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final systemIsDark = themeProvider.themeMode == ThemeMode.dark;
    // Main category screen always uses the light scenic UI (cream cards),
    // even when the app theme is dark.
    final isDark =
        _prayerGuidanceIsMainScreen() ? false : systemIsDark;
    final isWhiteLight = !isDark &&
        themeProvider.currentCustomTheme == AppCustomTheme.white;
    final accentFill = isWhiteLight
        ? const Color(0xFF424242)
        : const Color(0xFF5C4033);
    final titleInk = isDark
        ? Colors.white
        : (isWhiteLight ? const Color(0xFF212121) : const Color(0xFF3D2914));

    return WillPopScope(
      onWillPop: () async {
        // If viewing responses, go back to category selection view
        if (_messages.isNotEmpty || _isLoading || _responseHeaderTitle != null) {
          debugPrint(
              '🔙 BACK BUTTON: System back pressed, clearing messages...');
          _resetPrayerChatView();
          return false; // Stay on screen, just clear messages
        }
        // If on category selection view, close the screen (show interstitial for unsubscribed then pop)
        debugPrint('🔙 BACK BUTTON: System back pressed, closing screen...');
        await _maybeShowInterstitialAndPop();
        return false;
      },
      child: Scaffold(
        backgroundColor: _prayerGuidanceIsCreatingView()
            ? Colors.transparent
            : (isDark
                ? CommanColor.darkPrimaryColor
                : _kPrayerGuidanceCream),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _prayerGuidanceBackgroundLayer(context),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                      height: _prayerGuidanceTopBarReservedHeight(context)),
                if ((_messages.isNotEmpty ||
                        _isLoading ||
                        _responseHeaderTitle != null) &&
                    !_prayerGuidanceIsCreatingView())
                  SizedBox(height: isCompactPhone ? 8 : 10),
                Expanded(
                  child: ClipRect(
                  child: _messages.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: illustration, title, subtitle (full-width)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  _prayerGuidanceHomeHeaderIcon(size, isDark: isDark),
                                  const SizedBox(height: 6),
                                  Text(
                                    ChatTranslations.get(
                                        'prayer_guidance_title', 'EN'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : titleInk,
                                      fontSize: size.width > 450 ? 26 : 24,
                                      fontFamily: 'Georgia',
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _prayerGuidanceHomeSubtitle(
                                    'Get guidance based on your need',
                                    isDark,
                                    secondLine: 'and God\'s Word.',
                                  ),
                                  const SizedBox(height: 8),
                                  _prayerGuidanceGoldDivider(),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _timeGreeting(),
                                    style: TextStyle(
                                      color: isDark
                                            ? Colors.white.withOpacity(0.88)
                                            : const Color(0xFF805531),
                                        fontWeight: FontWeight.w600,
                                        fontSize: size.width > 450 ? 16 : 14,
                                        fontFamily: 'Georgia',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: size.width > 450
                                          ? 6
                                          : (isCompactPhone ? 2 : 4)),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'What do you need\nprayer for today?',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : titleInk,
                                        fontWeight: FontWeight.w700,
                                        fontSize: size.width > 450 ? 26 : 22,
                                        height: 1.1,
                                        fontFamily: 'Georgia',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: size.width > 450
                                          ? 10
                                          : (isCompactPhone ? 6 : 8)),
                                  // Action cards: Pray for Me / Community Prayers
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final isConnected =
                                                await InternetConnection()
                                                    .hasInternetAccess;
                                            if (!isConnected) {
                                              Constants.showToast(
                                                  'No internet connection',
                                                  5000);
                                              return;
                                            }
                                            // When Pray for Me is tapped, directly show the custom prayer dialog (same popup as the search input used to open)
                                            _showCustomPrayerDialog(context);
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  _kPrayerBrownMid,
                                                  _kPrayerBrownDark,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _kPrayerBrownDark
                                                      .withOpacity(0.28),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            constraints: const BoxConstraints(
                                              minHeight: 72,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                            child: _prayerGuidanceActionCardBody(
                                              icon: _prayerGuidanceActionIcon(
                                                'assets/pray_fr_me.png',
                                                tintColor: Colors.white,
                                              ),
                                              title: 'Pray for Me',
                                              subtitleFirstLine:
                                                  'Receive personal',
                                              subtitleSecondLine:
                                                  'prayer guidance',
                                              titleColor: Colors.white,
                                              subtitleColor: Colors.white70,
                                              titleSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            // Navigate to Prayer Wall (community prayers)
                                            _resetPrayerChatView();
                                            await _refreshCommunityLiveIndicator();
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const PrayerWallScreen(),
                                              ),
                                            );
                                            if (mounted) {
                                              await _refreshCommunityLiveIndicator();
                                              _resetPrayerChatView();
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                            decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.black
                                                          .withOpacity(0.42)
                                                      : _kPrayerCardCream,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                              border: Border.all(
                                                    color: isDark
                                                        ? Colors.white
                                                            .withOpacity(0.22)
                                                        : _kPrayerCardBorder,
                                                  ),
                                                  boxShadow: isDark
                                                      ? null
                                                      : [
                                                          BoxShadow(
                                                            color:
                                                                _kPrayerBrownDark
                                                                    .withOpacity(
                                                                        0.08),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                    0, 4),
                                                          ),
                                                        ],
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                  minHeight: 72,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                                child:
                                                    _prayerGuidanceActionCardBody(
                                                  icon: _prayerGuidanceActionIcon(
                                                    'assets/community.png',
                                                    tintColor: isDark
                                                        ? Colors.white
                                                        : _kPrayerBrownMid,
                                                  ),
                                                  title: 'Prayer wall',
                                                  subtitleFirstLine:
                                                      'See what others',
                                                  subtitleSecondLine:
                                                      'are praying for',
                                                  titleColor: isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF3D2914),
                                                  subtitleColor: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.78)
                                                      : const Color(
                                                              0xFF4A3728)
                                                          .withOpacity(0.72),
                                                  titleSize: 11.5,
                                                ),
                                              ),
                                              if (_communityPrayerCountLoaded &&
                                                  _communityPrayerCount > 0)
                                                Positioned(
                                                  top: -11,
                                                  right: 6,
                                                  child: Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 22,
                                                      minHeight: 22,
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFE89B3C),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              11),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      _communityPrayerCount > 99
                                                          ? '99+'
                                                          : '$_communityPrayerCount',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.1,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: size.width > 450
                                        ? 10
                                        : (isCompactPhone ? 6 : 8),
                                  ),
                                ],
                              ),
                            ),
                            // Grid scrolls (full-width content)
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const ClampingScrollPhysics(),
                                primary: false,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Prayer Categories',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF3D2914),
                                          fontWeight: FontWeight.w700,
                                          fontSize:
                                              size.width > 450 ? 18 : 16,
                                          fontFamily: 'Georgia',
                                          shadows: isDark
                                              ? const [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 6,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                    // Keep the grid tight under the header.
                                    const SizedBox(height: 10),
                                    LayoutBuilder(
                                      builder: (context, gridConstraints) {
                                        const crossAxisCount = 3;
                                        const gridSpacing = 10.0;
                                        const categoryCircleSize = 56.0;
                                        final titleSlotHeight =
                                            size.width > 450 ? 34.0 : 30.0;
                                        final subtitleSlotHeight =
                                            size.width > 450 ? 26.0 : 24.0;
                                        final accentStripHeight = isDark ? 4.0 : 11.0;
                                        final cardPaddingV =
                                            size.width > 450 ? 14.0 : 10.0;
                                        const cardBorderInset = 2.0;
                                        final cellHeight = (categoryCircleSize +
                                                6 +
                                                titleSlotHeight +
                                                subtitleSlotHeight +
                                                accentStripHeight +
                                                cardPaddingV * 2 +
                                                cardBorderInset)
                                            .clamp(148.0, 176.0);

                                        return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: gridSpacing,
                                            mainAxisSpacing: gridSpacing,
                                            mainAxisExtent: cellHeight,
                                          ),
                                          itemCount: _categories.length >= 6
                                              ? 6
                                              : _categories.length,
                                      itemBuilder: (context, index) {
                                        // Match reference order: Thanksgiving, Healing, Forgiveness, Guidance, Anxiety & Peace, Family
                                        final order = <int>[0, 4, 1, 2, 3, 5];
                                        final categoryIndex = order
                                            .where((i) => i < _categories.length)
                                            .toList()[index];
                                        final iconAsset =
                                            _categoryIconAsset(categoryIndex);

                                        final borderClr = isDark
                                            ? Colors.white.withOpacity(0.28)
                                            : const Color(0xFFD4C4B0);
                                        final textClr = isDark
                                            ? Colors.white
                                            : const Color(0xFF3D2914);
                                        final accentClr =
                                            _categoryAccentColor(categoryIndex);
                                        final textShadows = isDark
                                            ? const [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 1),
                                                ),
                                              ]
                                            : null;

                                        return InkWell(
                                          onTap: () {
                                            _sendPrayerRequest(categoryIndex);
                                          },
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: size.width > 450
                                                  ? 14
                                                  : 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                      ? Colors.black
                                                      .withOpacity(0.48)
                                                  : _kPrayerCardCream,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark
                                                    ? borderClr
                                                    : _kPrayerCardBorder,
                                                width: 1,
                                              ),
                                              boxShadow: isDark
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color: _kPrayerBrownDark
                                                            .withOpacity(0.06),
                                                        blurRadius: 6,
                                                        offset:
                                                            const Offset(0, 3),
                                                      ),
                                                    ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height: categoryCircleSize + 6,
                                                  width: double.infinity,
                                                  child: Center(
                                                    child: iconAsset != null
                                                        ? SizedBox(
                                                            width:
                                                                categoryCircleSize,
                                                            height:
                                                                categoryCircleSize,
                                                            child: Image.asset(
                                                              iconAsset,
                                                              fit: BoxFit.contain,
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .high,
                                                            ),
                                                          )
                                                        : Container(
                                                            width:
                                                                categoryCircleSize,
                                                            height:
                                                                categoryCircleSize,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isDark
                                                                  ? Colors.white
                                                                      .withOpacity(
                                                                          0.12)
                                                                  : accentClr
                                                                      .withOpacity(
                                                                          0.14),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              Icons.favorite,
                                                              size:
                                                                  categoryCircleSize *
                                                                      0.38,
                                                              color: isDark
                                                                  ? textClr
                                                                  : accentClr,
                                                              shadows:
                                                                  textShadows,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: titleSlotHeight,
                                                  width: double.infinity,
                                child: Align(
                                                    alignment: Alignment.center,
                                  child: Text(
                                                      _categories[categoryIndex]
                                                          .title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize:
                                                            size.width > 450
                                                                ? 14
                                                                : 12,
                                                        height: 1.1,
                                                        color: textClr,
                                                        shadows: textShadows,
                                    ),
                                  ),
                                ),
                                                ),
                                                SizedBox(
                                                  height: subtitleSlotHeight,
                                                  width: double.infinity,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      categoryIndex <
                                                              _categorySubtitles
                                                                  .length
                                                          ? _categorySubtitles[
                                                              categoryIndex]
                                                          : '',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize:
                                                            size.width > 450
                                                                ? 11.5
                                                                : 10,
                                                        color: isDark
                                          ? Colors.white
                                                                .withOpacity(
                                                                    0.9)
                                                            : textClr
                                                                .withOpacity(
                                                                    0.78),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        shadows: textShadows,
                                                        height: 1.15,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (!isDark) ...[
                                                  const SizedBox(height: 4),
                                                  Center(
                                                child: Container(
                                                      width: 24,
                                                      height: 3,
                                                  decoration: BoxDecoration(
                                                        color: accentClr
                                                            .withOpacity(0.85),
                                                    borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 2),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    FutureBuilder<bool>(
                                      future: _showPrayerReminderPromptFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.data != true) {
                                          return const SizedBox.shrink();
                                        }
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildDailyPrayerReminderCard(isDark),
                                            const SizedBox(height: 16),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : _buildPrayerResponseView(
                          context, size, isDark, accentFill),
                  ),
                ),
                // AMEN button at the bottom - only show after valid prayer content is generated
                if (_prayerGuidanceHasValidPrayerContent())
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      size.width > 450 ? 20 : 16,
                      8,
                      size.width > 450 ? 20 : 16,
                      12,
                    ),
                    child: _buildPrayerAmenButton(
                      size,
                        onPressed: () async {
                          // Increment AMEN tap counter
                          _amenTapCount++;
                          await _saveAmenTapCount(); // Save to SharedPreferences
                          debugPrint(
                              '🔍 AMEN: Tap count = $_amenTapCount / 10');

                          // Interstitial ad removed from Amen; shown only when user taps Back (see WillPopScope / app bar back).

                          // Show Amen message
                          // Only show once per AI response. Determine latest AI response index.
                          int latestAiIndex = -1;
                          for (int idx = _messages.length - 1;
                              idx >= 0;
                              idx--) {
                            if (!_messages[idx].isUser) {
                              latestAiIndex = idx;
                              break;
                            }
                          }

                          if (latestAiIndex == -1) {
                            // No AI response yet - preserve existing behaviour
                            _showRotatingAmenMessage();
                          } else {
                            // Use a hash of the AI response text so clearing/refreshing
                            // the _messages list doesn't cause index collisions.
                            final aiText = _messages[latestAiIndex].text;
                            final hash = aiText.hashCode;
                            if (_amenShownForResponseHashes.contains(hash)) {
                              debugPrint(
                                  '🔍 AMEN: Toast already shown for response hash $hash');
                              // Do not show again for the same AI response content
                            } else {
                              _showRotatingAmenMessage();
                              _amenShownForResponseHashes.add(hash);
                            }
                          }
                          // Visual-only: fill Amen heart after tap.
                          if (mounted) setState(() {});
                        },
                    ),
                  ),
              ],
            ),
          ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildPrayerGuidanceTopBar(context, size, isDark),
            ),
        ],
        ),
      ),
    );
  }
}

class _PrayerCreatingDashedLinePainter extends CustomPainter {
  _PrayerCreatingDashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashHeight = 4.0;
    const gap = 4.0;
    var y = 0.0;
    final x = size.width / 2;
    while (y < size.height) {
      final endY = y + dashHeight;
      canvas.drawLine(Offset(x, y), Offset(x, endY > size.height ? size.height : endY), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PrayerCreatingDashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
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
