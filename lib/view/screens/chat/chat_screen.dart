import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/rating_dialog_helper.dart';
import 'package:biblebookapp/utils/network_error_message.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_history_screen.dart';
import 'package:biblebookapp/view/screens/chat/chat_translations.dart';
import 'package:biblebookapp/services/milestone_lifetime_paywall_coordinator.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  final String? historyDateKey;
  final Map<String, String>?
      verseContext; // Verse context: verseText, book, chapter, verse

  const ChatScreen({super.key, this.historyDateKey, this.verseContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentConversationId;
  bool _openedRecentFromHome = false;
  static const String _baseUrl =
      'https://my-backend-one-eta.vercel.app/api/gemini';
  int? _selectedTopicIndex; // Track which topic button is selected
  int?
      _selectedExampleQuestionIndex; // Track which example question button is tapped
  String _introAnswerLength = 'small';

  /// Normalized text of follow-up chips the user already sent (so the next
  /// reply can surface different suggestions).
  final Set<String> _usedFollowUpSuggestionKeys = {};

  /// API-generated follow-ups for the footer row (same language as assistant).
  List<String>? _geminiFollowUpSuggestions;
  int? _geminiFollowUpsMessageHash;

  // Speech to text
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechInitialized = false;
  String _text = '';
  bool _openedSettingsForPermission = false; // Track if user opened settings

  // Wallet credits (loaded from local storage immediately)
  int _currentCredits = 0;
  Timer? _creditsTimer;

  // Recent conversations
  List<Map<String, dynamic>> _recentConversations = [];

  // Back-button interstitial: show one interstitial when leaving Chat (for unsubscribed) after any activity
  bool _hasShownBackInterstitial = false;
  bool _userDidActivity = false;
  bool _isHandlingBack =
      false; // Prevent multiple triggers (e.g. system back + app bar) showing ad repeatedly
  final AdService _chatBackAdService = AdService();

  // Topic-based questions (translation keys)
  final List<Map<String, String>> _topicQuestionKeys = [
    {'topicKey': 'topic_anxious', 'questionKey': 'question_anxious'},
    {'topicKey': 'topic_confused', 'questionKey': 'question_confused'},
    {'topicKey': 'topic_strength', 'questionKey': 'question_strength'},
    {'topicKey': 'topic_lost', 'questionKey': 'question_lost'},
    {'topicKey': 'topic_stuck', 'questionKey': 'question_stuck'},
    {'topicKey': 'topic_promises', 'questionKey': 'question_promises'},
  ];

  // Helper to get translated topic questions
  // NOTE: Chat language should control ONLY AI responses, not the Chat UI.
  // Keep UI text stable (English) regardless of AppApiConstant.chatLanguage.
  static const String _uiLang = 'EN';
  List<Map<String, String>> get _topicQuestions =>
      _topicQuestionKeys.map((keys) {
        return {
          'topic': ChatTranslations.get(keys['topicKey']!, _uiLang),
          'question': ChatTranslations.get(keys['questionKey']!, _uiLang),
        };
      }).toList();

  // UI labels that should not follow chat response language.
  String _tUi(String key) => ChatTranslations.get(key, _uiLang);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.historyDateKey != null) {
      _currentConversationId = widget.historyDateKey;
    } else {
      _currentConversationId = _generateConversationId();
    }
    _loadChatHistory();
    // Refresh chat language so AI suggestions and UI reflect app language
    AppApiConstant.loadChatLanguage().then((_) {
      if (mounted) setState(() {});
    });
    // Track Geneva Bible Chat event
    AnalyticsService.trackGenevaBibleChat();
    _showChatIntroIfNeeded();
    _loadRecentConversations();

    // Load credits from local storage immediately (no API dependency)
    _loadCreditsFromLocal();

    // Refresh credits periodically from local storage (not API dependent)
    _creditsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadCreditsFromLocal();
    });

    // Speech will be initialized only when voice icon is clicked
    // Don't initialize here to avoid asking permission on screen entry

    // Listen to text field changes
    _messageController.addListener(() {
      setState(() {});
    });

    // Load interstitial for back-button ad (one ad when leaving Chat for unsubscribed)
    _chatBackAdService.loadInterstitialAd(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _speech?.stop();
    _creditsTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes, check permission status if we opened settings
    if (state == AppLifecycleState.resumed && _openedSettingsForPermission) {
      _openedSettingsForPermission = false;
      // Check permission status after returning from settings
      _checkPermissionAfterReturningFromSettings();
    }
  }

  Future<void> _checkPermissionAfterReturningFromSettings() async {
    // Wait a bit for system to update permission status
    await Future.delayed(const Duration(milliseconds: 300));
    final permissionStatus = await Permission.microphone.status;
    if (permissionStatus.isGranted && mounted) {
      // Permission was granted, reset speech initialization to start fresh
      if (mounted) {
        setState(() {
          _speechInitialized = false;
        });
      }
      // Don't automatically start listening, let user tap record button
    }
  }

  Future<void> _showChatIntroIfNeeded() async {
    // Show Important Notice first when entering chat; only then show intro bottom sheet.
    final agreed = await _showPleaseNoteDialog();
    if (!agreed || !mounted) {
      if (mounted) Navigator.of(context).pop();
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
    // Brief delay so the dialog route is fully popped before showing bottom sheet.
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _showChatIntroDialog();
  }

  Future<void> _showChatIntroDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final screenWidth = MediaQuery.of(context).size.width;

    // Load initial credits to display
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
                        color: isDark
                            ? CommanColor.darkPrimaryColor
                            : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Section with Gradient
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
                                Container(
                                  width: screenWidth > 450 ? 38 : 34,
                                  height: screenWidth > 450 ? 38 : 34,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(
                                              "assets/start_icon.png"))),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Welcome to Bible Chat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth > 450 ? 22 : 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose your preferred answer style',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: screenWidth > 450 ? 15 : 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                // Credits display
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth > 450 ? 16 : 14,
                                    vertical: screenWidth > 450 ? 10 : 8,
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
                                        size: screenWidth > 450 ? 20 : 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'You have $initialCredits credits',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth > 450 ? 15 : 14,
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
                                padding:
                                    EdgeInsets.all(screenWidth > 450 ? 24 : 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Info Card
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : CommanColor.lightDarkPrimary(
                                                    context)
                                                .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.1)
                                              : CommanColor.lightDarkPrimary(
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
                                                  ? Colors.white
                                                      .withOpacity(0.12)
                                                  : CommanColor
                                                          .lightDarkPrimary(
                                                              context)
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                  : CommanColor
                                                      .lightDarkPrimary(
                                                          context),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Each answer uses credits. You can change this anytime in your Wallet.',
                                              style: TextStyle(
                                                color: CommanColor.whiteBlack(
                                                        context)
                                                    .withOpacity(0.8),
                                                fontSize:
                                                    screenWidth > 450 ? 14 : 13,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Answer Length Options
                                    Text(
                                      'Select Answer Length',
                                      style: TextStyle(
                                        color: CommanColor.whiteBlack(context),
                                        fontSize: screenWidth > 450 ? 17 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildIntroAnswerLengthOption(
                                      context,
                                      screenWidth,
                                      isDark,
                                      'small',
                                      'Short Answer',
                                      'Quick & concise response',
                                      '20 Credits',
                                      setBottomSheetState,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildIntroAnswerLengthOption(
                                      context,
                                      screenWidth,
                                      isDark,
                                      'medium',
                                      'Medium Answer',
                                      'Balanced explanation',
                                      '50 Credits',
                                      setBottomSheetState,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildIntroAnswerLengthOption(
                                      context,
                                      screenWidth,
                                      isDark,
                                      'large',
                                      'Full Study',
                                      'Detailed & comprehensive',
                                      '100 Credits',
                                      setBottomSheetState,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              screenWidth > 450 ? 24 : 20,
                              8,
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
                                  await prefs.setBool('chat_intro_seen', true);
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
                                      vertical: screenWidth > 450 ? 16 : 14,
                                    ),
                                    child: Text(
                                      'Got it, Let\'s Chat!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth > 450 ? 17 : 16,
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
                    )));
          },
        );
      },
    );
  }

  Widget _buildIntroAnswerLengthOption(
    BuildContext context,
    double screenWidth,
    bool isDark,
    String length,
    String title,
    String description,
    String cost,
    StateSetter setBottomSheetState,
  ) {
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
              : (isDark ? Colors.black.withOpacity(0.22) : Colors.grey.shade50),
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
            // Custom Radio Button
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
                          color:
                              isDark ? const Color(0xFF3D2914) : Colors.white,
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
                      color: CommanColor.whiteBlack(context).withOpacity(0.6),
                      fontSize: screenWidth > 450 ? 13 : 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Cost Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      ? (isDark ? const Color(0xFF3D2914) : Colors.white)
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

  Future<void> _initializeSpeech() async {
    if (_speech == null) return;
    try {
      bool available = await _speech!.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              if (status == 'done' || status == 'notListening') {
                _isListening = false;
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            // Only show error if it's not a permission error (to avoid spam)
            if (!error.errorMsg.toLowerCase().contains('permission')) {
              Constants.showToast(
                  'Speech recognition error: ${error.errorMsg}', 5000);
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          _speechInitialized = available;
        });
        // Don't show toast if not available - it's normal on some devices
      }
    } catch (e) {
      // Handle any initialization errors gracefully
      if (mounted) {
        setState(() {
          _speechInitialized = false;
        });
      }
    }
  }

  void _startListening() async {
    // Check if user has enough credits before starting voice input
    final chatCost = await WalletService.getChatCost();
    final hasCredits = await WalletService.getCredits() >= chatCost;
    if (!hasCredits) {
      await _showInsufficientCreditsDialog();
      return;
    }

    if (_speech == null) {
      _speech = stt.SpeechToText();
    }
    if (!_isListening) {
      // Initialize if not already initialized
      // On iOS, speech_to_text package handles Speech Recognition permission automatically
      // On Android, it handles Microphone permission automatically
      // We should rely on the package's initialization result rather than pre-checking
      if (!_speechInitialized) {
        try {
          bool available = await _speech!.initialize(
            onStatus: (status) {
              if (mounted) {
                setState(() {
                  if (status == 'done' || status == 'notListening') {
                    _isListening = false;
                  }
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _isListening = false;
                });
                // Check if it's a permission error and handle it
                final errorMsg = error.errorMsg.toLowerCase();
                if (errorMsg.contains('permission') ||
                    errorMsg.contains('denied') ||
                    errorMsg.contains('not authorized')) {
                  // Permission was denied, check status and handle
                  _handlePermissionError();
                } else {
                  Constants.showToast(
                      'Speech recognition error: ${error.errorMsg}', 5000);
                }
              }
            },
          );
          if (mounted) {
            setState(() {
              _speechInitialized = available;
            });
          }
          if (!available) {
            // Initialization failed - check if it's a permission issue
            // On iOS, speech recognition permission might be denied
            // On Android, microphone permission might be denied
            await _checkAndHandlePermissionIssue();
            return;
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _speechInitialized = false;
            });
          }
          // Check if it's a permission issue
          await _checkAndHandlePermissionIssue();
          return;
        }
      }

      if (_speechInitialized) {
        try {
          setState(() {
            _isListening = true;
          });
          await _speech!.listen(
            onResult: (result) {
              if (mounted) {
                setState(() {
                  _text = result.recognizedWords;
                  // Update text field immediately as user speaks (real-time)
                  _messageController.text = result.recognizedWords;
                  if (result.finalResult) {
                    _isListening = false;
                  }
                });
              }
            },
          );
        } catch (e) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
          Constants.showToast('Failed to start listening', 5000);
        }
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() async {
    if (_isListening && _speechInitialized && _speech != null) {
      try {
        await _speech!.stop();
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      } catch (e) {
        // Ignore errors when stopping
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      }
    }
  }

  Future<void> _checkAndHandlePermissionIssue() async {
    // Check microphone permission status (works for both iOS and Android)
    // On iOS, speech recognition also requires microphone access
    final micStatus = await Permission.microphone.status;

    if (micStatus.isGranted) {
      // Permission is granted, but initialization failed - might be a different issue
      // Reset and try again
      if (mounted) {
        setState(() {
          _speechInitialized = false;
        });
      }
      // Wait a moment and retry
      await Future.delayed(const Duration(milliseconds: 200));
      return _startListening();
    }

    // Permission not granted
    if (micStatus.isPermanentlyDenied) {
      // Check status again in case user just enabled it in settings
      await Future.delayed(const Duration(milliseconds: 100));
      final recheckStatus = await Permission.microphone.status;
      if (recheckStatus.isGranted) {
        // Permission was granted in settings, retry
        if (mounted) {
          setState(() {
            _speechInitialized = false;
          });
        }
        return _startListening();
      } else {
        // Still denied, show settings dialog
        _showMicrophonePermissionDialog();
        return;
      }
    }

    // Permission not granted and not permanently denied, try to request it
    final newStatus = await Permission.microphone.request();
    if (!newStatus.isGranted) {
      if (newStatus.isPermanentlyDenied) {
        _showMicrophonePermissionDialog();
      }
      // If denied but not permanently, silently return - user can try again
      return;
    }

    // Permission was just granted, try initializing again
    if (mounted) {
      setState(() {
        _speechInitialized = false;
      });
    }
    await Future.delayed(const Duration(milliseconds: 200));
    return _startListening();
  }

  Future<void> _handlePermissionError() async {
    // This is called from onError callback when permission error occurs
    await _checkAndHandlePermissionIssue();
  }

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
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                              color: isDark
                                  ? Colors.white
                                  : CommanColor.lightDarkPrimary(ctx),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Agree & Continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CommanColor.darkPrimaryColor
                                    : Colors.white,
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
                              color: isDark ? Colors.white12 : Colors.white,
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

  void _showMicrophonePermissionDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 100 : 24,
          vertical: isTablet ? 60 : 24,
        ),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 28 : 24),
          decoration: BoxDecoration(
            color: CommanColor.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Microphone icon
              Container(
                width: isTablet ? 80 : 70,
                height: isTablet ? 80 : 70,
                decoration: BoxDecoration(
                  color: CommanColor.lightDarkPrimary(context).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic,
                  size: isTablet ? 40 : 35,
                  color: CommanColor.lightDarkPrimary(context),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                "Microphone Permission",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  color: CommanColor.black,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                "To use voice input, please enable microphone permission in your device settings.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Instructions
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Settings > App > Microphone > Enable",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _tUi('cancel'),
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await SharPreferences.setString('OpenAd', '1');
                        // Mark that we're opening settings for permission
                        _openedSettingsForPermission = true;
                        await openAppSettings();
                        if (context.mounted) {
                          Navigator.pop(context);
                          // Permission check will happen in didChangeAppLifecycleState when app resumes
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CommanColor.lightDarkPrimary(context),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.settings,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Open Settings',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
  }

  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Show interstitial and wait for dismiss (for back-button ad). One ad only for unsubscribed when leaving after activity.
  Future<void> _showChatBackInterstitialAndWait() async {
    final completer = Completer<void>();
    final ad = _chatBackAdService.interstitialAd;
    if (ad == null) {
      completer.complete();
      return completer.future;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) async {
        a.dispose();
        _chatBackAdService.loadInterstitialAd(() {});
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _chatBackAdService.loadInterstitialAd(() {});
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
  }

  Future<void> _returnToChatHome() async {
    setState(() {
      _openedRecentFromHome = false;
      _messages.clear();
      _usedFollowUpSuggestionKeys.clear();
      _geminiFollowUpSuggestions = null;
      _geminiFollowUpsMessageHash = null;
      _currentConversationId = _generateConversationId();
    });
    await _loadRecentConversations();
  }

  Future<void> _handleBack() async {
    // Only one back-handler runs at a time; avoid interstitial showing multiple times
    if (_isHandlingBack) {
      if (mounted) Get.back();
      return;
    }

    if (_openedRecentFromHome &&
        widget.historyDateKey == null &&
        widget.verseContext == null) {
      await _returnToChatHome();
      return;
    }

    _isHandlingBack = true;
    if (_userDidActivity && !_hasShownBackInterstitial && mounted) {
      final downloadProvider =
          Provider.of<DownloadProvider>(context, listen: false);
      final plan = await downloadProvider.getSubscriptionPlan();
      final isSubscribed = plan != null &&
          plan.isNotEmpty &&
          ['platinum', 'gold', 'silver'].contains(plan.toLowerCase());
      if (!isSubscribed) {
        try {
          // Show back interstitial at most once every 3 minutes (shared with Prayer)
          final lastStr = await SharPreferences.getString(
              SharPreferences.lastBackInterstitialTime);
          final now = DateTime.now();
          final canShowByTime = lastStr == null ||
              lastStr.isEmpty ||
              now.difference(DateTime.tryParse(lastStr) ?? now).inMinutes >= 3;
          if (canShowByTime) {
            final hasInternet = await InternetConnection().hasInternetAccess;
            if (hasInternet) {
              final result = await Connectivity().checkConnectivity();
              final isMobileOnly = result.contains(ConnectivityResult.mobile) &&
                  !result.contains(ConnectivityResult.wifi) &&
                  !result.contains(ConnectivityResult.ethernet);
              if (!isMobileOnly) {
                _hasShownBackInterstitial = true;
                await _showChatBackInterstitialAndWait();
                await SharPreferences.setString(
                    SharPreferences.lastBackInterstitialTime,
                    now.toIso8601String());
              }
            }
          }
        } catch (_) {}
      }
    }
    if (mounted) Get.back();
  }

  Future<void> _loadChatHistory() async {
    if (_currentConversationId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('chat_history_$_currentConversationId');
    if (historyJson != null) {
      final List<dynamic> history = jsonDecode(historyJson);
      setState(() {
        _messages.clear();
        _usedFollowUpSuggestionKeys.clear();
        _geminiFollowUpSuggestions = null;
        _geminiFollowUpsMessageHash = null;
        _messages.addAll(
          history.map((item) => ChatMessage.fromJson(item)).toList(),
        );
      });
      // When opening a recent conversation, fetch Gemini follow-ups for the
      // latest assistant reply so the footer suggestions also appear in history view.
      final lastAi = _messages.lastWhere(
        (m) => !m.isUser,
        orElse: () => ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      if (lastAi.text.trim().isNotEmpty) {
        unawaited(_fetchGeminiFollowUpSuggestions(
          lastAi.text,
          avoidNormalizedQuestions: _usedFollowUpSuggestionKeys,
        ));
      }
      // Removed _scrollToBottom() to keep view at top when loading history
    }
  }

  Future<void> _saveChatHistory() async {
    if (_currentConversationId == null || _messages.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(
      _messages.map((msg) => msg.toJson()).toList(),
    );
    await prefs.setString('chat_history_$_currentConversationId', historyJson);

    // Also save conversation metadata
    String preview;
    // If verse context exists, use verse reference as preview
    if (widget.verseContext != null) {
      final book = widget.verseContext!['book'] ?? '';
      final chapter = widget.verseContext!['chapter'] ?? '';
      final verse = widget.verseContext!['verse'] ?? '';
      preview = '$book $chapter:$verse';
    } else {
      preview = _messages.first.text.length > 50
          ? '${_messages.first.text.substring(0, 50)}...'
          : _messages.first.text;
    }

    final conversationMeta = {
      'id': _currentConversationId,
      'date': DateTime.now().toIso8601String(),
      'preview': preview,
      'messageCount': _messages.length,
    };
    await prefs.setString(
        'chat_meta_$_currentConversationId', jsonEncode(conversationMeta));

    // Reload recent conversations to update the list
    _loadRecentConversations();
  }

  String _getTodayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Helper function to extract verse reference from message text
  String? _extractVerseReference(String messageText) {
    // Check for "Reference: Book Chapter:Verse" pattern
    final referencePattern = RegExp(r'Reference:\s*([^\n]+)');
    final match = referencePattern.firstMatch(messageText);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }

  Future<void> _loadRecentConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('chat_history_'))
        .toList();

    final List<Map<String, dynamic>> conversations = [];
    for (final key in keys) {
      final conversationId = key.replaceFirst('chat_history_', '');
      // Skip current conversation
      if (conversationId == _currentConversationId) continue;

      final historyJson = prefs.getString(key);
      if (historyJson != null) {
        final List<dynamic> history = jsonDecode(historyJson);
        if (history.isNotEmpty) {
          DateTime date;
          String preview;

          // Try to get metadata first
          final metaKey = 'chat_meta_$conversationId';
          final metaJson = prefs.getString(metaKey);

          if (metaJson != null) {
            try {
              final meta = jsonDecode(metaJson);
              date = DateTime.parse(meta['date'] as String);
              preview = meta['preview'] as String;
              // If preview doesn't look like a verse reference, try to extract from first message
              if (!preview.contains(RegExp(r'\d+:\d+'))) {
                final firstMessage = history.first['text'] as String? ?? '';
                final verseRef = _extractVerseReference(firstMessage);
                if (verseRef != null) {
                  preview = verseRef;
                }
              }
            } catch (e) {
              date = DateTime.now();
              final firstMessage = history.first['text'] as String? ?? '';
              final verseRef = _extractVerseReference(firstMessage);
              if (verseRef != null) {
                preview = verseRef;
              } else {
                preview = firstMessage;
                if (preview.length > 50) {
                  preview = '${preview.substring(0, 50)}...';
                }
              }
            }
          } else {
            try {
              date = DateFormat('yyyy-MM-dd').parse(conversationId);
            } catch (e) {
              if (history.first['timestamp'] != null) {
                try {
                  date = DateTime.parse(history.first['timestamp'] as String);
                } catch (e2) {
                  date = DateTime.now();
                }
              } else {
                date = DateTime.now();
              }
            }
            final firstMessage = history.first['text'] as String? ?? '';
            final verseRef = _extractVerseReference(firstMessage);
            if (verseRef != null) {
              preview = verseRef;
            } else {
              preview = firstMessage;
              if (preview.length > 50) {
                preview = '${preview.substring(0, 50)}...';
              }
            }
          }

          conversations.add({
            'id': conversationId,
            'date': date,
            'preview': preview,
            'messageCount': history.length,
          });
        }
      }
    }

    conversations.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (mounted) {
      setState(() {
        _recentConversations =
            conversations.take(3).toList(); // Show only top 3
      });
    }
  }

  /// Load credits from local storage immediately (no API dependency)
  /// This ensures credits are shown even when offline or on slow connections
  Future<void> _loadCreditsFromLocal() async {
    try {
      // Get credits from local storage (WalletService uses SharedPreferences)
      final credits = await WalletService.getCredits();
      if (mounted && credits != _currentCredits) {
        setState(() {
          _currentCredits = credits;
        });
      }
    } catch (e) {
      debugPrint('Error loading credits from local storage: $e');
      // If error, keep showing current value
    }
  }

  Future<bool> _checkChatLimit() async {
    // Check if user has enough credits (cost depends on selected answer length)
    final chatCost = await WalletService.getChatCost();
    final credits = await WalletService.getCredits();
    return credits >= chatCost;
  }

  Future<void> _deductChatCredits() async {
    // Deduct credits for chat (cost depends on selected answer length)
    final chatCost = await WalletService.getChatCost();
    final success = await WalletService.deductCredits(chatCost);
    if (success) {
      // Show credit debit message only the first time
      final prefs = await SharedPreferences.getInstance();
      final creditDebitShown =
          prefs.getBool('chat_credit_debit_shown') ?? false;
      if (!creditDebitShown) {
        Constants.showToast('Used $chatCost credits for this response', 1500);
        await prefs.setBool('chat_credit_debit_shown', true);
      }
      // Refresh credits display immediately after deduction
      _loadCreditsFromLocal();
    }
  }

  Future<void> _showInsufficientCreditsDialog() async {
    final credits = await WalletService.getCredits();
    final chatCost = await WalletService.getChatCost();

    if (!mounted) return;

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Insufficient Credits',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'You need $chatCost credits to send a message. You currently have $credits credits.\n\nGet more credits from the wallet!',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                Get.to(
                  () => const WalletScreen(),
                  transition: Transition.cupertinoDialog,
                  duration: const Duration(milliseconds: 300),
                );
              },
              child: const Text(
                'Get Credits',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startNewChat() async {
    // Save current conversation to history before clearing (if it has messages)
    if (_messages.isNotEmpty && _currentConversationId != null) {
      await _saveChatHistory();
    }

    // Generate new conversation ID for the new chat
    _currentConversationId = _generateConversationId();

    // Clear only the current conversation, keep history intact
    setState(() {
      _openedRecentFromHome = false;
      _messages.clear();
      _usedFollowUpSuggestionKeys.clear();
      _geminiFollowUpSuggestions = null;
      _geminiFollowUpsMessageHash = null;
    });
  }

  void _showNewChatBottomSheet() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? CommanColor.darkPrimaryColor : CommanColor.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 450 ? 24 : 20,
              vertical: screenWidth > 450 ? 28 : 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: CommanColor.whiteBlack(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Icon
                Container(
                  width: screenWidth > 450 ? 70 : 60,
                  height: screenWidth > 450 ? 70 : 60,
                  decoration: BoxDecoration(
                    color:
                        CommanColor.lightDarkPrimary(context).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: screenWidth > 450 ? 35 : 30,
                    color: isDark
                        ? Colors.white
                        : CommanColor.lightDarkPrimary(context),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  _tUi('new_chat'),
                  style: TextStyle(
                    color: CommanColor.whiteBlack(context),
                    fontSize: screenWidth > 450 ? 24 : 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  _tUi('new_chat_confirmation'),
                  style: TextStyle(
                    color: CommanColor.whiteBlack(context).withOpacity(0.7),
                    fontSize: screenWidth > 450 ? 16 : 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth > 450 ? 16 : 14,
                          ),
                          side: BorderSide(
                            color: isDark
                                ? CommanColor.white.withOpacity(0.3)
                                : CommanColor.lightDarkPrimary(context)
                                    .withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              size: screenWidth > 450 ? 20 : 18,
                              color: isDark
                                  ? CommanColor.white.withOpacity(0.8)
                                  : CommanColor.lightDarkPrimary(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tUi('cancel'),
                              style: TextStyle(
                                color: isDark
                                    ? CommanColor.white.withOpacity(0.8)
                                    : CommanColor.lightDarkPrimary(context),
                                fontSize: screenWidth > 450 ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _startNewChat();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              CommanColor.lightDarkPrimary(context),
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth > 450 ? 16 : 14,
                          ),
                          elevation: 0,
                          side: isDark
                              ? const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: screenWidth > 450 ? 20 : 18,
                              color: CommanColor.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tUi('new_chat_long'),
                              style: TextStyle(
                                color: CommanColor.white,
                                fontSize: screenWidth > 450 ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth > 450 ? 8 : 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Show Please Note dialog before first response (must agree to continue)
    final agreed = await _showPleaseNoteDialog();
    if (!agreed || !mounted) return;

    // Check internet connection
    final bool isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      Constants.showToast("No internet connection", 5000);
      return;
    }

    // Check if user has enough credits before sending (cost depends on selected answer length)
    final chatCost = await WalletService.getChatCost();
    final hasCredits = await WalletService.getCredits() >= chatCost;
    if (!hasCredits) {
      await _showInsufficientCreditsDialog();
      return;
    }

    // Add user message to UI first
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _userDidActivity =
          true; // Track for back-button interstitial (one ad when leaving)
      _isLoading = true;
      _selectedTopicIndex = null; // Reset selected button when message is sent
      _selectedExampleQuestionIndex = null; // Reset example question selection
    });

    _messageController.clear();
    // Dismiss keyboard immediately when sending message - use FocusNode to ensure it stays dismissed
    _messageFocusNode.unfocus();
    // Also dismiss any other focus to ensure keyboard is fully dismissed
    FocusScope.of(context).unfocus();
    // Ensure keyboard stays dismissed by unfocusing again after a brief moment
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).unfocus();
        _messageFocusNode.unfocus();
      }
    });
    // Removed _scrollToBottom() to keep view at top when answer comes
    await _saveChatHistory();

    try {
      final url = Uri.parse('$_baseUrl');

      // Get selected answer length
      final answerLength = await WalletService.getAnswerLength();

      // Build answer length instruction based on selection
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

      // Build conversation context from history
      // Include system instruction and conversation history in the prompt
      String conversationContext =
          '''You are a knowledgeable and respectful assistant for the ${BibleInfo.bible_shortName}, one of the most historically significant English translations of the Bible. Follow these guidelines:

1. Provide accurate biblical information, interpretations, and explanations based on the ${BibleInfo.bible_shortName}
2. Help users understand verses, chapters, and biblical concepts with clarity and respect
3. Offer spiritual guidance and biblical wisdom in a thoughtful manner
4. Explain historical context and theological meanings accurately
5. Answer questions about biblical stories, characters, and teachings with proper context
6. Always maintain a respectful and reverent tone when discussing biblical matters
7. When explaining Bible content, be clear, accurate, and helpful
8. Provide well-structured responses that are easy to understand
9. If asked about specific verses, provide context and meaning
10. Always respond in plain text format without using asterisks (*), markdown formatting, or special characters
11. Do not repeat yourself: avoid restating the same sentences, bullet points, or stock phrases you already used in this conversation unless the user explicitly asks you to repeat or summarize.
12. Each new reply should add fresh detail, a different angle, or a deeper step—do not copy, closely paraphrase, or recycle your previous answer when the user asks a follow-up question.

${answerLengthInstruction}
${AppApiConstant.chatLanguage != null ? '\nIMPORTANT: Always respond in ${AppApiConstant.chatLanguage == 'TN' ? 'Tamil' : AppApiConstant.chatLanguage} language. All your responses must be in ${AppApiConstant.chatLanguage == 'TN' ? 'Tamil' : AppApiConstant.chatLanguage}.' : ''}

Remember: You are assisting users with the ${BibleInfo.bible_shortName}, so provide responses that honor the sacred nature of the text while being informative and helpful.
''';

      // Add previous messages to context (excluding the current user message we just added)
      final previousMessages = _messages.length > 1;
      if (previousMessages) {
        conversationContext += '\nConversation History:\n';
        for (int i = 0; i < _messages.length - 1; i++) {
          final msg = _messages[i];
          if (msg.isUser) {
            conversationContext += 'User: ${msg.text}\n';
          } else {
            conversationContext += 'Assistant: ${msg.text}\n';
          }
        }
      }

      // Add verse context if available
      String userMessageWithContext = message;
      if (widget.verseContext != null) {
        final verseText = widget.verseContext!['verseText'] ?? '';
        final book = widget.verseContext!['book'] ?? '';
        final chapter = widget.verseContext!['chapter'] ?? '';
        final verse = widget.verseContext!['verse'] ?? '';

        // Prepend verse information to the user's question
        userMessageWithContext = 'Reference: $book $chapter:$verse\n'
            'Verse: $verseText\n\n'
            'Question: $message';
      }

      // Add the current user message
      conversationContext += '\nUser: ${userMessageWithContext}\n';
      conversationContext += 'Assistant:';

      // Build request body with simple prompt format - exactly as API expects
      final requestBody = {
        'prompt': conversationContext,
      };

      // Debug: Print request for troubleshooting
      debugPrint('API Request URL: $url');
      debugPrint('API Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Debug: Print response for troubleshooting
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        String responseText = 'Sorry, I could not generate a response.';

        try {
          final responseData = jsonDecode(response.body);

          // Debug: Print parsed response data
          debugPrint('Parsed Response Data: $responseData');

          // Try output.candidates structure first (your API format)
          if (responseData['output'] != null && responseData['output'] is Map) {
            final output = responseData['output'] as Map;
            if (output['candidates'] != null &&
                output['candidates'] is List &&
                (output['candidates'] as List).isNotEmpty) {
              final candidate = (output['candidates'] as List)[0];
              if (candidate is Map) {
                if (candidate['content'] != null &&
                    candidate['content'] is Map &&
                    candidate['content']['parts'] != null &&
                    candidate['content']['parts'] is List &&
                    (candidate['content']['parts'] as List).isNotEmpty) {
                  final part = (candidate['content']['parts'] as List)[0];
                  if (part is Map && part['text'] != null) {
                    responseText = part['text'].toString();
                  }
                }
              }
            }
          }
          // Try direct response field
          else if (responseData['response'] != null) {
            if (responseData['response'] is String) {
              responseText = responseData['response'] as String;
            } else if (responseData['response'] is Map) {
              final responseObj = responseData['response'] as Map;
              if (responseObj['text'] != null) {
                responseText = responseObj['text'].toString();
              } else if (responseObj['content'] != null) {
                responseText = responseObj['content'].toString();
              }
            }
          }
          // Try direct text field
          else if (responseData['text'] != null) {
            responseText = responseData['text'].toString();
          }
          // Try message field
          else if (responseData['message'] != null) {
            responseText = responseData['message'].toString();
          }
          // Try candidates structure (direct Gemini API format)
          else if (responseData['candidates'] != null &&
              responseData['candidates'] is List &&
              (responseData['candidates'] as List).isNotEmpty) {
            final candidate = (responseData['candidates'] as List)[0];
            if (candidate is Map) {
              if (candidate['content'] != null &&
                  candidate['content'] is Map &&
                  candidate['content']['parts'] != null &&
                  candidate['content']['parts'] is List &&
                  (candidate['content']['parts'] as List).isNotEmpty) {
                final part = (candidate['content']['parts'] as List)[0];
                if (part is Map && part['text'] != null) {
                  responseText = part['text'].toString();
                }
              }
            }
          }
          // Try if responseData itself is a string
          else if (responseData is String) {
            responseText = responseData;
          }
        } catch (e) {
          // If JSON parsing fails, try to extract text from raw body
          // Remove JSON structure and try to find text content
          final body = response.body;
          if (body.contains('"text"')) {
            try {
              final textMatch =
                  RegExp(r'"text"\s*:\s*"([^"]+)"').firstMatch(body);
              if (textMatch != null) {
                responseText = textMatch.group(1) ?? responseText;
              }
            } catch (_) {
              responseText =
                  'Sorry, I could not generate a response. Please try again.';
            }
          } else if (body.isNotEmpty && !body.startsWith('{')) {
            // If body is not JSON, use it directly
            responseText = body;
          }
        }

        // Clean up the response text
        // Remove asterisks and trim whitespace
        responseText = responseText.replaceAll('*', '').trim();

        // Remove escape characters that might be in JSON strings
        responseText = responseText.replaceAll('\\n', '\n');
        responseText = responseText.replaceAll('\\"', '"');
        responseText = responseText.replaceAll('\\/', '/');

        // Ensure we have a valid response and it's not showing metadata
        if (responseText.isEmpty ||
            responseText == 'Sorry, I could not generate a response.' ||
            responseText.toLowerCase().contains('"candidates"') ||
            responseText.toLowerCase().contains('"usageMetadata"') ||
            responseText.toLowerCase().contains('"model"') ||
            responseText.toLowerCase().contains('"tokens"') ||
            (responseText.startsWith('{') && responseText.endsWith('}'))) {
          // If it looks like we're showing the full JSON, try to extract text one more time
          try {
            final responseData = jsonDecode(response.body);
            // Try to find text in nested structures
            String? extractText(dynamic data) {
              if (data is String) return data;
              if (data is Map) {
                // Try output structure first
                if (data['output'] != null) return extractText(data['output']);
                // Try common response fields
                if (data['response'] != null)
                  return extractText(data['response']);
                if (data['text'] != null) return extractText(data['text']);
                if (data['content'] != null)
                  return extractText(data['content']);
                if (data['message'] != null)
                  return extractText(data['message']);
                // Try candidates
                if (data['candidates'] != null && data['candidates'] is List) {
                  return extractText(data['candidates']);
                }
                if (data['parts'] != null && data['parts'] is List) {
                  for (var part in data['parts']) {
                    final text = extractText(part);
                    if (text != null && text.isNotEmpty) return text;
                  }
                }
              }
              if (data is List && data.isNotEmpty) {
                for (var item in data) {
                  final text = extractText(item);
                  if (text != null && text.isNotEmpty) return text;
                }
              }
              return null;
            }

            final extracted = extractText(responseData);
            if (extracted != null &&
                extracted.isNotEmpty &&
                !extracted.toLowerCase().contains('candidates') &&
                !extracted.toLowerCase().contains('usageMetadata') &&
                !extracted.startsWith('{')) {
              responseText = extracted.trim();
            } else {
              // If still no valid text, log the full response for debugging
              debugPrint(
                  'Failed to extract text from response. Full response: ${response.body}');
              responseText =
                  'Sorry, I could not generate a response. Please try again.';
            }
          } catch (e) {
            debugPrint('Error parsing response: $e');
            debugPrint('Response body: ${response.body}');
            responseText =
                'Sorry, I could not generate a response. Please try again.';
          }
        }

        // Debug: Print final extracted response
        debugPrint('Final Response Text: $responseText');

        setState(() {
          _messages.add(ChatMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
          _geminiFollowUpSuggestions = null;
          _geminiFollowUpsMessageHash = null;
        });

        // Ensure keyboard stays dismissed immediately after setState
        FocusScope.of(context).unfocus();
        _messageFocusNode.unfocus();

        // Deduct credits only after successful response (not for error messages)
        final isErrorResponse = responseText ==
                'Sorry, I could not generate a response.' ||
            responseText ==
                'Sorry, I could not generate a response. Please try again.' ||
            responseText.toLowerCase().contains('sorry, i could not generate');

        if (!isErrorResponse) {
          await _deductChatCredits();
          await updateBibleChatWidget(question: message, answer: responseText);
          await MilestoneLifetimePaywallCoordinator.onChatAiResponseSuccess(
              context);
          unawaited(_fetchGeminiFollowUpSuggestions(
            responseText,
            avoidNormalizedQuestions: _usedFollowUpSuggestionKeys,
          ));
        }

        // Scroll to top when answer comes to show at top of answer
        _scrollToTop();
        await _saveChatHistory();

        // Ensure keyboard stays dismissed after response - additional safeguard
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            FocusScope.of(context).unfocus();
            _messageFocusNode.unfocus();
          }
        });
      } else {
        String errorMessage =
            'Failed to get response from API (Status: ${response.statusCode})';

        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error']?['message'] ??
                errorData['message'] ??
                errorData['error']?.toString() ??
                errorMessage;
          }
        } catch (e) {
          // If error response is not JSON, use the body as error message
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }

        final displayError = userFacingNetworkMessage(
          errorMessage,
          fallback: 'Something went wrong. Please try again.',
        );

        setState(() {
          _messages.add(ChatMessage(
            text: displayError,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
          _geminiFollowUpSuggestions = null;
          _geminiFollowUpsMessageHash = null;
        });

        // Ensure keyboard stays dismissed immediately after setState
        FocusScope.of(context).unfocus();
        _messageFocusNode.unfocus();

        // Scroll to top when answer comes to show at top of answer
        _scrollToTop();
        await _saveChatHistory();

        // Keep keyboard dismissed after error response - additional safeguard
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            FocusScope.of(context).unfocus();
            _messageFocusNode.unfocus();
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _sendMessage: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _messages.add(ChatMessage(
          text: userFacingNetworkMessage(e),
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
        _geminiFollowUpSuggestions = null;
        _geminiFollowUpsMessageHash = null;
      });

      // Ensure keyboard stays dismissed immediately after setState
      FocusScope.of(context).unfocus();
      _messageFocusNode.unfocus();

      // Scroll to top when answer comes to show at top of answer
      _scrollToTop();
      await _saveChatHistory();

      // Keep keyboard dismissed after error - additional safeguard
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          FocusScope.of(context).unfocus();
          _messageFocusNode.unfocus();
        }
      });
    }
  }

  void _scrollToTop() {
    // Use double post-frame callback to ensure ListView has fully rendered the new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients &&
            _scrollController.position.maxScrollExtent > 0) {
          // Scroll to bottom to show the latest response
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  // @override
  // void dispose() {
  //   _messageController.dispose();
  //   _scrollController.dispose();
  //   _messageFocusNode.dispose();
  //   // Safely stop speech if it's listening
  //   if (_isListening && _speechInitialized && _speech != null) {
  //     try {
  //       _speech!.stop();
  //     } catch (e) {
  //       // Ignore errors during dispose
  //     }
  //   }
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) await _handleBack();
      },
      child: Scaffold(
        backgroundColor: isVintage
            ? (isDark ? CommanColor.black : themeProvider.backgroundColor)
            : (isDark
                ? CommanColor.darkPrimaryColor
                : themeProvider.backgroundColor),
        // appBar: AppBar(
        //   backgroundColor: isVintage
        //       ? (isDark ? CommanColor.black : themeProvider.backgroundColor)
        //       : (isDark ? CommanColor.darkPrimaryColor : themeProvider.backgroundColor),
        //   flexibleSpace: isVintage
        //       ? Container(
        //     decoration: BoxDecoration(
        //       color: isDark ? CommanColor.black : themeProvider.backgroundColor,
        //       image: DecorationImage(
        //         image: AssetImage(Images.bgImage(context)),
        //         fit: BoxFit.cover,
        //       ),
        //     ),
        //   )
        //       : null,
        //   elevation: 0,
        //   leading: IconButton(
        //     icon: Icon(
        //       Icons.arrow_back_ios_new,
        //       color: CommanColor.whiteBlack(context),
        //     ),
        //     onPressed: () => Get.back(),
        //   ),
        //   // title: Text(
        //   //   'Bible Chat',
        //   //   style: TextStyle(
        //   //     color: CommanColor.whiteBlack(context),
        //   //     fontSize: screenWidth > 450 ? 22 : 18,
        //   //     fontWeight: FontWeight.w600,
        //   //   ),
        //   // ),
        //   actions: [
        //     // Show new chat icon only when user has typed something
        //     if (_messageController.text.trim().isNotEmpty)
        //       IconButton(
        //         icon: Icon(
        //           Icons.add_circle_outline,
        //           color: CommanColor.whiteBlack(context),
        //         ),
        //         tooltip: 'New Chat',
        //         onPressed: () {
        //           if (_messages.isNotEmpty) {
        //             showDialog(
        //               context: context,
        //               builder: (context) {
        //                 final themeProvider = Provider.of<ThemeProvider>(context);
        //                 final isDark = themeProvider.themeMode == ThemeMode.dark;
        //                 final isVintage = themeProvider.currentCustomTheme == AppCustomTheme.vintage;
        //                 return AlertDialog(
        //                   backgroundColor: isDark
        //                       ? CommanColor.darkPrimaryColor
        //                       : (isVintage ? themeProvider.backgroundColor : CommanColor.white),
        //                   shape: RoundedRectangleBorder(
        //                     borderRadius: BorderRadius.circular(15),
        //                   ),
        //                   title: Text(
        //                     'Start New Chat',
        //                     style: TextStyle(
        //                       color: CommanColor.whiteBlack(context),
        //                     ),
        //                   ),
        //                   content: Text(
        //                     'Are you sure you want to start a new chat? The current conversation will be cleared.',
        //                     style: TextStyle(
        //                       color: CommanColor.whiteBlack(context),
        //                     ),
        //                   ),
        //                   actions: [
        //                     TextButton(
        //                       onPressed: () => Get.back(),
        //                       child: Text(
        //                         ChatTranslations.get('cancel', AppApiConstant.chatLanguage),
        //                         style: TextStyle(
        //                           color: isDark
        //                               ? CommanColor.white.withOpacity(0.8)
        //                               : CommanColor.lightDarkPrimary(context),
        //                         ),
        //                       ),
        //                     ),
        //                     TextButton(
        //                       onPressed: () {
        //                         Get.back();
        //                         _startNewChat();
        //                       },
        //                       child: Text(
        //                         ChatTranslations.get('new_chat', AppApiConstant.chatLanguage),
        //                         style: TextStyle(
        //                           color: isDark
        //                               ? CommanColor.lightDarkPrimary(context)
        //                               : CommanColor.lightDarkPrimary(context),
        //                           fontWeight: FontWeight.w600,
        //                         ),
        //                       ),
        //                     ),
        //                   ],
        //                 );
        //               },
        //             );
        //           } else {
        //             _startNewChat();
        //           }
        //         },
        //       ),
        //     IconButton(
        //       icon: Image.asset(
        //         "assets/message-time.png",
        //         width: 24,
        //         height: 24,
        //       ),
        //       tooltip: 'Chat History',
        //       onPressed: () {
        //         Get.to(
        //               () => const ChatHistoryScreen(),
        //           transition: Transition.cupertinoDialog,
        //           duration: const Duration(milliseconds: 300),
        //         );
        //       },
        //     ),
        //   ],
        // ),
        body: Container(
          decoration: isVintage
              ? BoxDecoration(
                  color: isDark
                      ? CommanColor.black
                      : themeProvider.backgroundColor,
                  image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.cover,
                  ),
                )
              : BoxDecoration(
                  color: isDark
                      ? CommanColor.darkPrimaryColor
                      : themeProvider.backgroundColor,
                ),
          child: SafeArea(
            bottom: false,
            child: GestureDetector(
              onTap: () {
                // Dismiss keyboard when tapping anywhere on the screen
                FocusScope.of(context).unfocus();
                _messageFocusNode.unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  // Top bar with back button and actions
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth > 450 ? 8 : 4,
                      vertical: screenWidth > 450 ? 8 : 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: CommanColor.whiteBlack(context),
                          ),
                          onPressed: () => _handleBack(),
                        ),
                        // Show "Faith Chat" in center when messages exist
                        if (_messages.isNotEmpty)
                          Expanded(
                            child: Center(
                              child: Text(
                                ChatTranslations.get('faith_chat', 'EN'),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF8D6E63),
                                  fontSize: screenWidth > 450 ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          Spacer(),
                        // Right pill (Wallet/Credits + New Chat) + History icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth > 450 ? 12 : 10,
                                vertical: screenWidth > 450 ? 10 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF4A342B)
                                    : const Color(0xFFF6F1E9).withOpacity(0.65),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : const Color(0xFF8D6E63)
                                          .withOpacity(0.18),
                                  width: isDark ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      Get.to(
                                        () => const WalletScreen(),
                                        transition: Transition.cupertinoDialog,
                                        duration:
                                            const Duration(milliseconds: 300),
                                      )?.then((_) {
                                        // Refresh credits when returning from wallet screen
                                        _loadCreditsFromLocal();
                                      });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: isDark
                                              ? BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                )
                                              : null,
                                          child: Icon(
                                            Icons.account_balance_wallet,
                                            size: screenWidth > 450 ? 22 : 20,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF8D6E63),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$_currentCredits',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF8D6E63),
                                            fontSize:
                                                screenWidth > 450 ? 14 : 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: screenWidth > 450 ? 12 : 10),
                                  Container(
                                    width: 1,
                                    height: screenWidth > 450 ? 18 : 16,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.22)
                                        : const Color(0xFF8D6E63)
                                            .withOpacity(0.22),
                                  ),
                                  SizedBox(width: screenWidth > 450 ? 12 : 10),
                                  // Keep the existing new-chat logic unchanged
                                  if (_messages.any((msg) => !msg.isUser))
                                    InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        // Post-frame + extra delay on tablets so the
                                        // tap-up is not handled as a barrier dismiss
                                        // (iPad). Same sheet actions as before.
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          final tablet = MediaQuery.of(context)
                                                  .size
                                                  .shortestSide >=
                                              600;
                                          Future.delayed(
                                              Duration(
                                                  milliseconds:
                                                      tablet ? 280 : 100), () {
                                            if (!mounted) return;
                                            showModalBottomSheet(
                                              context: context,
                                              backgroundColor:
                                                  Colors.transparent,
                                              isDismissible:
                                                  true, // Allow dismissing when tapping outside
                                              enableDrag: true,
                                              builder: (_) {
                                                final bg = isDark
                                                    ? CommanColor
                                                        .darkPrimaryColor
                                                        .withOpacity(0.96)
                                                    : const Color(0xFFF6F1E9);
                                                return SafeArea(
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(
                                                            12),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: bg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          dense: true,
                                                          leading: Icon(
                                                            Icons.add,
                                                            color: isDark
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF8D6E63),
                                                          ),
                                                          title: Text(
                                                            ChatTranslations
                                                                .get('new_chat',
                                                                    'EN'),
                                                            style: TextStyle(
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF8D6E63),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                            if (_messages
                                                                .isNotEmpty) {
                                                              _showNewChatBottomSheet();
                                                            } else {
                                                              _startNewChat();
                                                            }
                                                          },
                                                        ),
                                                        const Divider(
                                                            height: 1),
                                                        ListTile(
                                                          dense: true,
                                                          leading: Image.asset(
                                                            "assets/message-time.png",
                                                            width: 22,
                                                            height: 22,
                                                            color: isDark
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF8D6E63),
                                                          ),
                                                          title: Text(
                                                            ChatTranslations
                                                                .get('history',
                                                                    'EN'),
                                                            style: TextStyle(
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF8D6E63),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                            Get.to(
                                                              () =>
                                                                  const ChatHistoryScreen(),
                                                              transition: Transition
                                                                  .cupertinoDialog,
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                            )?.then((_) {
                                                              _loadRecentConversations();
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          });
                                        });
                                      },
                                      child: Icon(
                                        Icons.add,
                                        size: screenWidth > 450 ? 22 : 20,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF8D6E63),
                                      ),
                                    )
                                  else
                                    InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        // Same timing guard as the branch above (iPad).
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          final tablet = MediaQuery.of(context)
                                                  .size
                                                  .shortestSide >=
                                              600;
                                          Future.delayed(
                                              Duration(
                                                  milliseconds:
                                                      tablet ? 280 : 100), () {
                                            if (!mounted) return;
                                            showModalBottomSheet(
                                              context: context,
                                              backgroundColor:
                                                  Colors.transparent,
                                              isDismissible:
                                                  true, // Allow dismissing when tapping outside
                                              enableDrag: true,
                                              builder: (_) {
                                                final bg = isDark
                                                    ? CommanColor
                                                        .darkPrimaryColor
                                                        .withOpacity(0.96)
                                                    : const Color(0xFFF6F1E9);
                                                return SafeArea(
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(
                                                            12),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: bg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          dense: true,
                                                          leading: Icon(
                                                            Icons.add,
                                                            color: isDark
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF8D6E63),
                                                          ),
                                                          title: Text(
                                                            ChatTranslations
                                                                .get('new_chat',
                                                                    'EN'),
                                                            style: TextStyle(
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF8D6E63),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                            _startNewChat();
                                                          },
                                                        ),
                                                        const Divider(
                                                            height: 1),
                                                        ListTile(
                                                          dense: true,
                                                          leading: Image.asset(
                                                            "assets/message-time.png",
                                                            width: 22,
                                                            height: 22,
                                                            color: isDark
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF8D6E63),
                                                          ),
                                                          title: Text(
                                                            ChatTranslations
                                                                .get('history',
                                                                    'EN'),
                                                            style: TextStyle(
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF8D6E63),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                            Get.to(
                                                              () =>
                                                                  const ChatHistoryScreen(),
                                                              transition: Transition
                                                                  .cupertinoDialog,
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                            )?.then((_) {
                                                              _loadRecentConversations();
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          });
                                        });
                                      },
                                      child: Icon(
                                        Icons.add,
                                        size: screenWidth > 450 ? 22 : 20,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF8D6E63),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // IconButton(
                            //   icon: Image.asset(
                            //     "assets/message-time.png",
                            //     width: 24,
                            //     height: 24,
                            //     color: isDark
                            //         ? Colors.white
                            //         : const Color(0xFF8D6E63),
                            //   ),
                            //   tooltip: 'Chat History',
                            //   onPressed: () {
                            //     Get.to(
                            //       () => const ChatHistoryScreen(),
                            //       transition: Transition.cupertinoDialog,
                            //       duration: const Duration(milliseconds: 300),
                            //     );
                            //   },
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Main content area - Result Section with distinct background
                  Expanded(
                    child: Container(
                      color: Colors
                          .transparent, // Remove grey background - use transparent
                      child: _messages.isEmpty
                          ? SingleChildScrollView(
                              padding: EdgeInsets.only(
                                top: screenWidth > 450 ? 14 : 12,
                                bottom: screenWidth > 450 ? 14 : 12,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Show verse context if available
                                  if (widget.verseContext != null)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth > 450 ? 20 : 16,
                                      ),
                                      child: _buildVerseContext(
                                          screenWidth, isDark),
                                    ),
                                  if (widget.verseContext != null)
                                    const SizedBox(height: 20),
                                  // Hide illustration image when opened from verse popup
                                  if (widget.verseContext == null)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth > 450 ? 20 : 16,
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                              height:
                                                  screenWidth > 450 ? 10 : 5),
                                          Transform.translate(
                                            offset: const Offset(0, -10),
                                            child: Container(
                                              width:
                                                  screenWidth > 450 ? 140 : 130,
                                              height:
                                                  screenWidth > 450 ? 140 : 130,
                                              decoration: const BoxDecoration(
                                                color: Colors
                                                    .transparent, // Transparent background for illustration
                                              ),
                                              child: Image.asset(
                                                "assets/chat_img.png",
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  // Fallback to icon if image doesn't load
                                                  return Icon(
                                                    Icons.chat_bubble_outline,
                                                    size: 100,
                                                    color:
                                                        CommanColor.whiteBlack(
                                                                context)
                                                            .withOpacity(0.5),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            ChatTranslations.get(
                                                'faith_answers', 'EN'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: CommanColor.whiteBlack(
                                                      context)
                                                  .withOpacity(0.7),
                                              fontSize:
                                                  screenWidth > 450 ? 26 : 23,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom:
                                                    20), // Add bottom padding to prevent text from being hidden
                                            child: Text(
                                              ChatTranslations.get(
                                                  'get_guidance', 'EN'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: CommanColor.whiteBlack(
                                                        context)
                                                    .withOpacity(0.5),
                                                fontSize:
                                                    screenWidth > 450 ? 16 : 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Show verse context text if available
                                  if (widget.verseContext != null)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth > 450 ? 20 : 16,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            bottom:
                                                20), // Add bottom padding to prevent text from being hidden
                                        child: Text(
                                          ChatTranslations.get(
                                              'ask_questions_verse',
                                              AppApiConstant.chatLanguage),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                CommanColor.whiteBlack(context)
                                                    .withOpacity(0.5),
                                            fontSize:
                                                screenWidth > 450 ? 16 : 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Show default questions inside scrollable area
                                  widget.verseContext != null
                                      ? _buildVerseSuggestedQuestions(
                                          screenWidth, isDark)
                                      : _buildDefaultQuestions(
                                          screenWidth, isDark),
                                  // Show recent conversations inside scrollable area only in Chat Home Screen (no verse context and no history date key)
                                  if (_recentConversations.isNotEmpty &&
                                      widget.verseContext == null &&
                                      widget.historyDateKey == null) ...[
                                    const SizedBox(height: 8),
                                    _buildRecentConversations(
                                        screenWidth, isDark),
                                  ],
                                  // Add extra bottom padding for better scrolling
                                  const SizedBox(height: 20),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  EdgeInsets.all(screenWidth > 450 ? 20 : 16),
                              itemCount: _messages.length +
                                  (_isLoading ? 1 : 0) +
                                  1, // +1 for suggestions footer so it scrolls with content
                              itemBuilder: (context, index) {
                                if (index < _messages.length) {
                                  return _buildMessageBubble(
                                      _messages[index], screenWidth);
                                }
                                if (_isLoading && index == _messages.length) {
                                  return _buildLoadingIndicator();
                                }
                                // Footer: suggestions (when messages exist) so they scroll with content
                                if (index ==
                                    _messages.length + (_isLoading ? 1 : 0)) {
                                  return _messages.isNotEmpty
                                      ? _buildFollowUpSuggestions(
                                          screenWidth, isDark)
                                      : const SizedBox(height: 8);
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                    ),
                  ),
                  _buildInputArea(screenWidth, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultQuestions(double screenWidth, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: EdgeInsets.only(
        left: screenWidth > 450 ? 20 : 16,
        right: screenWidth > 450 ? 20 : 16,
        top: screenWidth > 450 ? 12 : 8,
        bottom: screenWidth > 450 ? 8 : 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic buttons in 2 rows, 3 columns
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: screenWidth > 450 ? 12 : 8,
              mainAxisSpacing: screenWidth > 450 ? 12 : 8,
              childAspectRatio: screenWidth > 450 ? 2.2 : 2.0,
            ),
            itemCount: _topicQuestions.length,
            itemBuilder: (context, index) {
              final topicItem = _topicQuestions[index];
              final isSelected = _selectedTopicIndex == index;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTopicIndex = index;
                    _messageController.text = topicItem['question']!;
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 450 ? 12 : 8,
                    vertical: screenWidth > 450 ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CommanColor.lightDarkPrimary(context)
                        : (isDark
                            ? CommanColor.darkPrimaryColor.withOpacity(0.6)
                            : (themeProvider.currentCustomTheme ==
                                    AppCustomTheme.vintage
                                ? themeProvider.backgroundColor
                                : CommanColor.backgrondcolor)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (isDark
                              ? const Color(
                                  0xFFFFD700) // Light yellow in dark mode when tapped
                              : CommanColor.lightDarkPrimary(context))
                          : (isDark
                              ? Colors
                                  .white // White border initially in dark mode
                              : CommanColor.lightDarkPrimary(context)
                                  .withOpacity(0.3)),
                      width: isSelected ? 2 : (isDark ? 2.5 : 1),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: CommanColor.lightDarkPrimary(context)
                                  .withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      topicItem['topic']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? CommanColor.white
                            : CommanColor.whiteBlack(context),
                        fontSize: screenWidth > 450 ? 14 : 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: screenWidth > 450 ? 12 : 4),
          // Question buttons as horizontal slider with send arrow icon
          SizedBox(
            height: screenWidth > 450 ? 64 : 58,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChatTranslations.get('what_god_say_fear', _uiLang),
                  ChatTranslations.get('example_forgive', _uiLang),
                  ChatTranslations.get('example_purpose', _uiLang),
                ].asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  final isTapped = _selectedExampleQuestionIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(
                        right: screenWidth > 450 ? 10 : 8,
                        bottom: screenWidth > 450 ? 4 : 2),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTopicIndex = null; // Reset topic selection
                          _selectedExampleQuestionIndex =
                              index; // Track tapped question
                        });
                        // Directly send the message without showing in text field
                        _messageController.text = question;
                        _sendMessage();
                        // Reset selection after a short delay
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            setState(() {
                              _selectedExampleQuestionIndex = null;
                            });
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 450 ? 18 : 14,
                          vertical: screenWidth > 450 ? 14 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: CommanColor.lightDarkPrimary(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTapped && isDark
                                ? const Color(
                                    0xFFFFD700) // Light yellow border when tapped in dark mode
                                : (isDark
                                    ? Colors
                                        .white // White border initially in dark mode
                                    : CommanColor.lightDarkPrimary(context)
                                        .withOpacity(0.3)),
                            width: isTapped && isDark ? 3 : (isDark ? 3 : 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CommanColor.lightDarkPrimary(context)
                                  .withOpacity(0.25),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.north_east,
                              size: screenWidth > 450 ? 18 : 16,
                              color: CommanColor.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              question,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: CommanColor.white,
                                fontSize: screenWidth > 450 ? 16 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentConversations(double screenWidth, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Container(
      padding: EdgeInsets.only(
        left: screenWidth > 450 ? 20 : 16,
        right: screenWidth > 450 ? 20 : 16,
        top: screenWidth > 450 ? 12 : 8,
        bottom: screenWidth > 450 ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ChatTranslations.get('recent_conversations', 'EN'),
                style: TextStyle(
                  color: CommanColor.whiteBlack(context).withOpacity(0.8),
                  fontSize: screenWidth > 450 ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () {
                  Get.to(
                    () => const ChatHistoryScreen(),
                    transition: Transition.cupertinoDialog,
                    duration: const Duration(milliseconds: 300),
                  )?.then((_) {
                    _loadRecentConversations();
                  });
                },
                child: Text(
                  ChatTranslations.get('view_all', 'EN'),
                  style: TextStyle(
                    color: CommanColor.whiteBlack(context),
                    fontSize: screenWidth > 450 ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    // decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentConversations.length,
            itemBuilder: (context, index) {
              final conversation = _recentConversations[index];
              final date = conversation['date'] as DateTime;
              final preview = conversation['preview'] as String;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final dateOnly = DateTime(date.year, date.month, date.day);
              String dateText;
              if (dateOnly == today) {
                dateText = 'Today, ${DateFormat('h:mm a').format(date)}';
              } else if (dateOnly == today.subtract(const Duration(days: 1))) {
                dateText = 'Yesterday, ${DateFormat('h:mm a').format(date)}';
              } else {
                dateText =
                    '${DateFormat('MMM dd').format(date)}, ${DateFormat('h:mm a').format(date)}';
              }

              return Container(
                margin: EdgeInsets.only(bottom: screenWidth > 450 ? 10 : 8),
                padding: EdgeInsets.all(screenWidth > 450 ? 14 : 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? CommanColor.darkPrimaryColor.withOpacity(0.6)
                      : (themeProvider.currentCustomTheme ==
                              AppCustomTheme.vintage
                          ? themeProvider.backgroundColor
                          : CommanColor.backgrondcolor),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        CommanColor.lightDarkPrimary(context).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _openedRecentFromHome = true;
                      _currentConversationId = conversation['id'] as String;
                    });
                    _loadChatHistory();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preview,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : CommanColor.lightDarkPrimary(context),
                                fontSize: screenWidth > 450 ? 15 : 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateText,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withOpacity(0.6)
                                    : CommanColor.lightDarkPrimary(context)
                                        .withOpacity(0.6),
                                fontSize: screenWidth > 450 ? 12 : 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: screenWidth > 450 ? 16 : 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : CommanColor.lightDarkPrimary(context)
                                .withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Second API call: 3 follow-up questions in the same language as [assistantReply].
  /// This powers ONLY the footer suggestions row (no local fallbacks).
  Future<void> _fetchGeminiFollowUpSuggestions(
    String assistantReply, {
    Set<String>? avoidNormalizedQuestions,
  }) async {
    if (assistantReply.isEmpty || !mounted) return;
    final snippet = assistantReply.length > 8000
        ? assistantReply.substring(0, 8000)
        : assistantReply;
    final avoid = (avoidNormalizedQuestions ?? const <String>{})
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(12)
        .join('\n');
    final prompt =
        '''You write short follow-up questions for a Bible faith chat app.
Read the assistant message below. Write EXACTLY 3 different questions the user might ask next about that reply.

Rules:
- Write all 3 questions in the SAME language and script as the assistant message (for example if the message is in Tamil, write only in Tamil; if in English, only English).
- Each question on its own line. No numbering, bullets, or markdown.
- Each line under 160 characters. Plain text only.
- Do not repeat the assistant text verbatim as a question.
- Do not repeat or paraphrase any of the "Avoid" questions below.

Avoid (do not output these):
${avoid.isEmpty ? '(none)' : avoid}

Assistant message:
---
$snippet
---

Your 3 questions (exactly 3 lines):''';

    try {
      final url = Uri.parse(_baseUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );
      if (response.statusCode != 200 || !mounted) return;
      var raw = _extractTextFromChatApiBody(response.body);
      raw = raw?.replaceAll('*', '').trim() ?? '';
      if (raw.isEmpty) return;
      raw = raw.replaceAll('\\n', '\n');
      raw = raw.replaceAll('\\"', '"');
      final three = _parseThreeFollowUpQuestionLines(raw);
      if (three == null || !mounted) return;
      final hash = assistantReply.hashCode;
      setState(() {
        _geminiFollowUpSuggestions = three;
        _geminiFollowUpsMessageHash = hash;
      });
    } catch (e) {
      debugPrint('Gemini follow-up suggestions failed: $e');
    }
  }

  String? _extractTextFromChatApiBody(String body) {
    if (body.isEmpty) return null;
    try {
      final responseData = jsonDecode(body);
      String? walk(dynamic data) {
        if (data is String) return data;
        if (data is Map) {
          if (data['output'] != null) return walk(data['output']);
          if (data['response'] != null) return walk(data['response']);
          if (data['text'] != null) return walk(data['text']);
          if (data['message'] != null) return walk(data['message']);
          if (data['candidates'] != null && data['candidates'] is List) {
            final list = data['candidates'] as List;
            if (list.isNotEmpty) return walk(list.first);
          }
          if (data['content'] is Map) {
            final parts = (data['content'] as Map)['parts'];
            if (parts is List && parts.isNotEmpty) {
              final p0 = parts.first;
              if (p0 is Map && p0['text'] != null) {
                return p0['text'].toString();
              }
            }
          }
        }
        if (data is List && data.isNotEmpty) {
          return walk(data.first);
        }
        return null;
      }

      return walk(responseData);
    } catch (_) {
      if (body.contains('"text"')) {
        final m = RegExp(r'"text"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(body);
        if (m != null) {
          return m.group(1)?.replaceAll(r'\n', '\n');
        }
      }
      return null;
    }
  }

  List<String>? _parseThreeFollowUpQuestionLines(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    try {
      if (t.startsWith('[')) {
        final decoded = jsonDecode(t);
        if (decoded is List) {
          final list = decoded
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty && s.length < 500)
              .take(3)
              .toList();
          if (list.length == 3) return list;
        }
      }
    } catch (_) {}
    final lines = t.split(RegExp(r'\r?\n'));
    final out = <String>[];
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      line = line.replaceFirst(RegExp(r'^\d+[\.\)\:\-]\s*'), '');
      line = line.replaceFirst(RegExp(r'^[-•*]\s*'), '');
      line = line.trim();
      if (line.length < 3) continue;
      out.add(line);
      if (out.length == 3) break;
    }
    return out.length == 3 ? out : null;
  }

  Widget _buildFollowUpSuggestions(double screenWidth, bool isDark) {
    // Follow-ups must match the latest assistant reply. If the last message is
    // the user's question (e.g. while loading), using lastWhere(!isUser) would
    // pick the *previous* AI message and show unrelated suggestions.
    if (_messages.isEmpty || _messages.last.isUser) {
      return const SizedBox.shrink();
    }
    final lastAi = _messages.last;
    if (lastAi.text.isEmpty) return const SizedBox.shrink();

    final hash = lastAi.text.hashCode;
    if (!(_geminiFollowUpsMessageHash == hash &&
        _geminiFollowUpSuggestions != null &&
        _geminiFollowUpSuggestions!.length >= 3)) {
      // Only show Gemini-backed suggestions. If not ready yet, show nothing.
      return const SizedBox.shrink();
    }

    final suggestions = _geminiFollowUpSuggestions!
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where(
            (s) => !_matchesAnyUsedSuggestion(s, _usedFollowUpSuggestionKeys))
        .take(3)
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(
        left: screenWidth > 450 ? 20 : 16,
        right: screenWidth > 450 ? 20 : 16,
        top: 115,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Suggestions :',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.75)
                  : const Color(0xFF8D6E63).withOpacity(0.65),
              fontSize: screenWidth > 450 ? 16 : 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: screenWidth > 450 ? 160 : 138,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: suggestions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  final isTapped = _selectedExampleQuestionIndex == index;
                  return Padding(
                    padding:
                        EdgeInsets.only(right: screenWidth > 450 ? 12 : 10),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _usedFollowUpSuggestionKeys
                              .add(_normalizeSuggestionKey(question));
                          _selectedTopicIndex = null;
                          _selectedExampleQuestionIndex = index;
                        });
                        _messageController.text = question;
                        _sendMessage();
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            setState(() {
                              _selectedExampleQuestionIndex = null;
                            });
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: screenWidth > 450 ? 280 : 240,
                        constraints: BoxConstraints(
                          minHeight: screenWidth > 450 ? 100 : 90,
                        ),
                        padding: EdgeInsets.only(
                          left: screenWidth > 450 ? 16 : 14,
                          right: screenWidth > 450 ? 50 : 44,
                          top: screenWidth > 450 ? 16 : 14,
                          bottom: screenWidth > 450 ? 16 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                              0xFF8D6E63), // Brown color matching user message
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTapped
                                ? const Color(0xFF8D6E63)
                                : Colors.transparent,
                            width: isTapped ? 2 : 0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Icon(
                                Icons.north_east,
                                size: screenWidth > 450 ? 20 : 18,
                                color: const Color(0xFFF6F1E9)
                                    .withOpacity(0.7), // Light beige icon
                              ),
                            ),
                            Text(
                              question,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color:
                                    const Color(0xFFF6F1E9), // Light beige text
                                fontSize: screenWidth > 450 ? 15 : 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _normalizeSuggestionKey(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

  static List<String> _rotateStrings(List<String> items, int offset) {
    if (items.isEmpty) return items;
    final n = items.length;
    final o = offset % n;
    return [...items.sublist(o), ...items.sublist(0, o)];
  }

  /// True if this chip matches something the user already sent (exact or fuzzy).
  bool _matchesAnyUsedSuggestion(String candidate, Set<String> used) {
    if (used.isEmpty) return false;
    final t = _normalizeSuggestionKey(candidate);
    for (final u in used) {
      if (t == u) return true;
      if (_chatSuggestionTooSimilar(t, u)) return true;
    }
    return false;
  }

  List<String> _getFollowUpList(
    String answer, {
    String? precedingQuestion,
    Set<String>? usedSuggestionKeys,
    int suggestionRotation = 0,
  }) {
    final used = usedSuggestionKeys ?? <String>{};
    final bool hasVerseContext = widget.verseContext != null;

    final pq = precedingQuestion?.trim();
    final conceptSource = <String>[
      if (pq != null && pq.isNotEmpty) pq,
      answer.trim(),
    ].join(' ');

    // Extract sentences from the response
    final sentences = answer
        .split(RegExp(r'[.!?]\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (sentences.isEmpty) {
      return _finalizeChatSuggestions(
        hasVerseContext
            ? [
                ChatTranslations.get(
                    'tell_more_verse', AppApiConstant.chatLanguage),
                ChatTranslations.get(
                    'how_apply_verse_life', AppApiConstant.chatLanguage),
                ChatTranslations.get(
                    'what_else_verse_teach', AppApiConstant.chatLanguage),
              ]
            : [
                ChatTranslations.get(
                    'explain_more', AppApiConstant.chatLanguage),
                ChatTranslations.get(
                    'how_apply_this', AppApiConstant.chatLanguage),
                ChatTranslations.get(
                    'what_else_know', AppApiConstant.chatLanguage),
              ],
        precedingQuestion,
        hasVerseContext,
        used,
        suggestionRotation,
      );
    }

    // Analyze question + reply so concepts/keywords align with this turn (e.g.
    // English question + Tamil answer still yields relevant follow-ups).
    final allText = conceptSource.toLowerCase();
    final firstSentence = sentences[0].toLowerCase();

    // Extract key phrases and nouns from the response
    var keyPhrases = List<String>.from(_extractKeyPhrases(answer, sentences));
    // Do not mine the user's message for phrases when it is only a generic
    // follow-up like "explain more" (TN matches the explain_more string)—that
    // produced chips repeating the same question as the AI reply.
    final explainMoreTemplate =
        ChatTranslations.get('explain_more', AppApiConstant.chatLanguage);
    if (pq != null &&
        pq.isNotEmpty &&
        !_chatSuggestionTooSimilar(pq, explainMoreTemplate)) {
      final qSentences = pq
          .split(RegExp(r'[.!?]\s+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      final qParts = qSentences.isEmpty ? <String>[pq] : qSentences;
      for (final p in _extractKeyPhrases(pq, qParts)) {
        if (keyPhrases.length >= 5) break;
        if (!keyPhrases.any((k) => k.toLowerCase() == p.toLowerCase())) {
          keyPhrases.add(p);
        }
      }
    }
    final importantConcepts = _extractImportantConcepts(allText);

    // Generate truly dynamic questions based on actual content
    final List<String> dynamicQuestions = [];

    // Priority 1: Alternate "relate to" vs "God says about" — avoid explain_more_about,
    // which shares Tamil "மேலும் விளக்க" with other chips and reads as repeated.
    if (keyPhrases.isNotEmpty) {
      for (var i = 0;
          i < keyPhrases.length && dynamicQuestions.length < 3;
          i++) {
        final phrase = keyPhrases[i];
        final useRelate = i.isEven;
        if (hasVerseContext) {
          dynamicQuestions.add(useRelate
              ? '${ChatTranslations.get('how_verse_relate_to', AppApiConstant.chatLanguage)} ${phrase}?'
              : '${ChatTranslations.get('verse_teach_about', AppApiConstant.chatLanguage)} ${phrase}?');
        } else {
          dynamicQuestions.add(useRelate
              ? '${ChatTranslations.get('how_relate_to', AppApiConstant.chatLanguage)} ${phrase}?'
              : '${ChatTranslations.get('god_say_about', AppApiConstant.chatLanguage)} ${phrase}?');
        }
      }
    }

    // Priority 2: Generate questions from detected concepts
    if (dynamicQuestions.length < 3 && importantConcepts.isNotEmpty) {
      for (var concept in importantConcepts.take(2)) {
        if (hasVerseContext) {
          if (!dynamicQuestions.any((q) => q.toLowerCase().contains(concept))) {
            dynamicQuestions.add(
                '${ChatTranslations.get('verse_teach_about', AppApiConstant.chatLanguage)} ${concept}?');
          }
        } else {
          if (!dynamicQuestions.any((q) => q.toLowerCase().contains(concept))) {
            dynamicQuestions.add(
                '${ChatTranslations.get('god_say_about', AppApiConstant.chatLanguage)} ${concept}?');
          }
        }
        if (dynamicQuestions.length >= 3) break;
      }
    }

    // Priority 3: Generate questions based on response structure and patterns
    if (dynamicQuestions.length < 3) {
      // Check for specific action words or verbs
      if (allText.contains('means') ||
          allText.contains('meaning') ||
          allText.contains('signifies') ||
          allText.contains('represents')) {
        dynamicQuestions.add(hasVerseContext
            ? 'What is the deeper meaning of this verse?'
            : 'What is the deeper meaning?');
      }

      if (allText.contains('teach') ||
          allText.contains('shows') ||
          allText.contains('reveals') ||
          allText.contains('demonstrates')) {
        dynamicQuestions.add(hasVerseContext
            ? 'What else does this verse teach?'
            : 'What else does this teach?');
      }

      if (allText.contains('help') ||
          allText.contains('guide') ||
          allText.contains('assist') ||
          allText.contains('support')) {
        dynamicQuestions.add(hasVerseContext
            ? 'How does this verse help me?'
            : 'How does this help me?');
      }

      if (allText.contains('promise') ||
          allText.contains('promises') ||
          allText.contains('assurance') ||
          allText.contains('guarantee')) {
        dynamicQuestions.add(hasVerseContext
            ? 'What promise does this verse contain?'
            : 'What promise does this contain?');
      }

      if (allText.contains('command') ||
          allText.contains('instruct') ||
          allText.contains('tells') ||
          allText.contains('requires')) {
        dynamicQuestions.add(hasVerseContext
            ? 'How should I obey this verse?'
            : 'How should I follow this?');
      }

      if (allText.contains('encourage') ||
          allText.contains('comfort') ||
          allText.contains('strengthen')) {
        dynamicQuestions.add(hasVerseContext
            ? 'How does this verse encourage me?'
            : 'How does this encourage me?');
      }

      if (allText.contains('warn') ||
          allText.contains('warning') ||
          allText.contains('caution')) {
        dynamicQuestions.add(hasVerseContext
            ? 'What warning does this verse give?'
            : 'What warning does this give?');
      }
    }

    // Priority 4: Generate questions based on sentence structure
    if (dynamicQuestions.length < 3) {
      // Look for "because", "so that", "in order to" patterns
      if (firstSentence.contains('because') ||
          firstSentence.contains('so that') ||
          firstSentence.contains('in order to')) {
        dynamicQuestions.add(hasVerseContext
            ? ChatTranslations.get(
                'why_verse_important', AppApiConstant.chatLanguage)
            : ChatTranslations.get(
                'why_important', AppApiConstant.chatLanguage));
      }

      // Look for "how to", "way to" patterns
      if (firstSentence.contains('how to') ||
          firstSentence.contains('way to') ||
          firstSentence.contains('steps')) {
        dynamicQuestions.add(hasVerseContext
            ? ChatTranslations.get(
                'what_steps_take', AppApiConstant.chatLanguage)
            : ChatTranslations.get(
                'what_practical_steps', AppApiConstant.chatLanguage));
      }

      // Look for questions in the response (skip explain_further — same "explain more"
      // family as other chips in many languages; other priorities already add variety.)
      if (firstSentence.contains('?') || answer.contains('?')) {
        dynamicQuestions.add(hasVerseContext
            ? ChatTranslations.get(
                'why_verse_important', AppApiConstant.chatLanguage)
            : ChatTranslations.get(
                'why_important', AppApiConstant.chatLanguage));
      }
    }

    // Return dynamic questions if we have enough, otherwise fill with contextual fallbacks
    if (dynamicQuestions.length >= 3) {
      return _finalizeChatSuggestions(
        dynamicQuestions,
        precedingQuestion,
        hasVerseContext,
        used,
        suggestionRotation,
      );
    }

    // Fill remaining slots with contextual questions
    while (dynamicQuestions.length < 3) {
      if (hasVerseContext) {
        if (!dynamicQuestions.any((q) =>
            q.contains('apply') ||
            q.contains(ChatTranslations.get(
                    'how_apply_verse_life', AppApiConstant.chatLanguage)
                .substring(0, 5)))) {
          dynamicQuestions.add(ChatTranslations.get(
              'how_apply_verse_life', AppApiConstant.chatLanguage));
        } else if (!dynamicQuestions.any((q) =>
            q.contains('more') ||
            q.contains(ChatTranslations.get(
                    'tell_more_verse', AppApiConstant.chatLanguage)
                .substring(0, 5)))) {
          dynamicQuestions.add(ChatTranslations.get(
              'tell_more_verse', AppApiConstant.chatLanguage));
        } else {
          dynamicQuestions.add(ChatTranslations.get(
              'what_else_verse_teach', AppApiConstant.chatLanguage));
        }
      } else {
        if (!dynamicQuestions.any((q) =>
            q.contains('apply') ||
            q.contains(ChatTranslations.get(
                    'how_apply_this', AppApiConstant.chatLanguage)
                .substring(0, 5)))) {
          dynamicQuestions.add(ChatTranslations.get(
              'how_apply_this', AppApiConstant.chatLanguage));
        } else if (!dynamicQuestions.any((q) =>
            q.contains('more') ||
            q.contains(ChatTranslations.get(
                    'explain_more', AppApiConstant.chatLanguage)
                .substring(0, 5)))) {
          dynamicQuestions.add(ChatTranslations.get(
              'explain_more', AppApiConstant.chatLanguage));
        } else {
          dynamicQuestions.add(ChatTranslations.get(
              'what_else_know', AppApiConstant.chatLanguage));
        }
      }
    }

    return _finalizeChatSuggestions(
      dynamicQuestions,
      precedingQuestion,
      hasVerseContext,
      used,
      suggestionRotation,
    );
  }

  /// Long ordered list of static templates for refilling when the user has
  /// already used some chips (prefer unused keys first).
  List<String> _staticFollowUpCandidatesOrdered(
      bool hasVerseContext, String lang) {
    if (hasVerseContext) {
      return [
        ChatTranslations.get('what_else_verse_teach', lang),
        ChatTranslations.get('tell_more_verse', lang),
        ChatTranslations.get('why_verse_important', lang),
        ChatTranslations.get('verse_daily_life', lang),
        ChatTranslations.get('how_apply_verse_life', lang),
        ChatTranslations.get('explain_verse_further', lang),
        ChatTranslations.get('ask_questions_verse', lang),
        ChatTranslations.get('what_steps_take', lang),
      ];
    }
    return [
      ChatTranslations.get('what_else_know', lang),
      ChatTranslations.get('why_important', lang),
      ChatTranslations.get('what_practical_steps', lang),
      ChatTranslations.get('how_apply_teaching', lang),
      ChatTranslations.get('how_apply_this', lang),
      ChatTranslations.get('what_steps_take', lang),
      ChatTranslations.get('explain_more', lang),
      ChatTranslations.get('explain_further', lang),
    ];
  }

  /// Shared wording across "explain more" templates (TA/EN/HI) — allow at most one such chip.
  List<String> _explainMoreSharedMarkers(String lang) {
    switch (lang) {
      case 'TN':
        return ['மேலும் விளக்க'];
      case 'HI':
        return ['और समझा', 'और बताए'];
      case 'EN':
        return ['explain more', 'explain this further', 'explain further'];
      default:
        final em = ChatTranslations.get('explain_more', lang);
        if (em.length < 10) return [em];
        return [em.substring(0, em.length < 18 ? em.length : 18)];
    }
  }

  List<String> _capExplainMoreFamilyChips(List<String> items, String lang) {
    if (items.length <= 1) return items;
    final markers = _explainMoreSharedMarkers(lang);
    final out = <String>[];
    var keptExplain = false;
    for (final s in items) {
      final t = s.trim();
      if (t.isEmpty) continue;
      final isExplain = markers.any((m) => m.isNotEmpty && t.contains(m));
      if (isExplain) {
        if (keptExplain) continue;
        keptExplain = true;
      }
      out.add(t);
    }
    return out;
  }

  /// Remove chips that restate the user's last question (e.g. Tamil "explain more"
  /// is identical to the [explain_more] translation) and refill with distinct options.
  List<String> _finalizeChatSuggestions(
    List<String> raw,
    String? precedingQuestion,
    bool hasVerseContext,
    Set<String> usedKeys,
    int suggestionRotation,
  ) {
    final lang = AppApiConstant.chatLanguage;
    final pq = precedingQuestion?.trim();

    var list = _dedupeChatSuggestions(raw, max: 20);
    list = list.where((s) => !_matchesAnyUsedSuggestion(s, usedKeys)).toList();
    if (pq != null && pq.isNotEmpty) {
      list = list.where((s) => !_suggestionEchoesUserMessage(s, pq)).toList();
    }
    list = _dedupeChatSuggestions(list, max: 10);
    list = _capExplainMoreFamilyChips(list, lang);

    bool canAdd(String candidate) {
      final t = candidate.trim();
      if (t.isEmpty) return false;
      if (_matchesAnyUsedSuggestion(t, usedKeys)) return false;
      if (pq != null && pq.isNotEmpty && _suggestionEchoesUserMessage(t, pq)) {
        return false;
      }
      return !list.any((x) => _chatSuggestionTooSimilar(x, t));
    }

    final primaryFillers = hasVerseContext
        ? <String>[
            ChatTranslations.get('what_else_verse_teach', lang),
            ChatTranslations.get('tell_more_verse', lang),
            ChatTranslations.get('why_verse_important', lang),
            ChatTranslations.get('verse_daily_life', lang),
          ]
        : <String>[
            ChatTranslations.get('what_else_know', lang),
            ChatTranslations.get('why_important', lang),
            ChatTranslations.get('what_practical_steps', lang),
            ChatTranslations.get('how_apply_teaching', lang),
          ];

    final combinedPool = <String>[];
    final poolKeys = <String>{};
    void addUniqueToPool(String s) {
      final k = _normalizeSuggestionKey(s);
      if (k.isEmpty || poolKeys.contains(k)) return;
      poolKeys.add(k);
      combinedPool.add(s.trim());
    }

    for (final f in primaryFillers) {
      addUniqueToPool(f);
    }
    for (final f in _staticFollowUpCandidatesOrdered(hasVerseContext, lang)) {
      addUniqueToPool(f);
    }

    final rotatedPool = _rotateStrings(combinedPool, suggestionRotation);

    for (final f in rotatedPool) {
      if (list.length >= 3) break;
      if (canAdd(f)) list.add(f);
    }

    return list.take(3).toList();
  }

  bool _suggestionEchoesUserMessage(String suggestion, String userQuestion) {
    final s = suggestion.trim();
    final u = userQuestion.trim();
    if (s.isEmpty || u.isEmpty) return false;
    if (s == u) return true;
    if (_chatSuggestionTooSimilar(s, u)) return true;
    if (s.length >= 12 && u.length >= 12 && (s.contains(u) || u.contains(s))) {
      return true;
    }
    // User typed a generic "explain more" prompt (often identical to the
    // explain_more string in TN). Drop any chip that is the same template or
    // the near-duplicate explain_further variant.
    final lang = AppApiConstant.chatLanguage;
    final explainMore = ChatTranslations.get('explain_more', lang);
    final explainFurther = ChatTranslations.get('explain_further', lang);
    final userAskedGenericExplain = _chatSuggestionTooSimilar(u, explainMore) ||
        _chatSuggestionTooSimilar(u, explainFurther);
    if (userAskedGenericExplain &&
        (_chatSuggestionTooSimilar(s, explainMore) ||
            _chatSuggestionTooSimilar(s, explainFurther))) {
      return true;
    }
    return false;
  }

  /// Drop near-duplicate suggestion strings (same wording or very high word overlap).
  List<String> _dedupeChatSuggestions(List<String> input, {int max = 3}) {
    final out = <String>[];
    for (final s in input) {
      final t = s.trim();
      if (t.isEmpty) continue;
      if (out.any((o) => _chatSuggestionTooSimilar(o, t))) continue;
      out.add(t);
      if (out.length >= max) break;
    }
    return out;
  }

  bool _chatSuggestionTooSimilar(String a, String b) {
    final xa = a.toLowerCase().trim();
    final xb = b.toLowerCase().trim();
    if (xa == xb) return true;
    // Tamil: several templates share "மேலும் விளக்க" — treat as the same intent.
    const taExplainCore = 'மேலும் விளக்க';
    if (xa.contains(taExplainCore) && xb.contains(taExplainCore)) {
      return true;
    }
    final wa = xa.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final wb = xb.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    if (wa.isEmpty || wb.isEmpty) return false;
    final inter = wa.intersection(wb).length;
    final union = wa.union(wb).length;
    if (union > 0 && (inter / union) > 0.65) return true;
    // Tamil / CJK: few word boundaries — long shared prefix ≈ duplicate chip.
    final ra = xa.runes.toList();
    final rb = xb.runes.toList();
    if (ra.length >= 12 && rb.length >= 12) {
      var same = 0;
      final n = ra.length < rb.length ? ra.length : rb.length;
      for (var i = 0; i < n && i < 16; i++) {
        if (ra[i] == rb[i]) same++;
      }
      if (same >= 12) return true;
    }
    return false;
  }

  // Extract key phrases/nouns from the response
  List<String> _extractKeyPhrases(String answer, List<String> sentences) {
    final List<String> phrases = [];
    final lower = answer.toLowerCase();

    // Extract important nouns and phrases (3-5 word phrases)
    // Look for patterns like "the [noun]", "this [noun]", "your [noun]"
    final nounPatterns = [
      RegExp(
          r'\b(the|this|your|my|our|his|her|their)\s+([a-z]+(?:\s+[a-z]+){0,2})\b',
          caseSensitive: false),
      RegExp(
          r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\b'), // Capitalized phrases (likely proper nouns or important concepts)
    ];

    for (var pattern in nounPatterns) {
      final matches = pattern.allMatches(answer);
      for (var match in matches) {
        final phrase = match.group(0)?.trim() ?? '';
        if (phrase.length > 3 &&
            phrase.length < 30 &&
            !phrases.contains(phrase)) {
          // Filter out common words
          if (!phrase.toLowerCase().contains('this verse') &&
              !phrase.toLowerCase().contains('the bible') &&
              !phrase.toLowerCase().contains('god') &&
              !phrase.toLowerCase().contains('jesus') &&
              !phrase.toLowerCase().contains('christ')) {
            phrases.add(phrase);
          }
        }
      }
    }

    // Also extract concepts from important words
    final importantWords = _extractImportantConcepts(lower);
    phrases.addAll(importantWords);

    return phrases.take(5).toList();
  }

  // Helper function to extract important concepts from text
  List<String> _extractImportantConcepts(String text) {
    final List<String> concepts = [];

    // Common important spiritual/biblical concepts with more keywords
    final conceptPatterns = {
      'fear': [
        'fear',
        'afraid',
        'anxious',
        'anxiety',
        'worried',
        'worry',
        'scared',
        'frightened'
      ],
      'forgiveness': [
        'forgive',
        'forgiveness',
        'hurt',
        'pain',
        'healing',
        'heal',
        'wound'
      ],
      'purpose': [
        'purpose',
        'plan',
        'calling',
        'mission',
        'destiny',
        'will',
        'intention'
      ],
      'love': ['love', 'loving', 'compassion', 'care', 'cherish', 'adore'],
      'faith': [
        'faith',
        'believe',
        'trust',
        'belief',
        'confidence',
        'reliance'
      ],
      'hope': [
        'hope',
        'promise',
        'promises',
        'future',
        'expectation',
        'anticipation'
      ],
      'peace': ['peace', 'calm', 'rest', 'quiet', 'tranquil', 'serenity'],
      'wisdom': [
        'wisdom',
        'wise',
        'understanding',
        'knowledge',
        'insight',
        'discernment'
      ],
      'strength': [
        'strength',
        'strong',
        'power',
        'mighty',
        'courage',
        'brave',
        'bold'
      ],
      'guidance': ['guide', 'guidance', 'direction', 'path', 'way', 'lead'],
      'prayer': ['pray', 'prayer', 'praying', 'prayed', 'supplication'],
      'salvation': [
        'salvation',
        'saved',
        'redeem',
        'redemption',
        'rescue',
        'deliverance'
      ],
      'obedience': [
        'obey',
        'obedience',
        'follow',
        'command',
        'submit',
        'comply'
      ],
      'grace': ['grace', 'mercy', 'kindness', 'favor', 'blessing'],
      'sin': [
        'sin',
        'sinful',
        'wrong',
        'wrongdoing',
        'transgression',
        'iniquity'
      ],
      'repentance': [
        'repent',
        'repentance',
        'turn',
        'change',
        'return',
        'convert'
      ],
      'joy': ['joy', 'joyful', 'rejoice', 'happiness', 'gladness', 'delight'],
      'patience': [
        'patience',
        'patient',
        'endure',
        'persevere',
        'wait',
        'longsuffering'
      ],
      'humility': ['humble', 'humility', 'meek', 'modest', 'lowly'],
    };

    // Find which concepts are mentioned (check for word boundaries)
    for (var entry in conceptPatterns.entries) {
      for (var keyword in entry.value) {
        // Use word boundary to avoid partial matches
        final pattern = RegExp(r'\b' + keyword + r'\b', caseSensitive: false);
        if (pattern.hasMatch(text)) {
          if (!concepts.contains(entry.key)) {
            concepts.add(entry.key);
          }
          break; // Found one keyword for this concept, move to next
        }
      }
    }

    return concepts;
  }

  Widget _buildVerseContext(double screenWidth, bool isDark) {
    if (widget.verseContext == null) return const SizedBox.shrink();

    final verseText = widget.verseContext!['verseText'] ?? '';
    final book = widget.verseContext!['book'] ?? '';
    final chapter = widget.verseContext!['chapter'] ?? '';
    final verse = widget.verseContext!['verse'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth > 450 ? 16 : 12),
      padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark
            ? CommanColor.darkPrimaryColor.withOpacity(0.8)
            : CommanColor.lightDarkPrimary(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : CommanColor.lightDarkPrimary(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.book,
                size: screenWidth > 450 ? 20 : 18,
                color: isDark
                    ? Colors.white
                    : CommanColor.lightDarkPrimary(context),
              ),
              const SizedBox(width: 8),
              Text(
                '$book $chapter:$verse',
                style: TextStyle(
                  color: isDark
                      ? Colors.white
                      : CommanColor.lightDarkPrimary(context),
                  fontSize: screenWidth > 450 ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verseText,
            style: TextStyle(
              color: CommanColor.whiteBlack(context),
              fontSize: screenWidth > 450 ? 15 : 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseSuggestedQuestions(double screenWidth, bool isDark) {
    if (widget.verseContext == null) return const SizedBox.shrink();

    // Generate suggested questions based on the verse
    final suggestedQuestions = [
      ChatTranslations.get('explain_verse', AppApiConstant.chatLanguage),
      ChatTranslations.get('verse_daily_life', AppApiConstant.chatLanguage),
      ChatTranslations.get('how_apply_teaching', AppApiConstant.chatLanguage),
    ];

    return Container(
      padding: EdgeInsets.only(
        left: screenWidth > 450 ? 20 : 16,
        right: screenWidth > 450 ? 20 : 16,
        top: screenWidth > 450 ? 12 : 8,
        bottom: screenWidth > 450 ? 8 : 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions :',
            style: TextStyle(
              color: CommanColor.whiteBlack(context).withOpacity(0.7),
              fontSize: screenWidth > 450 ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: screenWidth > 450 ? 64 : 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedQuestions.length,
              itemBuilder: (context, index) {
                final question = suggestedQuestions[index];
                final isSelected = _selectedExampleQuestionIndex == index;
                return Padding(
                  padding: EdgeInsets.only(
                      right: screenWidth > 450 ? 10 : 8,
                      bottom: screenWidth > 450 ? 4 : 2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTopicIndex = null;
                        _selectedExampleQuestionIndex = index;
                        _messageController.text = question;
                      });
                      _sendMessage();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _selectedExampleQuestionIndex = null;
                          });
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 450 ? 18 : 14,
                        vertical: screenWidth > 450 ? 14 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: CommanColor.lightDarkPrimary(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected && isDark
                              ? const Color(
                                  0xFFFFD700) // Light yellow border when tapped in dark mode
                              : (isDark
                                  ? Colors
                                      .white // White border initially in dark mode
                                  : CommanColor.lightDarkPrimary(context)
                                      .withOpacity(0.3)),
                          width: isSelected && isDark ? 3 : (isDark ? 3 : 1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CommanColor.lightDarkPrimary(context)
                                .withOpacity(0.25),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.north_east,
                            size: screenWidth > 450 ? 18 : 16,
                            color: CommanColor.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            question,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: CommanColor.white,
                              fontSize: screenWidth > 450 ? 16 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: 0,
        right: screenWidth * 0.15,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: screenWidth > 450 ? 18 : 16,
            backgroundColor: CommanColor.lightDarkPrimary(context),
            child: Image.asset("assets/Mask group.png"),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(screenWidth > 450 ? 16 : 12),
            decoration: BoxDecoration(
              color: isDark
                  ? CommanColor.darkPrimaryColor.withOpacity(0.3)
                  : CommanColor.backgrondcolor,
              border: Border.all(
                color: CommanColor.lightDarkPrimary(context).withOpacity(0.3),
                width: 1,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: _WaveLoader(
              color:
                  isDark ? Colors.white : CommanColor.lightDarkPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  // Function to parse verse reference and extract book, chapter, verse
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
        // Normalize book name (remove numbers, capitalize first letter)
        bookName = bookName.replaceAll(RegExp(r'^[1-3]\s+'), '').trim();
        if (bookName.isNotEmpty) {
          bookName =
              bookName[0].toUpperCase() + bookName.substring(1).toLowerCase();
        }
        final chapter = int.tryParse(match.group(2) ?? '');
        final verse = int.tryParse(match.group(3) ?? '');
        if (chapter != null && verse != null && bookName.isNotEmpty) {
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

  // Function to parse text and highlight verse references with clickable links
  List<TextSpan> _parseTextWithVerseHighlights(
      String text, bool isUser, double screenWidth, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final baseColor = isUser
        ? const Color(0xFFF6F1E9)
        : (isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF8D6E63));
    // Keep verse references clickable (for AI messages) but don't visually underline/highlight them.
    final highlightColor = baseColor;

    // Pattern to match verse references like "John 3:16", "Genesis 1:1-3", "1 Corinthians 13:4-7", "John 3:16, 17", etc.
    // Matches: Book name (with optional number prefix) + chapter:verse (with optional verse range or comma-separated verses)
    // More specific pattern to avoid matching standalone numbers
    final versePattern = RegExp(
      r'\b([1-3]?\s?[A-Za-z]{2,}\s+)?(\d{1,3}):(\d{1,3})(?:-(\d{1,3}))?(?:\s*,\s*(\d{1,3}))?',
      caseSensitive: false,
    );

    List<TextSpan> spans = [];
    int lastIndex = 0;

    for (Match match in versePattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: baseColor,
            fontSize: screenWidth > 450 ? 18 : 16,
            height: 1.4,
          ),
        ));
      }

      // Parse verse reference for navigation
      final verseRef = match.group(0) ?? '';
      final verseData = _parseVerseReference(verseRef);

      // Add highlighted clickable verse reference
      TapGestureRecognizer? recognizer;
      if (verseData != null && !isUser) {
        recognizer = TapGestureRecognizer()
          ..onTap = () async {
            // Navigate to verse screen
            final bookName = verseData['bookName'] as String;
            final chapter = verseData['chapter'] as int;
            final verse = verseData['verse'] as int;

            // Get book number from database using book name
            int? bookNum;
            try {
              final db = await DBHelper().db;
              if (db != null) {
                // Try exact match first
                final result = await db.rawQuery(
                  "SELECT book_num FROM book WHERE title = ? LIMIT 1",
                  [bookName],
                );

                // If no exact match, try case-insensitive search
                if (result.isEmpty) {
                  final caseInsensitiveResult = await db.rawQuery(
                    "SELECT book_num FROM book WHERE LOWER(title) = LOWER(?) LIMIT 1",
                    [bookName],
                  );
                  if (caseInsensitiveResult.isNotEmpty) {
                    bookNum = int.tryParse(
                        caseInsensitiveResult[0]['book_num'].toString());
                  } else {
                    // Fallback: try matching short_title and singular/plural variants
                    final shortTitleResult = await db.rawQuery(
                      "SELECT book_num FROM book WHERE LOWER(short_title) = LOWER(?) LIMIT 1",
                      [bookName],
                    );
                    if (shortTitleResult.isNotEmpty) {
                      bookNum = int.tryParse(
                          shortTitleResult[0]['book_num'].toString());
                    } else {
                      final altName = bookName.endsWith('s')
                          ? bookName.substring(0, bookName.length - 1)
                          : '$bookName' 's';
                      final altResult = await db.rawQuery(
                        "SELECT book_num FROM book WHERE LOWER(title) = LOWER(?) OR LOWER(short_title) = LOWER(?) LIMIT 1",
                        [altName, altName],
                      );
                      if (altResult.isNotEmpty) {
                        bookNum =
                            int.tryParse(altResult[0]['book_num'].toString());
                      }
                    }
                  }
                } else {
                  bookNum = int.tryParse(result[0]['book_num'].toString());
                }
              }
            } catch (e) {
              debugPrint('Error getting book number: $e');
            }

            if (bookNum == null) {
              Constants.showToast(
                  'Verse not found. Please check it manually in the reading screen');
              return;
            }

            // Save selected book and book number
            await SharPreferences.setString(
              SharPreferences.selectedBook,
              bookName,
            );
            await SharPreferences.setString(
              SharPreferences.selectedBookNum,
              bookNum.toString(),
            );
            await SharPreferences.setString(
              SharPreferences.selectedChapter,
              chapter.toString(),
            );

            // Navigate to HomeScreen with verse details
            Get.to(() => HomeScreen(
                  From: "chat",
                  selectedVerseNumForRead: verse.toString(),
                  selectedBookForRead: bookNum.toString(),
                  selectedChapterForRead: chapter.toString(),
                  selectedBookNameForRead: bookName,
                  selectedVerseForRead: "",
                ));
          };
      }

      spans.add(TextSpan(
        text: verseRef,
        style: TextStyle(
          color: highlightColor,
          fontSize: screenWidth > 450 ? 18 : 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        recognizer: recognizer,
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: baseColor,
          fontSize: screenWidth > 450 ? 18 : 16,
          height: 1.4,
        ),
      ));
    }

    // If no verse references found, return the whole text as a single span
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: baseColor,
          fontSize: screenWidth > 450 ? 18 : 16,
          height: 1.4,
        ),
      ));
    }

    return spans;
  }

  Widget _buildMessageBubble(ChatMessage message, double screenWidth) {
    final isUser = message.isUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: isUser ? screenWidth * 0.15 : 0,
        right: isUser ? 0 : screenWidth * 0.15,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment:
            CrossAxisAlignment.end, // Changed to .end for bottom alignment
        children: [
          if (!isUser) ...[
            Image.asset(
              "assets/Mask group.png",
              width: 30,
              height: 30,
              // color: Colors.white,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF8D6E63) // Brown color for user messages
                    : (isDark
                        ? const Color(
                            0xFF4A4A4A) // Solid dark gray for better contrast in dark mode
                        : const Color(
                            0xFFF6F1E9)), // Light beige like screenshot
                borderRadius:
                    BorderRadius.circular(20), // round like screenshot
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isUser
                            ? const Color(
                                0xFFF6F1E9) // Light beige text for user messages
                            : (isDark
                                ? Colors.white.withOpacity(0.9)
                                : const Color(
                                    0xFF8D6E63)), // Brown text like screenshot
                        fontSize: screenWidth > 450 ? 18 : 16,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      children: _parseTextWithVerseHighlights(
                          message.text, isUser, screenWidth, context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? const Color(0xFFF6F1E9).withOpacity(
                                  0.8) // Light beige for user timestamp
                              : (isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : const Color(0xFF8D6E63).withOpacity(
                                      0.6)), // Dark brown for AI timestamp
                          fontSize: screenWidth > 450 ? 12 : 11,
                        ),
                      ),
                      // Hide copy/share when no real AI response was generated.
                      if (!isUser && !_isFailedChatResponseText(message.text))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ChatTapFeedbackIcon(
                              onTap: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: message.text));
                                Constants.showToast(
                                    'Message copied to clipboard', 5000);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 2),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.14)
                                          : Colors.black.withOpacity(0.12),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Image.asset(
                                    "assets/Bookmark icons/Frame 3630.png",
                                    height: screenWidth > 450 ? 18 : 15,
                                    width: screenWidth > 450 ? 18 : 15,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            _ChatTapFeedbackIcon(
                              onTap: () async {
                                final screenSize = MediaQuery.of(context).size;
                                final sharePositionOrigin = Rect.fromLTWH(
                                  screenSize.width / 2 - 50,
                                  screenSize.height / 2 - 50,
                                  100,
                                  100,
                                );
                                await Share.share(
                                  _buildShareText(message.text),
                                  sharePositionOrigin: sharePositionOrigin,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 2),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.14)
                                          : Colors.black.withOpacity(0.12),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.share,
                                    size: screenWidth > 450 ? 18 : 15,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 4), // Add slight padding for better alignment
              child: CircleAvatar(
                radius: screenWidth > 450 ? 18 : 16,
                backgroundColor:
                    CommanColor.lightDarkPrimary(context).withOpacity(
                  isDark ? 0.25 : 0.15,
                ),
                child: Image.asset(
                  "assets/home icons/My Account.png",
                  width: screenWidth > 450 ? 20 : 18,
                  height: screenWidth > 450 ? 20 : 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isFailedChatResponseText(String text) {
    final trimmed = text.trim();
    final lower = trimmed.toLowerCase();
    return lower.startsWith('error:') ||
        trimmed == 'Sorry, I could not generate a response.' ||
        trimmed ==
            'Sorry, I could not generate a response. Please try again.' ||
        lower.contains('sorry, i could not generate');
  }

  String _buildShareText(String text) {
    final androidLink =
        "https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}";
    final iosLink = "https://itunes.apple.com/app/id${BibleInfo.apple_AppId}";
    final storeLink = Platform.isIOS ? iosLink : androidLink;
    return "$text\n\nRead more at: $storeLink";
  }

  void _showMessageOptions(BuildContext context, ChatMessage message,
      double screenWidth, bool isDark) {
    // Get theme provider values with listen: false to avoid provider errors
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.themeMode == ThemeMode.dark
        ? CommanColor.darkPrimaryColor
        : CommanColor.lightModePrimary;
    final textColor = themeProvider.themeMode == ThemeMode.dark
        ? CommanColor.white
        : CommanColor.black;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
            overlay.size.width / 2 - 100, overlay.size.height / 2, 200, 0),
        Offset.zero & overlay.size,
      ),
      color: isDark ? CommanColor.darkPrimaryColor : CommanColor.white,
      items: [
        if (message.isUser || !_isFailedChatResponseText(message.text))
          PopupMenuItem(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: primaryColor, width: 1.2),
                  ),
                  child: Image.asset(
                    "assets/Bookmark icons/Frame 3630.png",
                    height: screenWidth > 450 ? 16 : 14,
                    width: screenWidth > 450 ? 16 : 14,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  ChatTranslations.get('copy', _uiLang),
                  style: TextStyle(
                    color: textColor,
                    fontSize: screenWidth > 450 ? 16 : 14,
                  ),
                ),
              ],
            ),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: message.text));
              Constants.showToast(ChatTranslations.get('copied', _uiLang));
            },
          ),
        if (!message.isUser && !_isFailedChatResponseText(message.text))
          PopupMenuItem(
            child: Row(
              children: [
                Icon(
                  Icons.share,
                  size: screenWidth > 450 ? 20 : 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  ChatTranslations.get('share', _uiLang),
                  style: TextStyle(
                    color: textColor,
                    fontSize: screenWidth > 450 ? 16 : 14,
                  ),
                ),
              ],
            ),
            onTap: () async {
              // Check and show rating dialog on first share
              await RatingDialogHelper.showRatingDialogOnFirstShare(context);

              // Get screen size for sharePositionOrigin (required on iOS)
              final screenSize = MediaQuery.of(context).size;
              final sharePositionOrigin = Rect.fromLTWH(
                screenSize.width / 2 - 50,
                screenSize.height / 2 - 50,
                100,
                100,
              );
              await Share.share(
                _buildShareText(message.text),
                sharePositionOrigin: sharePositionOrigin,
              );
            },
          ),
      ],
    );
  }

  Widget _buildInputArea(double screenWidth, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final bool hasText = _messageController.text.trim().isNotEmpty;
    final Color sendBgColor = !_isLoading
        ? CommanColor.lightDarkPrimary(context)
        : CommanColor.lightDarkPrimary(context).withOpacity(0.3);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 450 ? 12 : 10,
        vertical: screenWidth > 450 ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: screenWidth > 450 ? 100 : 80,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : (themeProvider.currentCustomTheme ==
                                  AppCustomTheme.vintage
                              ? Colors.brown[100]
                              : Colors.white),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey[700]!.withOpacity(0.3)
                            : Colors.grey[300]!.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      enabled: !_isLoading, // Disable text field while loading
                      readOnly: _isLoading, // Prevent focus when loading
                      onSubmitted: (_) {
                        if (!_isLoading) {
                          _sendMessage();
                        }
                      },
                      style: TextStyle(
                        color: CommanColor.whiteBlack(context),
                        fontSize: screenWidth > 450 ? 15 : 14,
                      ),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? ChatTranslations.get('listening', _uiLang)
                            : (_isLoading
                                ? ChatTranslations.get(
                                    'seeking_guidance', _uiLang)
                                : ChatTranslations.get(
                                    'ask_anything', _uiLang)),
                        hintStyle: TextStyle(
                          color:
                              CommanColor.whiteBlack(context).withOpacity(0.5),
                          fontSize: screenWidth > 450 ? 15 : 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 450 ? 20 : 18,
                          vertical: screenWidth > 450 ? 16 : 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Voice input button temporarily hidden
                const SizedBox(width: 0, height: 0),
                const SizedBox(width: 8),
                Material(
                  color: isDark
                      ? (hasText && !_isLoading
                          ? Colors.white
                          : Colors.white.withOpacity(0.35))
                      : sendBgColor,
                  shape: const CircleBorder(),
                  elevation: isDark && hasText && !_isLoading ? 3 : 0,
                  shadowColor: Colors.black45,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: (!_isLoading && hasText) ? _sendMessage : null,
                    child: SizedBox(
                      width: screenWidth > 450 ? 48 : 44,
                      height: screenWidth > 450 ? 48 : 44,
                      child: Center(
                        child: isDark
                            ? Icon(
                                Icons.send_rounded,
                                color: hasText && !_isLoading
                                    ? CommanColor.darkPrimaryColor
                                    : CommanColor.darkPrimaryColor
                                        .withOpacity(0.45),
                                size: screenWidth > 450 ? 24 : 22,
                              )
                            : Image.asset(
                                "assets/send-2.png",
                                color: CommanColor.white,
                                width: screenWidth > 450 ? 24 : 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class _WaveLoader extends StatefulWidget {
  final Color color;

  const _WaveLoader({
    required this.color,
  });

  @override
  State<_WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<_WaveLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start animations with staggered delays for wave effect
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            // Create bouncing effect - dots move up and down
            final offset = (_animations[index].value - 0.5) * 6.0;

            return Transform.translate(
              offset: Offset(0, -offset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Brief scale pulse on tap so copy/share actions feel acknowledged.
class _ChatTapFeedbackIcon extends StatefulWidget {
  const _ChatTapFeedbackIcon({
    required this.onTap,
    required this.child,
  });

  final Future<void> Function() onTap;
  final Widget child;

  @override
  State<_ChatTapFeedbackIcon> createState() => _ChatTapFeedbackIconState();
}

class _ChatTapFeedbackIconState extends State<_ChatTapFeedbackIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.08), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward(from: 0);
    await widget.onTap();
    if (mounted) {
      await _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(8),
        child: widget.child,
      ),
    );
  }
}
