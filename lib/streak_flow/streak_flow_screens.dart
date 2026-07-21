import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:screenshot/screenshot.dart';
import 'package:biblebookapp/streak_flow/leave_rating_screen.dart';
import 'package:biblebookapp/streak_flow/mood_prayer_data.dart';
import 'package:biblebookapp/streak_flow/streak_saved_storage.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/streak/streak_live_activity.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/services/daily_slot_notification_helper.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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

bool _isStreakWhiteLight(BuildContext context) {
  try {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.currentCustomTheme == AppCustomTheme.white &&
        themeProvider.themeMode != ThemeMode.dark;
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
    if (themeProvider.currentCustomTheme == AppCustomTheme.white) {
      return [
        Colors.white,
        const Color(0xFFF7F7F7),
        const Color(0xFFEFEFEF),
      ];
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

Color _streakTextColor(BuildContext context) {
  if (_isStreakDark(context)) return Colors.white;
  if (_isStreakWhiteLight(context)) return const Color(0xFF2C2C2C);
  return _kStreakBrown;
}

/// Headers over full-bleed photos (verse / devotional / prayer) — white text
/// washes out on bright sky; use warm ink with a soft light halo in dark mode.
Color _streakHeaderOnPhotoColor(BuildContext context) {
  if (_isStreakDark(context)) return const Color(0xFF2A1F12);
  if (_isStreakWhiteLight(context)) return const Color(0xFF2C2C2C);
  return _kStreakBrown;
}

List<Shadow> _streakHeaderOnPhotoShadows(BuildContext context) {
  if (_isStreakDark(context)) {
    return [
      Shadow(
        color: Colors.white.withOpacity(0.9),
        blurRadius: 10,
        offset: const Offset(0, 0),
      ),
      Shadow(
        color: Colors.white.withOpacity(0.45),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }
  return const [];
}

Color _streakPanelColor(BuildContext context) =>
    _isStreakDark(context) ? Colors.white.withOpacity(0.12) : _kStreakCream;

/// Verse / Devotional / Prayer streak content — plain on background (no card box).
Widget _streakStepContentBox(
  BuildContext context,
  Widget child, {
  bool useContentScrim = true,
}) {
  if (!useContentScrim) return child;
  return _streakPhotoContentBackdrop(child: child);
}

/// Soft radial scrim so white verse/devotional text reads clearly on photos.
Widget _streakPhotoContentBackdrop({required Widget child}) {
  return Stack(
    alignment: Alignment.center,
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: -28,
        right: -28,
        top: -20,
        bottom: -20,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.95,
              colors: [
                Colors.black.withOpacity(0.52),
                Colors.black.withOpacity(0.32),
                Colors.black.withOpacity(0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.42, 0.72, 1.0],
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

/// ~10% lower contrast on rocky foreground photos so verse text reads easier.
const ColorFilter _streakPhotoContrastFilter = ColorFilter.matrix(<double>[
  0.9, 0, 0, 0, 12.75,
  0, 0.9, 0, 0, 12.75,
  0, 0, 0.9, 0, 12.75,
  0, 0, 0, 1, 0,
]);

const List<String> _streakPhotoBackgroundAssets = [
  'assets/back1.png',
  'assets/back2.png',
];

/// Warm placeholder shown until photo assets are decoded (UI only).
const Color _kStreakPhotoPlaceholder = Color(0xFF4A3528);

Future<void> precacheStreakPhotoBackgrounds(BuildContext context) {
  return Future.wait(
    _streakPhotoBackgroundAssets.map(
      (path) => precacheImage(AssetImage(path), context),
    ),
  );
}

Widget _streakPhotoBackgroundImage(String assetPath) {
  return Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _kStreakPhotoPlaceholder),
        ColorFiltered(
          colorFilter: _streakPhotoContrastFilter,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    ),
  );
}

/// Verse screen background — image shifted up so the cross sits above the verse area.
Widget _streakPhotoVerseBackgroundImage(String assetPath) {
  return Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _kStreakPhotoPlaceholder),
        ColorFiltered(
          colorFilter: _streakPhotoContrastFilter,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.22),
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    ),
  );
}

/// Verse screen overlays — top fade, center verse shadow, bottom fade (reference mockup).
Widget _streakPhotoVerseReadabilityOverlay(BuildContext context) {
  final h = MediaQuery.sizeOf(context).height;
  final topH = h * 0.22;
  final bottomH = h * 0.58;
  final centerH = h * 0.55;

  return Positioned.fill(
    child: IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.60),
                    Colors.black.withOpacity(0.28),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: h * 0.28,
            left: 0,
            right: 0,
            height: centerH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.20),
                    Colors.black.withOpacity(0.38),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.68, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.92),
                    Colors.black.withOpacity(0.72),
                    Colors.black.withOpacity(0.38),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.38, 0.68, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _streakPhotoVerseBackgroundStack({
  required BuildContext context,
  required String assetPath,
  required Widget child,
}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      _streakPhotoVerseBackgroundImage(assetPath),
      _streakPhotoVerseReadabilityOverlay(context),
      child,
    ],
  );
}

/// Top/bottom vignette for readable white text on photo backgrounds (UI only).
Widget _streakPhotoReadabilityOverlays(BuildContext context) {
  final h = MediaQuery.sizeOf(context).height;
  final topH = h * 0.22;
  final bottomH = h * 0.58;
  final centerH = h * 0.55;

  return Stack(
    fit: StackFit.expand,
    children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: topH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.58),
                Colors.black.withOpacity(0.28),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
      Positioned(
        top: h * 0.18,
        left: 0,
        right: 0,
        height: centerH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.18),
                Colors.black.withOpacity(0.34),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.68, 1.0],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: bottomH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.88),
                Colors.black.withOpacity(0.58),
                Colors.transparent,
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _streakPhotoBackgroundStack({
  required BuildContext context,
  required String assetPath,
  required Widget child,
}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      _streakPhotoBackgroundImage(assetPath),
      _streakPhotoReadabilityOverlays(context),
      child,
    ],
  );
}

const Color _kStreakPhotoGold = Color(0xFFC59434);

const List<Shadow> _kStreakPhotoTextShadows = [
  Shadow(color: Color(0xF0000000), blurRadius: 18, offset: Offset(0, 2)),
  Shadow(color: Color(0xCC000000), blurRadius: 8, offset: Offset(0, 1)),
  Shadow(color: Color(0x80000000), blurRadius: 2, offset: Offset(0, 0)),
];

const List<Shadow> _kStreakPhotoSoftTextShadows = [
  Shadow(color: Color(0xE6000000), blurRadius: 14, offset: Offset(0, 1)),
  Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1)),
];

TextStyle _streakPhotoTitleStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 28 : 24,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFamily: 'Georgia',
      shadows: _kStreakPhotoTextShadows,
      height: 1.15,
    );

TextStyle _streakPhotoSubtitleStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 15 : 13,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Georgia',
      height: 1.4,
      shadows: _kStreakPhotoTextShadows,
    );

TextStyle _streakPhotoBodyStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 21 : 18,
      height: 1.6,
      color: Colors.white,
      fontFamily: 'Georgia',
      fontWeight: FontWeight.w500,
      shadows: _kStreakPhotoTextShadows,
    );

TextStyle _streakPhotoReferenceStyle(BuildContext context) => TextStyle(
      fontSize: 17,
      fontStyle: FontStyle.italic,
      color: _kStreakPhotoGold,
      fontFamily: 'Georgia',
      fontWeight: FontWeight.w600,
      shadows: _kStreakPhotoTextShadows,
    );

TextStyle _streakPhotoCaptionStyle(BuildContext context) => TextStyle(
      fontSize: 12,
      height: 1.35,
      color: Colors.white.withOpacity(0.92),
      fontFamily: 'Georgia',
      fontWeight: FontWeight.w500,
      shadows: _kStreakPhotoSoftTextShadows,
    );

Widget _streakPhotoSubtitleText(BuildContext context, String subtitle) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Text(
      subtitle,
      textAlign: TextAlign.center,
      style: _streakPhotoSubtitleStyle(context),
    ),
  );
}

const List<Shadow> _kStreakVerseHeaderShadows = [
  Shadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 2)),
  Shadow(color: Color(0x77000000), blurRadius: 3, offset: Offset(0, 1)),
];

TextStyle _streakPhotoVerseTitleStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 30 : 26,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFamily: 'Georgia',
      height: 1.15,
      letterSpacing: 0.15,
      shadows: _kStreakVerseHeaderShadows,
    );

TextStyle _streakPhotoVerseSubtitleStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 15 : 14,
      fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.94),
      fontFamily: 'Georgia',
      height: 1.35,
      shadows: _kStreakVerseHeaderShadows,
    );

Widget _streakPhotoShortGoldLine({double width = 52}) {
  return Container(
    width: width,
    height: 2,
    decoration: BoxDecoration(
      color: _kStreakPhotoGold.withOpacity(0.92),
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

/// Verse screen header — no icon; title, subtitle, short gold rule.
Widget _streakPhotoVerseHeader({
  required BuildContext context,
  required String title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
    child: Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: _streakPhotoVerseTitleStyle(context),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: _streakPhotoVerseSubtitleStyle(context),
        ),
        const SizedBox(height: 18),
        _streakPhotoShortGoldLine(),
        const SizedBox(height: 22),
      ],
    ),
  );
}

