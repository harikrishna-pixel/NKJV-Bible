
// Create a parchment-like onboarding survey matching the provided UI.
// iPhone & iPad responsive. Persists answers with SharedPreferences.

import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/bible_select_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:biblebookapp/view/screens/onboarding_guidance_screen.dart';
import 'package:biblebookapp/view/screens/welcome_screen.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:biblebookapp/services/daily_slot_notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' show parse;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
PermissionStatus status;
if (Platform.isAndroid) {
status = await Permission.notification.request();
debugPrint('Android Notification Permission: $status');
} else if (Platform.isIOS) {
status = await Permission.notification.request();
debugPrint('iOS Notification Permission: $status');
} else {
return;
}

// If user denied (e.g. Don't Allow), keep Settings toggles OFF.
final permitted =
status.isGranted || status.isLimited || status.isProvisional;
if (!permitted) {
await SharPreferences.setBoolean(SharPreferences.isNotificationOn, false);
await SharPreferences.setBoolean(
SharPreferences.isNotificationOn1, false);
await SharPreferences.setBoolean(
SharPreferences.isNotificationOn2, false);
await SharPreferences.setBoolean(
SharPreferences.notificationSlotsSyncedFromPermission, true);
return;
}

// Additive: Allow → mirror Settings Morning/Afternoon/Evening ON
// (OS permission alone did not flip these prefs, so Settings looked Off).
final nt =
await SharPreferences.getBoolean(SharPreferences.isNotificationOn);
final nt1 =
await SharPreferences.getBoolean(SharPreferences.isNotificationOn1);
final nt2 =
await SharPreferences.getBoolean(SharPreferences.isNotificationOn2);
final allOff = (nt ?? false) == false &&
(nt1 ?? false) == false &&
(nt2 ?? false) == false;
if (allOff) {
await SharPreferences.setBoolean(SharPreferences.isNotificationOn, true);
await SharPreferences.setBoolean(SharPreferences.isNotificationOn1, true);
await SharPreferences.setBoolean(SharPreferences.isNotificationOn2, true);
await DailySlotNotificationHelper.rescheduleEnabledSlots();
}
await SharPreferences.setBoolean(
SharPreferences.notificationSlotsSyncedFromPermission, true);
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
// Do NOT set onboarding=true here — set it only when user taps Continue
// on OnboardingGuidanceScreen, so that closing the app on that screen
// and reopening sends user back to onboarding instead of empty Home.
// Request notification permission after completing all questions
await _requestNotificationPermission();

