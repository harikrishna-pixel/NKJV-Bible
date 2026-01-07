// lib/onboarding/faith_onboarding_screen.dart
// Create a parchment-like onboarding survey matching the provided UI.
// iPhone & iPad responsive. Persists answers with SharedPreferences.

import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/bible_select_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:biblebookapp/view/screens/onboarding_guidance_screen.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biblebookapp/view/screens/welcome_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biblebookapp/view/constants/images.dart';

import '../constants/share_preferences.dart';

/// Keys for persistence
class _PrefsKeys {
  static const survey = 'faith_survey_v1';
  static const completed = 'faith_survey_completed_v1';
}

/// Model for the survey values
class FaithSurveyData {
  String? purpose; // step 1
  String? ageGroup; // step 2
  String? challenge; // step 3
  String? frequency; // step 4
  String? growthWay; // step 5
  String? theme; // step 6

  Map<String, dynamic> toJson() => {
        'purpose': purpose,
        'ageGroup': ageGroup,
        'challenge': challenge,
        'frequency': frequency,
        'growthWay': growthWay,
        'theme': theme,
      };

  static FaithSurveyData fromJson(Map<String, dynamic> json) =>
      FaithSurveyData()
        ..purpose = json['purpose'] as String?
        ..ageGroup = json['ageGroup'] as String?
        ..challenge = json['challenge'] as String?
        ..frequency = json['frequency'] as String?
        ..growthWay = json['growthWay'] as String?
        ..theme = json['theme'] as String?;
}

/// Simple repository for SharedPreferences
class FaithSurveyRepo {
  Future<void> save(FaithSurveyData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefsKeys.survey, jsonEncode(data.toJson()));
    await prefs.setBool(_PrefsKeys.completed, true);
  }

  Future<FaithSurveyData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_PrefsKeys.survey);
    if (raw == null) return null;
    return FaithSurveyData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_PrefsKeys.completed) ?? false;
  }
}

/// Primary screen
class FaithOnboardingScreen extends StatefulWidget {
  const FaithOnboardingScreen({super.key});

  @override
  State<FaithOnboardingScreen> createState() => _FaithOnboardingScreenState();
}

class _FaithOnboardingScreenState extends State<FaithOnboardingScreen> {
  final _page = PageController();
  final _repo = FaithSurveyRepo();
  final data = FaithSurveyData();
  int step = 0; // 0..4 (5 questions)
  bool _hasRequestedNotification = false;
  final Set<String> _purposeSelections = {};
  final Set<String> _challengeSelections = {};
  final Set<String> _growthWaySelections = {};

  // UI palette
  static const Color _brown = Color(0xFF7A5435);
  static const Color _brownDark = Color(0xFF5F3E28);
  static const Color _brownLight = Color(0xFFD4B89E);
  static const Color _ink = Color(0xFF2E2C2B);

  @override
  void initState() {
    super.initState();
    // Notification permission will be requested after 2 questions (step == 2)
  }

