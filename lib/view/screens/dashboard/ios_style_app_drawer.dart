import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/material.dart';

/// Accordion iOS-style cream drawer (collapsed rows + expanded sub-items).
/// Visual-only; navigation stays in existing callbacks.
class IosStyleAppDrawer extends StatefulWidget {
  const IosStyleAppDrawer({
    super.key,
    required this.appTitle,
    required this.planLabel,
    required this.isPremium,
    required this.showPremiumBanner,
    required this.onAccountTap,
    required this.onUpgradeTap,
    this.onPremiumInfoTap,
    required this.onDailyVerseTap,
    required this.onVersesByTopicTap,
    required this.onFaithJourneyTap,
    required this.onAskAnythingTap,
    required this.onPrayerGuidanceTap,
    required this.onMyLibraryTap,
    required this.onCalendarTap,
    required this.onWallpapersTap,
    required this.onQuotesTap,
    required this.onShareTap,
    required this.onPrayerWallTap,
    required this.onTelegramTap,
    required this.onWidgetsTap,
    required this.onBackupTap,
    required this.onSettingsTap,
    required this.onBooksTap,
    required this.onMoreAppsTap,
    required this.onContactUsTap,
    required this.onEProductsTap,
    this.showAskAnything = true,
    this.showBooks = false,
    this.showEProducts = false,
    this.footer,
    this.tagline = 'Grow in Faith. Walk in Truth.',
    this.appIconAsset = Images.appIcon1024,
    this.crownAsset = 'assets/gold-premium-icons/top_crown.png',
  });

  final String appTitle;
  final String planLabel;
  final String tagline;
  final String appIconAsset;
  final String crownAsset;
  final bool isPremium;
  final bool showPremiumBanner;
  final bool showAskAnything;
  final bool showBooks;
  final bool showEProducts;
  final Widget? footer;

  final VoidCallback onAccountTap;
  final VoidCallback onUpgradeTap;
  final VoidCallback? onPremiumInfoTap;
  final VoidCallback onDailyVerseTap;
  final VoidCallback onVersesByTopicTap;
  final VoidCallback onFaithJourneyTap;
  final VoidCallback onAskAnythingTap;
  final VoidCallback onPrayerGuidanceTap;
  final VoidCallback onMyLibraryTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onWallpapersTap;
  final VoidCallback onQuotesTap;
  final VoidCallback onShareTap;
  final VoidCallback onPrayerWallTap;
  final VoidCallback onTelegramTap;
  final VoidCallback onWidgetsTap;
  final VoidCallback onBackupTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onBooksTap;
  final VoidCallback onMoreAppsTap;
  final VoidCallback onContactUsTap;
  final VoidCallback onEProductsTap;

  /// Light-mode default (also used by Scaffold Drawer shell fallback).
  static const Color cream = Color(0xFFFDF8F6);

  static Color backgroundOf(BuildContext context) =>
      _DrawerPalette.of(context).cream;

  @override
  State<IosStyleAppDrawer> createState() => _IosStyleAppDrawerState();
}

class _DrawerPalette {
  const _DrawerPalette({
    required this.cream,
    required this.ink,
    required this.muted,
    required this.iconTile,
    required this.railBg,
    required this.divider,
    required this.planBadgeBg,
    required this.premiumBg,
    required this.premiumBorder,
    required this.premiumAccent,
  });

  final Color cream;
  final Color ink;
  final Color muted;
  final Color iconTile;
  final Color railBg;
  final Color divider;
  final Color planBadgeBg;
  final Color premiumBg;
  final Color premiumBorder;
  final Color premiumAccent;

  factory _DrawerPalette.of(BuildContext context) {
    if (CommanColor.isDarkTheme(context)) {
      // Match app dark theme (CommanColor.darkPrimaryColor family) — not near-black.
      return const _DrawerPalette(
        cream: Color(0xFF745248),
        ink: Color(0xFFFFFFFF),
        muted: Color(0xFFE0D4CC),
        iconTile: Color(0xFF5C4038),
        railBg: Color(0xFF5C4038),
        divider: Color(0xFF8A6A5C),
        planBadgeBg: Color(0xFF5C4038),
        premiumBg: Color(0xFF5C4038),
        premiumBorder: Color(0xFFA2786C),
        premiumAccent: Color(0xFFE0A06A),
      );
    }
    return const _DrawerPalette(
      cream: Color(0xFFFDF8F6),
      ink: Color(0xFF3E2723),
      muted: Color(0xFF8A7264),
      iconTile: Color(0xFFF3E8DC),
      railBg: Color(0xFFF2E7D5),
      divider: Color(0xFFE8DFD4),
      planBadgeBg: Color(0xFFF6E8D8),
      premiumBg: Color(0xFFFFF3E8),
      premiumBorder: Color(0xFFE8C29A),
      premiumAccent: Color(0xFFD17D45),
    );
  }
}

