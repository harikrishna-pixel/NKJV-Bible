import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:biblebookapp/streak_flow/mood_prayer_data.dart';
import 'package:biblebookapp/streak_flow/streak_saved_storage.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/colors.dart';

// Color constants for streak completion screen
const Color _kParchmentLight = Color(0xFFF5EAC6);
const Color _kParchmentMid = Color(0xFFECE3CB);
const Color _kInkBrown = Color(0xFF4A2F1D);
const Color _kInkSepia = Color(0xFF6B4E37);
const Color _kCandleGold = Color(0xFFC9A227);
const Color _kCandleGlow = Color(0xFFFFF6D5);

// Streak flow colors (warm parchment / spiritual theme)
const Color _kStreakBrown = Color(0xFF3D2914);
const Color _kStreakGold = Color(0xFFC9A227);
const Color _kStreakCream = Color(0xFFF5F0E6);

/// Shared background music for Streak Flow (Devotional + Prayer).
/// Keeps playback continuous and preserves mute state across screens.
class _StreakFlowBgMusic {
  static const String _asset =
      'music/christian-rock-for-jesus-christ-always-301257.mp3';
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Keep audio stable across route transitions (prevents perceived stop/restart).
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
      await _player.setSource(AssetSource(_asset));
    } catch (_) {
      // ignore
    }
  }

  static Future<bool> getMuted() async {
    return (await SharPreferences.getBoolean(
            SharPreferences.streakFlowMusicMuted)) ??
        false;
  }

  static Future<void> setMuted(bool muted) async {
    await SharPreferences.setBoolean(
        SharPreferences.streakFlowMusicMuted, muted);
    try {
      if (muted) {
        await _player.pause();
      } else {
        await play();
      }
    } catch (_) {
      // ignore
    }
  }

  static Future<void> play() async {
    await _init();
    final muted = await getMuted();
    if (muted) return;
    try {
      if (_player.state == PlayerState.playing) return;
      await _player.resume();
    } catch (_) {
      // ignore
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // ignore
    }
  }
}

/// Track shape that uses full available width (no side insets).
class _FullWidthSliderTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2.0;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

bool _isStreakDark(BuildContext context) {
  try {
    return Provider.of<ThemeProvider>(context, listen: false).themeMode ==
        ThemeMode.dark;
  } catch (_) {
    return false;
  }
}

/// Old-paper (parchment) colors for Streak Flow; avoids app default (e.g. light yellow).
List<Color> _streakGradientColors(BuildContext context) {
  try {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (themeProvider.themeMode == ThemeMode.dark) {
      final Color dark = CommanColor.darkPrimaryColor;
      return [dark, dark, dark];
    }
    // Use fixed old-paper palette so Connection and Streak Flow feel consistent.
    return [
      const Color(0xFFE8DED0),
      const Color(0xFFD4C4B0),
      const Color(0xFFC9B896),
    ];
  } catch (_) {
    return [
      const Color(0xFFE8DED0),
      const Color(0xFFD4C4B0),
      const Color(0xFFC9B896)
    ];
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
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  } catch (_) {
    // ignore
  }
}

Future<void> _shareAsImage(
  BuildContext context, {
  Uint8List? imageBytes,
  required String fallbackText,
}) async {
  if (imageBytes != null && imageBytes.isNotEmpty) {
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/streak_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(imageBytes);
      final shareText = _shareTextWithAppUrl(fallbackText);
      await Share.shareXFiles([XFile(path)], text: shareText);
      return;
    } catch (_) {
      // fall through to text share
    }
  }
  if (context.mounted) _shareText(context, fallbackText);
}

void _showSavedToast(BuildContext context, {required bool saved}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      // Keep toast above bottom CTAs (Devotional/Prayer screens).
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
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
            saved
                ? Icons.bookmark_added_rounded
                : Icons.bookmark_remove_rounded,
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

void _showAppleToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 28,
      right: 28,
      bottom: 80,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.82),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1400), () {
    entry.remove();
  });
}

Future<Map<String, int>> _readStreakFlowStepsByDay() async {
  final raw =
      await SharPreferences.getString(SharPreferences.streakFlowStepsByDay);
  if (raw == null || raw.trim().isEmpty) return <String, int>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, int>{};
    return decoded.map((key, value) {
      final v =
          value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0;
      return MapEntry(key.toString(), v);
    });
  } catch (_) {
    return <String, int>{};
  }
}

Future<void> _storeStreakFlowStepsForDay(String dayKey, int steps) async {
  final safeDayKey = dayKey.trim();
  if (safeDayKey.isEmpty) return;
  final map = await _readStreakFlowStepsByDay();
  map[safeDayKey] = steps.clamp(0, 4);
  await SharPreferences.setString(
    SharPreferences.streakFlowStepsByDay,
    jsonEncode(map),
  );
}

Future<String> _currentStreakFlowProgressDayKey() async {
  final isRestoreRun = (await SharPreferences.getBoolean(
          SharPreferences.streakFlowRestoreActive)) ==
      true;
  if (isRestoreRun) {
    final restoreDate =
        await SharPreferences.getString(SharPreferences.streakFlowRestoreDate);
    if (restoreDate != null && restoreDate.trim().isNotEmpty) {
      return restoreDate;
    }
  }
  final started =
      await SharPreferences.getString(SharPreferences.streakFlowStartedDate);
  if (started != null && started.trim().isNotEmpty) {
    return started;
  }
  return DateTime.now().toIso8601String().split('T')[0];
}

Future<void> _storeActiveStreakFlowSteps(int steps) async {
  final dayKey = await _currentStreakFlowProgressDayKey();
  await _storeStreakFlowStepsForDay(dayKey, steps);
}

