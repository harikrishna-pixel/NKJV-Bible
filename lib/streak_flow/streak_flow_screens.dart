import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:biblebookapp/streak_flow/mood_prayer_data.dart';
import 'package:biblebookapp/streak_flow/streak_saved_storage.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/colors.dart';

// Streak flow colors (warm parchment / spiritual theme)
const Color _kStreakBrown = Color(0xFF3D2914);
const Color _kStreakGold = Color(0xFFC9A227);
const Color _kStreakCream = Color(0xFFF5F0E6);

bool _isStreakDark(BuildContext context) {
  try {
    return Provider.of<ThemeProvider>(context, listen: false).themeMode == ThemeMode.dark;
  } catch (_) {
    return false;
  }
}

List<Color> _streakGradientColors(BuildContext context) {
  try {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (themeProvider.themeMode == ThemeMode.dark) {
      final Color dark = CommanColor.darkPrimaryColor;
      return [dark, dark, dark];
    }
    final Color bg = themeProvider.backgroundColor;
    return [bg, bg, bg];
  } catch (_) {
    return [const Color(0xFFE8DED0), const Color(0xFFD4C4B0), const Color(0xFFC9B896)];
  }
}

Color _streakTextColor(BuildContext context) =>
    _isStreakDark(context) ? Colors.white : _kStreakBrown;

Color _streakPanelColor(BuildContext context) =>
    _isStreakDark(context) ? Colors.white.withOpacity(0.12) : _kStreakCream;

String _shareTextWithAppUrl(String content) {
  final androidLink =
      'https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}';
  final iosLink = 'https://itunes.apple.com/app/id${BibleInfo.apple_AppId}';
  final appUrl = Platform.isIOS ? iosLink : androidLink;
  return '$content\n\nRead more at: $appUrl';
}