Widget _streakProgressDots(
  BuildContext context,
  int currentStep, {
  bool onPhotoBackground = false,
}) {
  final inactive = onPhotoBackground
      ? Colors.white.withOpacity(0.38)
      : _streakTextColor(context).withOpacity(0.35);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(4, (i) {
      final step = i + 1;
      final active = step == currentStep;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: active ? 8 : 6,
        height: active ? 8 : 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _kStreakPhotoGold : inactive,
        ),
      );
    }),
  );
}

/// Step label + dots centered on screen; side actions do not shift alignment.
Widget _streakCenteredStepHeader({
  required BuildContext context,
  required int step,
  required Widget leftActions,
  required Widget rightActions,
  bool onPhotoBackground = false,
}) {
  final textColor = onPhotoBackground
      ? Colors.white.withOpacity(0.92)
      : _streakTextColor(context).withOpacity(0.95);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Step $step of 4',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 450 ? 14 : 12,
                fontWeight: FontWeight.w500,
                color: textColor,
                fontFamily: 'Georgia',
                shadows: onPhotoBackground ? _kStreakPhotoSoftTextShadows : null,
              ),
            ),
            const SizedBox(height: 6),
            _streakProgressDots(context, step,
                onPhotoBackground: onPhotoBackground),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftActions,
            rightActions,
          ],
        ),
      ],
    ),
  );
}

Widget _streakPhotoTopBar({
  required BuildContext context,
  required int step,
  required VoidCallback onBack,
  required VoidCallback onClose,
  VoidCallback? onMusicToggle,
  bool isMusicMuted = false,
  bool showMusic = false,
}) {
  return _streakCenteredStepHeader(
    context: context,
    step: step,
    onPhotoBackground: true,
    leftActions: IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: Colors.white,
        size: 20,
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
        ],
      ),
      onPressed: onBack,
      tooltip: 'Back',
    ),
    rightActions: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMusic)
          IconButton(
            onPressed: onMusicToggle,
            icon: Icon(
              isMusicMuted ? Icons.music_off : Icons.music_note,
              color: Colors.white,
              size: 24,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
              ],
            ),
            tooltip: isMusicMuted ? 'Audio Off' : 'Audio On',
          ),
        IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.white,
            size: 24,
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
            ],
          ),
          onPressed: onClose,
          tooltip: 'Close',
        ),
      ],
    ),
  );
}

Widget _streakPhotoHeaderIcon(IconData icon) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          boxShadow: [
            BoxShadow(
              color: _kStreakPhotoGold.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.9),
          border: Border.all(color: _kStreakPhotoGold.withOpacity(0.5), width: 1),
        ),
        child: Icon(icon, color: _kStreakPhotoGold, size: 28),
      ),
    ],
  );
}

Widget _streakPhotoStepHeader({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Column(
    children: [
      _streakPhotoHeaderIcon(icon),
      const SizedBox(height: 14),
      Text(title, textAlign: TextAlign.center, style: _streakPhotoTitleStyle(context)),
      const SizedBox(height: 10),
      _streakGoldDivider(),
      const SizedBox(height: 10),
      _streakPhotoSubtitleText(context, subtitle),
      const SizedBox(height: 20),
    ],
  );
}

/// Small gold cross for devotional / prayer dividers.
Widget _streakDividerCross({double size = 14}) {
  return Icon(
    Icons.add,
    color: _kStreakPhotoGold,
    size: size,
    shadows: _kStreakPhotoSoftTextShadows,
  );
}

Widget _streakDevotionalReflectionPrompt(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.edit_note_rounded,
          color: _kStreakPhotoGold,
          size: 28,
          shadows: _kStreakPhotoSoftTextShadows,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Take a moment',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 450 ? 16 : 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Georgia',
                  shadows: _kStreakPhotoTextShadows,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How does God\'s grace strengthen you in your daily life?',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 450 ? 14 : 13,
                  height: 1.35,
                  color: Colors.white.withOpacity(0.95),
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w500,
                  shadows: _kStreakPhotoSoftTextShadows,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Small gold heart for verse divider (avoids emoji / icon-font tofu boxes).
Widget _streakDividerHeart({double size = 14}) {
  return CustomPaint(
    size: Size(size, size),
    painter: _StreakGoldHeartPainter(color: _kStreakPhotoGold),
  );
}

class _StreakGoldHeartPainter extends CustomPainter {
  _StreakGoldHeartPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.88)
      ..cubicTo(w * 0.08, h * 0.52, 0, h * 0.28, w * 0.22, h * 0.08)
      ..cubicTo(w * 0.38, -h * 0.02, w * 0.5, h * 0.12, w * 0.5, h * 0.24)
      ..cubicTo(w * 0.5, h * 0.12, w * 0.62, -h * 0.02, w * 0.78, h * 0.08)
      ..cubicTo(w, h * 0.28, w * 0.92, h * 0.52, w * 0.5, h * 0.88)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StreakGoldHeartPainter oldDelegate) =>
      oldDelegate.color != color;
}

Widget _streakGoldDivider({Widget? center}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: _kStreakPhotoGold.withOpacity(0.75),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: center ??
              Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _kStreakPhotoGold,
                    border: Border.all(color: _kStreakPhotoGold.withOpacity(0.8)),
                  ),
                ),
              ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: _kStreakPhotoGold.withOpacity(0.75),
          ),
        ),
      ],
    ),
  );
}

/// Dark bottom scrim behind Save/Share + CTA on Verse screen (UI only).
Widget _streakPhotoVerseBottomShadow({required Widget child}) {
  return Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.bottomCenter,
    children: [
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: 280,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.22),
                Colors.black.withOpacity(0.52),
                Colors.black.withOpacity(0.78),
              ],
              stops: const [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: child,
      ),
    ],
  );
}

/// Save/Share row for Verse screen — plain on bottom shadow (no pill box).
Widget _streakPhotoVerseSaveShareRow({
  required bool saved,
  required String saveLabel,
  required VoidCallback onSave,
  required VoidCallback onShare,
}) {
  Widget action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _kStreakPhotoGold,
              size: 18,
              shadows: _kStreakPhotoSoftTextShadows,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
                shadows: _kStreakPhotoSoftTextShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      action(
        icon: saved ? Icons.bookmark : Icons.bookmark_border,
        label: saveLabel,
        onTap: onSave,
      ),
      Container(
        width: 1,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withOpacity(0.55),
      ),
      action(
        icon: Icons.share,
        label: 'Share',
        onTap: onShare,
      ),
    ],
  );
}

Widget _streakPhotoSaveShareRow({
  required bool saved,
  required String saveLabel,
  required VoidCallback onSave,
  required VoidCallback onShare,
}) {
  Widget action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _kStreakPhotoGold,
              size: 18,
              shadows: _kStreakPhotoSoftTextShadows,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
                shadows: _kStreakPhotoSoftTextShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      action(
        icon: saved ? Icons.bookmark : Icons.bookmark_border,
        label: saveLabel,
        onTap: onSave,
      ),
      Container(
        width: 1,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: Colors.white.withOpacity(0.45),
      ),
      action(
        icon: Icons.share,
        label: 'Share',
        onTap: onShare,
      ),
    ],
  );
}

Widget _streakPhotoPrimaryButton({
  required BuildContext context,
  required String label,
  required VoidCallback onPressed,
  IconData? leadingIcon,
  bool showShadow = true,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _kStreakPhotoGold,
          borderRadius: BorderRadius.circular(30),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 450 ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    ),
  );
}

TextStyle _streakShareBodyStyle() => const TextStyle(
      fontSize: 18,
      height: 1.55,
      color: Colors.white,
      fontFamily: 'Georgia',
      fontWeight: FontWeight.w500,
      shadows: _kStreakPhotoTextShadows,
    );

TextStyle _streakShareReferenceStyle() => const TextStyle(
      fontSize: 17,
      fontStyle: FontStyle.italic,
      color: _kStreakPhotoGold,
      fontFamily: 'Georgia',
      shadows: _kStreakPhotoTextShadows,
    );