void goNext() {
// Do NOT set onboarding here — set it only when user completes theme
// selection (onThemeSelected), so closing on Theme screen reopens to onboarding.
Get.to(() => OnboardingThemeSelectionScreen(
onThemeSelected: () {
// Do NOT set onboarding here — set it only when user completes
// preference/category selection (PreferenceSelectionScreen "Start now"
// or BibleVersionsScreen completion), so closing on that screen
// reopens to onboarding.
debugPrint("folders leng - ${BibleInfo.folders.length}");
if (BibleInfo.folders.length == 1) {
Get.off(() => PreferenceSelectionScreen(
isSetting: false,
selectedbible: BibleInfo.folders.first,
));
} else {
Get.off(() => BibleVersionsScreen(
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
Get.off(
() => const WelcomeScreen(),
transition: Transition.leftToRight,
duration: const Duration(milliseconds: 400),
);
}
return;
}

setState(() => step -= 1);
_page.previousPage(
duration: const Duration(milliseconds: 400),
curve: Curves.easeInOutCubic);
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
"Let's personalize your journey",
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
'What brings you here today?',
options: const [
'Find peace & comfort',
'Deepen my faith',
'Build a daily Bible habit',
"Overcome life's challenges",
'Grow closer to God',
],
selections: _purposeSelections,
onToggle: (option) => _toggleMultiSelect(
_purposeSelections,
option,
(value) => data.purpose = value,
),
),
_QuestionPage(
question: 'Which age group are you in?',
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
"What's weighing on you right now?",
options: const [
'Life feels overwhelming',
'Doubts about my faith',
'Hard to find verses that speak to me',
'I Struggle to pray regularly',
'Feeling distant from God',
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
'How often do you read the Bible?',
options: const [
'Every day',
'A few times a week',
'Now and then',
"I'm just getting started",
"I'm completely new to it",
],
getValue: () => data.frequency,
onChanged: (v) =>
setState(() => data.frequency = v),
),
_MultiSelectQuestionPage(
question:
"What helps you grow the most?",
options: const [
'Journaling & taking notes',
'Highlighting key verses',
'Sharing verses with friends',
'Daily reminders & devotions',
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
disabledBackgroundColor:
Colors.transparent,
shadowColor: Colors.transparent,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Text(
'Continue',
style: TextStyle(
fontSize: isTablet ? 20 : 18,
fontWeight: FontWeight.w700,
color: Colors.white,
),
),
const SizedBox(width: 8),
Icon(
Icons.arrow_forward,
color: Colors.white,
size: isTablet ? 22 : 20,
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
const SizedBox(height: 8),
Text(
'Select all that apply',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: isTablet ? 16 : 14,
fontWeight: FontWeight.w500,
color: const Color(0xFF5C4033).withOpacity(0.85),
height: 1.3,
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
// final String question;
// final List<String> options;
// final String? Function() getValue;
// final ValueChanged<String> onChanged;

// const _ThemePage({
// required this.question,
// required this.options,
// required this.getValue,
// required this.onChanged,
// });

// @override
// Widget build(BuildContext context) {
// final mq = MediaQuery.of(context);
// final isTablet = mq.size.width >= 600;

// return Padding(
// padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 8 : 4),
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.stretch,
// children: [
// const SizedBox(height: 4),
// Padding(
// padding: const EdgeInsets.symmetric(horizontal: 8),
// child: Text(
// question,
// textAlign: TextAlign.center,
// style: TextStyle(
// fontSize: isTablet ? 22 : 18,
// fontWeight: FontWeight.w700,
// color: const Color(0xFF2E2C2B),
// height: 1.3,
// ),
// ),
// ),
// const SizedBox(height: 18),
// ...options.map((e) {
// final selected = getValue() == e;
// return Padding(
// padding: const EdgeInsets.only(bottom: 14),
// child: _SelectButton(
// label: e,
// selected: selected,
// leading: _RadioVisual(selected: selected),
// onTap: () => onChanged(e),
// ),
// );
// }),
// const SizedBox(height: 8),
// Center(
// child: Text(
// 'Preview',
// style: TextStyle(
// fontSize: isTablet ? 16 : 14,
// fontWeight: FontWeight.w600,
// color: const Color(0xFF7A5435),
// ),
// ),
// ),
// const SizedBox(height: 10),
// Container(
// decoration: BoxDecoration(
// color: Colors.white.withOpacity(0.7),
// borderRadius: BorderRadius.circular(12),
// border:
// Border.all(color: const Color(0xFFB08D6E).withOpacity(0.6)),
// ),
// padding: const EdgeInsets.all(14),
// child: const Text(
// '1. In the beginning God created the heaven and the earth.\n\n'
// '2. And the earth was without form, and void; and darkness was upon the face of the deep. '
// 'And the Spirit of God moved upon the face of the waters.',
// style: TextStyle(
// height: 1.4,
// fontSize: 14,
// color: Color(0xFF2E2C2B),
// fontWeight: FontWeight.w500,
// ),
// ),
// ),
// const Spacer(),
// ],
// ),
// );
// }
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

// Additive: Bible preview from current installed bible language (not hardcoded EN).
static const String _kFallbackPreviewRef = 'Genesis 1:1–2';
static const String _kFallbackPreviewBody =
'1. In the beginning God created the heaven and the earth.\n\n'
'2. And the earth was without form, and void; and darkness was upon the face of the deep. '
'And the Spirit of God moved upon the face of the waters.';
String _previewRef = _kFallbackPreviewRef;
String _previewBody = _kFallbackPreviewBody;

@override
void initState() {
super.initState();
final provider = Provider.of<ThemeProvider>(context, listen: false);
_selectedTheme = provider.currentCustomTheme;
_selectedThemeName = _selectedTheme.name;
_loadBibleLanguagePreview();
}

String _plainVerseText(dynamic raw) {
final html = raw?.toString() ?? '';
if (html.isEmpty) return '';
return parse(html).body?.text?.trim() ?? html.trim();
}

/// Additive: load first-book ch.1 vv.1–2 from the active bible DB so preview
/// matches the installed language. Falls back to English if DB not ready.
Future<void> _loadBibleLanguagePreview() async {
try {
String? bookTitle;
String? previewBody;

final db = await DBHelper().db;
if (db != null) {
final books = await db.rawQuery(
'SELECT book_num, title FROM book ORDER BY book_num ASC LIMIT 1',
);
if (books.isNotEmpty) {
final bookNum = books.first['book_num'];
bookTitle = books.first['title']?.toString().trim();

List<Map<String, dynamic>> verses = [];
for (final chapterNum in const [0, 1]) {
final rows = await db.rawQuery(
'SELECT verse_num, content FROM verse '
'WHERE book_num = ? AND chapter_num = ? '
'ORDER BY verse_num ASC LIMIT 5',
[bookNum, chapterNum],
);
if (rows.isNotEmpty) {
verses = List<Map<String, dynamic>>.from(rows);
break;
}
}

if (verses.isNotEmpty) {
final firstTwo = verses.take(2).toList();
final parts = <String>[];
for (var i = 0; i < firstTwo.length; i++) {
final plain = _plainVerseText(firstTwo[i]['content']);
if (plain.isEmpty) continue;
parts.add('${i + 1}. $plain');
}
if (parts.isNotEmpty) {
previewBody = parts.join('\n\n');
}
}
}
}

// Additive: when DB not ready yet, still resolve book title from the
// app's current bible asset (language/version) so ref isn't stuck on EN.
if (bookTitle == null || bookTitle.isEmpty) {
final saved =
await SharPreferences.getString(SharPreferences.selectedBook);
if (saved != null && saved.trim().isNotEmpty) {
bookTitle = saved.trim();
}
}
if (bookTitle == null || bookTitle.isEmpty) {
final folder =
BibleInfo.folders.isNotEmpty ? BibleInfo.folders.first : null;
if (folder != null) {
try {
final raw =
await rootBundle.loadString('assets/zipped/$folder/book.json');
final decoded = jsonDecode(raw);
if (decoded is List && decoded.isNotEmpty) {
final first = decoded.first;
if (first is Map && first['title'] != null) {
bookTitle = first['title'].toString().trim();
}
}
} catch (e) {
debugPrint('Theme preview asset book.json skipped: $e');
}
}
}

if (!mounted) return;
if ((bookTitle == null || bookTitle.isEmpty) && previewBody == null) {
return;
}

setState(() {
if (bookTitle != null && bookTitle.isNotEmpty) {
final endVerse = previewBody != null && previewBody.contains('\n\n')
? 2
    : (previewBody != null ? 1 : 2);
_previewRef =
endVerse > 1 ? '$bookTitle 1:1–$endVerse' : '$bookTitle 1:1';
}
if (previewBody != null && previewBody.isNotEmpty) {
_previewBody = previewBody;
}
});
} catch (e) {
debugPrint('Theme preview bible load skipped: $e');
}
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

String _themeDisplayName(AppCustomTheme theme) {
switch (theme) {
case AppCustomTheme.vintage:
return 'Classic';
case AppCustomTheme.white:
return 'Pure Light';
case AppCustomTheme.lightbrown:
return 'Warm Cream';
}
}

Widget _themeOption(AppCustomTheme theme, bool isTablet) {
final color = getColor(theme);
final selected = _selectedTheme == theme;
const outerRadius = 10.0;
const borderWidth = 3.0;
const innerRadius = outerRadius - borderWidth;
final boxSize = isTablet ? 78.0 : 70.0;

return GestureDetector(
onTap: () {
setState(() {
_selectedTheme = theme;
_selectedThemeName = theme.name;
Provider.of<ThemeProvider>(context, listen: false)
    .setCustomTheme(theme);
});
},
child: SizedBox(
width: isTablet ? 108 : 96,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Stack(
clipBehavior: Clip.none,
children: [
Container(
width: boxSize,
height: boxSize,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(outerRadius),
border: Border.all(
color: selected
? const Color(0xFF7A5435)
    : const Color.fromARGB(255, 144, 144, 144),
width: borderWidth,
),
),
child: ClipRRect(
borderRadius: BorderRadius.circular(innerRadius),
child: DecoratedBox(
decoration: BoxDecoration(
color: color,
image: theme == AppCustomTheme.vintage
? DecorationImage(
image: AssetImage(Images.bgImage(context)),
fit: BoxFit.cover,
)
    : null,
),
child: const SizedBox.expand(),
),
),
),
if (selected)
Positioned(
top: -6,
right: -6,
child: Container(
width: 22,
height: 22,
decoration: const BoxDecoration(
color: Color(0xFF7A5435),
shape: BoxShape.circle,
),
child: const Icon(Icons.check,
color: Colors.white, size: 14),
),
),
],
),
const SizedBox(height: 8),
Text(
_themeDisplayName(theme),
textAlign: TextAlign.center,
style: TextStyle(
fontSize: isTablet ? 14 : 12,
fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
color: const Color(0xFF2E2C2B),
height: 1.2,
),
),
],
),
),
);
}

Widget _buildThemeSelectionCard(bool isTablet, List<AppCustomTheme> themes) {
return Container(
width: double.infinity,
padding: EdgeInsets.fromLTRB(12, isTablet ? 20 : 16, 12, 16),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.55),
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: const Color(0xFFB08D6E).withValues(alpha: 0.75),
),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
crossAxisAlignment: CrossAxisAlignment.start,
children: themes.map((theme) => _themeOption(theme, isTablet)).toList(),
),
);
}

Widget _buildThemePreviewCard(BuildContext context, {required bool compact}) {
final previewText = Text(
_previewBody,
style: const TextStyle(
height: 1.4,
fontSize: 15.5,
color: Color(0xFF2E2C2B),
fontWeight: FontWeight.w500,
),
);

return Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: const Color(0xFFB08D6E).withValues(alpha: 0.7),
),
),
child: ClipRRect(
borderRadius: BorderRadius.circular(12),
child: DecoratedBox(
decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
AppCustomTheme.vintage
? BoxDecoration(
image: DecorationImage(
image: AssetImage(Images.bgImage(context)),
fit: BoxFit.cover,
),
)
    : BoxDecoration(
color: Provider.of<ThemeProvider>(context).backgroundColor,
),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
children: [
Row(
children: [
Container(
width: 28,
height: 28,
decoration: BoxDecoration(
color: const Color(0xFF7A5435),
borderRadius: BorderRadius.circular(6),
),
child: const Icon(
Icons.menu_book_rounded,
color: Colors.white,
size: 16,
),
),
const SizedBox(width: 8),
Flexible(
child: Text(
_previewRef,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
color: Color(0xFF2E2C2B),
),
),
),
],
),
const SizedBox(height: 10),
if (compact)
previewText
else
Expanded(
child: SingleChildScrollView(
child: previewText,
),
),
],
),
),
),
),
);
}