Future<Map<String, dynamic>> _readStreakFlowItemByDay() async {
  final raw =
      await SharPreferences.getString(SharPreferences.streakFlowItemByDay);
  if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
  } catch (_) {}
  return <String, dynamic>{};
}

Map<String, dynamic> _serializeMoodPrayerItem(MoodPrayerItem item) {
  return {
    'connectionLevel': item.connectionLevel,
    'bookName': item.bookName,
    'bookNumber': item.bookNumber,
    'chapterNumber': item.chapterNumber,
    'verseNumber': item.verseNumber,
    'verseText': item.verseText,
    'devotionalText': item.devotionalText,
    'prayerText': item.prayerText,
    if (item.connectionSliderValue != null)
      'connectionSliderValue': item.connectionSliderValue,
  };
}

Future<void> _storeActiveStreakFlowItem(MoodPrayerItem item) async {
  final dayKey = await _currentStreakFlowProgressDayKey();
  final map = await _readStreakFlowItemByDay();
  map[dayKey] = _serializeMoodPrayerItem(item);
  await SharPreferences.setString(
    SharPreferences.streakFlowItemByDay,
    jsonEncode(map),
  );
}

Future<void> _recordStreakActivityForDay(String dayKey) async {
  final normalizedDay = dayKey.trim();
  if (normalizedDay.isEmpty) return;

  final lastStr =
      await SharPreferences.getString(SharPreferences.streakLastActivityDate);
  final prevCount =
      await SharPreferences.getInt(SharPreferences.streakCount) ?? 0;
  int newCount = 1;

  if (lastStr != null && lastStr.isNotEmpty) {
    try {
      final last = DateTime.parse(lastStr);
      final target = DateTime.parse(normalizedDay);
      final lastDate = DateTime(last.year, last.month, last.day);
      final targetDate = DateTime(target.year, target.month, target.day);
      final diffDays = targetDate.difference(lastDate).inDays;
      if (diffDays == 1) {
        newCount = prevCount + 1;
      } else if (diffDays == 0) {
        newCount = prevCount > 0 ? prevCount : 1;
      } else {
        newCount = 1;
      }
    } catch (_) {
      newCount = 1;
    }
  }

  await SharPreferences.setString(
      SharPreferences.streakLastActivityDate, normalizedDay);
  await SharPreferences.setInt(SharPreferences.streakCount, newCount);
}

void _goToHome(BuildContext context) {
  Get.offAll(
    () => HomeScreen(
      From: "splash",
      selectedVerseNumForRead: "",
      selectedBookForRead: "",
      selectedChapterForRead: "",
      selectedBookNameForRead: "",
      selectedVerseForRead: "",
    ),
    transition: Transition.cupertino,
    duration: const Duration(milliseconds: 350),
  );
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
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayDate = DateTime.now();
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    final dayBeforeYesterdayDate = todayDate.subtract(const Duration(days: 2));
    final yesterday =
        DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day)
            .toIso8601String()
            .split('T')[0];
    final dayBeforeYesterday = DateTime(
      dayBeforeYesterdayDate.year,
      dayBeforeYesterdayDate.month,
      dayBeforeYesterdayDate.day,
    ).toIso8601String().split('T')[0];
    final last = await SharPreferences.getString(
        SharPreferences.streakFlowLastShownDate);
    final dismissed = await SharPreferences.getString(
        SharPreferences.streakFlowDismissedDate);
    final started =
        await SharPreferences.getString(SharPreferences.streakFlowStartedDate);
    final steps = await SharPreferences.getInt(
            SharPreferences.streakFlowStepsCompletedToday) ??
        0;

    final isIncompleteYesterday = started != null &&
        started.isNotEmpty &&
        started == yesterday &&
        last != yesterday &&
        steps > 0;
    final isMissedYesterdayWithoutOpen = (last == dayBeforeYesterday);

    if (isIncompleteYesterday || isMissedYesterdayWithoutOpen) {
      await SharPreferences.setString(
        SharPreferences.streakFlowPausedDate,
        isIncompleteYesterday ? started : yesterday,
      );
      final pausedAt =
          await SharPreferences.getString(SharPreferences.streakFlowPausedAt);
      if (pausedAt == null || pausedAt.isEmpty) {
        await SharPreferences.setString(
          SharPreferences.streakFlowPausedAt,
          DateTime.now().toIso8601String(),
        );
      }
      if (!context.mounted) return;
      Get.offAll(() => const StreakPausedScreen());
      return;
    }

    if (last == today || dismissed == today) {
      _goToHome(context);
      return;
    }
    if (!context.mounted) return;
    Get.offAll(() => const StreakConnectionScreen());
  }
}

class StreakPausedScreen extends StatefulWidget {
  const StreakPausedScreen({super.key});

  @override
  State<StreakPausedScreen> createState() => _StreakPausedScreenState();
}

class _StreakPausedScreenState extends State<StreakPausedScreen> {
  static const int _restoreCost = 50;
  bool _busy = false;
  String _pausedDate = '';

  @override
  void initState() {
    super.initState();
    _loadPausedDate();
  }

  Future<void> _loadPausedDate() async {
    final paused =
        await SharPreferences.getString(SharPreferences.streakFlowPausedDate);
    if (!mounted) return;
    setState(() => _pausedDate = paused ?? '');
  }

  Future<bool> _isRestoreWindowOpen() async {
    final raw =
        await SharPreferences.getString(SharPreferences.streakFlowPausedAt);
    if (raw == null || raw.isEmpty) return true;
    try {
      final pausedAt = DateTime.parse(raw);
      return DateTime.now().difference(pausedAt).inHours <= 24;
    } catch (_) {
      return true;
    }
  }