/// Share card with photo background + readable text overlay.
Widget _streakShareCardForCapture(
  BuildContext context,
  Widget content, {
  String backgroundAsset = 'assets/back2.png',
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final cardWidth = screenWidth > 450 ? 400.0 : screenWidth.clamp(300.0, 400.0);
  const footerHeight = 56.0;
  return SizedBox(
    width: cardWidth,
    height: cardWidth * 1.35,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
          Container(color: Colors.black.withOpacity(0.42)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, footerHeight + 20),
            child: Center(child: content),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: footerHeight,
            child: ColoredBox(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/Icon-1024.png',
                      height: 22,
                      width: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      BibleInfo.bible_shortName,
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _streakCompletionShareBody(int streakDays) {
  if (streakDays == 1) {
    return 'I completed my first daily Bible streak today. One step closer to building a lasting habit with God.';
  }
  if (streakDays == 5) {
    return "Five days of staying connected with God's Word. Looking forward to tomorrow!";
  }
  if (streakDays > 0) {
    return "I've completed my $streakDays-day Bible streak and I'm growing closer to God every day.";
  }
  return "You're building a beautiful habit of seeking God daily.";
}

String _streakCompletionShareHeadline(int streakDays) {
  if (streakDays > 0) {
    return '🔥 Day $streakDays Streak Completed!';
  }
  return '🔥 Streak Completed!';
}

String _streakCompletionShareMessage(int streakDays) {
  return '${_streakCompletionShareHeadline(streakDays)}\n${_streakCompletionShareBody(streakDays)}';
}

String _streakCompletionShareMessageWithLink(int streakDays) {
  final androidLink =
      'https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}';
  final iosLink = 'https://itunes.apple.com/app/id${BibleInfo.apple_AppId}';
  final appUrl = Platform.isIOS ? iosLink : androidLink;
  return '${_streakCompletionShareMessage(streakDays)}\nJoin me:\n$appUrl';
}

String _streakCompletionShareImageFileName(int streakDays) {
  if (streakDays > 0) {
    return 'Day_${streakDays}_Streak_Completed.png';
  }
  return 'Streak_Completed.png';
}

Widget _streakCompleteShareContent(int streakDays) {
  final creditsEarned = streakDays * 20;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _kStreakPhotoGold.withOpacity(0.75),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _kStreakPhotoGold.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.local_fire_department_rounded,
          size: 42,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 18),
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Georgia',
            height: 1.15,
            shadows: _kStreakPhotoTextShadows,
          ),
          children: [
            TextSpan(
              text: streakDays > 0 ? 'Day $streakDays ' : '',
            ),
            const TextSpan(
              text: 'Streak!',
              style: TextStyle(color: _kStreakPhotoGold),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Streak Completed!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.95),
          fontFamily: 'Georgia',
          shadows: _kStreakPhotoSoftTextShadows,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        _streakCompletionShareBody(streakDays),
        textAlign: TextAlign.center,
        style: _streakShareBodyStyle().copyWith(fontSize: 14),
      ),
      if (streakDays > 0) ...[
        const SizedBox(height: 14),
        Text(
          '+$creditsEarned Faith Credits',
          textAlign: TextAlign.center,
          style: _streakShareReferenceStyle(),
        ),
      ],
    ],
  );
}

Future<Uint8List?> _captureStreakShareImage(
  BuildContext context, {
  required Widget content,
  String backgroundAsset = 'assets/back2.png',
}) async {
  final dpr = MediaQuery.of(context).devicePixelRatio;
  final controller = ScreenshotController();
  try {
    return await controller.captureFromWidget(
      _streakShareCardForCapture(
        context,
        content,
        backgroundAsset: backgroundAsset,
      ),
      delay: const Duration(milliseconds: 50),
      pixelRatio: (dpr * 2).clamp(2.5, 4.0),
      context: context,
    );
  } catch (e) {
    debugPrint('Streak share capture failed: $e');
    return null;
  }
}

String _shareTextWithAppUrl(String content) {
  final androidLink =
      'https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}';
  final iosLink = 'https://itunes.apple.com/app/id${BibleInfo.apple_AppId}';
  final appUrl = Platform.isIOS ? iosLink : androidLink;
  return '$content\n\nRead more at: $appUrl';
}

Future<void> _shareText(
  BuildContext context,
  String text, {
  bool appendAppUrl = true,
}) async {
  try {
    final shareContent =
        appendAppUrl ? _shareTextWithAppUrl(text) : text;
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
  String? imageFileName,
  bool appendAppUrlToFallback = true,
}) async {
  if (imageBytes != null && imageBytes.isNotEmpty) {
    try {
      final directory = await getTemporaryDirectory();
      final shareFileName = (imageFileName != null && imageFileName.trim().isNotEmpty)
          ? (imageFileName.endsWith('.png')
              ? imageFileName
              : '$imageFileName.png')
          : 'streak_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File('${directory.path}/$shareFileName');
      await imageFile.writeAsBytes(imageBytes, flush: true);

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [
          XFile(
            imageFile.path,
            mimeType: 'image/png',
            name: shareFileName,
          ),
        ],
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
      return;
    } catch (e) {
      debugPrint('Streak image share failed: $e');
      // fall through to text share
    }
  }
  if (context.mounted) {
    _shareText(
      context,
      fallbackText,
      appendAppUrl: appendAppUrlToFallback,
    );
  }
}

Future<void> _shareStreakFlowImageWithLoader(
  BuildContext shareContext, {
  required String backgroundAsset,
  required Widget content,
  required String fallbackText,
  String? imageFileName,
  bool appendAppUrlToFallback = true,
}) async {
  HapticFeedback.lightImpact();
  EasyLoading.show(
    status: 'Preparing...',
    maskType: EasyLoadingMaskType.clear,
  );
  try {
    final image = await _captureStreakShareImage(
      shareContext,
      backgroundAsset: backgroundAsset,
      content: content,
    );
    await EasyLoading.dismiss();
    if (!shareContext.mounted) return;
    await _shareAsImage(
      shareContext,
      imageBytes: image,
      imageFileName: imageFileName,
      fallbackText: fallbackText,
      appendAppUrlToFallback: appendAppUrlToFallback,
    );
  } catch (_) {
    await EasyLoading.dismiss();
  }
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
            saved ? 'Saved to Faith Journey' : 'Removed',
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
  // UI mirror only — does not change step storage above.
  StreakLiveActivitySync.sync(forceStart: true);
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

MoodPrayerItem? _deserializeMoodPrayerItem(Object? raw) {
  if (raw is! Map) return null;
  try {
    final m = Map<String, dynamic>.from(raw);
    return MoodPrayerItem(
      connectionLevel: (m['connectionLevel'] as num?)?.toInt() ?? 20,
      bookName: m['bookName']?.toString() ?? '',
      bookNumber: (m['bookNumber'] as num?)?.toInt() ?? 0,
      chapterNumber: (m['chapterNumber'] as num?)?.toInt() ?? 0,
      verseNumber: (m['verseNumber'] as num?)?.toInt() ?? 0,
      verseText: m['verseText']?.toString() ?? '',
      devotionalText: m['devotionalText']?.toString() ?? '',
      prayerText: m['prayerText']?.toString() ?? '',
      connectionSliderValue: (m['connectionSliderValue'] as num?)?.toDouble(),
    );
  } catch (_) {
    return null;
  }
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
  // Navigate immediately; warm data in the background so Close (X) does not
  // pause on the streak screen then flash a yellow/brown frame.
  try {
    final provider = Provider.of<DownloadProvider>(context, listen: false);
    provider.warmDataBeforeHomeScreen();
  } catch (e) {
    debugPrint('warmDataBeforeHomeScreen error: $e');
  }
  Get.offAll(
    () => HomeScreen(
      From: "splash",
      selectedVerseNumForRead: "",
      selectedBookForRead: "",
      selectedChapterForRead: "",
      selectedBookNameForRead: "",
      selectedVerseForRead: "",
    ),
    transition: Transition.fadeIn,
    duration: const Duration(milliseconds: 280),
    opaque: true,
  );
}

Future<void> _startNewJourneyFromPaused(BuildContext context) async {
  final today = DateTime.now().toIso8601String().split('T')[0];
  await SharPreferences.setBoolean(
      SharPreferences.streakFlowRestoreActive, false);
  await SharPreferences.setString(SharPreferences.streakFlowRestoreDate, '');
  await SharPreferences.setString(SharPreferences.streakFlowPausedDate, '');
  await SharPreferences.setString(SharPreferences.streakFlowPausedAt, '');
  await SharPreferences.setString(
      SharPreferences.streakFlowLastShownDate, today);
  await SharPreferences.setInt(SharPreferences.streakFlowStepsCompletedToday, 0);
  await SharPreferences.setString(
      SharPreferences.streakFlowStartedDate, today);
  if (!context.mounted) return;
  Get.offAll(
    () => const StreakConnectionScreen(),
    transition: Transition.cupertino,
    duration: const Duration(milliseconds: 350),
  );
}

void _popBackToFaithJourney(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
    return;
  }
  Get.back();
}

Future<void> _animateFaithJourneyPage(
  PageController? controller,
  int pageIndex,
) async {
  if (controller == null || !controller.hasClients) return;
  await controller.animateToPage(
    pageIndex,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeInOutCubic,
  );
}

Future<MoodPrayerItem?> _resolveFaithJourneyItem({
  MoodPrayerItem? item,
  int connectionIndex = 1,
}) async {
  if (item != null) return item;
  final dayKey = await _currentStreakFlowProgressDayKey();
  final byDay = await _readStreakFlowItemByDay();
  final stored = _deserializeMoodPrayerItem(byDay[dayKey]);
  return stored ?? await MoodPrayerLoader.pickItem(connectionIndex: connectionIndex);
}

/// Swipeable pager for Home → Faith Journey (Connect, Verse, Devotional, Prayer).
class FaithJourneyStepPager extends StatefulWidget {
  const FaithJourneyStepPager({
    super.key,
    required this.initialStep,
    this.item,
    this.initialSliderValue,
    this.viewOnly = false,
    this.connectionIndex = 1,
    this.stepsCompleted = 4,
  });

  /// 1 = Connect, 2 = Verse, 3 = Devotional, 4 = Prayer
  final int initialStep;
  final MoodPrayerItem? item;
  final double? initialSliderValue;
  final bool viewOnly;
  final int connectionIndex;
  /// Highest completed step (1–4); limits which pages are reachable in the pager.
  final int stepsCompleted;

  @override
  State<FaithJourneyStepPager> createState() => _FaithJourneyStepPagerState();
}

