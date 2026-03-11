import 'package:biblebookapp/streak_flow/mood_prayer_data.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

// Streak flow colors (warm parchment / spiritual theme)
const Color _kStreakBrown = Color(0xFF3D2914);
const Color _kStreakGold = Color(0xFFC9A227);
const Color _kStreakCream = Color(0xFFF5F0E6);

Future<void> _shareText(BuildContext context, String text) async {
  try {
    final RenderObject? renderObject = context.findRenderObject();
    final RenderBox? box = renderObject is RenderBox ? renderObject : null;
    await Share.share(
      text,
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  } catch (_) {
    // ignore
  }
}

void _showSavedToast(BuildContext context, {required bool saved}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      content: Text(saved ? 'Saved' : 'Removed'),
      duration: const Duration(milliseconds: 900),
    ),
  );
}

void _goToHome(BuildContext context) {
  Get.offAll(() => HomeScreen(
        From: "splash",
        selectedVerseNumForRead: "",
        selectedBookForRead: "",
        selectedChapterForRead: "",
        selectedBookNameForRead: "",
        selectedVerseForRead: "",
      ));
}

/// Entry point for streak flow. Call when navigating to Home; shows flow once per day first.
class StreakFlowNavigation {
  /// Show streak flow if not yet shown today, else go to Home.
  static Future<void> navigateToStreakFlowOrHome(BuildContext context) async {
    final today =
        DateTime.now().toIso8601String().split('T')[0];
    final last = await SharPreferences.getString(
        SharPreferences.streakFlowLastShownDate);
    if (last == today) {
      _goToHome(context);
      return;
    }
    if (!context.mounted) return;
    Get.offAll(() => const StreakConnectionScreen());
  }
}

/// 1. How is your connection with God today?
class StreakConnectionScreen extends StatefulWidget {
  const StreakConnectionScreen({super.key});

  @override
  State<StreakConnectionScreen> createState() => _StreakConnectionScreenState();
}

class _StreakConnectionScreenState extends State<StreakConnectionScreen> {
  double _value = 0.5; // 0=Far, 0.5=Near, 1=Deeply Connected

  int get _connectionIndex {
    if (_value < 0.35) return 0;
    if (_value < 0.65) return 1;
    return 2;
  }

  double _snap(double v) => (v * 2).round() / 2;