class _DrawerSubItem {
  const _DrawerSubItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.asset,
  });

  final String label;
  final IconData icon;
  final String? asset;
  final VoidCallback onTap;
}

class _IosStyleAppDrawerState extends State<IosStyleAppDrawer> {
  /// All sections start collapsed (including App).
  String? _expandedKey;

  void _toggle(String key) {
    setState(() {
      _expandedKey = _expandedKey == key ? null : key;
    });
  }

  void _closeDrawerThen(VoidCallback action) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
    Future.microtask(action);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    final dailyChildren = <_DrawerSubItem>[
      _DrawerSubItem(
        label: "Verse for You",
        icon: Icons.today_outlined,
        asset: 'assets/home icons/Daily verse.png',
        onTap: widget.onDailyVerseTap,
      ),
      _DrawerSubItem(
        label: 'Verses by Topic',
        icon: Icons.grid_view_rounded,
        onTap: widget.onVersesByTopicTap,
      ),
      _DrawerSubItem(
        label: 'Faith Journey',
        icon: Icons.local_fire_department_outlined,
        asset: 'assets/home icons/book.png',
        onTap: widget.onFaithJourneyTap,
      ),
    ];

    final aiChildren = <_DrawerSubItem>[
      if (widget.showAskAnything)
        _DrawerSubItem(
          label: 'Ask Anything',
          icon: Icons.chat_bubble_outline_rounded,
          asset: 'assets/Chat icon.png',
          onTap: widget.onAskAnythingTap,
        ),
      _DrawerSubItem(
        label: 'Prayer Guidance',
        icon: Icons.favorite_outline_rounded,
        asset: 'assets/dove.png',
        onTap: widget.onPrayerGuidanceTap,
      ),
    ];

    final journeyChildren = <_DrawerSubItem>[
      _DrawerSubItem(
        label: 'My Library',
        icon: Icons.library_books_outlined,
        asset: 'assets/home icons/My Library.png',
        onTap: widget.onMyLibraryTap,
      ),
      _DrawerSubItem(
        label: 'Calendar',
        icon: Icons.calendar_month_outlined,
        asset: 'assets/home icons/Artboard – 35.png',
        onTap: widget.onCalendarTap,
      ),
    ];

    final inspirationChildren = <_DrawerSubItem>[
      _DrawerSubItem(
        label: 'Wallpapers',
        icon: Icons.image_outlined,
        asset: 'assets/home icons/Wallpaper.png',
        onTap: widget.onWallpapersTap,
      ),
      _DrawerSubItem(
        label: 'Quotes',
        icon: Icons.format_quote_rounded,
        asset: 'assets/home icons/Quotes.png',
        onTap: widget.onQuotesTap,
      ),
    ];

    final communityChildren = <_DrawerSubItem>[
      _DrawerSubItem(
        label: 'Prayer Wall',
        icon: Icons.volunteer_activism_outlined,
        onTap: widget.onPrayerWallTap,
      ),
      _DrawerSubItem(
        label: 'Social Links',
        icon: Icons.send_rounded,
        onTap: widget.onTelegramTap,
      ),
      _DrawerSubItem(
        label: 'Invite Friends',
        icon: Icons.person_add_alt_1_outlined,
        asset: 'assets/home icons/Share.png',
        onTap: widget.onShareTap,
      ),
    ];

    final moreChildren = <_DrawerSubItem>[
      _DrawerSubItem(
        label: 'Widgets',
        icon: Icons.widgets_outlined,
        onTap: widget.onWidgetsTap,
      ),
      _DrawerSubItem(
        label: 'Backup & Sync',
        icon: Icons.cloud_upload_outlined,
        asset: 'assets/home icons/Frame 3631.png',
        onTap: widget.onBackupTap,
      ),
      if (widget.showBooks)
        _DrawerSubItem(
          label: 'Christian Books',
          icon: Icons.menu_book_outlined,
          asset: 'assets/home icons/book.png',
          onTap: widget.onBooksTap,
        ),
      if (widget.showEProducts)
        _DrawerSubItem(
          label: 'e-Products',
          icon: Icons.shopping_bag_outlined,
          asset: 'assets/eproduct-d.png',
          onTap: widget.onEProductsTap,
        ),
      _DrawerSubItem(
        label: 'More Apps',
        icon: Icons.apps_outlined,
        asset: 'assets/home icons/More apps.png',
        onTap: widget.onMoreAppsTap,
      ),
      _DrawerSubItem(
        label: 'Contact Us',
        icon: Icons.mail_outline_rounded,
        asset: 'assets/home icons/customer-service 2.png',
        onTap: widget.onContactUsTap,
      ),
    ];