class _FaithJourneyStepPagerState extends State<FaithJourneyStepPager> {
  late final PageController _pageController;
  MoodPrayerItem? _item;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _pageController =
        PageController(initialPage: widget.initialStep.clamp(1, 4) - 1);
    _pageController.addListener(_handlePageChange);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _item ??= await _resolveFaithJourneyItem(
      connectionIndex: widget.connectionIndex,
    );
    if (!mounted) return;
    precacheStreakPhotoBackgrounds(context);
    await _syncMusicForPage(widget.initialStep.clamp(1, 4) - 1);
    if (mounted) setState(() => _ready = true);
  }

  void _handlePageChange() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;
    _syncMusicForPage(page.round());
  }

  Future<void> _syncMusicForPage(int pageIndex) async {
    if (pageIndex == 2 || pageIndex == 3) {
      final muted = await _StreakFlowBgMusic.getMuted();
      if (!muted) {
        await _StreakFlowBgMusic.play();
      }
    } else {
      await _StreakFlowBgMusic.stop();
    }
  }

  void _onFaithJourneyItemResolved(MoodPrayerItem item) {
    if (!mounted) return;
    setState(() => _item = item);
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    _StreakFlowBgMusic.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final item = _item;
    final canSwipe = widget.stepsCompleted >= 4;
    return PageView(
      controller: _pageController,
      physics: canSwipe
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      children: [
        StreakConnectionScreen(
          viewOnly: widget.viewOnly && widget.stepsCompleted >= 1,
          initialSliderValue: widget.initialSliderValue,
          openedFromFaithJourney: true,
          faithJourneyPageController: _pageController,
          onFaithJourneyItemResolved: _onFaithJourneyItemResolved,
        ),
        if (item != null)
          StreakVerseScreen(
            item: item,
            viewOnly: widget.viewOnly && widget.stepsCompleted >= 2,
            openedFromFaithJourney: true,
            faithJourneyPageController: _pageController,
          )
        else
          const SizedBox.expand(),
        if (item != null)
          StreakDevotionalScreen(
            item: item,
            viewOnly: widget.viewOnly && widget.stepsCompleted >= 3,
            openedFromFaithJourney: true,
            faithJourneyPageController: _pageController,
          )
        else
          const SizedBox.expand(),
        if (item != null)
          StreakPrayerScreen(
            item: item,
            viewOnly: widget.viewOnly && widget.stepsCompleted >= 4,
            openedFromFaithJourney: true,
            faithJourneyPageController: _pageController,
          )
        else
          const SizedBox.expand(),
      ],
    );
  }
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

    if ((isIncompleteYesterday || isMissedYesterdayWithoutOpen) &&
        started != today) {
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
      Get.offAll(
        () => const StreakPausedScreen(),
        transition: Transition.cupertino,
        duration: const Duration(milliseconds: 350),
      );
      return;
    }

    if (last == today || dismissed == today) {
      _goToHome(context);
      return;
    }

    // Already completed Connection (and maybe more) today — do not restart at
    // Connection on reopen. Open Reading screen; user can resume pending steps
    // from Faith Journey.
    final stepsByDay = await _readStreakFlowStepsByDay();
    final stepsTodayFromMap = stepsByDay[today] ?? 0;
    final effectiveSteps =
        stepsTodayFromMap > steps ? stepsTodayFromMap : steps;
    if (started == today && effectiveSteps > 0) {
      _goToHome(context);
      return;
    }

    if (!context.mounted) return;
    Get.offAll(
      () => const UpgradeCheckWrapper(
        showUpgradeAlert: true,
        child: StreakConnectionScreen(),
      ),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 350),
    );
  }
}

class StreakPausedScreen extends StatefulWidget {
  const StreakPausedScreen({super.key});

  @override
  State<StreakPausedScreen> createState() => _StreakPausedScreenState();
}

