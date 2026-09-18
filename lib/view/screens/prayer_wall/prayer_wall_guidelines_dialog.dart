import 'package:flutter/material.dart';

/// Prayer Wall Guidelines sheet — UI only.
class PrayerWallGuidelinesDialog {
  PrayerWallGuidelinesDialog._();

  static const Color _cream = Color(0xFFFDF7EB);
  static const Color _ink = Color(0xFF4B3423);
  static const Color _muted = Color(0xFF6B4E3D);
  static const Color _brown = Color(0xFF5C4033);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _iconBg = Color(0xFFF0E6D8);
  static const Color _link = Color(0xFFB07A4A);
  static const Color _banner = Color(0xFFF3E4D8);

  static const List<_GuidelineItem> _items = [
    _GuidelineItem(
      icon: Icons.favorite_border,
      title: 'Respectful',
      body: 'Use kind and respectful words toward others.',
    ),
    _GuidelineItem(
      icon: Icons.volunteer_activism_outlined,
      title: 'Prayer-focused',
      body:
          'Share genuine prayer requests, praise, thanksgiving, or faith-related needs.',
    ),
    _GuidelineItem(
      icon: Icons.verified_user_outlined,
      title: 'Safe for everyone',
      body:
          'Do not include threats, harmful content, hate, harassment, or offensive language.',
    ),
    _GuidelineItem(
      icon: Icons.campaign_outlined,
      title: 'Free from advertising',
      body:
          'Do not post promotions, advertisements, links, or unrelated content.',
    ),
    _GuidelineItem(
      icon: Icons.person_outline,
      title: 'Personal and appropriate',
      body: 'Avoid sharing private information about yourself or others.',
    ),
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height;
        return Container(
          height: h * 0.92,
          decoration: const BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: _ink),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                    child: Column(
                      children: [
                        const _GuidelinesHeaderIcon(),
                        const SizedBox(height: 12),
                        const Text(
                          'Prayer Wall Guidelines',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _GoldCrossDivider(),
                        const SizedBox(height: 14),
                        const Text(
                          'The Prayer Wall is a place to share prayer requests, encourage one another, and grow in faith.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (var i = 0; i < _items.length; i++) ...[
                          _GuidelineRow(item: _items[i]),
                          if (i < _items.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE6DCCD),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brown,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Banner used on Post a Prayer screen.
  static Widget helpBanner(BuildContext context, {bool isDark = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => show(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : _banner,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.7),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: isDark ? Colors.white70 : _brown,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _helpText(isDark: isDark)),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact footer link used under the rejection dialog.
  static Widget helpLink(BuildContext context) {
    return InkWell(
      onTap: () => show(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _muted.withValues(alpha: 0.55)),
              ),
              child: const Text(
                '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: _helpText()),
          ],
        ),
      ),
    );
  }

  static Widget _helpText({bool isDark = false}) {
    final base = isDark ? Colors.white70 : _ink;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
          color: base,
          fontWeight: FontWeight.w500,
        ),
        children: [
          const TextSpan(text: 'Need help?\nLearn about '),
          TextSpan(
            text: 'Prayer Wall guidelines',
            style: TextStyle(
              color: isDark ? const Color(0xFFD4A574) : _link,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: isDark ? const Color(0xFFD4A574) : _link,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidelineItem {
  const _GuidelineItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({required this.item});

  final _GuidelineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: PrayerWallGuidelinesDialog._iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: PrayerWallGuidelinesDialog._brown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PrayerWallGuidelinesDialog._ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: PrayerWallGuidelinesDialog._muted,
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

class _GuidelinesHeaderIcon extends StatelessWidget {
  const _GuidelinesHeaderIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Positioned(
            top: 2,
            left: 10,
            child: Icon(Icons.star, size: 11, color: PrayerWallGuidelinesDialog._gold),
          ),
          Positioned(
            top: 0,
            right: 12,
            child: Icon(Icons.star, size: 12, color: PrayerWallGuidelinesDialog._gold),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Icon(Icons.star, size: 10, color: PrayerWallGuidelinesDialog._gold),
          ),
          Positioned(
            bottom: 4,
            right: 8,
            child: Icon(Icons.star, size: 11, color: PrayerWallGuidelinesDialog._gold),
          ),
          Icon(
            Icons.volunteer_activism,
            size: 36,
            color: PrayerWallGuidelinesDialog._gold,
          ),
        ],
      ),
    );
  }
}

class _GoldCrossDivider extends StatelessWidget {
  const _GoldCrossDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: PrayerWallGuidelinesDialog._gold.withValues(alpha: 0.55),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.add,
            size: 16,
            color: PrayerWallGuidelinesDialog._gold,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: PrayerWallGuidelinesDialog._gold.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