Future<void> _shareText(BuildContext context, String text) async {
  try {
    final shareContent = _shareTextWithAppUrl(text);
    final RenderObject? renderObject = context.findRenderObject();
    final RenderBox? box = renderObject is RenderBox ? renderObject : null;
    await Share.share(
      shareContent,
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
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      duration: const Duration(milliseconds: 1400),
      backgroundColor: _kStreakCream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _kStreakBrown.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      content: Row(
        children: [
          Icon(
            saved ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
            color: _kStreakGold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            saved ? 'Saved' : 'Removed',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kStreakBrown,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
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

Widget _buildStepIndicator(BuildContext context, int step) {
  final textColor = _streakTextColor(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Step $step of 4',
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width > 450 ? 15 : 13,
          fontWeight: FontWeight.w600,
          color: textColor.withOpacity(0.9),
          fontFamily: 'Georgia',
        ),
      ),
      const SizedBox(height: 6),
      Transform.rotate(
        angle: 0.785398, // 45 degrees for diamond
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _kStreakGold,
            border: Border.all(
              color: _kStreakGold.withOpacity(0.8),
              width: 1,
            ),
          ),
        ),
      ),
    ],
  );
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
  // UI shows 5 stops (Far/Returning/Near/Close/Deeply Connected),
  // but we still map it into the existing 3 buckets for content selection.
  double _value = 0.5;

  @override
  void initState() {
    super.initState();
    _markStreakFlowStartedToday();
  }

  Future<void> _markStreakFlowStartedToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existing =
        await SharPreferences.getString(SharPreferences.streakFlowStartedDate);
    if (existing != today) {
      await SharPreferences.setString(
          SharPreferences.streakFlowStartedDate, today);
    }
  }

  int get _connectionIndex {
    // 0.00 (Far) + 0.25 (Returning) => bucket 0
    // 0.50 (Near) => bucket 1
    // 0.75 (Close) + 1.00 (Deeply Connected) => bucket 2
    if (_value <= 0.375) return 0;
    if (_value <= 0.625) return 1;
    return 2;
  }

  /// Which label to highlight for UI: 0=Far, 1=Returning, 2=Near, 3=Close, 4=Deeply Connected.
  /// Each slider position highlights its own label.
  int get _activeLabelIndex {
    if (_value <= 0.125) return 0;
    if (_value <= 0.375) return 1;
    if (_value <= 0.625) return 2;
    if (_value <= 0.875) return 3;
    return 4;
  }

  double _snap(double v) => (v * 4).round() / 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _streakGradientColors(context),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: _streakTextColor(context)),
                      onPressed: () => _goToHome(context),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(context, 1),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'How is your connection with God today?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width > 450 ? 28 : 22,
                    fontWeight: FontWeight.w600,
                    color: _streakTextColor(context),
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pause and reflect for a moment.',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 450 ? 18 : 15,
                  color: _streakTextColor(context).withOpacity(0.9),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Far',
                                  textAlign: TextAlign.center,
                                  style: _labelStyle(context, active: _activeLabelIndex == 0)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Returning',
                                textAlign: TextAlign.center,
                                style: _labelStyle(context, active: _activeLabelIndex == 1),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Near',
                                  textAlign: TextAlign.center,
                                  style: _labelStyle(context, active: _activeLabelIndex == 2)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Close',
                                textAlign: TextAlign.center,
                                style: _labelStyle(context, active: _activeLabelIndex == 3),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Deeply\nConnected',
                                  textAlign: TextAlign.center,
                                  style: _labelStyle(context, active: _activeLabelIndex == 4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _streakTextColor(context),
                        inactiveTrackColor: _streakPanelColor(context),
                        thumbColor: _streakTextColor(context),
                        overlayColor: _streakTextColor(context).withOpacity(0.2),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        activeTickMarkColor: Colors.transparent,
                        inactiveTickMarkColor: Colors.transparent,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double pad = 12;
                          final w = constraints.maxWidth - pad * 2;
                          const double smallR = 4.0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Slider(
                                value: _value,
                                divisions: 4,
                                onChanged: (v) => setState(() => _value = _snap(v)),
                              ),
                              for (int i = 0; i < 5; i++) ...[
                                Positioned(
                                  left: pad + (w * i / 4) - smallR,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Container(
                                      width: smallR * 2,
                                      height: smallR * 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _streakTextColor(context).withOpacity(0.35),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
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
    final c = _streakTextColor(context);
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 16 : 14,
      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
      color: active ? c : c.withOpacity(0.7),
      fontFamily: 'Georgia',
    );
  }
}

Widget _parchmentButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
}) {
  final isDark = _isStreakDark(context);
  final textColor = _streakTextColor(context);
  final btnBg = isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFE8DCC8);
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
            color: btnBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: textColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: textColor.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width > 450 ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: textColor, size: 20),
              ],
            ),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
  }

  Future<void> _loadSaved() async {
    final item = widget.item;
    final contained = await StreakSavedStorage.contains(
        'verse', item.verseReference, item.verseText);
    if (mounted) setState(() => _saved = contained);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back1.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _streakTextColor(context).withOpacity(0.08),
              _streakTextColor(context).withOpacity(0.12),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: _streakTextColor(context)),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(context, 2),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, color: _streakTextColor(context), size: 32),
                  const SizedBox(width: 8),
                  Text(
                    'Verse of the Day',
                    style: TextStyle(
                      fontSize:
                          MediaQuery.of(context).size.width > 450 ? 26 : 22,
                      fontWeight: FontWeight.w600,
                      color: _streakTextColor(context),
                      fontFamily: 'Georgia',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '"${item.verseText}"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width > 450
                                        ? 26
                                        : 22,
                                    height: 1.5,
                                    color: _streakTextColor(context),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '- ${item.verseReference}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    color: _streakTextColor(context),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                        color: _streakTextColor(context),
                        size: 28,
                      ),
                      onPressed: () async {
                        final item = widget.item;
                        if (_saved) {
                          await StreakSavedStorage.remove(
                              'verse', item.verseReference, item.verseText);
                          if (mounted) setState(() => _saved = false);
                          if (context.mounted) _showSavedToast(context, saved: false);
                        } else {
                          await StreakSavedStorage.add(StreakSavedItem(
                            type: 'verse',
                            title: item.verseReference,
                            body: item.verseText,
                            savedAt: DateTime.now().toIso8601String(),
                          ));
                          if (mounted) setState(() => _saved = true);
                          if (context.mounted) _showSavedToast(context, saved: true);
                        }
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
                        icon: Icon(Icons.share,
                            color: Colors.white , size: 26),
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
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  bool _isAudioMuted = false;
  static const String _backgroundMusicUrl =
      'music/christian-rock-for-jesus-christ-always-301257.mp3';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isAudioPlaying = state == PlayerState.playing);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSaved();
      _playBackgroundMusic();
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    if (_isAudioMuted) return;
    try {
      if (_audioPlayer.state == PlayerState.playing) return;
      if (_audioPlayer.state != PlayerState.stopped) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.setSource(AssetSource(_backgroundMusicUrl));
      await Future.delayed(const Duration(milliseconds: 200));
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
    } catch (e) {
      if (mounted) setState(() => _isAudioPlaying = false);
    }
  }

  Future<void> _toggleAudio() async {
    if (_isAudioMuted) {
      _isAudioMuted = false;
      if (_isAudioPlaying) {
        await _audioPlayer.resume();
      } else {
        await _playBackgroundMusic();
      }
    } else {
      _isAudioMuted = true;
      await _audioPlayer.pause();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadSaved() async {
    final item = widget.item;
    const title = "Today's Devotional";
    final contained = await StreakSavedStorage.contains(
        'devotional', title, item.devotionalText);
    if (mounted) setState(() => _saved = contained);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back2.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _streakTextColor(context).withOpacity(0.08),
              _streakTextColor(context).withOpacity(0.12),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: _streakTextColor(context)),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(context, 3),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleAudio,
                      icon: Icon(
                        _isAudioMuted ? Icons.music_off : Icons.music_note,
                        color: _streakTextColor(context),
                        size: 26,
                      ),
                      tooltip: _isAudioMuted ? 'Audio Off' : 'Audio On',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Today\'s Devotional',
                style: TextStyle(
                  fontSize: 18,
                  color: _streakTextColor(context).withOpacity(0.9),
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Text(
                            item.devotionalText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 450 ? 22 : 20,
                              height: 1.6,
                              color: _streakTextColor(context),
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                        color: _streakTextColor(context),
                        size: 28,
                      ),
                      onPressed: () async {
                        final item = widget.item;
                        const title = "Today's Devotional";
                        if (_saved) {
                          await StreakSavedStorage.remove(
                              'devotional', title, item.devotionalText);
                          if (mounted) setState(() => _saved = false);
                          if (context.mounted) _showSavedToast(context, saved: false);
                        } else {
                          await StreakSavedStorage.add(StreakSavedItem(
                            type: 'devotional',
                            title: title,
                            body: item.devotionalText,
                            savedAt: DateTime.now().toIso8601String(),
                          ));
                          if (mounted) setState(() => _saved = true);
                          if (context.mounted) _showSavedToast(context, saved: true);
                        }
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
                        icon: Icon(Icons.share,
                            color: _streakTextColor(shareContext), size: 26),
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
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  bool _isAudioMuted = false;
  static const String _backgroundMusicUrl =
      'music/christian-rock-for-jesus-christ-always-301257.mp3';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isAudioPlaying = state == PlayerState.playing);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSaved();
      _playBackgroundMusic();
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    if (_isAudioMuted) return;
    try {
      if (_audioPlayer.state == PlayerState.playing) return;
      if (_audioPlayer.state != PlayerState.stopped) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.setSource(AssetSource(_backgroundMusicUrl));
      await Future.delayed(const Duration(milliseconds: 200));
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
    } catch (e) {
      if (mounted) setState(() => _isAudioPlaying = false);
    }
  }

  Future<void> _toggleAudio() async {
    if (_isAudioMuted) {
      _isAudioMuted = false;
      if (_isAudioPlaying) {
        await _audioPlayer.resume();
      } else {
        await _playBackgroundMusic();
      }
    } else {
      _isAudioMuted = true;
      await _audioPlayer.pause();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadSaved() async {
    final item = widget.item;
    const title = 'A Prayer of Gratitude';
    final contained = await StreakSavedStorage.contains(
        'prayer', title, item.prayerText);
    if (mounted) setState(() => _saved = contained);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back3.jpeg'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _streakTextColor(context).withOpacity(0.08),
              _streakTextColor(context).withOpacity(0.12),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: _streakTextColor(context)),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(context, 4),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleAudio,
                      icon: Icon(
                        _isAudioMuted ? Icons.music_off : Icons.music_note,
                        color: _streakTextColor(context),
                        size: 26,
                      ),
                      tooltip: _isAudioMuted ? 'Audio Off' : 'Audio On',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A Prayer of Gratitude',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _streakTextColor(context),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Text(
                            item.prayerText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 450 ? 22 : 20,
                              height: 1.7,
                              color: _streakTextColor(context),
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                        color: _streakTextColor(context),
                        size: 28,
                      ),
                      onPressed: () async {
                        final item = widget.item;
                        const title = 'A Prayer of Gratitude';
                        if (_saved) {
                          await StreakSavedStorage.remove(
                              'prayer', title, item.prayerText);
                          if (mounted) setState(() => _saved = false);
                          if (context.mounted) _showSavedToast(context, saved: false);
                        } else {
                          await StreakSavedStorage.add(StreakSavedItem(
                            type: 'prayer',
                            title: title,
                            body: item.prayerText,
                            savedAt: DateTime.now().toIso8601String(),
                          ));
                          if (mounted) setState(() => _saved = true);
                          if (context.mounted) _showSavedToast(context, saved: true);
                        }
                      },
                    ),
                    Flexible(
                      child: _parchmentButton(
                        context,
                        label: 'Amen',
                        onPressed: () async {
                          await StreakService.recordActivity();
                          final today =
                              DateTime.now().toIso8601String().split('T')[0];
                          final lastAwarded = await SharPreferences.getString(
                              SharPreferences.streakFlowCreditsAwardedDate);
                          if (lastAwarded != today) {
                            await WalletService.addCredits(20);
                            await SharPreferences.setString(
                                SharPreferences.streakFlowCreditsAwardedDate,
                                today);
                          }
                          await SharPreferences.setString(
                              SharPreferences.streakFlowLastShownDate,
                              DateTime.now().toIso8601String().split('T')[0]);
                          if (!context.mounted) return;
                          final streakCount = await StreakService.getCurrentStreak();
                          await SharPreferences.setInt(
                              SharPreferences.pendingStreakCompleteCelebration,
                              streakCount);
                          if (!context.mounted) return;
                          Get.offAll(() => const StreakCompletedScreen());
                        },
                      ),
                    ),
                    Builder(
                      builder: (shareContext) => IconButton(
                        icon: Icon(Icons.share,
                            color: _streakTextColor(shareContext), size: 26),
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
    final isDark = _isStreakDark(context);
    final textColor = _streakTextColor(context);
    final bgColor = isDark ? CommanColor.darkPrimaryColor : _kStreakCream;
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white24 : const Color(0xFF8B7355),
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
                color: textColor,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re walking faithfully today.',
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontFamily: 'Georgia',
              ),
            ),
            Text(
              'Keep the light alive.',
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: _streakPanelColor(context),
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
                      color: textColor,
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
                          color: textColor,
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
                      color: textColor.withOpacity(0.8),
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
