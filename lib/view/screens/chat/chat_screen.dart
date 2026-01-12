import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/utils/rating_dialog_helper.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_history_screen.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/setting_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/services/statsig/statsig_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/gestures.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
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
  static const String _baseUrl =
      'https://my-backend-one-eta.vercel.app/api/gemini';
  int? _selectedTopicIndex; // Track which topic button is selected
  int?
      _selectedExampleQuestionIndex; // Track which example question button is tapped
  String _introAnswerLength = 'small';

  // Speech to text
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechInitialized = false;
  String _text = '';
  bool _openedSettingsForPermission = false; // Track if user opened settings

  // Wallet credits (loaded from local storage immediately)
  int _currentCredits = 0;
  Timer? _creditsTimer;

  // Topic-based questions
  final List<Map<String, String>> _topicQuestions = [
    {
      'topic': 'I feel anxious',
      'question': 'Show me verses that calm anxiety..'
    },
    {
      'topic': 'I\'m confused',
      'question': 'Show me verses about clarity and direction..'
    },
    {
      'topic': 'I need strength',
      'question': 'How can I stay strong spiritually?'
    },
    {
      'topic': 'I feel lost',
      'question': 'How does God guide me when I feel lost?'
    },
    {
      'topic': 'I feel stuck',
      'question': 'Encourage me when everything feels heavy..'
    },
    {
      'topic': 'God\'s promises',
      'question': 'What promises remind me I\'m not alone?'
    },
  ];

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
    // Track Geneva Bible Chat event
    StatsigService.trackGenevaBibleChat();
    _showChatIntroIfNeeded();

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
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('chat_intro_seen') ?? false;
    if (seenIntro || !mounted) return;

    final length = await WalletService.getAnswerLength();
    if (mounted) {
      setState(() {
        _introAnswerLength = length;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showChatIntroDialog();
      });
    }
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
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
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

                          // Content Section
                          Padding(
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
                                        : CommanColor.lightDarkPrimary(context)
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
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: CommanColor.lightDarkPrimary(
                                            context),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Each answer uses credits. You can change this anytime in your Wallet.',
                                          style: TextStyle(
                                            color:
                                                CommanColor.whiteBlack(context)
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
                                  20,
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
                                  50,
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
                                  100,
                                  setBottomSheetState,
                                ),
                                const SizedBox(height: 24),

                                // Action Button
                                SizedBox(
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
                                      padding: EdgeInsets.zero, // IMPORTANT
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
                                          vertical: screenWidth > 450 ? 16 : 14,
                                        ),
                                        child: Text(
                                          'Got it, Let\'s Chat!',
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

                                SizedBox(
                                    height: MediaQuery.of(context)
                                            .viewInsets
                                            .bottom +
                                        10),
                              ],
                            ),
                          ),
                        ]),
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
    int cost,
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
            // Custom Radio Button
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
                    ? CommanColor.lightDarkPrimary(context)
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : CommanColor.lightDarkPrimary(context)
                            .withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$cost',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : CommanColor.lightDarkPrimary(context),
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
                        'Cancel',
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

  Future<void> _loadChatHistory() async {
    if (_currentConversationId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('chat_history_$_currentConversationId');
    if (historyJson != null) {
      final List<dynamic> history = jsonDecode(historyJson);
      setState(() {
        _messages.clear();
        _messages.addAll(
          history.map((item) => ChatMessage.fromJson(item)).toList(),
        );
      });
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
    final conversationMeta = {
      'id': _currentConversationId,
      'date': DateTime.now().toIso8601String(),
      'preview': _messages.first.text.length > 50
          ? '${_messages.first.text.substring(0, 50)}...'
          : _messages.first.text,
      'messageCount': _messages.length,
    };
    await prefs.setString(
        'chat_meta_$_currentConversationId', jsonEncode(conversationMeta));
  }

  String _getTodayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
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
        Constants.showToast('Used $chatCost credits for this response', 5000);
        await prefs.setBool('chat_credit_debit_shown', true);
      }
      // Refresh credits display immediately after deduction
      _loadCreditsFromLocal();
    }
  }

  Future<void> _showInsufficientCreditsDialog() async {
    final credits = await WalletService.getCredits();
    final chatCost = await WalletService.getChatCost();
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;

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
      _messages.clear();
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
                  'New Chat',
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
                  'Are you sure you want to start a new chat?\nYour current conversation will be cleared.',
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
                              'Cancel',
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
                              'New Chat ',
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

    // Check internet connection
    final bool isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      Constants.showToast("Check Your Internet Connection", 5000);
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
          '''You are a knowledgeable and respectful assistant for the Geneva Bible, one of the most historically significant English translations of the Bible. Follow these guidelines:

1. Provide accurate biblical information, interpretations, and explanations based on the Geneva Bible
2. Help users understand verses, chapters, and biblical concepts with clarity and respect
3. Offer spiritual guidance and biblical wisdom in a thoughtful manner
4. Explain historical context and theological meanings accurately
5. Answer questions about biblical stories, characters, and teachings with proper context
6. Always maintain a respectful and reverent tone when discussing biblical matters
7. When explaining Bible content, be clear, accurate, and helpful
8. Provide well-structured responses that are easy to understand
9. If asked about specific verses, provide context and meaning
10. Always respond in plain text format without using asterisks (*), markdown formatting, or special characters

${answerLengthInstruction}
${AppApiConstant.chatLanguage != null ? '\nIMPORTANT: Always respond in ${AppApiConstant.chatLanguage == 'TN' ? 'Tamil' : AppApiConstant.chatLanguage} language. All your responses must be in ${AppApiConstant.chatLanguage == 'TN' ? 'Tamil' : AppApiConstant.chatLanguage}.' : ''}

Remember: You are assisting users with the Geneva Bible, so provide responses that honor the sacred nature of the text while being informative and helpful.
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
        });

        // Ensure keyboard stays dismissed immediately after setState
        FocusScope.of(context).unfocus();
        _messageFocusNode.unfocus();

        // Deduct credits after successful response
        await _deductChatCredits();

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

        setState(() {
          _messages.add(ChatMessage(
            text: 'Error: $errorMessage',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
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
          text: 'Error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
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

    return Scaffold(
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
      //                         'Cancel',
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
      //                         'New Chat',
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
                color:
                    isDark ? CommanColor.black : themeProvider.backgroundColor,
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
                        onPressed: () => Get.back(),
                      ),
                      // Show "Faith Chat" in center when messages exist
                      if (_messages.isNotEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              'Faith Chat',
                              style: TextStyle(
                                color: CommanColor.whiteBlack(context),
                                fontSize: screenWidth > 450 ? 18 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => const WalletScreen(),
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300),
                              )?.then((_) {
                                // Refresh credits when returning from wallet screen
                                _loadCreditsFromLocal();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth > 450 ? 8 : 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CommanColor.darkPrimaryColor
                                        .withOpacity(0.6)
                                    : CommanColor.lightDarkPrimary(context)
                                        .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    size: screenWidth > 450 ? 26 : 24,
                                    color: isDark
                                        ? Colors.white
                                        : CommanColor.lightDarkPrimary(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_currentCredits',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : CommanColor.lightDarkPrimary(
                                              context),
                                      fontSize: screenWidth > 450 ? 13 : 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Wallet icon button
                          // IconButton(
                          //   icon: Icon(
                          //     Icons.account_balance_wallet,
                          //     color: isDark
                          //         ? Colors.white
                          //         : CommanColor.lightDarkPrimary(context),
                          //   ),
                          //   tooltip: 'Wallet',
                          //   onPressed: () {
                          //     Get.to(
                          //       () => const WalletScreen(),
                          //       transition: Transition.cupertinoDialog,
                          //       duration: const Duration(milliseconds: 300),
                          //     )?.then((_) {
                          //       // Refresh credits when returning from wallet screen
                          //       _loadCreditsFromLocal();
                          //     });
                          //   },
                          // ),
                          // Show new chat icon when at least one response has been received
                          if (_messages.any((msg) => !msg.isUser))
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: isDark
                                    ? Colors.white
                                    : CommanColor.lightDarkPrimary(context),
                              ),
                              tooltip: 'New Chat',
                              onPressed: () {
                                if (_messages.isNotEmpty) {
                                  _showNewChatBottomSheet();
                                } else {
                                  _startNewChat();
                                }
                              },
                            ),
                          IconButton(
                            icon: Image.asset(
                              "assets/message-time.png",
                              width: 24,
                              height: 24,
                              color: isDark
                                  ? Colors.white
                                  : CommanColor.lightDarkPrimary(context),
                            ),
                            tooltip: 'Chat History',
                            onPressed: () {
                              Get.to(
                                () => const ChatHistoryScreen(),
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300),
                              );
                            },
                          ),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth > 450 ? 20 : 16,
                              vertical: screenWidth > 450 ? 14 : 12,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Show verse context if available
                                if (widget.verseContext != null)
                                  _buildVerseContext(screenWidth, isDark),
                                if (widget.verseContext != null)
                                  const SizedBox(height: 20),
                                // Hide illustration image when opened from verse popup
                                if (widget.verseContext == null) ...[
                                  SizedBox(height: screenWidth > 450 ? 10 : 5),
                                  Transform.translate(
                                    offset: const Offset(0, -10),
                                    child: Container(
                                      width: screenWidth > 450 ? 140 : 130,
                                      height: screenWidth > 450 ? 140 : 130,
                                      decoration: const BoxDecoration(
                                        color: Colors
                                            .transparent, // Transparent background for illustration
                                      ),
                                      child: Image.asset(
                                        "assets/chat_img.png",
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          // Fallback to icon if image doesn't load
                                          return Icon(
                                            Icons.chat_bubble_outline,
                                            size: 100,
                                            color:
                                                CommanColor.whiteBlack(context)
                                                    .withOpacity(0.5),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Faith Answers',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: CommanColor.whiteBlack(context)
                                          .withOpacity(0.7),
                                      fontSize: screenWidth > 450 ? 26 : 23,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom:
                                          20), // Add bottom padding to prevent text from being hidden
                                  child: Text(
                                    widget.verseContext != null
                                        ? 'Ask questions about this verse...'
                                        : 'Get Guidance Based On Your Need...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: CommanColor.whiteBlack(context)
                                          .withOpacity(0.5),
                                      fontSize: screenWidth > 450 ? 16 : 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding:
                                EdgeInsets.all(screenWidth > 450 ? 20 : 16),
                            itemCount: _messages.length + (_isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length) {
                                return _buildLoadingIndicator();
                              }
                              return _buildMessageBubble(
                                  _messages[index], screenWidth);
                            },
                          ),
                  ),
                ),
                // Show default questions only when there are no messages
                if (_messages.isEmpty)
                  widget.verseContext != null
                      ? _buildVerseSuggestedQuestions(screenWidth, isDark)
                      : _buildDefaultQuestions(screenWidth, isDark)
                else
                  _buildFollowUpSuggestions(screenWidth, isDark),
                _buildInputArea(screenWidth, isDark),
              ],
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
                  'What does God say about fear?',
                  'How do I forgive someone who hurt me?',
                  'What is God\'s purpose for my life?',
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

  Widget _buildFollowUpSuggestions(double screenWidth, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // Find last AI response
    final lastAi = _messages.lastWhere(
      (m) => !m.isUser,
      orElse: () =>
          ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
    );
    if (lastAi.text.isEmpty) return const SizedBox.shrink();

    final suggestions = _getFollowUpList(lastAi.text);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(
        left: screenWidth > 450 ? 20 : 16,
        right: screenWidth > 450 ? 20 : 16,
        top: screenWidth > 450 ? 8 : 6,
        bottom: screenWidth > 450 ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Suggestions for this answer',
            style: TextStyle(
              color: CommanColor.whiteBlack(context).withOpacity(0.7),
              fontSize: screenWidth > 450 ? 15 : 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: screenWidth > 450 ? 64 : 58,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: suggestions.asMap().entries.map((entry) {
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
                                ? const Color(0xFFFFD700)
                                : (isDark
                                    ? Colors.white
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
                              Icons.link,
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

  List<String> _getFollowUpList(String answer) {
    final bool hasVerseContext = widget.verseContext != null;

    // Extract sentences from the response
    final sentences = answer
        .split(RegExp(r'[.!?]\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (sentences.isEmpty) {
      return hasVerseContext
          ? [
              'Tell me more about this verse',
              'How can I apply this verse in my life?',
              'What else does this verse teach?',
            ]
          : [
              'Can you explain more?',
              'How can I apply this?',
              'What else should I know?',
            ];
    }

    // Analyze the entire response to extract key information
    final allText = answer.toLowerCase();
    final firstSentence = sentences[0].toLowerCase();

    // Extract key phrases and nouns from the response
    final keyPhrases = _extractKeyPhrases(answer, sentences);
    final importantConcepts = _extractImportantConcepts(allText);

    // Generate truly dynamic questions based on actual content
    final List<String> dynamicQuestions = [];

    // Priority 1: Generate questions from extracted key phrases
    if (keyPhrases.isNotEmpty) {
      for (var phrase in keyPhrases.take(2)) {
        if (hasVerseContext) {
          dynamicQuestions.add('Can you explain more about ${phrase}?');
          dynamicQuestions.add('How does this verse relate to ${phrase}?');
        } else {
          dynamicQuestions.add('Can you explain more about ${phrase}?');
          dynamicQuestions.add('How does this relate to ${phrase}?');
        }
        if (dynamicQuestions.length >= 3) break;
      }
    }

    // Priority 2: Generate questions from detected concepts
    if (dynamicQuestions.length < 3 && importantConcepts.isNotEmpty) {
      for (var concept in importantConcepts.take(2)) {
        if (hasVerseContext) {
          if (!dynamicQuestions.any((q) => q.toLowerCase().contains(concept))) {
            dynamicQuestions
                .add('What does this verse teach about ${concept}?');
          }
        } else {
          if (!dynamicQuestions.any((q) => q.toLowerCase().contains(concept))) {
            dynamicQuestions.add('What does God say about ${concept}?');
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
            ? 'Why is this verse important?'
            : 'Why is this important?');
      }

      // Look for "how to", "way to" patterns
      if (firstSentence.contains('how to') ||
          firstSentence.contains('way to') ||
          firstSentence.contains('steps')) {
        dynamicQuestions.add(hasVerseContext
            ? 'What steps should I take?'
            : 'What practical steps can I take?');
      }

      // Look for questions in the response
      if (firstSentence.contains('?') || answer.contains('?')) {
        dynamicQuestions.add(hasVerseContext
            ? 'Can you explain this verse further?'
            : 'Can you explain this further?');
      }
    }

    // Return dynamic questions if we have enough, otherwise fill with contextual fallbacks
    if (dynamicQuestions.length >= 3) {
      return dynamicQuestions.take(3).toList();
    }

    // Fill remaining slots with contextual questions
    while (dynamicQuestions.length < 3) {
      if (hasVerseContext) {
        if (!dynamicQuestions.any((q) => q.contains('apply'))) {
          dynamicQuestions.add('How can I apply this verse in my life?');
        } else if (!dynamicQuestions.any((q) => q.contains('more'))) {
          dynamicQuestions.add('Tell me more about this verse');
        } else {
          dynamicQuestions.add('What else does this verse teach?');
        }
      } else {
        if (!dynamicQuestions.any((q) => q.contains('apply'))) {
          dynamicQuestions.add('How can I apply this?');
        } else if (!dynamicQuestions.any((q) => q.contains('more'))) {
          dynamicQuestions.add('Can you explain more?');
        } else {
          dynamicQuestions.add('What else should I know?');
        }
      }
    }

    return dynamicQuestions.take(3).toList();
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
      'Explain this verse',
      'What does this verse mean for my daily life?',
      'How can I apply this teaching?',
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
            'Suggestions Questions:',
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
    final baseColor =
        isUser ? CommanColor.white : CommanColor.whiteBlack(context);
    // Use a brighter, more visible color for verse highlighting
    // For AI responses (isUser = false): use yellow in light mode, white in dark mode
    // For user messages: use the same colors
    final highlightColor = isDark
        ? Colors
            .white // White color for dark mode - highly visible against dark background
        : (isUser
            ? CommanColor.white // Keep white for user messages in light mode
            : Colors
                .brown); // Light yellow/gold color for AI responses in light mode - visible against light beige background

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
                  }
                } else {
                  bookNum = int.tryParse(result[0]['book_num'].toString());
                }
              }
            } catch (e) {
              debugPrint('Error getting book number: $e');
            }

            // Save selected book and book number
            await SharPreferences.setString(
              SharPreferences.selectedBook,
              bookName,
            );
            if (bookNum != null) {
              await SharPreferences.setString(
                SharPreferences.selectedBookNum,
                bookNum.toString(),
              );
            }
            await SharPreferences.setString(
              SharPreferences.selectedChapter,
              chapter.toString(),
            );

            // Navigate to HomeScreen with verse details
            Get.to(() => HomeScreen(
                  From: "chat",
                  selectedVerseNumForRead: verse.toString(),
                  selectedBookForRead: bookNum?.toString() ?? "",
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
          fontWeight: isDark
              ? FontWeight.w700
              : FontWeight.w600, // Bolder in dark mode for better visibility
          decoration: TextDecoration.underline,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    ? CommanColor.lightDarkPrimary(context)
                    : (isDark
                        ? CommanColor.darkPrimaryColor.withOpacity(0.5)
                        : (themeProvider.currentCustomTheme ==
                                AppCustomTheme.vintage
                            ? themeProvider.backgroundColor.withOpacity(0.9)
                            : CommanColor.backgrondcolor.withOpacity(0.9))),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : CommanColor.whiteBlack(context).withOpacity(0.5),
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
                              ? Colors.white.withOpacity(0.9)
                              : CommanColor.whiteBlack(context)
                                  .withOpacity(0.5),
                          fontSize: screenWidth > 450 ? 12 : 11,
                        ),
                      ),
                      // Show copy and share icons only for non-user messages (results)
                      if (!isUser)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: message.text));
                                Constants.showToast(
                                    'Message copied to clipboard', 5000);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          CommanColor.lightDarkPrimary(context),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Image.asset(
                                    "assets/Bookmark icons/Frame 3630.png",
                                    height: screenWidth > 450 ? 18 : 15,
                                    width: screenWidth > 450 ? 18 : 15,
                                    color: CommanColor.whiteBlack(context)
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () async {
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          CommanColor.lightDarkPrimary(context),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.share,
                                    size: screenWidth > 450 ? 18 : 15,
                                    color: CommanColor.whiteBlack(context)
                                        .withOpacity(0.7),
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
            CircleAvatar(
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
          ],
        ],
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
                'Copy',
                style: TextStyle(
                  color: textColor,
                  fontSize: screenWidth > 450 ? 16 : 14,
                ),
              ),
            ],
          ),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: message.text));
            Constants.showToast('Message copied to clipboard');
          },
        ),
        if (!message.isUser) // Only show Share for reply messages
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
                  'Share',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                            ? 'Listening...'
                            : (_isLoading
                                ? 'Seeking guidance...'
                                : "Ask anything here..."),
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
                Container(
                  decoration: BoxDecoration(
                    color: sendBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                CommanColor.white,
                              ),
                            ),
                          )
                        : Image.asset(
                            "assets/send-2.png",
                            color: CommanColor.white,
                            width: screenWidth > 450 ? 24 : 20,
                          ),
                    onPressed: (!_isLoading && hasText) ? _sendMessage : null,
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
