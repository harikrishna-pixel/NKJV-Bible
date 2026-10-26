import 'package:biblebookapp/view/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Parchment palette shared by the App Support screens.
class SupportPalette {
  const SupportPalette._({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.border,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.headerTop,
    required this.headerBottom,
    required this.iconBg,
  });

  final bool isDark;
  final Color bg;
  final Color card;
  final Color border;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color headerTop;
  final Color headerBottom;
  final Color iconBg;

  static SupportPalette of(BuildContext context) {
    final dark = CommanColor.isDarkTheme(context);
    if (dark) {
      return const SupportPalette._(
        isDark: true,
        bg: Color(0xFF1F1813),
        card: Color(0xFF2C221A),
        border: Color(0xFF4A3A2C),
        ink: Color(0xFFF3E7D3),
        muted: Color(0xFFC9B79E),
        accent: Color(0xFFD9A25F),
        headerTop: Color(0xFF3B2618),
        headerBottom: Color(0xFF2A1B11),
        iconBg: Color(0xFF3A2C20),
      );
    }
    return const SupportPalette._(
      isDark: false,
      bg: Color(0xFFF6ECDC),
      card: Color(0xFFFCF6EC),
      border: Color(0xFFE6D3B5),
      ink: Color(0xFF3B2416),
      muted: Color(0xFF8A6E57),
      accent: Color(0xFF7A4520),
      headerTop: Color(0xFF7B4A27),
      headerBottom: Color(0xFF5E3519),
      iconBg: Color(0xFFF1E2CB),
    );
  }

  TextStyle serif(double size, {FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: 'Georgia',
        fontSize: size,
        fontWeight: weight,
        color: ink,
        height: 1.15,
      );
}

/// Maps JSON icon names to Material icons.
IconData supportIcon(String name) {
  switch (name) {
    case 'alert':
      return Icons.error_outline_rounded;
    case 'bell':
      return Icons.notifications_none_rounded;
    case 'book':
      return Icons.menu_book_outlined;
    case 'book_open':
      return Icons.auto_stories_outlined;
    case 'bookmark':
      return Icons.bookmark_border_rounded;
    case 'books':
      return Icons.library_books_outlined;
    case 'calendar':
      return Icons.event_note_outlined;
    case 'card':
      return Icons.credit_card_outlined;
    case 'card_alert':
      return Icons.credit_card_off_outlined;
    case 'chart':
      return Icons.insert_chart_outlined_rounded;
    case 'chat':
      return Icons.chat_bubble_outline_rounded;
    case 'clock':
      return Icons.schedule_rounded;
    case 'cloud_download':
      return Icons.cloud_download_outlined;
    case 'crown':
      return Icons.workspace_premium_outlined;
    case 'devices':
      return Icons.devices_outlined;
    case 'document':
      return Icons.description_outlined;
    case 'download':
      return Icons.download_rounded;
    case 'flag':
      return Icons.outlined_flag_rounded;
    case 'gear':
      return Icons.settings_outlined;
    case 'headphones':
      return Icons.headphones_outlined;
    case 'heart':
      return Icons.favorite_border_rounded;
    case 'info':
      return Icons.info_outline_rounded;
    case 'layout':
      return Icons.dashboard_outlined;
    case 'lightbulb':
      return Icons.lightbulb_outline_rounded;
    case 'pencil':
      return Icons.edit_outlined;
    case 'restore':
      return Icons.restore_rounded;
    case 'search':
      return Icons.search_rounded;
    case 'share':
      return Icons.share_outlined;
    case 'sparkle':
      return Icons.auto_awesome_outlined;
    case 'speed':
      return Icons.speed_rounded;
    case 'sun':
      return Icons.wb_sunny_outlined;
    case 'sync':
      return Icons.sync_rounded;
    case 'trophy':
      return Icons.emoji_events_outlined;
    case 'wallet':
      return Icons.account_balance_wallet_outlined;
    case 'warning':
      return Icons.warning_amber_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

/// Brown rounded header bar with back button, centered title and
/// optional subtitle / trailing widget.
class SupportHeader extends StatelessWidget {
  const SupportHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    // Light mode: no brown bar — header sits on the parchment background.
    final ink = p.isDark ? Colors.white : p.ink;
    final subInk =
        p.isDark ? Colors.white.withValues(alpha: 0.85) : p.muted;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Container(
        decoration: p.isDark
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.headerTop, p.headerBottom],
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(22)),
              )
            : null,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack ?? () => Get.back(),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: ink, size: 20),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: subInk),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 48, child: trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round icon + serif title + subtitle used at the top of category screens.
class SupportHero extends StatelessWidget {
  const SupportHero({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: p.iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: p.border, width: 1.5),
            ),
            child: Icon(icon, color: p.accent, size: 32),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: p.serif(24)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: p.muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card row: leading icon, title, subtitle, chevron.
class SupportTile extends StatelessWidget {
  const SupportTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14, vertical: large ? 14 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: large ? 46 : 38,
                    height: large ? 46 : 38,
                    decoration: BoxDecoration(
                      color: p.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: p.accent, size: large ? 26 : 21),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: large ? 16 : 14.5,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                          fontFamily: large ? 'Georgia' : null,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5, color: p.muted, height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(Icons.chevron_right_rounded, color: p.muted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple question row with a divider (Popular Questions lists).
class SupportQuestionRow extends StatelessWidget {
  const SupportQuestionRow({
    super.key,
    required this.text,
    this.onTap,
    this.showDivider = true,
  });

  final String text;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border:
              showDivider ? Border(bottom: BorderSide(color: p.border)) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 14, color: p.ink, height: 1.3),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Rounded card container with the parchment border.
class SupportCard extends StatelessWidget {
  const SupportCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

/// Brown full-width primary button.
class SupportPrimaryButton extends StatelessWidget {
  const SupportPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: p.isDark ? const Color(0xFF8A5530) : p.headerTop,
          disabledBackgroundColor:
              (p.isDark ? const Color(0xFF8A5530) : p.headerTop)
                  .withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

/// Status chip used in Support History.
class SupportStatusChip extends StatelessWidget {
  const SupportStatusChip(
      {super.key, required this.label, required this.style});

  final String label;

  /// One of: neutral, warning, attention, success, muted (from JSON).
  final String style;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (style) {
      case 'success':
        bg = const Color(0xFFE3EFD9);
        fg = const Color(0xFF4E7A35);
        break;
      case 'warning':
        bg = const Color(0xFFFBE7C2);
        fg = const Color(0xFF9A6514);
        break;
      case 'attention':
        bg = const Color(0xFFF8DCCF);
        fg = const Color(0xFFA2481F);
        break;
      case 'muted':
        bg = const Color(0xFFE8E2DA);
        fg = const Color(0xFF7D7268);
        break;
      default:
        bg = const Color(0xFFEDE3D3);
        fg = const Color(0xFF6E5442);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// Scaffold with parchment background and the brown header.
class SupportScaffold extends StatelessWidget {
  const SupportScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget body;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          SupportHeader(title: title, subtitle: subtitle, trailing: trailing),
          Expanded(child: body),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