  @override
  Widget build(BuildContext context) {
    final active = _connectionIndex;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8DED0),
              Color(0xFFD4C4B0),
              Color(0xFFC9B896),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: _kStreakBrown),
                  onPressed: () => _goToHome(context),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'How is your connection with God today?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width > 450 ? 28 : 22,
                    fontWeight: FontWeight.w600,
                    color: _kStreakBrown,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pause and reflect for a moment.',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 450 ? 18 : 15,
                  color: _kStreakBrown.withOpacity(0.9),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Far',
                              style: _labelStyle(context, active: active == 0)),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text('Near',
                              style: _labelStyle(context, active: active == 1)),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('Deeply\nConnected',
                              textAlign: TextAlign.right,
                              style: _labelStyle(context, active: active == 2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _kStreakBrown,
                        inactiveTrackColor: _kStreakCream,
                        thumbColor: Colors.white,
                        overlayColor: _kStreakBrown.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _value,
                        divisions: 2,
                        onChanged: (v) => setState(() => _value = _snap(v)),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _parchmentButton(
                context,
                label: 'Take the Next Step',
                onPressed: () async {
                  final item = await MoodPrayerLoader.pickItem(
                      connectionIndex: _connectionIndex);
                  if (!mounted) return;
                  if (item == null) {
                    _goToHome(context);
                    return;
                  }
                  Get.to(() => StreakVerseScreen(item: item));
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context, {required bool active}) {
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 16 : 14,
      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
      color: active ? _kStreakBrown : _kStreakBrown.withOpacity(0.7),
      fontFamily: 'Georgia',
    );
  }
}

Widget _parchmentButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8DCC8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _kStreakBrown, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _kStreakBrown.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 450 ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: _kStreakBrown,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: _kStreakBrown, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 2. Verse of the Day
class StreakVerseScreen extends StatefulWidget {
  const StreakVerseScreen({super.key, required this.item});
  final MoodPrayerItem item;

  @override
  State<StreakVerseScreen> createState() => _StreakVerseScreenState();
}

class _StreakVerseScreenState extends State<StreakVerseScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE5D5C4),
              Color(0xFFD9C9B8),
              Color(0xFFCFC0A8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: _kStreakBrown),
                  onPressed: () => Get.back(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, color: _kStreakBrown, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Verse of the Day',
                    style: TextStyle(
                      fontSize:
                          MediaQuery.of(context).size.width > 450 ? 24 : 20,
                      fontWeight: FontWeight.w600,
                      color: _kStreakBrown,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '"${item.verseText}"',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width > 450
                                    ? 20
                                    : 17,
                                height: 1.5,
                                color: _kStreakBrown,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '- ${item.verseReference}',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: _kStreakBrown,
                                fontFamily: 'Georgia',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _saved ? Icons.bookmark : Icons.bookmark_border,
                        color: _kStreakBrown,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() => _saved = !_saved);
                        _showSavedToast(context, saved: _saved);
                      },
                    ),
                    Flexible(
                      child: _parchmentButton(
                        context,
                        label: 'Read Devotional',
                        onPressed: () =>
                            Get.to(() => StreakDevotionalScreen(item: item)),
                      ),
                    ),
                    Builder(
                      builder: (shareContext) => IconButton(
                        icon: const Icon(Icons.share,
                            color: _kStreakBrown, size: 26),
                        onPressed: () => _shareText(
                            shareContext, '${item.verseText}\n- ${item.verseReference}'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3. Devotional Insight
class StreakDevotionalScreen extends StatefulWidget {
  const StreakDevotionalScreen({super.key, required this.item});
  final MoodPrayerItem item;

  @override
  State<StreakDevotionalScreen> createState() => _StreakDevotionalScreenState();
}

class _StreakDevotionalScreenState extends State<StreakDevotionalScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE2D8CC),
              Color(0xFFD5C8BC),
              Color(0xFFCBBEAF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: _kStreakBrown),
                  onPressed: () => Get.back(),
                ),
              ),
              Text(
                'Devotional Insight',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 450 ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: _kStreakBrown,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Today\'s Devotional',
                style: TextStyle(
                  fontSize: 16,
                  color: _kStreakBrown.withOpacity(0.9),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    item.devotionalText,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 450 ? 18 : 16,
                      height: 1.6,
                      color: _kStreakBrown,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _saved ? Icons.bookmark : Icons.bookmark_border,
                        color: _kStreakBrown,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() => _saved = !_saved);
                        _showSavedToast(context, saved: _saved);
                      },
                    ),
                    Flexible(
                      child: _parchmentButton(
                        context,
                        label: 'Continue to Prayer',
                        onPressed: () =>
                            Get.to(() => StreakPrayerScreen(item: item)),
                      ),
                    ),
                    Builder(
                      builder: (shareContext) => IconButton(
                        icon: const Icon(Icons.share,
                            color: _kStreakBrown, size: 26),
                        onPressed: () => _shareText(shareContext, item.devotionalText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4. Prayer for Today
class StreakPrayerScreen extends StatefulWidget {
  const StreakPrayerScreen({super.key, required this.item});
  final MoodPrayerItem item;

  @override
  State<StreakPrayerScreen> createState() => _StreakPrayerScreenState();
}

class _StreakPrayerScreenState extends State<StreakPrayerScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFD8CFC4),
              const Color(0xFFCEC4B8),
              const Color(0xFFC4B8A8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: _kStreakBrown),
                  onPressed: () => Get.back(),
                ),
              ),
              Text(
                'Prayer for Today',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 450 ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: _kStreakBrown,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A Prayer of Gratitude',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kStreakBrown,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    item.prayerText,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 450 ? 18 : 16,
                      height: 1.7,
                      color: _kStreakBrown,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _saved ? Icons.bookmark : Icons.bookmark_border,
                        color: _kStreakBrown,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() => _saved = !_saved);
                        _showSavedToast(context, saved: _saved);
                      },
                    ),
                    Flexible(
                      child: _parchmentButton(
                        context,
                        label: 'Amen',
                        onPressed: () async {
                          await StreakService.recordActivity();
                          await SharPreferences.setString(
                              SharPreferences.streakFlowLastShownDate,
                              DateTime.now().toIso8601String().split('T')[0]);
                          if (!context.mounted) return;
                          Get.offAll(() => const StreakCompletedScreen());
                        },
                      ),
                    ),
                    Builder(
                      builder: (shareContext) => IconButton(
                        icon: const Icon(Icons.share,
                            color: _kStreakBrown, size: 26),
                        onPressed: () => _shareText(shareContext, item.prayerText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 5. Daily Streak Completed!
class StreakCompletedScreen extends StatelessWidget {
  const StreakCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kStreakCream,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B7355),
                border: Border.all(color: _kStreakGold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _kStreakGold.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Daily Streak Completed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 450 ? 26 : 22,
                fontWeight: FontWeight.w700,
                color: _kStreakBrown,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re walking faithfully today.',
              style: TextStyle(
                fontSize: 16,
                color: _kStreakBrown,
                fontFamily: 'Georgia',
              ),
            ),
            Text(
              'Keep the light alive.',
              style: TextStyle(
                fontSize: 16,
                color: _kStreakBrown,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kStreakGold, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    'REWARD EARNED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: _kStreakBrown,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on,
                          color: _kStreakGold, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '+20 Faith Credits',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _kStreakBrown,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Added to your Wallet',
                    style: TextStyle(
                      fontSize: 14,
                      color: _kStreakBrown.withOpacity(0.8),
                      fontFamily: 'Georgia',
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: _parchmentButton(
                  context,
                  label: 'Continue My Journey',
                  onPressed: () => _goToHome(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