    return ColoredBox(
      color: _DrawerPalette.of(context).cream,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: topInset + 12),
          _buildHeader(),
          const SizedBox(height: 16),
          // Free plan only — completely hidden for Premium users.
          if (!widget.isPremium && widget.showPremiumBanner) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PremiumBanner(
                crownAsset: widget.crownAsset,
                onTap: () => _closeDrawerThen(widget.onUpgradeTap),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _NavLinkRow(
            icon: Icons.person_outline_rounded,
            asset: 'assets/home icons/My Account.png',
            label: 'My Account',
            onTap: () => _closeDrawerThen(widget.onAccountTap),
          ),
          _sectionDivider(),
          _AccordionSection(
            icon: Icons.local_fire_department_outlined,
            label: 'Daily',
            expanded: _expandedKey == 'daily',
            onHeaderTap: () => _toggle('daily'),
            children: dailyChildren,
            onItemTap: _closeDrawerThen,
            useIconRail: false,
          ),
          _sectionDivider(),
          _AccordionSection(
            icon: Icons.smart_toy_outlined,
            label: 'AI Companion',
            expanded: _expandedKey == 'ai',
            onHeaderTap: () => _toggle('ai'),
            children: aiChildren,
            onItemTap: _closeDrawerThen,
            useIconRail: false,
          ),
          _sectionDivider(),
          _AccordionSection(
            icon: Icons.menu_book_outlined,
            label: 'My Journey',
            expanded: _expandedKey == 'journey',
            onHeaderTap: () => _toggle('journey'),
            children: journeyChildren,
            onItemTap: _closeDrawerThen,
            useIconRail: false,
          ),
          _sectionDivider(),
          _AccordionSection(
            icon: Icons.auto_awesome_outlined,
            label: 'Inspiration',
            expanded: _expandedKey == 'inspiration',
            onHeaderTap: () => _toggle('inspiration'),
            children: inspirationChildren,
            onItemTap: _closeDrawerThen,
            useIconRail: false,
          ),
          _sectionDivider(),
          _AccordionSection(
            icon: Icons.groups_outlined,
            label: 'Community',
            expanded: _expandedKey == 'community',
            onHeaderTap: () => _toggle('community'),
            children: communityChildren,
            onItemTap: _closeDrawerThen,
            useIconRail: false,
          ),
          _sectionDivider(),
          _AccordionSection(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            expanded: _expandedKey == 'more',
            onHeaderTap: () => _toggle('more'),
            children: moreChildren,
            onItemTap: _closeDrawerThen,
            useIconRail: false,
          ),
          _sectionDivider(),
          _NavLinkRow(
            icon: Icons.settings_outlined,
            asset: 'assets/home icons/setting.png',
            label: 'Settings',
            onTap: () => _closeDrawerThen(widget.onSettingsTap),
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: 8),
            widget.footer!,
          ],
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colors = _DrawerPalette.of(context);
    final isPremium = widget.isPremium;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        crossAxisAlignment:
            isPremium ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              widget.appIconAsset,
              width: isPremium ? 56 : 48,
              height: isPremium ? 56 : 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: isPremium ? 56 : 48,
                height: isPremium ? 56 : 48,
                color: colors.iconTile,
                child: Icon(Icons.menu_book, color: colors.ink),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tagline,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: colors.muted,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isPremium)
                  _PlanBadge(
                    label: 'Free Plan',
                    icon: Icons.workspace_premium_outlined,
                    outlined: false,
                  )
                else
                  _PlanBadge(
                    label: 'Premium Active',
                    crownAsset: widget.crownAsset,
                    outlined: true,
                    showInfoIcon: true,
                    onInfoTap: widget.onPremiumInfoTap == null
                        ? null
                        : () => _closeDrawerThen(widget.onPremiumInfoTap!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
          height: 1, thickness: 0.8, color: _DrawerPalette.of(context).divider),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.label,
    this.crownAsset,
    this.icon,
    this.outlined = false,
    this.showInfoIcon = false,
    this.onInfoTap,
  }) : assert(crownAsset != null || icon != null);

  final String label;
  final String? crownAsset;
  final IconData? icon;
  final bool outlined;
  final bool showInfoIcon;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final colors = _DrawerPalette.of(context);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: outlined ? colors.cream : colors.planBadgeBg,
        borderRadius: BorderRadius.circular(20),
        border: outlined
            ? Border.all(color: colors.premiumBorder, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (crownAsset != null)
            Image.asset(
              crownAsset!,
              width: 14,
              height: 14,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                icon ?? Icons.workspace_premium,
                size: 14,
                color: colors.premiumAccent,
              ),
            )
          else
            Icon(
              icon,
              size: 14,
              color: colors.premiumAccent,
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          if (showInfoIcon) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: colors.ink,
            ),
          ],
        ],
      ),
    );

    if (onInfoTap == null) return badge;
    return GestureDetector(
      onTap: onInfoTap,
      behavior: HitTestBehavior.opaque,
      child: badge,
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.crownAsset, required this.onTap});

  final String crownAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            color: _DrawerPalette.of(context).premiumBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _DrawerPalette.of(context).premiumBorder),
          ),
          child: Row(
            children: [
              Image.asset(
                crownAsset,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.workspace_premium,
                  size: 36,
                  color: _DrawerPalette.of(context).premiumAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _DrawerPalette.of(context).ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unlock all features and grow spiritually every day.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        color: _DrawerPalette.of(context).muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _DrawerPalette.of(context).premiumAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLinkRow extends StatelessWidget {
  const _NavLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.asset,
  });

  final IconData icon;
  final String? asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconTile(icon: icon, asset: asset),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _DrawerPalette.of(context).ink,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _DrawerPalette.of(context).ink,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onHeaderTap,
    required this.children,
    required this.onItemTap,
    required this.useIconRail,
  });

  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onHeaderTap;
  final List<_DrawerSubItem> children;
  final void Function(VoidCallback action) onItemTap;
  final bool useIconRail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onHeaderTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _IconTile(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _DrawerPalette.of(context).ink,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.chevron_right_rounded,
                  color: _DrawerPalette.of(context).ink,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: useIconRail
              ? _IconRailSubList(children: children, onItemTap: onItemTap)
              : _PlainSubList(children: children, onItemTap: onItemTap),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}

