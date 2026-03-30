import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/milestone_lifetime_paywall_coordinator.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:biblebookapp/view/screens/chat/chat_translations.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/post_prayer_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_screen.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // UI mode: true => Pray for Me view (search + categories). Community navigates to PrayerWallScreen.
  bool _isPrayForMeMode = true;

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
    {
      'titleKey': 'prayer_feelings',
      'prompt':
          'Give me a prayer to bring my feelings and emotions before God. Include 1-2 Geneva Bible verse references.',
    },
    {
      'titleKey': 'prayer_praise',
      'prompt':
          'Write a short prayer of praise and worship to God. Include 1-2 Geneva Bible verse references.',
    },
  ];

  // Get categories with English titles only (do not translate)
  List<_GuidanceCategory> get _categories => _categoryKeys
      .map((cat) => _GuidanceCategory(
            title: ChatTranslations.get(cat['titleKey']!, 'EN'),
            prompt: cat['prompt']!,
          ))
      .toList();

  Future<bool> _showPleaseNoteDialog() async {
    final agreed =
        await SharPreferences.getBoolean(SharPreferences.aiDisclaimerAgreed);
    if (agreed == true) return true;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    final bodyColor = isDark ? Colors.white70 : const Color(0xFF4A3728);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            backgroundColor: isDark
                ? CommanColor.darkPrimaryColor
                : CommanColor.backgrondcolor,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Important Notice',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CommanColor.whiteBlack(ctx),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Chat allows you to ask questions and receive Bible-based guidance.\n\n'
                    'To generate responses, the message you type may be securely sent to Google Gemini for processing.\n\n'
                    'The following data may be transmitted:\n'
                    '• Your chat message\n'
                    '• Device type\n'
                    '• App version\n\n'
                    'This data is used only to generate AI responses.\n\n'
                    'We do not collect personal identity information such as your name, email, contacts, or location.\n\n'
                    'By tapping "Agree & Continue", you allow your chat input to be processed by the AI service according to our Privacy Policy.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 14,
                      color: bodyColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await SharPreferences.setBoolean(
                                SharPreferences.aiDisclaimerAgreed, true);
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: CommanColor.lightDarkPrimary(ctx),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Agree & Continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (ctx.mounted) Navigator.pop(ctx, false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CommanColor.lightDarkPrimary(ctx),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CommanColor.lightDarkPrimary(ctx),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => launchUrlString(
                            'https://bibleoffice.com/terms_conditions.html'),
                        child: Text(
                          'Terms',
                          style: TextStyle(
                            fontSize: 12,
                            color: CommanColor.whiteBlack(ctx),
                          ),
                        ),
                      ),
                      Text(
                        ' | ',
                        style: TextStyle(
                          fontSize: 12,
                          color: CommanColor.whiteBlack(ctx),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => launchUrlString(
                            'https://bibleoffice.com/privacy_policy.html'),
                        child: Text(
                          'Privacy',
                          style: TextStyle(
                            fontSize: 12,
                            color: CommanColor.whiteBlack(ctx),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

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

  String _buildShareText(String text) {
    final androidLink =
        "https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}";
    final iosLink = "https://itunes.apple.com/app/id${BibleInfo.apple_AppId}";
    final storeLink = Platform.isIOS ? iosLink : androidLink;
    return "$text\n\nRead more at: $storeLink";
  }

  Future<void> _sendPrayerRequest(int categoryIndex) async {
    if (_isLoading) return;

    // Show Please Note dialog before first response (must agree to continue)
    final agreed = await _showPleaseNoteDialog();
    if (!agreed || !mounted) return;

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
        if (mounted) {
          final prefs = await SharedPreferences.getInstance();
          final creditDebitShown =
              prefs.getBool('prayer_credit_debit_shown') ?? false;
          if (!creditDebitShown) {
            Constants.showToast(
                'Used $chatCost credits for this response', 5000);
            await prefs.setBool('prayer_credit_debit_shown', true);
          }
          _loadCreditsFromLocal();
        }
        await updateBiblePrayerWidget(prayerText: responseText);
        // Automatically unmute and play background music when prayer is generated
        _isAudioMuted = false;
        await _playBackgroundMusic();
        await MilestoneLifetimePaywallCoordinator
            .onPrayerGuidanceAiResponseSuccess(context);
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

    // Show Please Note dialog before first response (same as category prayer)
    final agreed = await _showPleaseNoteDialog();
    if (!agreed || !mounted) return;

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
        if (mounted) {
          final prefs = await SharedPreferences.getInstance();
          final creditDebitShown =
              prefs.getBool('prayer_credit_debit_shown') ?? false;
          if (!creditDebitShown) {
            Constants.showToast(
                'Used $chatCost credits for this response', 5000);
            await prefs.setBool('prayer_credit_debit_shown', true);
          }
          _loadCreditsFromLocal();
        }
        await updateBiblePrayerWidget(prayerText: responseText);
        // Automatically unmute and play background music when prayer is generated
        _isAudioMuted = false;
        await _playBackgroundMusic();
        await MilestoneLifetimePaywallCoordinator
            .onPrayerGuidanceAiResponseSuccess(context);
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
                            "Let your prayer begin with a thought or feeling, or choose a theme below.",
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

    // Refresh chat language so UI reflects app language
    AppApiConstant.loadChatLanguage().then((_) {
      if (mounted) setState(() {});
    });

    // Load credits and refresh periodically (same as Chat screen)
    _loadCreditsFromLocal();
    _creditsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadCreditsFromLocal();
    });

    // Show shared answer-length intro if needed (same behaviour as Chat).
    _showPrayerIntroIfNeeded();
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
      debugPrint('Prayer credits load error: $e');
    }
  }

  /// Show the shared "Select Answer Length" intro once, same as Chat screen.
  Future<void> _showPrayerIntroIfNeeded() async {
    // Show Important Notice first when entering prayer guidance; only then show intro.
    final agreed = await _showPleaseNoteDialog();
    if (!agreed || !mounted) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('chat_intro_seen') ?? false;
    if (seenIntro || !mounted) return;

    final length = await WalletService.getAnswerLength();
    if (!mounted) return;
    setState(() {
      _introAnswerLength = length;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _showPrayerIntroDialog();
  }

  Future<void> _showPrayerIntroDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final initialCredits = await WalletService.getCredits();

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 50),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: ConstrainedBox(
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
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
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
                        Padding(
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
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color:
                                          CommanColor.lightDarkPrimary(
                                              context),
                                      size: 20,
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
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      side: isDark
                                          ? const BorderSide(
                                              color: Colors.white,
                                              width: 1.5)
                                          : BorderSide.none,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () async {
                                    final prefs =
                                        await SharedPreferences
                                            .getInstance();
                                    await prefs.setBool(
                                        'chat_intro_seen', true);
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(16),
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
                                        vertical: screenWidth > 450
                                            ? 16
                                            : 14,
                                      ),
                                      child: Text(
                                        'Continue',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth > 450
                                              ? 17
                                              : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom +
                                    10,
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
                  ? CommanColor.lightDarkPrimary(context).withOpacity(0.15)
                  : CommanColor.lightDarkPrimary(context).withOpacity(0.08))
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark
                    ? Colors.white
                    : CommanColor.lightDarkPrimary(context))
                : (isDark
                    ? Colors.white.withOpacity(0.1)
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
                      ? CommanColor.lightDarkPrimary(context)
                      : (isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.grey.shade400),
                  width: 2,
                ),
                color: isSelected
                    ? CommanColor.lightDarkPrimary(context)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
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
                    ? CommanColor.lightDarkPrimary(context)
                        .withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CommanColor.lightDarkPrimary(context)
                      .withOpacity(0.6),
                ),
              ),
              child: Text(
                cost,
                style: TextStyle(
                  color: CommanColor.lightDarkPrimary(context),
                  fontSize: screenWidth > 450 ? 13 : 12,
                  fontWeight: FontWeight.w600,
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
  void dispose() {
    _creditsTimer?.cancel();
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

  /// Show interstitial for unsubscribed users then pop. Call when user taps Back to leave the screen.
  /// Guarded so only one interstitial shows per leave (no repeated triggers).
  Future<void> _maybeShowInterstitialAndPop() async {
    if (_isClosingWithAd) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _isClosingWithAd = true;
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);
    final subscriptionPlan = await downloadProvider.getSubscriptionPlan();
    final isSubscribed = subscriptionPlan != null &&
        subscriptionPlan.isNotEmpty &&
        ['platinum', 'gold', 'silver'].contains(subscriptionPlan.toLowerCase());
    if (!isSubscribed) {
      try {
        // Show back interstitial at most once every 3 minutes (shared with Chat)
        final lastStr = await SharPreferences.getString(
            SharPreferences.lastBackInterstitialTime);
        final now = DateTime.now();
        final canShowByTime = lastStr == null ||
            lastStr.isEmpty ||
            now.difference(DateTime.tryParse(lastStr) ?? now).inMinutes >= 3;
        if (canShowByTime) {
          final hasInternet = await InternetConnection().hasInternetAccess;
          if (hasInternet) {
            final connectivityResult = await Connectivity().checkConnectivity();
            final isMobileOnly =
                connectivityResult.contains(ConnectivityResult.mobile) &&
                    !connectivityResult.contains(ConnectivityResult.wifi) &&
                    !connectivityResult.contains(ConnectivityResult.ethernet);
            if (!isMobileOnly) {
              await _showInterstitialAdAndWait();
              await SharPreferences.setString(
                  SharPreferences.lastBackInterstitialTime,
                  now.toIso8601String());
            }
          }
        }
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
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
        // If on category selection view, close the screen (show interstitial for unsubscribed then pop)
        debugPrint('🔙 BACK BUTTON: System back pressed, closing screen...');
        await _maybeShowInterstitialAndPop();
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
                          // If on category selection view, close the screen (show interstitial for unsubscribed then pop)
                          debugPrint(
                              '🔙 BACK BUTTON: Back arrow pressed, closing screen...');
                          await _maybeShowInterstitialAndPop();
                        },
                        icon: Icon(Icons.arrow_back_ios,
                            color: CommanColor.whiteBlack(context), size: 18),
                      ),
                      Expanded(
                        child: _messages.isEmpty
                            ? const SizedBox.shrink()
                            : Center(
                                child: Text(
                                  ChatTranslations.get(
                                      'prayer_guidance_title', 'EN'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: CommanColor.whiteBlack(context)
                                        .withOpacity(0.7),
                                    fontSize: size.width > 450 ? 22 : 18,
                                  ),
                                ),
                              ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Wallet icon and credits (same as Chat screen)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width > 450 ? 12 : 10,
                              vertical: size.width > 450 ? 10 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: Provider.of<ThemeProvider>(context)
                                          .themeMode ==
                                      ThemeMode.dark
                                  ? CommanColor.darkPrimaryColor
                                      .withOpacity(0.35)
                                  : const Color(0xFFF6F1E9).withOpacity(0.65),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Provider.of<ThemeProvider>(context)
                                            .themeMode ==
                                        ThemeMode.dark
                                    ? Colors.white.withOpacity(0.18)
                                    : const Color(0xFF8D6E63)
                                        .withOpacity(0.18),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                Get.to(
                                  () => const WalletScreen(),
                                  transition: Transition.cupertinoDialog,
                                  duration:
                                      const Duration(milliseconds: 300),
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
                                    color: Provider.of<ThemeProvider>(context)
                                                .themeMode ==
                                            ThemeMode.dark
                                        ? Colors.white
                                        : const Color(0xFF8D6E63),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_currentCredits',
                                    style: TextStyle(
                                      color: Provider.of<ThemeProvider>(
                                                  context)
                                              .themeMode ==
                                          ThemeMode.dark
                                          ? Colors.white
                                          : const Color(0xFF8D6E63),
                                      fontSize:
                                          size.width > 450 ? 14 : 13,
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
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              child: IconButton(
                                onPressed: _toggleAudio,
                                icon: Icon(
                                  _isAudioMuted
                                      ? Icons.music_off
                                      : Icons.music_note,
                                  color: CommanColor.whiteBlack(context),
                                  size: 22,
                                ),
                                tooltip:
                                    _isAudioMuted ? 'Audio Off' : 'Audio On',
                              ),
                            )
                          else
                            const SizedBox(width: 24, height: 48),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header: illustration, title, subtitle (full-width)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Icon(
                                    Icons.volunteer_activism,
                                    size: size.width > 450 ? 56 : 48,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5C4033),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    ChatTranslations.get(
                                        'prayer_guidance_title', 'EN'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF3D2914),
                                      fontSize: size.width > 450 ? 24 : 22,
                                      fontFamily: 'Georgia',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ChatTranslations.get('get_guidance_need', 'EN'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF6D6D6D),
                                      fontSize: size.width > 450 ? 15 : 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Mode selector: Pray for Me / Community Prayers
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            // When Pray for Me is tapped, directly show the custom prayer dialog (same popup as the search input used to open)
                                            if (mounted) {
                                              setState(() {
                                                _isPrayForMeMode = true;
                                              });
                                            }
                                            final agreed = await _showPleaseNoteDialog();
                                            if (!agreed || !mounted) return;
                                            _showCustomPrayerDialog(context);
                                          },
                                          borderRadius: BorderRadius.circular(28),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _isPrayForMeMode
                                                  ? (isDark ? const Color(0xFF5C4033) : const Color(0xFF5C4033))
                                                  : (isDark ? Colors.transparent : Colors.white),
                                              borderRadius: BorderRadius.circular(28),
                                              border: Border.all(
                                                color: _isPrayForMeMode
                                                    ? Colors.transparent
                                                    : (isDark ? Colors.white24 : const Color(0xFFD4C4B0)),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Pray for Me',
                                                style: TextStyle(
                                                  color: _isPrayForMeMode ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF3D2914)),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            // Navigate to Prayer Wall (community prayers)
                                            if (mounted) {
                                              setState(() {
                                                _isPrayForMeMode = false;
                                              });
                                            }
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const PrayerWallScreen(),
                                              ),
                                            );
                                            if (mounted) {
                                              setState(() {
                                                _isPrayForMeMode = true;
                                              });
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(28),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: !_isPrayForMeMode
                                                  ? (isDark ? const Color(0xFF5C4033) : const Color(0xFF5C4033))
                                                  : (isDark ? Colors.transparent : Colors.white),
                                              borderRadius: BorderRadius.circular(28),
                                              border: Border.all(
                                                color: !_isPrayForMeMode
                                                    ? Colors.transparent
                                                    : (isDark ? Colors.white24 : const Color(0xFFD4C4B0)),
                                              ),
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Center(
                                                  child: Text(
                                                    'Community Prayers',
                                                    style: TextStyle(
                                                      color: !_isPrayForMeMode ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF3D2914)),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 8,
                                                  top: 6,
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF4CAF50),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 1.2),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Search input removed: tapping "Pray for Me" shows the same popup as before
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                            // Grid scrolls (full-width content)
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing:
                                            size.width > 450 ? 16 : 12,
                                        mainAxisSpacing:
                                            size.width > 450 ? 16 : 12,
                                        childAspectRatio:
                                            size.width > 450 ? 1.4 : 1.3,
                                      ),
                                      itemCount: _categories.length,
                                      itemBuilder: (context, index) {
                                        final categoryIndex = index;
                                        // Get icon for each category
                                        IconData categoryIcon;

                                        switch (categoryIndex % 9) {
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
                                            categoryIcon =
                                                Icons.self_improvement;
                                            break;
                                          case 4: // Healing
                                            categoryIcon = Icons.healing;
                                            break;
                                          case 5: // Family
                                            categoryIcon =
                                                Icons.family_restroom;
                                            break;
                                          case 6: // Strength
                                            categoryIcon = Icons.fitness_center;
                                            break;
                                          case 7: // Protection
                                            categoryIcon = Icons.shield;
                                            break;
                                          default: // Feelings
                                            categoryIcon = Icons.mood;
                                            break;
                                        }

                                        // Old paper theme: same texture as screen background
                                        final borderClr = isDark
                                            ? Colors.white24
                                            : const Color(0xFFD4C4B0);
                                        final textClr = isDark
                                            ? Colors.white
                                            : const Color(0xFF3D2914);

                                        return InkWell(
                                          onTap: () {
                                            _sendPrayerRequest(categoryIndex);
                                          },
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  size.width > 450 ? 16 : 12,
                                              vertical:
                                                  size.width > 450 ? 20 : 16,
                                            ),
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(Images
                                                    .bgImage(context)),
                                                fit: BoxFit.cover,
                                              ),
                                              color: (isDark
                                                      ? Colors.black
                                                      : Colors.white)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: borderClr,
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  categoryIcon,
                                                  size: size.width > 450
                                                      ? 30
                                                      : 26,
                                                  color: textClr,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _categories[categoryIndex]
                                                      .title,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: size.width > 450
                                                        ? 15
                                                        : 13,
                                                    color: textClr,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  categoryIndex < _categorySubtitles.length
                                                      ? _categorySubtitles[categoryIndex]
                                                      : '',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: size.width > 450 ? 13 : 12,
                                                    color: textClr.withOpacity(0.85),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    // Get Prayer button (opens custom prayer dialog; show Important Notice first)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final agreed = await _showPleaseNoteDialog();
                                          if (!agreed || !mounted) return;
                                          _showCustomPrayerDialog(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark
                                              ? CommanColor.darkPrimaryColor
                                              : const Color(0xFFD4A574),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Get Prayer',
                                          style: TextStyle(
                                            fontSize: size.width > 450 ? 17 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF5C4033),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                    maxWidth: isUser
                                        ? size.width * 0.92
                                        : size.width,
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildMessageWithVerseLinks(
                                        message.text,
                                        isUser,
                                        size,
                                        isDark,
                                      ),
                                      const SizedBox(height: 6),
                                      // Action icons (Copy / Share) for responses only
                                      if (!isUser)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            // Copy (same style as Chat screen)
                                            InkWell(
                                              onTap: () async {
                                                await Clipboard.setData(
                                                    ClipboardData(
                                                        text: message.text));
                                                Constants.showToast(
                                                    ChatTranslations.get(
                                                        'copied',
                                                        AppApiConstant
                                                            .chatLanguage));
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                        vertical: 2),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.white
                                                              .withOpacity(0.14)
                                                          : Colors.black
                                                              .withOpacity(
                                                                  0.12),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Image.asset(
                                                    "assets/Bookmark icons/Frame 3630.png",
                                                    height: size.width > 450
                                                        ? 18
                                                        : 15,
                                                    width: size.width > 450
                                                        ? 18
                                                        : 15,
                                                    color: isDark
                                                        ? Colors.white
                                                            .withOpacity(0.8)
                                                        : Colors.black
                                                            .withOpacity(0.6),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            // Share (same style as Chat screen)
                                            InkWell(
                                              onTap: () async {
                                                // Rating request shown only on 2nd app open (see home_screen), not here
                                                final screenSize =
                                                    MediaQuery.of(context).size;
                                                final sharePositionOrigin =
                                                    Rect.fromLTWH(
                                                  screenSize.width / 2 - 50,
                                                  screenSize.height / 2 - 50,
                                                  100,
                                                  100,
                                                );
                                                await Share.share(
                                                  _buildShareText(message.text),
                                                  sharePositionOrigin:
                                                      sharePositionOrigin,
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                        vertical: 2),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.white
                                                              .withOpacity(0.14)
                                                          : Colors.black
                                                              .withOpacity(
                                                                  0.12),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.share,
                                                    size: size.width > 450
                                                        ? 18
                                                        : 15,
                                                    color: isDark
                                                        ? Colors.white
                                                            .withOpacity(0.8)
                                                        : Colors.black
                                                            .withOpacity(0.6),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // AMEN button at the bottom - only show after prayer is generated (at least one AI response)
                if (_messages.any((m) => !m.isUser))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