  void _showInsufficientCreditsToast() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Insufficient credits',
              style: TextStyle(color: Colors.white),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  messenger.hideCurrentSnackBar();
                  await Get.to(() => const WalletScreen());
                  await _tryRestore();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kStreakGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Get credits',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.9),
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _tryRestore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final canRestore = await _isRestoreWindowOpen();
    if (!canRestore) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Restore is available only within 24 hours.')),
        );
      }
      if (mounted) setState(() => _busy = false);
      return;
    }

    final credits = await WalletService.getCredits();
    if (credits < _restoreCost) {
      if (mounted) _showInsufficientCreditsToast();
      if (mounted) setState(() => _busy = false);
      return;
    }

    final debited = await WalletService.deductCredits(_restoreCost);
    if (!debited) {
      if (mounted) _showInsufficientCreditsToast();
      if (mounted) setState(() => _busy = false);
      return;
    }

    await SharPreferences.setBoolean(
        SharPreferences.streakFlowRestoreActive, true);
    await SharPreferences.setString(
      SharPreferences.streakFlowRestoreDate,
      _pausedDate.isNotEmpty
          ? _pausedDate
          : DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String()
              .split('T')[0],
    );
    await SharPreferences.setInt(
        SharPreferences.streakFlowStepsCompletedToday, 0);
    await SharPreferences.setString(
      SharPreferences.streakFlowStartedDate,
      DateTime.now().toIso8601String().split('T')[0],
    );
    if (!mounted) return;
    _showAppleToast(context, 'Credits debited');
    Get.offAll(() => const StreakConnectionScreen());
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = _streakPanelColor(context);
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark = _isStreakDark(context);
    final warmText = isDark ? Colors.white : const Color(0xFF4A2F1D);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/back1.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _streakGradientColors(context).first.withOpacity(0.70),
              _streakGradientColors(context)[1].withOpacity(0.72),
              _streakGradientColors(context).last.withOpacity(0.74),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Scroll content first so the close control stays above and receives taps.
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    isTablet ? 30 : 22, 60, isTablet ? 30 : 22, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: isTablet ? 84 : 78,
                          height: isTablet ? 84 : 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _kStreakGold.withOpacity(0.9), width: 1.6),
                            boxShadow: [
                              BoxShadow(
                                color: _kStreakGold.withOpacity(0.18),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: isTablet ? 50 : 44,
                              height: isTablet ? 50 : 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _kStreakGold.withOpacity(0.9),
                                    width: 1.3),
                              ),
                              child: const Icon(Icons.pause,
                                  color: _kStreakGold, size: 24),
                            ),
                          ),
                        ),
                    const SizedBox(height: 22),
                    Text(
                      'Your Streak Paused',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 52 : 50,
                        fontWeight: FontWeight.w700,
                        color: warmText,
                        fontFamily: 'Georgia',
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'You missed a day - and that\'s okay.\nEvery journey has pauses.\nWhat matters is starting again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        height: 1.45,
                        color: warmText.withOpacity(0.9),
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<int?>(
                      future:
                          SharPreferences.getInt(SharPreferences.streakCount),
                      builder: (context, snap) {
                        final v = (snap.data ?? 0).clamp(0, 9999);
                        return Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: isTablet ? 25 : 22,
                                  fontWeight: FontWeight.w700,
                                  color: warmText,
                                  fontFamily: 'Georgia',
                                ),
                                children: [
                                  const TextSpan(text: 'You built a '),
                                  TextSpan(
                                    text: '$v Day Faith Habit.',
                                    style: const TextStyle(color: _kStreakGold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Continue your streak from yesterday',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: warmText.withOpacity(0.85),
                                fontFamily: 'Georgia',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                              color: warmText.withOpacity(0.24), thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.auto_awesome,
                              color: _kStreakGold.withOpacity(0.7), size: 14),
                        ),
                        Expanded(
                          child: Divider(
                              color: warmText.withOpacity(0.24), thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: panelColor.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: warmText.withOpacity(0.16), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          _buildParchmentButton(
                            context: context,
                            label:
                                _busy ? 'Please wait...' : 'Restore Yesterday',
                            onTap: _busy ? () {} : _tryRestore,
                            isSecondary: false,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Uses 50 Faith Credits',
                            style: TextStyle(
                              color: const Color(0xFFA94442).withOpacity(0.95),
                              fontSize: isTablet ? 17 : 16,
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Note: Yesterday Streaks can Restored within 24 hours',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: warmText.withOpacity(0.8),
                        fontSize: isTablet ? 14 : 13,
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: warmText.withOpacity(0.28),
                                thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: warmText.withOpacity(0.82),
                              fontFamily: 'Georgia',
                              fontSize: isTablet ? 22 : 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: warmText.withOpacity(0.28),
                                thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildParchmentButton(
                      context: context,
                      label: 'Start New Journey',
                      onTap: () => _goToHome(context),
                      isSecondary: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: isTablet ? 30 : 22,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _goToHome(context),
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(Icons.close,
                        size: 28, color: warmText.withOpacity(0.7)),
                  ),
                ),
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

/// 1. How is your connection with God today?
class StreakConnectionScreen extends StatefulWidget {
  const StreakConnectionScreen({
    super.key,
    this.viewOnly = false,
    this.initialSliderValue,
  });

  /// When true, slider is read-only and the flow does not advance / touch streak prefs.
  final bool viewOnly;

  /// Restored slider position from stored day item (0–1).
  final double? initialSliderValue;

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
    if (widget.initialSliderValue != null) {
      _value = _snap(widget.initialSliderValue!.clamp(0.0, 1.0));
    }
    if (!widget.viewOnly) {
      _markStreakFlowStartedToday();
    }
  }

  Future<void> _markStreakFlowStartedToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existing =
        await SharPreferences.getString(SharPreferences.streakFlowStartedDate);
    if (existing != today) {
      await SharPreferences.setString(
          SharPreferences.streakFlowStartedDate, today);
      // New day: reset step progress so we don't reuse a previous day's value.
      await SharPreferences.setInt(
          SharPreferences.streakFlowStepsCompletedToday, 0);
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
                      icon: Icon(Icons.arrow_back_ios,
                          color: _streakTextColor(context)),
                      onPressed: () async {
                        if (widget.viewOnly) {
                          if (context.mounted &&
                              Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Get.back();
                          }
                          return;
                        }
                        final today =
                            DateTime.now().toIso8601String().split('T')[0];
                        await SharPreferences.setString(
                            SharPreferences.streakFlowDismissedDate, today);
                        _goToHome(context);
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(context, 1),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _streakTextColor(context)),
                      onPressed: () => _goToHome(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 60),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'How is your connection with God today?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 450
                                ? 28
                                : 22,
                            fontWeight: FontWeight.w600,
                            color: _streakTextColor(context),
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pause and reflect for a moment.',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 450
                                ? 18
                                : 15,
                            color: _streakTextColor(context).withOpacity(0.9),
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 140),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                            style: _labelStyle(context,
                                                active:
                                                    _activeLabelIndex == 0)),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: AnimatedOpacity(
                                        opacity: _activeLabelIndex == 1 ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 160),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Returning',
                                            textAlign: TextAlign.center,
                                            style: _labelStyle(context,
                                                active: _activeLabelIndex == 1),
                                          ),
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
                                            style: _labelStyle(context,
                                                active:
                                                    _activeLabelIndex == 2)),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: AnimatedOpacity(
                                        opacity: _activeLabelIndex == 3 ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 160),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Close',
                                            textAlign: TextAlign.center,
                                            style: _labelStyle(context,
                                                active: _activeLabelIndex == 3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('Seeking',
                                            textAlign: TextAlign.center,
                                            style: _labelStyle(context,
                                                active:
                                                    _activeLabelIndex == 4)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _streakTextColor(context),
                                  inactiveTrackColor:
                                      _streakPanelColor(context),
                                  trackShape: const _FullWidthSliderTrackShape(),
                                  thumbColor: _streakTextColor(context),
                                  overlayColor: _streakTextColor(context)
                                      .withOpacity(0.2),
                                  trackHeight: 6,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 12),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 20),
                                  activeTickMarkColor: Colors.transparent,
                                  inactiveTickMarkColor: Colors.transparent,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    const double smallR = 4.0;
                                    final trackW = constraints.maxWidth;
                                    final usable = trackW - (smallR * 2);
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Slider(
                                          value: _value,
                                          divisions: 4,
                                          onChanged: widget.viewOnly
                                              ? null
                                              : (v) => setState(
                                                  () => _value = _snap(v)),
                                        ),
                                        for (int i = 0; i < 5; i++) ...[
                                          Positioned(
                                            left: usable * (i / 4),
                                            top: 0,
                                            bottom: 0,
                                            child: Center(
                                              child: Container(
                                                width: smallR * 2,
                                                height: smallR * 2,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      _streakTextColor(context)
                                                          .withOpacity(0.35),
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
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: widget.viewOnly
                    ? const SizedBox.shrink()
                    : _parchmentButton(
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
                          await _storeActiveStreakFlowItem(
                            item.copyWith(connectionSliderValue: _value),
                          );
                          await SharPreferences.setInt(
                              SharPreferences.streakFlowStepsCompletedToday, 1);
                          await _storeActiveStreakFlowSteps(1);
                          if (!mounted) return;
                          Get.to(() => StreakVerseScreen(item: item));
                        },
                      ),
              ),
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

/// Helper for StreakPausedScreen buttons with proper dark mode support
Widget _buildParchmentButton({
  required BuildContext context,
  required String label,
  required VoidCallback onTap,
  bool isSecondary = false,
}) {
  final isDark = _isStreakDark(context);
  final warmText = isDark ? Colors.white : const Color(0xFF4A2F1D);
  
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSecondary 
              ? (isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.42))
              : (isDark ? const Color(0xFF3B2A1A) : _kStreakGold),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSecondary 
                ? _kStreakGold.withOpacity(0.55)
                : (isDark ? _kStreakGold : Colors.transparent),
            width: isSecondary ? 1.5 : (isDark ? 1.5 : 0),
          ),
          boxShadow: [
            if (!isSecondary)
              BoxShadow(
                color: _kStreakGold.withOpacity(isDark ? 0.3 : 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isSecondary) ...[
              const Icon(Icons.local_fire_department,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSecondary ? warmText : Colors.white,
                fontSize: MediaQuery.of(context).size.width > 450 ? 22 : 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Georgia',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _parchmentButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
}) {
  final isDark = _isStreakDark(context);
  final baseTextColor = _streakTextColor(context);
  final btnBg =
      isDark ? const Color(0xFF3B2A1A) : CommanColor.lightDarkPrimary(context);
  final labelColor = isDark ? _kParchmentLight : Colors.white;
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
            border: Border.all(
                color: isDark ? _kCandleGold : Colors.transparent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? _kCandleGold : baseTextColor).withOpacity(0.15),
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
                    color: labelColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: labelColor, size: 20),
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
  const StreakVerseScreen({
    super.key,
    required this.item,
    this.viewOnly = false,
  });
  final MoodPrayerItem item;
  final bool viewOnly;

  @override
  State<StreakVerseScreen> createState() => _StreakVerseScreenState();
}

class _StreakVerseScreenState extends State<StreakVerseScreen> {
  bool _saved = false;
  final ScreenshotController _screenshotController = ScreenshotController();

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
                      icon: Icon(Icons.arrow_back_ios,
                          color: _streakTextColor(context)),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(context, 2),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _streakTextColor(context)),
                      onPressed: () => _goToHome(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book,
                      color: _streakTextColor(context), size: 32),
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
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Screenshot(
                            controller: _screenshotController,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                // color: _streakPanelColor(context).withOpacity(
                                //     _isStreakDark(context) ? 0.18 : 0.88),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _streakTextColor(context).withOpacity(
                                      _isStreakDark(context) ? 0.18 : 0.12),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                        _isStreakDark(context) ? 0.18 : 0.10),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '"${item.verseText}"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width >
                                                  450
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
                      ),
                    );
                  },
                ),
              ),
              if (!widget.viewOnly)
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
                            if (context.mounted)
                              _showSavedToast(context, saved: false);
                          } else {
                            await StreakSavedStorage.add(StreakSavedItem(
                              type: 'verse',
                              title: item.verseReference,
                              body: item.verseText,
                              savedAt: DateTime.now().toIso8601String(),
                            ));
                            if (mounted) setState(() => _saved = true);
                            if (context.mounted)
                              _showSavedToast(context, saved: true);
                          }
                        },
                      ),
                      Flexible(
                        child: _parchmentButton(
                          context,
                          label: 'Read Devotional',
                          onPressed: () async {
                            await SharPreferences.setInt(
                                SharPreferences.streakFlowStepsCompletedToday,
                                2);
                            await _storeActiveStreakFlowSteps(2);
                            if (!mounted) return;
                            Get.to(() => StreakDevotionalScreen(
                                  item: item,
                                  viewOnly: widget.viewOnly,
                                ));
                          },
                        ),
                      ),
                      Builder(
                        builder: (shareContext) => IconButton(
                          icon:
                              Icon(Icons.share, color: Colors.white, size: 26),
                          onPressed: () async {
                            final image = await _screenshotController.capture(
                              delay: const Duration(milliseconds: 80),
                            );
                            if (shareContext.mounted) {
                              await _shareAsImage(
                                shareContext,
                                imageBytes: image,
                                fallbackText:
                                    '${item.verseText}\n- ${item.verseReference}',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3. Devotional Insight
class StreakDevotionalScreen extends StatefulWidget {
  const StreakDevotionalScreen({
    super.key,
    required this.item,
    this.viewOnly = false,
  });
  final MoodPrayerItem item;
  final bool viewOnly;

  @override
  State<StreakDevotionalScreen> createState() => _StreakDevotionalScreenState();
}

class _StreakDevotionalScreenState extends State<StreakDevotionalScreen> {
  bool _saved = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isAudioMuted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSaved();
      _loadMusicMuted();
      _StreakFlowBgMusic.play();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadMusicMuted() async {
    final muted = await _StreakFlowBgMusic.getMuted();
    if (mounted) setState(() => _isAudioMuted = muted);
  }

  Future<void> _toggleAudio() async {
    final next = !_isAudioMuted;
    await _StreakFlowBgMusic.setMuted(next);
    if (mounted) setState(() => _isAudioMuted = next);
  }

  Future<void> _loadSaved() async {
    final item = widget.item;
    const title = "Devotional Moment";
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
                      icon: Icon(Icons.arrow_back_ios,
                          color: _streakTextColor(context)),
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
                    IconButton(
                      icon: Icon(Icons.close, color: _streakTextColor(context)),
                      onPressed: () async {
                        await _StreakFlowBgMusic.stop();
                        if (context.mounted) _goToHome(context);
                      },
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Devotional Moment',
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
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Screenshot(
                            controller: _screenshotController,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                item.devotionalText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width > 450
                                          ? 22
                                          : 20,
                                  height: 1.6,
                                  color: _streakTextColor(context),
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!widget.viewOnly)
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
                          const title = "Devotional Moment";
                          if (_saved) {
                            await StreakSavedStorage.remove(
                                'devotional', title, item.devotionalText);
                            if (mounted) setState(() => _saved = false);
                            if (context.mounted)
                              _showSavedToast(context, saved: false);
                          } else {
                            await StreakSavedStorage.add(StreakSavedItem(
                              type: 'devotional',
                              title: title,
                              body: item.devotionalText,
                              savedAt: DateTime.now().toIso8601String(),
                            ));
                            if (mounted) setState(() => _saved = true);
                            if (context.mounted)
                              _showSavedToast(context, saved: true);
                          }
                        },
                      ),
                      Flexible(
                        child: _parchmentButton(
                          context,
                          label: 'Continue to Prayer',
                          onPressed: () async {
                            await SharPreferences.setInt(
                                SharPreferences.streakFlowStepsCompletedToday,
                                3);
                            await _storeActiveStreakFlowSteps(3);
                            if (!mounted) return;
                            // Keep music continuous into Prayer; do not stop/restart.
                            Get.to(() => StreakPrayerScreen(
                                  item: item,
                                  viewOnly: widget.viewOnly,
                                ));
                          },
                        ),
                      ),
                      Builder(
                        builder: (shareContext) => IconButton(
                          icon: Icon(Icons.share,
                              color: _streakTextColor(shareContext), size: 26),
                          onPressed: () async {
                            final image = await _screenshotController.capture(
                              delay: const Duration(milliseconds: 80),
                            );
                            if (shareContext.mounted) {
                              await _shareAsImage(
                                shareContext,
                                imageBytes: image,
                                fallbackText: item.devotionalText,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4. Prayer for Today
class StreakPrayerScreen extends StatefulWidget {
  const StreakPrayerScreen({
    super.key,
    required this.item,
    this.viewOnly = false,
  });
  final MoodPrayerItem item;
  final bool viewOnly;

  @override
  State<StreakPrayerScreen> createState() => _StreakPrayerScreenState();
}

class _StreakPrayerScreenState extends State<StreakPrayerScreen> {
  bool _saved = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isAudioMuted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSaved();
      _loadMusicMuted();
      _StreakFlowBgMusic.play();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadMusicMuted() async {
    final muted = await _StreakFlowBgMusic.getMuted();
    if (mounted) setState(() => _isAudioMuted = muted);
  }

  Future<void> _toggleAudio() async {
    final next = !_isAudioMuted;
    await _StreakFlowBgMusic.setMuted(next);
    if (mounted) setState(() => _isAudioMuted = next);
  }

  Future<void> _loadSaved() async {
    final item = widget.item;
    const title = 'Prayer Moment';
    final contained =
        await StreakSavedStorage.contains('prayer', title, item.prayerText);
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
                      icon: Icon(Icons.arrow_back_ios,
                          color: _streakTextColor(context)),
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
                    IconButton(
                      icon: Icon(Icons.close, color: _streakTextColor(context)),
                      onPressed: () async {
                        await _StreakFlowBgMusic.stop();
                        if (context.mounted) _goToHome(context);
                      },
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prayer Moment',
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
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Screenshot(
                            controller: _screenshotController,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                item.prayerText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width > 450
                                          ? 22
                                          : 20,
                                  height: 1.7,
                                  color: _streakTextColor(context),
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!widget.viewOnly)
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
                          const title = 'Today\'s Prayer';
                          if (_saved) {
                            await StreakSavedStorage.remove(
                                'prayer', title, item.prayerText);
                            if (mounted) setState(() => _saved = false);
                            if (context.mounted)
                              _showSavedToast(context, saved: false);
                          } else {
                            await StreakSavedStorage.add(StreakSavedItem(
                              type: 'prayer',
                              title: title,
                              body: item.prayerText,
                              savedAt: DateTime.now().toIso8601String(),
                            ));
                            if (mounted) setState(() => _saved = true);
                            if (context.mounted)
                              _showSavedToast(context, saved: true);
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
                            final isRestoreRun =
                                await SharPreferences.getBoolean(SharPreferences
                                        .streakFlowRestoreActive) ==
                                    true;
                            final restoreDate = await SharPreferences.getString(
                                SharPreferences.streakFlowRestoreDate);
                            final completionDate = (isRestoreRun &&
                                    restoreDate != null &&
                                    restoreDate.isNotEmpty)
                                ? restoreDate
                                : DateTime.now()
                                    .toIso8601String()
                                    .split('T')[0];

                            await _storeStreakFlowStepsForDay(
                              completionDate,
                              4,
                            );
                            // When completing a restored day (e.g. yesterday), make sure streak count/date
                            // reflects that day so today's completion increments correctly (Day 2, Day 3, ...).
                            if (isRestoreRun) {
                              await _recordStreakActivityForDay(completionDate);
                            }
                            await SharPreferences.setString(
                                SharPreferences.streakFlowLastShownDate,
                                completionDate);
                            if (isRestoreRun) {
                              final completed =
                                  await SharPreferences.getStringList(
                                          SharPreferences
                                              .streakCompletedDates) ??
                                      <String>[];
                              if (!completed.contains(completionDate)) {
                                await SharPreferences.setListString(
                                  SharPreferences.streakCompletedDates,
                                  [...completed, completionDate],
                                );
                              }
                            }
                            if (!context.mounted) return;
                            final streakCount =
                                await StreakService.getCurrentStreak();
                            await SharPreferences.setInt(
                                SharPreferences
                                    .pendingStreakCompleteCelebration,
                                streakCount);
                            // Stop background music once Prayer moment is completed.
                            try {
                              await _StreakFlowBgMusic.stop();
                            } catch (_) {}
                            if (!context.mounted) return;
                            if (isRestoreRun) {
                              await SharPreferences.setBoolean(
                                  SharPreferences.streakFlowRestoreActive,
                                  false);
                              await SharPreferences.setString(
                                  SharPreferences.streakFlowRestoreDate, '');
                              final startToday = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) {
                                      final isDark = _isStreakDark(context);
                                      final textColor = _streakTextColor(context);
                                      final panelColor = _streakPanelColor(context);
                                      return Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding:
                                            const EdgeInsets.symmetric(horizontal: 24),
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 360),
                                          decoration: BoxDecoration(
                                            color: panelColor,
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: textColor.withOpacity(0.18),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.25),
                                                blurRadius: 18,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.fromLTRB(18, 16, 18, 18),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.local_fire_department_rounded,
                                                  size: 34,
                                                  color: _kStreakGold,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'Streak Completed! ✨',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w800,
                                                    color: textColor,
                                                    fontFamily: 'Georgia',
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'You completed yesterday\'s faith journey.\nStart today\'s journey and keep growing in faith.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.4,
                                                    color: textColor.withOpacity(0.88),
                                                    fontFamily: 'Georgia',
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: _buildParchmentButton(
                                                        context: context,
                                                        label: 'Later',
                                                        isSecondary: true,
                                                        onTap: () =>
                                                            Navigator.of(context).pop(false),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: _buildParchmentButton(
                                                        context: context,
                                                        label: 'Start Today',
                                                        onTap: () =>
                                                            Navigator.of(context).pop(true),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (!isDark) const SizedBox(height: 2),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ) ??
                                  false;
                              if (!context.mounted) return;
                              if (startToday) {
                                await SharPreferences.setInt(
                                    SharPreferences
                                        .streakFlowStepsCompletedToday,
                                    0);
                                await SharPreferences.setString(
                                  SharPreferences.streakFlowStartedDate,
                                  DateTime.now()
                                      .toIso8601String()
                                      .split('T')[0],
                                );
                                Get.offAll(
                                    () => const StreakConnectionScreen());
                                return;
                              }
                              _goToHome(context);
                              return;
                            }
                            // Prevent showing the "Daily Streak Completed" screen more than once per day.
                            final todayKey =
                                DateTime.now().toIso8601String().split('T')[0];
                            if (completionDate == todayKey) {
                              final lastShown = await SharPreferences.getString(
                                  SharPreferences
                                      .streakCompletedScreenShownDate);
                              if (lastShown == todayKey) {
                                _goToHome(context);
                                return;
                              }
                              await SharPreferences.setString(
                                  SharPreferences
                                      .streakCompletedScreenShownDate,
                                  todayKey);
                            }
                            Get.offAll(() => const StreakCompletedScreen());
                          },
                        ),
                      ),
                      Builder(
                        builder: (shareContext) => IconButton(
                          icon: Icon(Icons.share,
                              color: _streakTextColor(shareContext), size: 26),
                          onPressed: () async {
                            final image = await _screenshotController.capture(
                              delay: const Duration(milliseconds: 80),
                            );
                            if (shareContext.mounted) {
                              await _shareAsImage(
                                shareContext,
                                imageBytes: image,
                                fallbackText: item.prayerText,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 5. Daily Streak Completed!

// ─── Stub preferences ────────────────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════════════════════
class StreakCompletedScreen extends StatefulWidget {
  const StreakCompletedScreen({super.key});

  @override
  State<StreakCompletedScreen> createState() => _StreakCompletedScreenState();
}

class _StreakCompletedScreenState extends State<StreakCompletedScreen>
    with TickerProviderStateMixin {
  bool _isStreakDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _streakTextColor(BuildContext context) =>
      _isStreakDark(context) ? _kParchmentLight : _kInkBrown;

  Color _streakPanelColor(BuildContext context) =>
      _isStreakDark(context) ? const Color(0xFF2A1F12) : _kParchmentMid;

  Widget _parchmentButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final isDark = _isStreakDark(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3B2A1A) : _kInkBrown,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _kCandleGold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kCandleGold.withOpacity(0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF5EAC6),
              fontFamily: 'Georgia',
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  void _goToHome(BuildContext context) {
    Get.offAll(
      () => HomeScreen(
        From: "splash",
        selectedVerseNumForRead: "",
        selectedBookForRead: "",
        selectedChapterForRead: "",
        selectedBookNameForRead: "",
        selectedVerseForRead: "",
      ),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 350),
    );
  }

  // ── Unchanged controllers (kept identical) ─────────────────────────────────
  late final AnimationController _ctrl;
  late final AnimationController _twinkleCtrl;
  late final AnimationController _rayCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _twinkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    )..repeat();
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutQuart),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOutQuart),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _twinkleCtrl.dispose();
    _rayCtrl.dispose();
    super.dispose();
  }

  // ── SMOOTH LIGHT RAYS ─────────────────────────────────────────────────
  // Very slow, elegant rotating glow effect
  Widget _lightRaysOverlay(bool isDark) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _rayCtrl,
        builder: (context, _) {
          final t = _rayCtrl.value;
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              // Large slow rotating gradient
              Positioned(
                top: -40,
                child: Transform.rotate(
                  angle: t * math.pi * 2,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _kCandleGold.withOpacity(isDark ? 0.08 : 0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),
                ),
              ),
              // Secondary counter-rotating glow
              Positioned(
                top: -20,
                child: Transform.rotate(
                  angle: -t * math.pi * 1.5 + 1.0,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _kCandleGlow.withOpacity(isDark ? 0.06 : 0.09),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
              ),
              // Subtle shimmer overlay
              Positioned(
                top: 20,
                child: Opacity(
                  opacity: 0.5 + (math.sin(t * math.pi * 2) * 0.2),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _kCandleGold.withOpacity(isDark ? 0.05 : 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── SMOOTH CELEBRATION BURST ───────────────────────────────────────────────
  // Elegant expanding ripple with breathing effect
  Widget _celebrationBurstOverlay(bool isDark) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          final easeT = Curves.easeOutQuart.transform(t);
          final opacity = (1.0 - easeT).clamp(0.0, 1.0);
          final maxRing = MediaQuery.of(context).size.width * 0.5;

          return Opacity(
            opacity: opacity,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Outer expanding ring
                Positioned(
                  top: 60,
                  child: Container(
                    width: maxRing * (0.25 + (0.75 * easeT)),
                    height: maxRing * (0.25 + (0.75 * easeT)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kCandleGold.withOpacity(
                          isDark ? 0.35 : 0.28,
                        ),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                // Middle ring with breathing
                Positioned(
                  top: 72,
                  child: AnimatedBuilder(
                    animation: _twinkleCtrl,
                    builder: (context, _) {
                      final breath = 0.95 + (_twinkleCtrl.value * 0.05);
                      return Transform.scale(
                        scale: breath,
                        child: Container(
                          width: maxRing * (0.18 + (0.55 * easeT)),
                          height: maxRing * (0.18 + (0.55 * easeT)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _kInkSepia.withOpacity(
                                isDark ? 0.25 : 0.20,
                              ),
                              width: 0.6,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Inner soft glow (pulsing)
                Positioned(
                  top: 84,
                  child: AnimatedBuilder(
                    animation: _twinkleCtrl,
                    builder: (context, _) {
                      return Container(
                        width: maxRing * 0.22,
                        height: maxRing * 0.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _kCandleGlow.withOpacity(
                                (isDark ? 0.12 : 0.18) +
                                    (_twinkleCtrl.value * 0.08),
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── PARCHMENT TEXTURE OVERLAY ─────────────────────────────────────────────
  // Subtle aged-paper grain via semi-transparent lines (no external assets).
  @override
  Widget build(BuildContext context) {
    final isDark = _isStreakDark(context);
    final textColor = _streakTextColor(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Candlelight rays (same logic, parchment palette)
              _lightRaysOverlay(isDark),
              // 2. Ink-bleed celebration burst (same logic, parchment palette)
              _celebrationBurstOverlay(isDark),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.close, color: textColor.withOpacity(0.85)),
                  onPressed: () => _goToHome(context),
                  tooltip: 'Close',
                ),
              ),

            Column(
              children: [
                const SizedBox(height: 40),

                // ── Illuminated Flame Badge ──────────────────────────────────
                FutureBuilder<int?>(
                  future: SharPreferences.getInt(
                      SharPreferences.pendingStreakCompleteCelebration),
                  builder: (context, snap) {
                    final streakDays = (snap.data ?? 0).clamp(0, 9999);
                    return FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _twinkleCtrl,
                              builder: (context, child) {
                                final pulse = 1 + (_twinkleCtrl.value * 0.08);
                                return Transform.scale(
                                  scale: pulse,
                                  child: Container(
                                    width: 108,
                                    height: 108,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      // Parchment circle bg
                                      color: isDark
                                          ? const Color(0xFF2E1E0A)
                                          : _kParchmentMid,
                                      // Ink-drawn border
                                      border: Border.all(
                                          color: _kInkSepia, width: 2.5),
                                      boxShadow: [
                                        // Strong outer glow - flame effect
                                        BoxShadow(
                                          color: _kCandleGold.withOpacity(0.40 +
                                              (_twinkleCtrl.value * 0.35)),
                                          blurRadius:
                                              35 + (_twinkleCtrl.value * 25),
                                          spreadRadius:
                                              8 + (_twinkleCtrl.value * 8),
                                        ),
                                        // Medium glow layer
                                        BoxShadow(
                                          color: _kCandleGold.withOpacity(0.25 +
                                              (_twinkleCtrl.value * 0.25)),
                                          blurRadius:
                                              22 + (_twinkleCtrl.value * 18),
                                          spreadRadius:
                                              4 + (_twinkleCtrl.value * 4),
                                        ),
                                        // Inner warm halo
                                        BoxShadow(
                                          color: _kCandleGlow.withOpacity(0.20 +
                                              (_twinkleCtrl.value * 0.30)),
                                          blurRadius:
                                              12 + (_twinkleCtrl.value * 12),
                                          spreadRadius: _twinkleCtrl.value * 3,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            // Icon inner glow
                                            BoxShadow(
                                              color: _kCandleGold.withOpacity(0.6),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.local_fire_department_rounded,
                                          size: 58,
                                          color: Color(0xFFC9A227),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            // Decorative manuscript rule above title
                            _ManuscriptRule(color: _kInkSepia.withOpacity(0.5)),
                            const SizedBox(height: 8),

                            Text(
                              streakDays > 0
                                  ? '$streakDays Day Streak!'
                                  : 'Streak Completed!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width > 450
                                        ? 30
                                        : 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                fontFamily: 'Georgia',
                                // Slight letter-spacing for inscription feel
                                letterSpacing: 1.0,
                              ),
                            ),

                            const SizedBox(height: 8),
                            _ManuscriptRule(color: _kInkSepia.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                const SizedBox(height: 8),

                // Scripture-style subtitle
                Text(
                  'You\'re walking faithfully today.',
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor.withOpacity(0.85),
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep the light alive.',
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor.withOpacity(0.85),
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Reward Scroll Card ────────────────────────────────────────
                SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: _streakPanelColor(context).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                        // Double ink border — like a manuscript frame
                        border: Border.all(color: _kInkSepia, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _kInkBrown.withOpacity(isDark ? 0.40 : 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                          // Inner candle-glow
                          BoxShadow(
                            color:
                                _kCandleGold.withOpacity(isDark ? 0.12 : 0.10),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Scroll top ornament line
                          _ScrollOrnament(color: _kInkSepia),
                          const SizedBox(height: 10),

                          Text(
                            'REWARD  EARNED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: textColor.withOpacity(0.7),
                              fontFamily: 'Georgia',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.monetization_on,
                                  color: _kCandleGold, size: 26),
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
                              fontSize: 13,
                              color: textColor.withOpacity(0.75),
                              fontFamily: 'Georgia',
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Scroll bottom ornament line
                          _ScrollOrnament(color: _kInkSepia),
                        ],
                      ),
                    ),
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
          ],
        ),
      ),
      )
    );
  }
}

// ─── Manuscript horizontal rule ───────────────────────────────────────────────
class _ManuscriptRule extends StatelessWidget {
  final Color color;
  const _ManuscriptRule({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.diamond_outlined, size: 10, color: color),
          ),
          Expanded(child: Container(height: 1, color: color)),
        ],
      ),
    );
  }
}

// ─── Scroll ornament (❧ style ends) ─────────────────────────────────────────
class _ScrollOrnament extends StatelessWidget {
  final Color color;
  const _ScrollOrnament({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 40, height: 1, color: color.withOpacity(0.5)),
        const SizedBox(width: 6),
        Icon(Icons.auto_awesome, size: 12, color: color),
        const SizedBox(width: 6),
        Container(width: 40, height: 1, color: color.withOpacity(0.5)),
      ],
    );
  }
}

// (removed unused parchment grain painter)
