import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:screenshot/screenshot.dart';
import 'package:biblebookapp/streak_flow/mood_prayer_data.dart';
import 'package:biblebookapp/streak_flow/streak_saved_storage.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
Widget _streakStepContentBox(BuildContext context, Widget child) {
  return child;
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

/// Top/bottom vignette for readable white text on photo backgrounds (UI only).
Widget _streakPhotoReadabilityOverlays(BuildContext context) {
  final h = MediaQuery.sizeOf(context).height;
  final topH = h * 0.18;
  final bottomH = h * 0.55;

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
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.22),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
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
                Colors.black.withOpacity(0.82),
                Colors.black.withOpacity(0.5),
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
  Shadow(color: Color(0xE6000000), blurRadius: 14, offset: Offset(0, 2)),
  Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1)),
];

const List<Shadow> _kStreakPhotoSoftTextShadows = [
  Shadow(color: Color(0xCC000000), blurRadius: 10, offset: Offset(0, 1)),
  Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1)),
];

TextStyle _streakPhotoTitleStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 28 : 24,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFamily: 'Georgia',
      shadows: _kStreakPhotoTextShadows,
    );

TextStyle _streakPhotoSubtitleStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 15 : 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.95),
      fontFamily: 'Georgia',
      height: 1.4,
      shadows: _kStreakPhotoSoftTextShadows,
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

TextStyle _streakPhotoVerseTitleStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 30 : 26,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1A1A1A),
      fontFamily: 'Georgia',
      height: 1.15,
      letterSpacing: 0.2,
      shadows: [
        Shadow(
          color: Colors.white.withOpacity(0.85),
          blurRadius: 10,
          offset: const Offset(0, 0),
        ),
        Shadow(
          color: Colors.white.withOpacity(0.45),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );

TextStyle _streakPhotoVerseSubtitleStyle(BuildContext context) => TextStyle(
      fontSize: MediaQuery.of(context).size.width > 450 ? 15 : 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF2E2E2E),
      fontFamily: 'Georgia',
      height: 1.35,
      shadows: [
        Shadow(
          color: Colors.white.withOpacity(0.75),
          blurRadius: 8,
          offset: const Offset(0, 0),
        ),
        Shadow(
          color: Colors.white.withOpacity(0.35),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
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
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: _streakPhotoVerseSubtitleStyle(context),
        ),
        const SizedBox(height: 12),
        _streakPhotoShortGoldLine(),
        const SizedBox(height: 18),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                Expanded(
                  child: Center(child: content),
                ),
                const SizedBox(height: 14),
                Row(
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
                        color: Colors.white.withOpacity(0.92),
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        shadows: const [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
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
      delay: const Duration(milliseconds: 350),
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
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [
          XFile.fromData(
            imageBytes,
            mimeType: 'image/png',
            name: 'streak_share.png',
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
  static const String _restoreDebitedDateKey =
      'streak_flow_restore_debited_date_v1';
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
              // Add a subtle dark overlay so top pause icon and bottom note remain readable.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.22),
                        Colors.transparent,
                        Colors.black.withOpacity(0.18),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
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
                          width: isTablet ? 92 : 86,
                          height: isTablet ? 92 : 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.14),
                            border: Border.all(
                                color: _kStreakGold.withOpacity(0.9), width: 1.6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: _kStreakGold.withOpacity(0.28),
                                blurRadius: 22,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: isTablet ? 58 : 52,
                              height: isTablet ? 58 : 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.55),
                                border: Border.all(
                                    color: _kStreakGold.withOpacity(0.9),
                                    width: 1.6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: _kStreakGold.withOpacity(0.25),
                                    blurRadius: 14,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.pause,
                                color: Colors.white,
                                size: isTablet ? 30 : 28,
                              ),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.52),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.16),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Note: Yesterday Streaks can Restored within 24 hours',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: isTablet ? 15 : 14,
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
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
              _streakCenteredStepHeader(
                context: context,
                step: 1,
                leftActions: widget.viewOnly
                    ? IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: _streakTextColor(context)),
                        onPressed: () async {
                          if (context.mounted &&
                              Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Get.back();
                          }
                        },
                      )
                    : const SizedBox(width: 48, height: 48),
                rightActions: IconButton(
                  icon: Icon(Icons.close, color: _streakTextColor(context)),
                  onPressed: () => _goToHome(context),
                  tooltip: 'Close',
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
                                        child: Text('Surrender',
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
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _parchmentButton(
                            context,
                            label: 'Take the Next Step',
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
                              await precacheStreakPhotoBackgrounds(context);
                              if (!mounted) return;
                              Get.to(() => StreakVerseScreen(item: item!));
                            },
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              final today = DateTime.now()
                                  .toIso8601String()
                                  .split('T')[0];
                              await SharPreferences.setString(
                                  SharPreferences.streakFlowDismissedDate,
                                  today);
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
      body: _streakPhotoBackgroundStack(
        context: context,
        assetPath: 'assets/back1.png',
        child: SafeArea(
          child: Column(
            children: [
              _streakPhotoTopBar(
                context: context,
                step: 2,
                onBack: () => Get.back(),
                onClose: () => _goToHome(context),
              ),
              _streakPhotoVerseHeader(
                context: context,
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _streakPhotoSaveShareRow(
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
                          final image = await _captureStreakShareImage(
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
                      const SizedBox(height: 16),
                      _streakPhotoPrimaryButton(
                        context: context,
                        label: 'Read Devotional',
                        onPressed: () async {
                          await SharPreferences.setInt(
                              SharPreferences.streakFlowStepsCompletedToday, 2);
                          await _storeActiveStreakFlowSteps(2);
                          if (!mounted) return;
                          await precacheStreakPhotoBackgrounds(context);
                          if (!mounted) return;
                          Get.to(() => StreakDevotionalScreen(
                                item: item,
                                viewOnly: widget.viewOnly,
                              ));
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Explore deeper insights and grow in your faith.',
                        textAlign: TextAlign.center,
                        style: _streakPhotoCaptionStyle(context),
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      precacheStreakPhotoBackgrounds(context);
      _loadSaved();
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
      body: _streakPhotoBackgroundStack(
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
                  if (context.mounted) Get.back();
                },
                onClose: () async {
                  await _StreakFlowBgMusic.stop();
                  if (context.mounted) _goToHome(context);
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _streakDevotionalReflectionPrompt(context),
                      _streakPhotoPrimaryButton(
                        context: context,
                        label: 'Continue to Prayer',
                        onPressed: () async {
                          await SharPreferences.setInt(
                              SharPreferences.streakFlowStepsCompletedToday, 3);
                          await _storeActiveStreakFlowSteps(3);
                          if (!mounted) return;
                          await precacheStreakPhotoBackgrounds(context);
                          if (!mounted) return;
                          Get.to(() => StreakPrayerScreen(
                                item: item,
                                viewOnly: widget.viewOnly,
                              ));
                        },
                      ),
                      const SizedBox(height: 14),
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
                          final image = await _captureStreakShareImage(
                            shareContext,
                            backgroundAsset: 'assets/back2.png',
                            content: Text(
                              item.devotionalText,
                              textAlign: TextAlign.center,
                              style: _streakShareBodyStyle(),
                            ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      precacheStreakPhotoBackgrounds(context);
      _loadSaved();
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
      body: _streakPhotoBackgroundStack(
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
                  if (context.mounted) Get.back();
                },
                onClose: () async {
                  await _StreakFlowBgMusic.stop();
                  if (context.mounted) _goToHome(context);
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            // Do not show app-open ad immediately on streak completion.
                            // Instead, schedule it for next cold start (Splash shows it after ~2s).
                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString("showopenad", "true");
                              await SharPreferences.setString('OpenAd', '1');
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
                      const SizedBox(height: 14),
                      _streakPhotoSaveShareRow(
                        saved: _saved,
                        saveLabel: _saved ? 'Saved' : 'Save Prayer',
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
                          final image = await _captureStreakShareImage(
                            shareContext,
                            backgroundAsset: 'assets/back1.png',
                            content: Text(
                              item.prayerText,
                              textAlign: TextAlign.center,
                              style: _streakShareBodyStyle(),
                            ),
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
          borderRadius: BorderRadius.circular(14),
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
              if (isDark)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.62),
                          Colors.black.withOpacity(0.45),
                          Colors.black.withOpacity(0.58),
                        ],
                      ),
                    ),
                  ),
                ),
              // 1. Candlelight rays (same logic, parchment palette)
              _lightRaysOverlay(isDark),
              // 2. Ink-bleed celebration burst (same logic, parchment palette)
              _celebrationBurstOverlay(isDark),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : textColor.withOpacity(0.85),
                  ),
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
                                          // No extra icon shadow (keep clean like design)
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
                                  ? 'Day $streakDays Streak'
                                  : 'Streak Completed!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width > 450
                                        ? 30
                                        : 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : textColor,
                                fontFamily: 'Georgia',
                                letterSpacing: 1.0,
                                shadows: isDark
                                    ? const [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 8),
                            _ManuscriptRule(
                                color: (isDark ? Colors.white : _kInkSepia)
                                    .withOpacity(0.5)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                const SizedBox(height: 8),

                // Scripture-style subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.35)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            'You\'re walking faithfully today.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white.withOpacity(0.95)
                                  : textColor.withOpacity(0.85),
                              fontFamily: 'Georgia',
                              fontStyle: FontStyle.italic,
                              shadows: isDark
                                  ? const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 8,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep the light alive.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white.withOpacity(0.95)
                                  : textColor.withOpacity(0.85),
                              fontFamily: 'Georgia',
                              fontStyle: FontStyle.italic,
                              shadows: isDark
                                  ? const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 8,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
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