Widget _buildPreviewDivider(bool isTablet) {
return Row(
children: [
Expanded(
child: Divider(
color: const Color(0xFF7A5435).withValues(alpha: 0.35),
thickness: 1,
),
),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 10),
child: Text(
'◆ Preview ◆',
style: TextStyle(
fontSize: isTablet ? 16 : 14,
fontWeight: FontWeight.w600,
color: const Color(0xFF7A5435),
),
),
),
Expanded(
child: Divider(
color: const Color(0xFF7A5435).withValues(alpha: 0.35),
thickness: 1,
),
),
],
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
child: Stack(
children: [
CustomScrollView(
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
const Opacity(
opacity: 0, child: SizedBox(width: 40)),
],
),
),
),
SliverToBoxAdapter(
child: Center(
child: ConstrainedBox(
constraints:
BoxConstraints(maxWidth: maxContentWidth),
child: Padding(
padding: EdgeInsets.fromLTRB(
16, isTablet ? 8 : 4, 16, 0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
mainAxisSize: MainAxisSize.min,
children: [
SizedBox(height: isTablet ? 12 : 6),
_buildThemeSelectionCard(isTablet, themes),
SizedBox(height: isTablet ? 20 : 12),
_buildPreviewDivider(isTablet),
SizedBox(height: isTablet ? 12 : 8),
_buildThemePreviewCard(context, compact: true),
],
),
),
),
),
),
SliverToBoxAdapter(
child: SizedBox(
height: (isTablet ? 64 : 56) + (isTablet ? 14 : 8),
),
),
],
),
Positioned(
left: 0,
right: 0,
bottom: 0,
child: Padding(
padding: EdgeInsets.fromLTRB(
16, isTablet ? 12 : 8, 16, isTablet ? 20 : 12),
child: Center(
child: ConstrainedBox(
constraints: BoxConstraints(maxWidth: maxContentWidth),
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
const outerRadius = 10.0;
const borderWidth = 3.0;
const innerRadius = outerRadius - borderWidth;
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
borderRadius: BorderRadius.circular(outerRadius),
border: Border.all(
color: _selectedTheme == theme
? Colors.brown
    : const Color.fromARGB(255, 144, 144, 144),
width: borderWidth,
),
),
child: ClipRRect(
borderRadius: BorderRadius.circular(innerRadius),
child: DecoratedBox(
decoration: BoxDecoration(
color: color,
image: theme == AppCustomTheme.vintage
? DecorationImage(
image: AssetImage(Images.bgImage(context)),
fit: BoxFit.cover,
)
    : null,
),
child: const SizedBox.expand(),
),
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
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: const Color(0xFFB08D6E).withValues(alpha: 0.7),
),
),
child: ClipRRect(
borderRadius: BorderRadius.circular(12),
child: DecoratedBox(
decoration: Provider.of<ThemeProvider>(context)
    .currentCustomTheme ==
AppCustomTheme.vintage
? BoxDecoration(
image: DecorationImage(
image: AssetImage(Images.bgImage(context)),
fit: BoxFit.cover,
),
)
    : BoxDecoration(
color:
Provider.of<ThemeProvider>(context).backgroundColor,
),
child: const Padding(
padding: EdgeInsets.all(14),
child: Text(
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
color: selected
? const Color(0xFF805531)
    : const Color(
0xFF9E9E9E), // Border color: #805531 when selected, 9E9E9E when not
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
// shared_preferences: ^2.2.3
//
// 2) (Optional) Add a parchment background image to assets and uncomment the Image.asset
// flutter:
// assets:
// - assets/images/parchment_bg.jpg
//
// 3) Push FaithOnboardingScreen() from your start flow. Example:
// Navigator.of(context).push(
// MaterialPageRoute(builder: (_) => const FaithOnboardingScreen()),
// );
// When the final Continue is pressed, answers are saved and the page pops.