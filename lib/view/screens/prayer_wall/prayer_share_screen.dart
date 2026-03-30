import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
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
    final d = description.trim();
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
      const SnackBar(content: Text('Copied to clipboard.')),
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
      await launchUrl(uri);
      return;
    }
    // Fallback to system share if WhatsApp scheme isn't available.
    await _shareSystem(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final cream = isDark
        ? CommanColor.darkPrimaryColor
        : (themeProvider.currentCustomTheme == AppCustomTheme.vintage
            ? const Color(0xFFF5F0E6)
            : themeProvider.backgroundColor);

    final cardBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;

    return Scaffold(
      backgroundColor: cream,
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: brown.withValues(alpha: 0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isEmpty ? 'Prayer Request' : title.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : brown,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.trim().isEmpty ? '-' : description.trim(),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _actionTile(
                context,
                icon: Icons.chat_bubble,
                title: 'Share on WhatsApp',
                subtitle: 'Send this prayer to a friend or group',
                color: const Color(0xFF25D366),
                onTap: () => _shareWhatsApp(context),
              ),
              const SizedBox(height: 10),
              _actionTile(
                context,
                icon: Icons.share,
                title: 'Share',
                subtitle: 'Use your phone share options',
                color: brown,
                onTap: () => _shareSystem(context),
              ),
              const SizedBox(height: 10),
              _actionTile(
                context,
                icon: Icons.link,
                title: 'Copy',
                subtitle: 'Copy text to share anywhere',
                color: brown.withValues(alpha: 0.9),
                onTap: () => _copy(context),
              ),
              const Spacer(),
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
    );
  }

  static Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
            color: Colors.white.withValues(alpha: 0.0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