/// Expanded style: tan icon rail with labels left-aligned beside each icon.
class _IconRailSubList extends StatelessWidget {
  const _IconRailSubList({required this.children, required this.onItemTap});

  final List<_DrawerSubItem> children;
  final void Function(VoidCallback action) onItemTap;

  static const double _rowHeight = 36;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final colors = _DrawerPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            decoration: BoxDecoration(
              color: colors.railBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final item in children)
                  SizedBox(
                    height: _rowHeight,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: item.asset != null
                            ? Image.asset(
                                item.asset!,
                                width: 18,
                                height: 18,
                                color: colors.ink,
                                errorBuilder: (_, __, ___) => Icon(
                                  item.icon,
                                  size: 18,
                                  color: colors.ink,
                                ),
                              )
                            : Icon(
                                item.icon,
                                size: 18,
                                color: colors.ink,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in children)
                    InkWell(
                      onTap: () => onItemTap(item.onTap),
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: _rowHeight,
                        width: double.infinity,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.label,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: colors.ink,
                            ),
                          ),
                        ),
                      ),
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

/// Expanded App style from UI2: indented icon + label, no rail.
class _PlainSubList extends StatelessWidget {
  const _PlainSubList({required this.children, required this.onItemTap});

  final List<_DrawerSubItem> children;
  final void Function(VoidCallback action) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 6),
      child: Column(
        children: [
          for (final item in children)
            InkWell(
              onTap: () => onItemTap(item.onTap),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(46, 10, 8, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: item.asset != null
                          ? Image.asset(
                              item.asset!,
                              width: 20,
                              height: 20,
                              color: _DrawerPalette.of(context).ink,
                              errorBuilder: (_, __, ___) => Icon(
                                item.icon,
                                size: 20,
                                color: _DrawerPalette.of(context).ink,
                              ),
                            )
                          : Icon(
                              item.icon,
                              size: 20,
                              color: _DrawerPalette.of(context).ink,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _DrawerPalette.of(context).ink,
                        ),
                      ),
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

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.asset});

  final IconData icon;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _DrawerPalette.of(context).iconTile,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: asset != null
          ? Image.asset(
              asset!,
              width: 18,
              height: 18,
              color: _DrawerPalette.of(context).ink,
              errorBuilder: (_, __, ___) => Icon(
                icon,
                size: 18,
                color: _DrawerPalette.of(context).ink,
              ),
            )
          : Icon(icon, size: 18, color: _DrawerPalette.of(context).ink),
    );
  }
}