  Future<void> _requestNotificationPermission() async {
    // Initialize notifications first - this will show the permission pop-up
    await NotificationsServices().initialiseNotifications();

    // Then request permission explicitly if needed
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      debugPrint('Android Notification Permission: $status');
    } else if (Platform.isIOS) {
      final status = await Permission.notification.request();
      debugPrint('iOS Notification Permission: $status');
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() async {
    if (step < 4) {
      // Show Apple notification permission AFTER answering the 4th question (when moving from step 3 to step 4)
      if (Platform.isIOS &&
          step == 3 &&
          _isStepAnswered(3) &&
          !_hasRequestedNotification) {
        _hasRequestedNotification = true;
        await _requestNotificationPermission();
      }

      setState(() => step += 1);
      _page.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      await _repo.save(data);
      if (step == 4) {
        await SharPreferences.setBoolean(SharPreferences.onboarding, true);
        // Request notification permission after completing all questions
        await _requestNotificationPermission();

        void goNext() {
          // Show theme selection screen after OnboardingGuidanceScreen
          Get.to(() => OnboardingThemeSelectionScreen(
                onThemeSelected: () {
                  debugPrint("folders leng - ${BibleInfo.folders.length}");
                  if (BibleInfo.folders.length == 1) {
                    Get.to(() => PreferenceSelectionScreen(
                          isSetting: false,
                          selectedbible: BibleInfo.folders.first,
                        ));
                  } else {
                    Get.to(() => BibleVersionsScreen(
                          from: 'onboard',
                        ));
                  }
                },
              ));
        }

        Get.to(() => OnboardingGuidanceScreen(onContinue: goNext));
      }
      //if (mounted) Navigator.of(context).maybePop();
    }
  }

  void _toggleMultiSelect(
      Set<String> bucket, String option, void Function(String?) setter) {
    setState(() {
      if (!bucket.add(option)) {
        bucket.remove(option);
      }
      setter(bucket.isEmpty ? null : bucket.join(', '));
    });
  }

  void _back() {
    if (step == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Get.offAll(() => const WelcomeScreen());
      }
      return;
    }

    setState(() => step -= 1);
    _page.previousPage(
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  bool _isStepAnswered(int index) {
    switch (index) {
      case 0:
        return data.purpose != null;
      case 1:
        return data.ageGroup != null;
      case 2:
        return data.challenge != null;
      case 3:
        return data.frequency != null;
      case 4:
        return data.growthWay != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    final isTablet = width >= 600;

    // constrain content for large screens (iPad / landscape)
    final maxContentWidth = isTablet ? 520.0 : 440.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2E6D7), // base parchment color
        body: Stack(
          children: [
            // Optional background image (uncomment and add the asset to pubspec if you have a parchment texture)
            Positioned.fill(
              child: Image.asset(
                Images.bgImage(context),
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(6, isTablet ? 8 : 4, 6, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _back,
                            icon: const Icon(Icons.arrow_back_ios_new,
                                size: 20, color: _ink),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Let's know your Faith Goals..",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 28 : 19,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ),
                          const Opacity(
                              opacity: 0,
                              child: SizedBox(width: 40)), // balance
                        ],
                      ),
                    ),
                  ),

                  // Stepper dots
                  SliverToBoxAdapter(
                    child: Center(
                      child: SizedBox(
                        width: maxContentWidth,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: isTablet ? 18 : 14,
                              bottom: isTablet ? 8 : 6),
                          child: _StepperDots(
                              page: _page,
                              current: step,
                              total: 5,
                              activeColor: _brown,
                              inactiveColor: _brownLight),
                        ),
                      ),
                    ),
                  ),

                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView(
                                controller: _page,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _MultiSelectQuestionPage(
                                    question:
                                        'What brings you to our Bible app today?',
                                    options: const [
                                      'Find peace and comfort',
                                      'Deepen my faith',
                                      'Study the Bible regularly',
                                      "Overcome life's challenges",
                                      'Strengthen my connection with God',
                                    ],
                                    selections: _purposeSelections,
                                    onToggle: (option) => _toggleMultiSelect(
                                      _purposeSelections,
                                      option,
                                      (value) => data.purpose = value,
                                    ),
                                  ),
                                  _QuestionPage(
                                    question: 'What is your age group?',
                                    options: const [
                                      '13–17',
                                      '18–24',
                                      '25–34',
                                      '35–44',
                                      '45–54',
                                      '55+'
                                    ],
                                    getValue: () => data.ageGroup,
                                    onChanged: (v) =>
                                        setState(() => data.ageGroup = v),
                                  ),
                                  _MultiSelectQuestionPage(
                                    question:
                                        'What challenges affect your spiritual growth the most?',
                                    options: const [
                                      'Life feels overwhelming',
                                      'Doubts about faith',
                                      'Not finding relatable scripture',
                                      'Struggle to pray regularly',
                                      'Feeling disconnected from God',
                                    ],
                                    selections: _challengeSelections,
                                    onToggle: (option) => _toggleMultiSelect(
                                      _challengeSelections,
                                      option,
                                      (value) => data.challenge = value,
                                    ),
                                  ),
                                  _QuestionPage(
                                    question:
                                        'How often do you read or study the Bible?',
                                    options: const [
                                      'I read the Bible daily',
                                      'A few times a week',
                                      'Occasionally',
                                      "I’m planning to start reading",
                                      "I’m completely new to Bible study",
                                    ],
                                    getValue: () => data.frequency,
                                    onChanged: (v) =>
                                        setState(() => data.frequency = v),
                                  ),
                                  _MultiSelectQuestionPage(
                                    question:
                                        "What's your favorite way to grow spiritually?",
                                    options: const [
                                      'Journaling or taking notes',
                                      'Highlighting key verses',
                                      'Sharing verses with friends',
                                      'Setting daily reminders',
                                    ],
                                    selections: _growthWaySelections,
                                    onToggle: (option) => _toggleMultiSelect(
                                      _growthWaySelections,
                                      option,
                                      (value) => data.growthWay = value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  16, 12, 16, 20 + mq.padding.bottom),
                              child: SizedBox(
                                width: double.infinity,
                                height: isTablet ? 64 : 56,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: _isStepAnswered(step)
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF763201),
                                              Color(0xFFD5821F),
                                              Color(0xFF763201),
                                            ],
                                          )
                                        : null,
                                    color: _isStepAnswered(step)
                                        ? null
                                        : _brown.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        _isStepAnswered(step) ? _next : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      step == 5 ? 'Continue' : 'Continue',
                                      style: TextStyle(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question page variant that allows multiple selections
class _MultiSelectQuestionPage extends StatelessWidget {
  final String question;
  final List<String> options;
  final Set<String> selections;
  final ValueChanged<String> onToggle;

  const _MultiSelectQuestionPage({
    required this.question,
    required this.options,
    required this.selections,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 8 : 4),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2C2B),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final option = options[i];
                final selected = selections.contains(option);
                return _SelectButton(
                  label: option,
                  selected: selected,
                  onTap: () => onToggle(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Question page with vertical options list styled like the UI
class _QuestionPage extends StatelessWidget {
  final String question;
  final List<String> options;
  final String? Function() getValue;
  final ValueChanged<String> onChanged;

  const _QuestionPage({
    required this.question,
    required this.options,
    required this.getValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 8 : 4),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2C2B),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final selected = getValue() == options[i];
                return _SelectButton(
                  label: options[i],
                  selected: selected,
                  onTap: () => onChanged(options[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// /// Final theme page with preview card
// class _ThemePage extends StatelessWidget {
//   final String question;
//   final List<String> options;
//   final String? Function() getValue;
//   final ValueChanged<String> onChanged;

//   const _ThemePage({
//     required this.question,
//     required this.options,
//     required this.getValue,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final mq = MediaQuery.of(context);
//     final isTablet = mq.size.width >= 600;

//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 8 : 4),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const SizedBox(height: 4),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Text(
//               question,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: isTablet ? 22 : 18,
//                 fontWeight: FontWeight.w700,
//                 color: const Color(0xFF2E2C2B),
//                 height: 1.3,
//               ),
//             ),
//           ),
//           const SizedBox(height: 18),
//           ...options.map((e) {
//             final selected = getValue() == e;
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 14),
//               child: _SelectButton(
//                 label: e,
//                 selected: selected,
//                 leading: _RadioVisual(selected: selected),
//                 onTap: () => onChanged(e),
//               ),
//             );
//           }),
//           const SizedBox(height: 8),
//           Center(
//             child: Text(
//               'Preview',
//               style: TextStyle(
//                 fontSize: isTablet ? 16 : 14,
//                 fontWeight: FontWeight.w600,
//                 color: const Color(0xFF7A5435),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.7),
//               borderRadius: BorderRadius.circular(12),
//               border:
//                   Border.all(color: const Color(0xFFB08D6E).withOpacity(0.6)),
//             ),
//             padding: const EdgeInsets.all(14),
//             child: const Text(
//               '1. In the beginning God created the heaven and the earth.\n\n'
//               '2. And the earth was without form, and void; and darkness was upon the face of the deep. '
//               'And the Spirit of God moved upon the face of the waters.',
//               style: TextStyle(
//                 height: 1.4,
//                 fontSize: 14,
//                 color: Color(0xFF2E2C2B),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
// }

/// Theme selection screen for onboarding flow
class OnboardingThemeSelectionScreen extends StatefulWidget {
  final VoidCallback onThemeSelected;

  const OnboardingThemeSelectionScreen({
    super.key,
    required this.onThemeSelected,
  });

  @override
  State<OnboardingThemeSelectionScreen> createState() =>
      _OnboardingThemeSelectionScreenState();
}

class _OnboardingThemeSelectionScreenState
    extends State<OnboardingThemeSelectionScreen> {
  late AppCustomTheme _selectedTheme;
  String? _selectedThemeName;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    _selectedTheme = provider.currentCustomTheme;
    _selectedThemeName = _selectedTheme.name;
  }

  Color getColor(AppCustomTheme theme) {
    switch (theme) {
      case AppCustomTheme.vintage:
        return const Color(0xFFF3E5C2);
      case AppCustomTheme.white:
        return Colors.white;
      case AppCustomTheme.lightbrown:
        return CommanColor.backgrondcolor;
    }
  }

  Widget themeBox(AppCustomTheme theme) {
    final color = getColor(theme);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
          _selectedThemeName = theme.name;
          Provider.of<ThemeProvider>(context, listen: false)
              .setCustomTheme(theme);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          image: theme == AppCustomTheme.vintage
              ? DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                )
              : null,
          border: Border.all(
            color: _selectedTheme == theme
                ? Colors.brown
                : const Color.fromARGB(255, 144, 144, 144),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;
    final themes = AppCustomTheme.values;
    final maxContentWidth = isTablet ? 520.0 : 440.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2E6D7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              Images.bgImage(context),
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(6, isTablet ? 8 : 4, 6, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 20, color: Color(0xFF2E2C2B)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Choose Your Theme",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 28 : 19,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2C2B),
                            ),
                          ),
                        ),
                        const Opacity(opacity: 0, child: SizedBox(width: 40)),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: isTablet ? 8 : 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Which theme do you love most?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E2C2B),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: themes.map(themeBox).toList(),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: Text(
                                'Preview',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7A5435),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: Provider.of<ThemeProvider>(context)
                                          .currentCustomTheme ==
                                      AppCustomTheme.vintage
                                  ? BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(
                                              Images.bgImage(context)),
                                          fit: BoxFit.cover),
                                      border: Border.all(
                                        color: const Color(0xFFB08D6E)
                                            .withValues(alpha: 0.7),
                                      ),
                                    )
                                  : BoxDecoration(
                                      color: Provider.of<ThemeProvider>(context)
                                          .backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFB08D6E)
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                              padding: const EdgeInsets.all(14),
                              child: const Text(
                                '1. In the beginning God created the heaven and the earth.\n\n'
                                '2. And the earth was without form, and void; and darkness was upon the face of the deep. '
                                'And the Spirit of God moved upon the face of the waters.',
                                style: TextStyle(
                                  height: 1.4,
                                  fontSize: 15.5,
                                  color: Color(0xFF2E2C2B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  16, 12, 16, 20 + mq.padding.bottom),
                              child: SizedBox(
                                width: double.infinity,
                                height: isTablet ? 64 : 56,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF763201),
                                        Color(0xFFD5821F),
                                        Color(0xFF763201),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      widget.onThemeSelected();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Final theme page with preview card + theme selection (kept for backward compatibility if needed)
class _ThemePage extends StatefulWidget {
  final String question;
  final String? Function() getValue;
  final ValueChanged<String> onChanged;

  const _ThemePage({
    required this.question,
    required this.getValue,
    required this.onChanged,
  });

  @override
  State<_ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<_ThemePage> {
  late AppCustomTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    _selectedTheme = provider.currentCustomTheme;
  }

  Color getColor(AppCustomTheme theme) {
    switch (theme) {
      case AppCustomTheme.vintage:
        return const Color(0xFFF3E5C2);
      case AppCustomTheme.white:
        return Colors.white;
      case AppCustomTheme.lightbrown:
        return CommanColor.backgrondcolor;
    }
  }

  Widget themeBox(AppCustomTheme theme) {
    final color = getColor(theme);
    return GestureDetector(
      onTap: () {
        widget.onChanged(theme.name);
        setState(() {
          _selectedTheme = theme;
          Provider.of<ThemeProvider>(context, listen: false)
              .setCustomTheme(theme);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          image: theme == AppCustomTheme.vintage
              ? DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                )
              : null,
          border: Border.all(
            color: _selectedTheme == theme
                ? Colors.brown
                : const Color.fromARGB(255, 144, 144, 144),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;
    final themes = AppCustomTheme.values;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 8 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.question,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2C2B),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 18),

          /// --- Theme selection row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: themes.map(themeBox).toList(),
          ),

          const SizedBox(height: 18),
          Center(
            child: Text(
              'Preview',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7A5435),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: Provider.of<ThemeProvider>(context)
                        .currentCustomTheme ==
                    AppCustomTheme.vintage
                ? BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(Images.bgImage(context)),
                        fit: BoxFit.cover),
                    border: Border.all(
                      color: const Color(0xFFB08D6E).withValues(alpha: 0.7),
                    ),
                  )
                : BoxDecoration(
                    color: Provider.of<ThemeProvider>(context).backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFB08D6E).withValues(alpha: 0.7),
                    ),
                  ),
            padding: const EdgeInsets.all(14),
            child: const Text(
              '1. In the beginning God created the heaven and the earth.\n\n'
              '2. And the earth was without form, and void; and darkness was upon the face of the deep. '
              'And the Spirit of God moved upon the face of the waters.',
              style: TextStyle(
                height: 1.4,
                fontSize: 14,
                color: Color(0xFF2E2C2B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _RadioVisual extends StatelessWidget {
  final bool selected;
  const _RadioVisual({required this.selected});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFF7A5435) : Colors.transparent,
        border: Border.all(color: const Color(0xFF7A5435), width: 2),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

/// Styled button used for each option row
class _SelectButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  //final Widget? leading;

  const _SelectButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;

    final borderRadius = BorderRadius.circular(7);
    // Border with increased thickness when selected
    final baseBorder = Border.all(
      color: selected ? const Color(0xFF805531) : const Color(0xFF9E9E9E), // Border color: #805531 when selected, 9E9E9E when not
      width: selected ? 2.0 : 1.0, // Increase thickness when selected
    );

    // Selected option: background color 805531 with 20% opacity
    final bg = selected
        ? const Color(0xFF805531).withOpacity(0.2)
        : Colors.transparent;
    final fg = selected
        ? const Color(0xFF2E2C2B)
        : const Color(0xFF2E2C2B); // Keep text color same for both states

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius,
            border:
                baseBorder, // Always show border with thickness based on selection
          ),
          padding: EdgeInsets.symmetric(
              horizontal: 18, vertical: isTablet ? 18 : 16),
          child: Row(
            children: [
              //if (leading != null) leading!,
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal stepper that matches the screenshots (6 circles with a connecting track)
class _StepperDots extends StatelessWidget {
  final int current; // 0-based
  final int total;
  final Color activeColor;
  final Color inactiveColor;
  final PageController page;
  const _StepperDots({
    required this.current,
    required this.total,
    required this.activeColor,
    required this.inactiveColor,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < total; i++) ...[
          _stepCircle(i),
          if (i != total - 1) _connector(i),
        ]
      ],
    );
  }

  Widget _connector(int i) {
    final filled = i < current;
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 0.1),
        decoration: BoxDecoration(
          color: filled ? activeColor : inactiveColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _stepCircle(int i) {
    final isActive = i <= current;
    return GestureDetector(
      onTap: () {
        page.jumpToPage(i);
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          gradient: isActive
              ? const RadialGradient(
                  colors: [
                    Color(0xFF763201),
                    Color(0xFFD5821F),
                    Color(0xFFAD4D08),
                    Color(0xFF763201),
                  ],
                )
              : null,
          color: isActive ? null : inactiveColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${i + 1}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

// -------------------------
// HOW TO USE
// -------------------------
// 1) Add shared_preferences to pubspec.yaml
// dependencies:
//   shared_preferences: ^2.2.3
//
// 2) (Optional) Add a parchment background image to assets and uncomment the Image.asset
// flutter:
//   assets:
//     - assets/images/parchment_bg.jpg
//
// 3) Push FaithOnboardingScreen() from your start flow. Example:
// Navigator.of(context).push(
//   MaterialPageRoute(builder: (_) => const FaithOnboardingScreen()),
// );
// When the final Continue is pressed, answers are saved and the page pops.
