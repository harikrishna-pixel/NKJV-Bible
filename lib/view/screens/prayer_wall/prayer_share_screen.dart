import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';  
import 'package:url_launcher/url_launcher.dart';

class PrayerShareScreen extends StatelessWidget {
  const PrayerShareScreen({
    super.key,
    required this.prayerId,
    required this.title,
    required this.description,
  });

  final String prayerId;
  final String title;
  final String description;

  String get _appLink {
    final androidLink =
        'https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}';
    final iosLink = 'https://itunes.apple.com/app/id${BibleInfo.apple_AppId}';
    return Platform.isIOS ? iosLink : androidLink;
  }

  String get _shareText {
    final t = title.trim().isEmpty ? 'Prayer Request' : title.trim();
    final myWords = PrayerDualDescription.myWords(description);
    final ai = PrayerDualDescription.aiPrayer(description);
    final String d;
    if (myWords != null && ai != null) {
      d = 'My Words:\n$myWords\n\nPrayer Created for You:\n$ai';
    } else {
      d = description.trim();
    }
    final idLine = prayerId.trim().isEmpty ? '' : '\n\nPrayer ID: $prayerId';
    return '$t\n\n$d$idLine\n\nRead more at: $_appLink';
  }

  Rect? _shareOrigin(BuildContext context) {
    final renderObject = context.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    if (box == null) return null;
    final size = box.size;
    if (size.isEmpty) return null;
    final origin = box.localToGlobal(Offset.zero) & size;
    // share_plus on iPad requires a non-zero origin within the view.
    if (origin.size.isEmpty) return null;
    return origin;
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareSystem(BuildContext context) async {
    try {
      await Share.share(
        _shareText,
        sharePositionOrigin: _shareOrigin(context),
      );
    } catch (_) {
      // Avoid crashing on platform-specific share failures.
    }
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent(_shareText);
    final uri = Uri.parse('whatsapp://send?text=$text');
    final can = await canLaunchUrl(uri);
    if (can) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    // Don't open system share sheet here; user explicitly chose WhatsApp.
    if (context.mounted) {
      Constants.showToast('WhatsApp is not installed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final usesLightCustom = themeProvider.currentCustomTheme ==
            AppCustomTheme.white ||
        themeProvider.currentCustomTheme == AppCustomTheme.lightbrown;
    final isDark =
        themeProvider.themeMode == ThemeMode.dark && !usesLightCustom;
    final brown = const Color(0xFF5C4033);
    final cream = isDark
        ? CommanColor.darkPrimaryColor
        : (isVintage
            ? const Color(0xFFF5F0E6)
            : themeProvider.backgroundColor);

    final tileBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isVintage
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(color: cream),
        child: Scaffold(
          backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Invite / Share Prayer',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _prayerDetailBody(
                    isDark: isDark,
                    brown: brown,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _actionTile(
                context,
                icon: Icons.share,
                title: 'Share',
                subtitle: 'Use your phone share options',
                color: brown,
                isDark: isDark,
                tileBg: tileBg,
                onTap: () => _shareSystem(context),
              ),
              const SizedBox(height: 10),
              _actionTile(
                context,
                icon: Icons.link,
                title: 'Copy',
                subtitle: 'Copy text to share anywhere',
                color: brown.withValues(alpha: 0.9),
                isDark: isDark,
                tileBg: tileBg,
                onTap: () => _copy(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Tip: Share the prayer so others can support you in faith.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
        )
      )
    );
  }

  Widget _prayerDetailBody({
    required bool isDark,
    required Color brown,
  }) {
    final myWords = PrayerDualDescription.myWords(description)?.trim();
    final ai = PrayerDualDescription.aiPrayer(description)?.trim();
    final plain = description.trim();
    final onBg = isDark ? const Color(0xFFF5EFE4) : const Color(0xFF3D2914);
    final onBgBrown = isDark ? const Color(0xFFE8D4B8) : brown;
    final onBgMuted = isDark ? const Color(0xFFD8C8B4) : const Color(0xFF8A7568);
    final hasMyWords = myWords != null && myWords.isNotEmpty;
    final hasAi = ai != null && ai.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.trim().isEmpty ? 'Prayer Request' : title.trim(),
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: onBg,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2118)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasMyWords) ...[
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: onBgMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Original Request',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: onBg,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(Your words)',
                      style: TextStyle(
                        fontSize: 13,
                        color: onBgMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '"$myWords"',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                    color: onBg,
                  ),
                ),
              ],
              if (hasMyWords && (hasAi || plain.isNotEmpty)) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: onBgBrown.withValues(alpha: 0.35),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.menu_book_outlined,
                        size: 18,
                        color: onBgBrown,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: onBgBrown.withValues(alpha: 0.35),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              if (hasAi || (!hasMyWords && plain.isNotEmpty)) ...[
                Row(
                  children: [
                    Text(
                      'Prayer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: onBg,
                      ),
                    ),
                    if (hasAi) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(Enhanced with AI)',
                        style: TextStyle(
                          fontSize: 13,
                          color: onBgMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hasAi ? ai : plain,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: isDark
                        ? const Color(0xFFD5CBE0)
                        : const Color(0xFF5C5670),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required Color tileBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : color.withValues(alpha: 0.22),
              width: isDark ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark
                      ? Border.all(color: Colors.white.withValues(alpha: 0.35))
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Georgia',
                        color: isDark ? Colors.white : const Color(0xFF3D2914),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
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