class _StreakPausedScreenState extends State<StreakPausedScreen> {
  static const int _restoreCost = 50;
  static const String _restoreDebitedDateKey =
      'streak_flow_restore_debited_date_v1';
  bool _busy = false;
  String _pausedDate = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) precacheStreakPhotoBackgrounds(context);
    });
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

    final restoreDateToUse = _pausedDate.isNotEmpty
        ? _pausedDate
        : DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0];

    // If a restore is already active for this date, do not debit again.
    final alreadyActive = (await SharPreferences.getBoolean(
            SharPreferences.streakFlowRestoreActive)) ==
        true;
    final activeDate =
        await SharPreferences.getString(SharPreferences.streakFlowRestoreDate);
    final debitedFor =
        await SharPreferences.getString(_restoreDebitedDateKey);
    if (alreadyActive &&
        activeDate != null &&
        activeDate == restoreDateToUse &&
        debitedFor == restoreDateToUse) {
      if (!mounted) return;
      Get.offAll(() => const StreakConnectionScreen());
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
    await SharPreferences.setString(_restoreDebitedDateKey, restoreDateToUse);
    await SharPreferences.setString(
      SharPreferences.streakFlowRestoreDate,
      restoreDateToUse,
    );
    await SharPreferences.setInt(
        SharPreferences.streakFlowStepsCompletedToday, 0);
    await SharPreferences.setString(
      SharPreferences.streakFlowStartedDate,
      DateTime.now().toIso8601String().split('T')[0],
    );
    if (!mounted) return;
    _showAppleToast(context, 'Credits debited from your wallet');
    Get.offAll(() => const StreakConnectionScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark = _isStreakDark(context);
    final warmText = isDark ? Colors.white : const Color(0xFF4A2F1D);
    return Scaffold(
      backgroundColor: _kStreakPhotoPlaceholder,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _streakPhotoBackgroundImage('assets/back1.png'),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(isDark ? 0.52 : 0.42),
                  Colors.black.withOpacity(isDark ? 0.34 : 0.28),
                  Colors.black.withOpacity(isDark ? 0.58 : 0.55),
                ],
              ),
            ),
          ),
          _streakPhotoReadabilityOverlays(context),
          SafeArea(
            child: Column(
              children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 22 : 14,
                  4,
                  isTablet ? 22 : 14,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _goToHome(context),
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            Icons.close,
                            size: 26,
                            color: warmText.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 30 : 22,
                    8,
                    isTablet ? 30 : 22,
                    12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        children: [
                          Container(
                            width: isTablet ? 80 : 74,
                            height: isTablet ? 80 : 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4A2F1D).withOpacity(0.88),
                              border: Border.all(
                                color: _kStreakGold.withOpacity(0.95),
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kStreakGold.withOpacity(0.4),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pause,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Your Streak Paused',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 38 : 32,
                              fontWeight: FontWeight.w700,
                              color: warmText,
                              fontFamily: 'Georgia',
                              height: 1.05,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: warmText.withOpacity(0.28),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.favorite,
                                  color: _kStreakGold.withOpacity(0.9),
                                  size: 14,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: warmText.withOpacity(0.28),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You missed a day - and that\'s okay.\nEvery journey has pauses.\nWhat matters is starting again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14.5,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : warmText.withOpacity(0.92),
                              fontFamily: 'Georgia',
                              shadows: isDark
                                  ? const [
                                      Shadow(
                                        color: Color(0xE6000000),
                                        blurRadius: 16,
                                        offset: Offset(0, 2),
                                      ),
                                      Shadow(
                                        color: Color(0x99000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: isTablet ? 68 : 62,
                            height: isTablet ? 68 : 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF8F1E4).withOpacity(0.95),
                              border: Border.all(
                                color: _kStreakGold.withOpacity(0.55),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kStreakGold.withOpacity(0.35),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: _kStreakGold,
                              size: isTablet ? 34 : 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<int?>(
                            future: SharPreferences.getInt(
                                SharPreferences.streakCount),
                            builder: (context, snap) {
                              final v = (snap.data ?? 0).clamp(0, 9999);
                              return Column(
                                children: [
                                  Text(
                                    'You built a',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.95),
                                      fontFamily: 'Georgia',
                                      shadows: const [
                                        Shadow(
                                          color: Color(0xE6000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 2),
                                        ),
                                        Shadow(
                                          color: Color(0x99000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$v Day Faith Habit',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 26 : 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontFamily: 'Georgia',
                                      height: 1.2,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0xE6000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 2),
                                        ),
                                        Shadow(
                                          color: Color(0x99000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Continue your streak from yesterday',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 13,
                                      color: Colors.white.withOpacity(0.95),
                                      fontFamily: 'Georgia',
                                      fontStyle: FontStyle.italic,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 6,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 22),
                          _buildParchmentButton(
                            context: context,
                            label:
                                _busy ? 'Please wait...' : 'Restore Yesterday',
                            leadingIcon: Icons.history,
                            onTap: _busy ? () {} : _tryRestore,
                            isSecondary: false,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: _kStreakGold.withOpacity(0.95),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: isTablet ? 15 : 14,
                                    fontFamily: 'Georgia',
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: const [
                                    TextSpan(text: 'Uses '),
                                    TextSpan(
                                      text: '50',
                                      style: TextStyle(color: _kStreakGold),
                                    ),
                                    TextSpan(text: ' Faith Credits'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: _kStreakGold.withOpacity(0.9),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  textAlign: TextAlign.left,
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: isTablet ? 13 : 12.5,
                                      fontFamily: 'Georgia',
                                      height: 1.35,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text:
                                            'Note: Yesterday Streaks can be restored within ',
                                      ),
                                      TextSpan(
                                        text: '24 hours',
                                        style: TextStyle(
                                          color: _kStreakGold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(text: '.'),
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
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 30 : 22,
                  4,
                  isTablet ? 30 : 22,
                  10,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _buildParchmentButton(
                      context: context,
                      label: 'Start New Journey',
                      onTap: () => _startNewJourneyFromPaused(context),
                      isSecondary: true,
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

/// 1. How is your connection with God today?
class StreakConnectionScreen extends StatefulWidget {
  const StreakConnectionScreen({
    super.key,
    this.viewOnly = false,
    this.initialSliderValue,
    this.openedFromFaithJourney = false,
    this.faithJourneyPageController,
    this.onFaithJourneyItemResolved,
  });

  /// When true, slider is read-only and the flow does not advance / touch streak prefs.
  final bool viewOnly;

  /// Restored slider position from stored day item (0–1).
  final double? initialSliderValue;

  /// Opened from Home → Faith Journey → Connect (stacked on Daily Journey).
  final bool openedFromFaithJourney;

  /// When set, this screen is inside [FaithJourneyStepPager] (swipe handled by PageView).
  final PageController? faithJourneyPageController;

  final ValueChanged<MoodPrayerItem>? onFaithJourneyItemResolved;

  @override
  State<StreakConnectionScreen> createState() => _StreakConnectionScreenState();
}

class _StreakConnectionScreenState extends State<StreakConnectionScreen> {
  // UI shows 5 stops (Very Far/Far/Growing/Close/Very Close),
  // but we still map it into the existing 3 buckets for content selection.
  double _value = 0.5;
  bool _sliderInteracted = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSliderValue != null) {
      _value = _snap(widget.initialSliderValue!.clamp(0.0, 1.0));
      if (!widget.viewOnly) {
        _sliderInteracted = true;
      }
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
    // 0.00 (Very Far) + 0.25 (Far) => bucket 0
    // 0.50 (Growing) => bucket 1
    // 0.75 (Close) + 1.00 (Very Close) => bucket 2
    if (_value <= 0.375) return 0;
    if (_value <= 0.625) return 1;
    return 2;
  }

  /// Which label to highlight for UI: 0=Very Far, 1=Far, 2=Growing, 3=Close, 4=Very Close.
  /// Each slider position highlights its own label.
  int get _activeLabelIndex {
    if (_value <= 0.125) return 0;
    if (_value <= 0.375) return 1;
    if (_value <= 0.625) return 2;
    if (_value <= 0.875) return 3;
    return 4;
  }

  double _snap(double v) => (v * 4).round() / 4;

  void _popBackToFaithJourney() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Get.back();
  }

  void _dismissConnection() {
    if (widget.openedFromFaithJourney) {
      _popBackToFaithJourney();
      return;
    }
    if (widget.viewOnly && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _goToHome(context);
  }

  void _returnToHomeFromFaithJourney() {
    _goToHome(context);
  }

  Widget _connectionHonestyCard(BuildContext context) {
    final textColor = _streakTextColor(context);
    final isDark = _isStreakDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.06),
                  ]
                : const [
                    _kParchmentLight,
                    _kParchmentMid,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.14)
                : _kInkSepia.withOpacity(0.22),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: _kInkBrown.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : _kStreakCream,
                shape: BoxShape.circle,
                border: Border.all(color: _kStreakGold, width: 1.5),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: _kStreakGold,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thank you for being honest.',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 450 ? 16 : 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: textColor,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This helps us show you verses, devotions and prayers that speak to your heart today.',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 450 ? 14 : 13,
                      height: 1.4,
                      color: textColor.withOpacity(0.82),
                      fontFamily: 'Georgia',
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

  Widget _connectionPrivacyNote(BuildContext context) {
    final textColor = _streakTextColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 16,
            color: textColor.withOpacity(0.55),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Your reflection is private and secure.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 450 ? 13 : 12,
                color: textColor.withOpacity(0.55),
                fontFamily: 'Georgia',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _streakGradientColors(context);
    return Scaffold(
      // Prevent yellow/brown flash when this route is dismissed or replaced.
      backgroundColor: gradientColors.first,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _streakCenteredStepHeader(
                context: context,
                step: 1,
                leftActions: widget.openedFromFaithJourney
                    ? IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: _streakTextColor(context)),
                        onPressed: _popBackToFaithJourney,
                      )
                    : widget.viewOnly
                        ? IconButton(
                            icon: Icon(Icons.arrow_back_ios,
                                color: _streakTextColor(context)),
                            onPressed: _dismissConnection,
                          )
                        : const SizedBox(width: 48, height: 48),
                rightActions: IconButton(
                  icon: Icon(Icons.close, color: _streakTextColor(context)),
                  onPressed: widget.openedFromFaithJourney
                      ? _returnToHomeFromFaithJourney
                      : _dismissConnection,
                  tooltip: 'Close',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
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
                      'Choose what feels closest to your heart.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 450
                            ? 18
                            : 15,
                        color: _streakTextColor(context).withOpacity(0.9),
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Very Far',
                                          textAlign: TextAlign.center,
                                          style: _labelStyle(context,
                                              active: _activeLabelIndex == 0)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: AnimatedOpacity(
                                      opacity:
                                          _activeLabelIndex == 1 ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 160),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Far',
                                          textAlign: TextAlign.center,
                                          style: _labelStyle(context,
                                              active:
                                                  _activeLabelIndex == 1),
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
                                      child: Text('Growing',
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
                                      opacity:
                                          _activeLabelIndex == 3 ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 160),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Close',
                                          textAlign: TextAlign.center,
                                          style: _labelStyle(context,
                                              active:
                                                  _activeLabelIndex == 3),
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
                                      child: Text('Very Close',
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
                                activeTrackColor: _isStreakDark(context)
                                    ? Colors.white.withOpacity(0.85)
                                    : _kStreakBrown,
                                inactiveTrackColor: _streakPanelColor(context),
                                trackShape: const _FullWidthSliderTrackShape(),
                                thumbColor: _isStreakDark(context)
                                    ? Colors.white
                                    : _kStreakBrown,
                                overlayColor: (_isStreakDark(context)
                                        ? Colors.white
                                        : _kStreakBrown)
                                    .withOpacity(0.12),
                                trackHeight: 5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 11,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 18,
                                ),
                                activeTickMarkColor: Colors.transparent,
                                inactiveTickMarkColor: Colors.transparent,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  const double dotSize = 8.0;
                                  const double dotRadius = dotSize / 2;
                                  final trackW = constraints.maxWidth;
                                  final dotFill = _isStreakDark(context)
                                      ? Colors.white.withOpacity(0.5)
                                      : const Color(0xFFF0E8DC);
                                  final dotBorder = (_isStreakDark(context)
                                          ? Colors.white
                                          : const Color(0xFF8B7355))
                                      .withOpacity(0.5);

                                  // Match Material Slider thumb centers on full-width track:
                                  // thumb x = trackLeft + trackWidth * (i / divisions).
                                  double dotLeftForIndex(int i) {
                                    return (trackW * (i / 4)) - dotRadius;
                                  }

                                  return SizedBox(
                                    height: 48,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Slider(
                                          value: _value,
                                          divisions: 4,
                                          onChanged: widget.viewOnly
                                              ? null
                                              : (v) => setState(() {
                                                    _sliderInteracted = true;
                                                    _value = _snap(v);
                                                  }),
                                        ),
                                        for (int i = 0; i < 5; i++)
                                          Positioned(
                                            left: dotLeftForIndex(i),
                                            top: 0,
                                            bottom: 0,
                                            child: Center(
                                              child: IgnorePointer(
                                                child: Container(
                                                  width: dotSize,
                                                  height: dotSize,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: dotFill,
                                                    border: Border.all(
                                                      color: dotBorder,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _sliderInteracted && !widget.viewOnly
                    ? Padding(
                        key: const ValueKey('honesty-card'),
                        padding: const EdgeInsets.only(top: 28),
                        child: _connectionHonestyCard(context),
                      )
                    : const SizedBox(
                        key: ValueKey('honesty-spacer'),
                        height: 28,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: widget.viewOnly
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _streakPhotoPrimaryButton(
                            context: context,
                            label: 'Continue',
                            showShadow: false,
                            onPressed: () async {
                              final dayKey =
                                  await _currentStreakFlowProgressDayKey();
                              final byDay = await _readStreakFlowItemByDay();
                              MoodPrayerItem? item =
                                  _deserializeMoodPrayerItem(byDay[dayKey]);
                              item ??= await MoodPrayerLoader.pickItem(
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
                                  SharPreferences.streakFlowStepsCompletedToday,
                                  1);
                              await _storeActiveStreakFlowSteps(1);
                              if (!mounted) return;
                              final storedItem =
                                  item!.copyWith(connectionSliderValue: _value);
                              if (widget.faithJourneyPageController != null) {
                                widget.onFaithJourneyItemResolved
                                    ?.call(storedItem);
                                await _animateFaithJourneyPage(
                                  widget.faithJourneyPageController,
                                  1,
                                );
                                return;
                              }
                              await precacheStreakPhotoBackgrounds(context);
                              if (!mounted) return;
                              Get.to(() => StreakVerseScreen(
                                    item: storedItem,
                                    openedFromFaithJourney:
                                        widget.openedFromFaithJourney,
                                  ));
                            },
                          ),
                          const SizedBox(height: 10),
                          _connectionPrivacyNote(context),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              final today = DateTime.now()
                                  .toIso8601String()
                                  .split('T')[0];
                              await SharPreferences.setString(
                                  SharPreferences.streakFlowDismissedDate,
                                  today);
                              // Skip is not streak completion — never queue rating.
                              await SharPreferences.setInt(
                                  SharPreferences
                                      .pendingStreakCompleteCelebration,
                                  0);
                              await SharPreferences.setBoolean(
                                  SharPreferences.deferUpgradeAlert, false);
                              _goToHome(context);
                            },
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width > 450
                                    ? 16
                                    : 15,
                                fontWeight: FontWeight.w600,
                                color: _streakTextColor(context)
                                    .withOpacity(0.85),
                                fontFamily: 'Georgia',
                                decoration: TextDecoration.underline,
                                decorationColor: _streakTextColor(context)
                                    .withOpacity(0.6),
                              ),
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

/// Standard button helper for popups matching other app popups
Widget _buildStandardButton({
  required BuildContext context,
  required String label,
  required VoidCallback onTap,
  required Color bgColor,
  required bool isDark,
  bool isSecondary = false,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSecondary 
              ? Colors.transparent
              : bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSecondary 
                ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSecondary 
                ? (isDark ? Colors.white : Colors.black)
                : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Georgia',
          ),
        ),
      ),
    ),
  );
}

/// Helper for StreakPausedScreen buttons with proper dark mode support
Widget _buildParchmentButton({
  required BuildContext context,
  required String label,
  required VoidCallback onTap,
  bool isSecondary = false,
  IconData? leadingIcon,
}) {
  final isDark = _isStreakDark(context);
  final primaryIcon = leadingIcon ?? Icons.local_fire_department;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: isSecondary
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD4AF37),
                    Color(0xFFC9A227),
                    Color(0xFFB8860B),
                  ],
                ),
          color: isSecondary
              ? Colors.black.withOpacity(0.38)
              : null,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSecondary
                ? _kStreakGold.withOpacity(0.85)
                : (isDark ? _kStreakGold : Colors.transparent),
            width: isSecondary ? 1.5 : (isDark ? 1.5 : 0),
          ),
          boxShadow: [
            if (!isSecondary)
              BoxShadow(
                color: _kStreakGold.withOpacity(isDark ? 0.35 : 0.28),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isSecondary) ...[
              Icon(primaryIcon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ] else ...[
              Icon(Icons.eco_outlined, color: _kStreakGold, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width > 450 ? 20 : 18,
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
  final isWhiteLight = _isStreakWhiteLight(context);
  final baseTextColor = _streakTextColor(context);
  // Make button match the streak UI palette in both themes.
  final btnBg = isDark
      ? const Color(0xFF2A1F12)
      : (isWhiteLight ? const Color(0xFF424242) : _kStreakGold);
  final labelColor = isDark ? const Color(0xFFF5EAC6) : Colors.white;
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
            border: Border.all(color: _kCandleGold, width: 1.5),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: baseTextColor.withOpacity(0.18),
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
    this.openedFromFaithJourney = false,
    this.faithJourneyPageController,
  });
  final MoodPrayerItem item;
  final bool viewOnly;
  final bool openedFromFaithJourney;
  final PageController? faithJourneyPageController;

  @override
  State<StreakVerseScreen> createState() => _StreakVerseScreenState();
}

class _StreakVerseScreenState extends State<StreakVerseScreen> {
  bool _saved = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheStreakPhotoBackgrounds(context);
      _loadSaved();
    });
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
      body: _streakPhotoVerseBackgroundStack(
        context: context,
        assetPath: 'assets/back1.png',
        child: SafeArea(
          child: Column(
            children: [
              _streakPhotoTopBar(
                context: context,
                step: 2,
                onBack: () {
                  if (widget.openedFromFaithJourney) {
                    _popBackToFaithJourney(context);
                  } else {
                    Get.back();
                  }
                },
                onClose: () {
                  if (widget.openedFromFaithJourney) {
                    _goToHome(context);
                  } else {
                    _goToHome(context);
                  }
                },
              ),
              _streakPhotoStepHeader(
                context: context,
                icon: Icons.menu_book_rounded,
                title: 'Verse of the Day',
                subtitle: 'God\'s Word for your heart today.',
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Screenshot(
                            controller: _screenshotController,
                            child: _streakStepContentBox(
                              context,
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '“',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 40,
                                      height: 1,
                                      color: _kStreakPhotoGold,
                                      fontFamily: 'Georgia',
                                      fontWeight: FontWeight.w700,
                                      shadows: _kStreakPhotoSoftTextShadows,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.verseText,
                                    textAlign: TextAlign.center,
                                    style: _streakPhotoBodyStyle(context).copyWith(
                                      fontSize: MediaQuery.of(context).size.width > 450
                                          ? 20
                                          : 18,
                                      height: 1.55,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    item.verseReference,
                                    textAlign: TextAlign.center,
                                    style: _streakPhotoReferenceStyle(context).copyWith(
                                      fontSize: 16,
                                      fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _streakGoldDivider(
                                    center: _streakDividerHeart(),
                                  ),
                                ],
                              ),
                              useContentScrim: false,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _streakPhotoVerseBottomShadow(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Always show Save & Share (including after all steps completed).
                      _streakPhotoVerseSaveShareRow(
                        saved: _saved,
                        saveLabel: _saved ? 'Saved' : 'Save',
                        onSave: () async {
                          if (_saved) {
                            await StreakSavedStorage.remove(
                                'verse', item.verseReference, item.verseText);
                            if (mounted) setState(() => _saved = false);
                            if (context.mounted) {
                              _showSavedToast(context, saved: false);
                            }
                          } else {
                            await StreakSavedStorage.add(StreakSavedItem(
                              type: 'verse',
                              title: item.verseReference,
                              body: item.verseText,
                              savedAt: DateTime.now().toIso8601String(),
                            ));
                            if (mounted) setState(() => _saved = true);
                            if (context.mounted) {
                              _showSavedToast(context, saved: true);
                            }
                          }
                        },
                        onShare: () async {
                          final shareContext = context;
                          await _shareStreakFlowImageWithLoader(
                            shareContext,
                            backgroundAsset: 'assets/back1.png',
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '"${item.verseText}"',
                                  textAlign: TextAlign.center,
                                  style: _streakShareBodyStyle(),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  item.verseReference,
                                  textAlign: TextAlign.center,
                                  style: _streakShareReferenceStyle(),
                                ),
                              ],
                            ),
                            fallbackText:
                                '${item.verseText}\n- ${item.verseReference}',
                          );
                        },
                      ),
                      if (!widget.viewOnly) ...[
                        const SizedBox(height: 24),
                        _streakPhotoPrimaryButton(
                          context: context,
                          label: 'Read Devotional',
                          onPressed: () async {
                            await SharPreferences.setInt(
                                SharPreferences.streakFlowStepsCompletedToday,
                                2);
                            await _storeActiveStreakFlowSteps(2);
                            if (!mounted) return;
                            if (widget.faithJourneyPageController != null) {
                              await _animateFaithJourneyPage(
                                widget.faithJourneyPageController,
                                2,
                              );
                              return;
                            }
                            await precacheStreakPhotoBackgrounds(context);
                            if (!mounted) return;
                            Get.to(() => StreakDevotionalScreen(
                                  item: item,
                                  viewOnly: widget.viewOnly,
                                  openedFromFaithJourney:
                                      widget.openedFromFaithJourney,
                                ));
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Explore deeper insights and grow in your faith.',
                          textAlign: TextAlign.center,
                          style: _streakPhotoCaptionStyle(context),
                        ),
                      ],
                    ],
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

/// 3. Devotional Insight
class StreakDevotionalScreen extends StatefulWidget {
  const StreakDevotionalScreen({
    super.key,
    required this.item,
    this.viewOnly = false,
    this.openedFromFaithJourney = false,
    this.faithJourneyPageController,
  });
  final MoodPrayerItem item;
  final bool viewOnly;
  final bool openedFromFaithJourney;
  final PageController? faithJourneyPageController;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      precacheStreakPhotoBackgrounds(context);
      _loadSaved();
      if (widget.faithJourneyPageController != null) {
        await _loadMusicMuted();
        return;
      }
      await _loadMusicMuted();
      if (!_isAudioMuted) {
        await _StreakFlowBgMusic.play();
      }
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
      body: _streakPhotoVerseBackgroundStack(
        context: context,
        assetPath: 'assets/back2.png',
        child: SafeArea(
          child: Column(
            children: [
              _streakPhotoTopBar(
                context: context,
                step: 3,
                showMusic: true,
                isMusicMuted: _isAudioMuted,
                onMusicToggle: _toggleAudio,
                onBack: () async {
                  await _StreakFlowBgMusic.stop();
                  if (!context.mounted) return;
                  if (widget.openedFromFaithJourney) {
                    _popBackToFaithJourney(context);
                  } else {
                    Get.back();
                  }
                },
                onClose: () async {
                  await _StreakFlowBgMusic.stop();
                  if (!context.mounted) return;
                  if (widget.openedFromFaithJourney) {
                    _goToHome(context);
                  } else {
                    _goToHome(context);
                  }
                },
              ),
              _streakPhotoStepHeader(
                context: context,
                icon: Icons.local_fire_department_rounded,
                title: 'Devotional Moment',
                subtitle: 'A short reflection to encourage your heart today.',
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Screenshot(
                            controller: _screenshotController,
                            child: _streakStepContentBox(
                              context,
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.devotionalText,
                                    textAlign: TextAlign.center,
                                    style: _streakPhotoBodyStyle(context),
                                  ),
                                  const SizedBox(height: 20),
                                  _streakGoldDivider(
                                    center: _streakDividerCross(),
                                  ),
                                ],
                              ),
                              useContentScrim: false,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _streakPhotoVerseBottomShadow(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Always show Save & Share (including after all steps completed).
                      _streakPhotoSaveShareRow(
                        saved: _saved,
                        saveLabel: _saved ? 'Saved' : 'Save',
                        onSave: () async {
                          const title = 'Devotional Moment';
                          if (_saved) {
                            await StreakSavedStorage.remove(
                                'devotional', title, item.devotionalText);
                            if (mounted) setState(() => _saved = false);
                            if (context.mounted) {
                              _showSavedToast(context, saved: false);
                            }
                          } else {
                            await StreakSavedStorage.add(StreakSavedItem(
                              type: 'devotional',
                              title: title,
                              body: item.devotionalText,
                              savedAt: DateTime.now().toIso8601String(),
                            ));
                            if (mounted) setState(() => _saved = true);
                            if (context.mounted) {
                              _showSavedToast(context, saved: true);
                            }
                          }
                        },
                        onShare: () async {
                          final shareContext = context;
                          await _shareStreakFlowImageWithLoader(
                            shareContext,
                            backgroundAsset: 'assets/back2.png',
                            content: Text(
                              item.devotionalText,
                              textAlign: TextAlign.center,
                              style: _streakShareBodyStyle(),
                            ),
                            fallbackText: item.devotionalText,
                          );
                        },
                      ),
                      if (!widget.viewOnly) ...[
                        const SizedBox(height: 16),
                        _streakPhotoPrimaryButton(
                          context: context,
                          label: 'Continue to Prayer',
                          onPressed: () async {
                            await SharPreferences.setInt(
                                SharPreferences.streakFlowStepsCompletedToday,
                                3);
                            await _storeActiveStreakFlowSteps(3);
                            if (!mounted) return;
                            if (widget.faithJourneyPageController != null) {
                              await _animateFaithJourneyPage(
                                widget.faithJourneyPageController,
                                3,
                              );
                              return;
                            }
                            await precacheStreakPhotoBackgrounds(context);
                            if (!mounted) return;
                            Get.to(() => StreakPrayerScreen(
                                  item: item,
                                  viewOnly: widget.viewOnly,
                                  openedFromFaithJourney:
                                      widget.openedFromFaithJourney,
                                ));
                          },
                        ),
                      ],
                    ],
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

/// 4. Prayer for Today
class StreakPrayerScreen extends StatefulWidget {
  const StreakPrayerScreen({
    super.key,
    required this.item,
    this.viewOnly = false,
    this.openedFromFaithJourney = false,
    this.faithJourneyPageController,
  });
  final MoodPrayerItem item;
  final bool viewOnly;
  final bool openedFromFaithJourney;
  final PageController? faithJourneyPageController;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      precacheStreakPhotoBackgrounds(context);
      _loadSaved();
      if (widget.faithJourneyPageController != null) {
        await _loadMusicMuted();
        return;
      }
      await _loadMusicMuted();
      if (!_isAudioMuted) {
        await _StreakFlowBgMusic.play();
      }
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
      body: _streakPhotoVerseBackgroundStack(
        context: context,
        assetPath: 'assets/back1.png',
        child: SafeArea(
          child: Column(
            children: [
              _streakPhotoTopBar(
                context: context,
                step: 4,
                showMusic: true,
                isMusicMuted: _isAudioMuted,
                onMusicToggle: _toggleAudio,
                onBack: () async {
                  await _StreakFlowBgMusic.stop();
                  if (!context.mounted) return;
                  if (widget.openedFromFaithJourney) {
                    _popBackToFaithJourney(context);
                  } else {
                    Get.back();
                  }
                },
                onClose: () async {
                  await _StreakFlowBgMusic.stop();
                  if (!context.mounted) return;
                  if (widget.openedFromFaithJourney) {
                    _goToHome(context);
                  } else {
                    _goToHome(context);
                  }
                },
              ),
              _streakPhotoStepHeader(
                context: context,
                icon: Icons.volunteer_activism_rounded,
                title: 'Prayer Moment',
                subtitle: 'Talk to God and pour out your heart.',
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Screenshot(
                            controller: _screenshotController,
                            child: _streakStepContentBox(
                              context,
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.prayerText,
                                    textAlign: TextAlign.center,
                                    style: _streakPhotoBodyStyle(context),
                                  ),
                                  const SizedBox(height: 20),
                                  _streakGoldDivider(
                                    center: _streakDividerCross(),
                                  ),
                                ],
                              ),
                              useContentScrim: false,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _streakPhotoVerseBottomShadow(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Always show Save & Share (including after all steps completed).
                      _streakPhotoSaveShareRow(
                        saved: _saved,
                        saveLabel: _saved ? 'Saved' : 'Save',
                        onSave: () async {
                          const title = 'Today\'s Prayer';
                          if (_saved) {
                            await StreakSavedStorage.remove(
                                'prayer', title, item.prayerText);
                            if (mounted) setState(() => _saved = false);
                            if (context.mounted) {
                              _showSavedToast(context, saved: false);
                            }
                          } else {
                            await StreakSavedStorage.add(StreakSavedItem(
                              type: 'prayer',
                              title: title,
                              body: item.prayerText,
                              savedAt: DateTime.now().toIso8601String(),
                            ));
                            if (mounted) setState(() => _saved = true);
                            if (context.mounted) {
                              _showSavedToast(context, saved: true);
                            }
                          }
                        },
                        onShare: () async {
                          final shareContext = context;
                          await _shareStreakFlowImageWithLoader(
                            shareContext,
                            backgroundAsset: 'assets/back1.png',
                            content: Text(
                              item.prayerText,
                              textAlign: TextAlign.center,
                              style: _streakShareBodyStyle(),
                            ),
                            fallbackText: item.prayerText,
                          );
                        },
                      ),
                      if (!widget.viewOnly) ...[
                      const SizedBox(height: 16),
                      _streakPhotoPrimaryButton(
                        context: context,
                        label: 'Amen',
                        leadingIcon: Icons.favorite_border,
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
                            // One notif only after streak done: cancel streak nudges, prefer chat/verse.
                            await DailySlotNotificationHelper
                                .rescheduleEnabledSlots();
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
                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              if (streakCount == 1) {
                                // Day-1 rating only — suppress open ad so they do not overlap.
                                await SharPreferences.setBoolean(
                                    SharPreferences.deferUpgradeAlert, true);
                                await prefs.setString("showopenad", "false");
                                await SharPreferences.setString('OpenAd', '1');
                              } else {
                                // Later streak days: allow open ad on next cold start only.
                                await prefs.setString("showopenad", "true");
                                await SharPreferences.setString('OpenAd', '1');
                              }
                            } catch (_) {}
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
                                      // Standard popup colors matching other app popups
                                      final bgColor = isDark ? const Color(0xFF2A1F12) : Colors.white;
                                      final txtColor = isDark ? Colors.white : Colors.black;
                                      final btnBg = isDark ? const Color(0xFF3B2A1A) : CommanColor.lightDarkPrimary(context);
                                      return Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding:
                                            const EdgeInsets.symmetric(horizontal: 24),
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 360),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isDark ? const Color(0xFF3B2A1A) : Colors.grey.shade300,
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
                                                    color: txtColor,
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
                                                    color: isDark ? Colors.white70 : Colors.black87,
                                                    fontFamily: 'Georgia',
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: _buildStandardButton(
                                                        context: context,
                                                        label: 'Later',
                                                        isSecondary: true,
                                                        onTap: () =>
                                                            Navigator.of(context).pop(false),
                                                        bgColor: btnBg,
                                                        isDark: isDark,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: _buildStandardButton(
                                                        context: context,
                                                        label: 'Start Today',
                                                        isSecondary: false,
                                                        onTap: () =>
                                                            Navigator.of(context).pop(true),
                                                        bgColor: btnBg,
                                                        isDark: isDark,
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
                      ],
                    ],
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
  int _streakDays = 0;
  bool _showStreakCompletedToast = true;
  Timer? _streakCompletedToastTimer;

  Future<void> _shareStreakCompleted() async {
    HapticFeedback.lightImpact();
    EasyLoading.show(
      status: 'Preparing...',
      maskType: EasyLoadingMaskType.clear,
    );
    final shareContext = context;
    final streakDays = _streakDays;
    try {
      final image = await _captureStreakShareImage(
        shareContext,
        backgroundAsset: 'assets/back1.png',
        content: _streakCompleteShareContent(streakDays),
      );
      await EasyLoading.dismiss();
      if (!shareContext.mounted) return;
      await _shareAsImage(
        shareContext,
        imageBytes: image,
        imageFileName: _streakCompletionShareImageFileName(streakDays),
        fallbackText: _streakCompletionShareMessageWithLink(streakDays),
        appendAppUrlToFallback: false,
      );
    } catch (_) {
      await EasyLoading.dismiss();
    }
  }

  void _goToHome(BuildContext context) {
    try {
      final provider = Provider.of<DownloadProvider>(context, listen: false);
      provider.warmDataBeforeHomeScreen();
    } catch (e) {
      debugPrint('warmDataBeforeHomeScreen error: $e');
    }
    Get.offAll(
      () => HomeScreen(
        From: "splash",
        selectedVerseNumForRead: "",
        selectedBookForRead: "",
        selectedChapterForRead: "",
        selectedBookNameForRead: "",
        selectedVerseForRead: "",
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 280),
      opaque: true,
    );
  }

  Future<void> _onContinuePressed(BuildContext context) async {
    final count = await SharPreferences.getInt(
        SharPreferences.pendingStreakCompleteCelebration);
    final hasShownLeaveRating = await SharPreferences.getBoolean(
            SharPreferences.hasShownLeaveRatingScreen) ??
        false;
    // Leave Rating only after the very first streak completion — never again.
    if (count == 1 && !hasShownLeaveRating) {
      await SharPreferences.setBoolean(
          SharPreferences.hasShownLeaveRatingScreen, true);
      Get.to(
        () => const LeaveRatingScreen(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 280),
        opaque: true,
      );
      return;
    }
    _goToHome(context);
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
    SharPreferences.getInt(SharPreferences.pendingStreakCompleteCelebration)
        .then((value) {
      if (!mounted) return;
      setState(() => _streakDays = value ?? 0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) precacheStreakPhotoBackgrounds(context);
    });
    // Top "Streak Completed!" should feel like a short toast, not a fixed header.
    _streakCompletedToastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _showStreakCompletedToast = false);
    });
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
    _streakCompletedToastTimer?.cancel();
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
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _kStreakPhotoPlaceholder,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _streakPhotoBackgroundImage('assets/back1.png'),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.42),
                  Colors.black.withOpacity(0.28),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),
          _streakPhotoReadabilityOverlays(context),
          _lightRaysOverlay(true),
          _celebrationBurstOverlay(true),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: _showStreakCompletedToast ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: !_showStreakCompletedToast,
                          child: Text(
                            'Streak Completed!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth > 450 ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                              fontFamily: 'Georgia',
                              shadows: _kStreakPhotoSoftTextShadows,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 22,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          onPressed: _shareStreakCompleted,
                          tooltip: 'Share',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: FutureBuilder<int?>(
                      future: SharPreferences.getInt(
                          SharPreferences.pendingStreakCompleteCelebration),
                      builder: (context, snap) {
                        final streakDays = (snap.data ?? 0).clamp(0, 9999);
                        final creditsEarned = streakDays * 20;

                        return FadeTransition(
                          opacity: _fade,
                          child: Column(
                            children: [
                              ScaleTransition(
                                scale: _scale,
                                child: _StreakCompleteFlameBadge(
                                  twinkleCtrl: _twinkleCtrl,
                                ),
                              ),
                              const SizedBox(height: 18),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: screenWidth > 450 ? 34 : 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Georgia',
                                    height: 1.15,
                                    shadows: _kStreakPhotoTextShadows,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: streakDays > 0
                                          ? 'Day $streakDays '
                                          : '',
                                    ),
                                    const TextSpan(
                                      text: 'Streak!',
                                      style: TextStyle(
                                        color: _kStreakPhotoGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'You\'re building a beautiful habit of seeking God daily.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenWidth > 450 ? 15 : 14,
                                  height: 1.45,
                                  color: Colors.white.withOpacity(0.92),
                                  fontFamily: 'Georgia',
                                  shadows: _kStreakPhotoSoftTextShadows,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _streakGoldDivider(center: _streakDividerHeart()),
                              const SizedBox(height: 18),
                              SlideTransition(
                                position: _cardSlide,
                                child: _StreakCompleteRewardCard(
                                  creditsLabel: '+20 Faith Credits',
                                ),
                              ),
                              const SizedBox(height: 14),
                              SlideTransition(
                                position: _cardSlide,
                                child: _StreakCompleteMotivationCard(),
                              ),
                              const SizedBox(height: 14),
                              SlideTransition(
                                position: _cardSlide,
                                child: _StreakCompleteStatsBar(
                                  daysStreak: streakDays,
                                  versesRead: streakDays,
                                  prayersOffered: streakDays,
                                  faithCreditsEarned: creditsEarned,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _streakPhotoPrimaryButton(
                                context: context,
                                label: 'Continue My Journey',
                                onPressed: () => _onContinuePressed(context),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
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

class _StreakCompleteFlameBadge extends StatelessWidget {
  const _StreakCompleteFlameBadge({required this.twinkleCtrl});

  final AnimationController twinkleCtrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            left: 18,
            child: Icon(
              Icons.auto_awesome,
              size: 14,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          Positioned(
            top: 22,
            right: 12,
            child: Icon(
              Icons.auto_awesome,
              size: 12,
              color: _kStreakPhotoGold.withOpacity(0.85),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 10,
            child: Icon(
              Icons.auto_awesome,
              size: 11,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 20,
            child: Icon(
              Icons.auto_awesome,
              size: 13,
              color: _kStreakPhotoGold.withOpacity(0.8),
            ),
          ),
          AnimatedBuilder(
            animation: twinkleCtrl,
            builder: (context, child) {
              final pulse = 1 + (twinkleCtrl.value * 0.05);
              return Transform.scale(
                scale: pulse,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _kStreakPhotoGold.withOpacity(0.55),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kStreakPhotoGold.withOpacity(
                          0.35 + (twinkleCtrl.value * 0.25),
                        ),
                        blurRadius: 28 + (twinkleCtrl.value * 16),
                        spreadRadius: 4 + (twinkleCtrl.value * 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.28),
                        border: Border.all(
                          color: _kStreakPhotoGold.withOpacity(0.75),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StreakCompleteRewardCard extends StatelessWidget {
  const _StreakCompleteRewardCard({required this.creditsLabel});

  final String creditsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REWARD EARNED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: _kStreakPhotoGold.withOpacity(0.95),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: _kStreakPhotoGold,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        creditsLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Added to your wallet',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.72),
                    fontFamily: 'Georgia',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/gold-treasure-icon.png',
            width: 78,
            height: 72,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _StreakCompleteMotivationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite_border,
            color: _kStreakPhotoGold.withOpacity(0.95),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 450 ? 15 : 14,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.92),
                  fontFamily: 'Georgia',
                ),
                children: const [
                  TextSpan(
                    text: 'Keep going! ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'Your consistency is preparing you for something ',
                  ),
                  TextSpan(
                    text: 'greater.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCompleteStatsBar extends StatelessWidget {
  const _StreakCompleteStatsBar({
    required this.daysStreak,
    required this.versesRead,
    required this.prayersOffered,
    required this.faithCreditsEarned,
  });

  final int daysStreak;
  final int versesRead;
  final int prayersOffered;
  final int faithCreditsEarned;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _StreakCompleteStatItem(
              iconAsset: 'assets/streak_completed_icons/days_strek.png',
              tintIconAsset: false,
              iconColor: _kStreakPhotoGold,
              value: '$daysStreak',
              label: 'Days Streak',
            ),
          ),
          Expanded(
            child: _StreakCompleteStatItem(
              iconAsset: 'assets/streak_completed_icons/verse-read_complete.png',
              tintIconAsset: false,
              iconColor: const Color(0xFFB39DDB),
              value: '$versesRead',
              label: 'Verses Read',
            ),
          ),
          Expanded(
            child: _StreakCompleteStatItem(
              iconAsset: 'assets/streak_completed_icons/Mask group.png',
              tintIconAsset: false,
              iconColor: const Color(0xFF81C784),
              value: '$prayersOffered',
              label: 'Prayer\nOffered',
            ),
          ),
          Expanded(
            child: _StreakCompleteStatItem(
              iconAsset:
                  'assets/streak_completed_icons/faith_credits_earned.png',
              tintIconAsset: false,
              iconColor: const Color(0xFF64B5F6),
              value: '$faithCreditsEarned',
              label: 'Faith Credits\nEarned',
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _StreakCompleteStatItem extends StatelessWidget {
  const _StreakCompleteStatItem({
    this.icon,
    this.iconAsset,
    this.tintIconAsset = true,
    required this.iconColor,
    required this.value,
    required this.label,
  }) : assert(icon != null || iconAsset != null);

  final IconData? icon;
  final String? iconAsset;
  final bool tintIconAsset;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 360;
    final iconSlotHeight = compact ? 30.0 : 32.0;
    final labelSlotHeight = compact ? 26.0 : 28.0;
    final iconSize = compact ? 18.0 : 20.0;
    final labelStyle = TextStyle(
      fontSize: compact ? 9 : 10,
      height: 1.2,
      color: Colors.white.withOpacity(0.72),
      fontFamily: 'Georgia',
    );
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: iconSlotHeight,
            width: double.infinity,
            child: Center(
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      color: tintIconAsset ? iconColor : null,
                      colorBlendMode: tintIconAsset ? BlendMode.srcIn : null,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.volunteer_activism_outlined,
                        color: iconColor,
                        size: iconSize,
                      ),
                    )
                  : Icon(icon!, color: iconColor, size: iconSize),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: labelSlotHeight,
            width: double.infinity,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                strutStyle: StrutStyle(
                  fontSize: labelStyle.fontSize,
                  height: labelStyle.height,
                  fontFamily: labelStyle.fontFamily,
                  forceStrutHeight: true,
                ),
                style: labelStyle,
              ),
            ),
          ),
        ],
      ),
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
