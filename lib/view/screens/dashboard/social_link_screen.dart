
import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({super.key});

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  static const Color _brown = Color(0xFF5C4033);
  static const Color _muted = Color(0xFF7A6A5C);

  bool _isLoading = true;
  String? _errorMessage;
  List<_SocialLinkItem> _socials = const [];

  @override
  void initState() {
    super.initState();
    _fetchSocialLinks();
  }

  String get _bundleId {
    if (Platform.isIOS) {
      return BibleInfo.ios_Bundle_Id;
    }
    return BibleInfo.android_Package_Name;
  }

  Future<void> _fetchSocialLinks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        'https://bibleoffice.com/social/social.php?app=${Uri.encodeQueryComponent(_bundleId)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to load social links');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        throw Exception('Failed to load social links');
      }

      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      final socialsJson = data['socials'] as List<dynamic>? ?? [];
      final socials = socialsJson
          .map((item) => _SocialLinkItem.fromJson(item as Map<String, dynamic>))
          .where((item) => item.url.isNotEmpty)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (!mounted) return;
      setState(() {
        _socials = socials;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load social links. Please try again.';
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Constants.showToast('Could not open link');
    }
  }

  String _subtitleFor(_SocialLinkItem item) {
    final key = item.platform.toLowerCase().trim().isNotEmpty
        ? item.platform.toLowerCase().trim()
        : item.icon.toLowerCase().trim();
    final label = item.label.toLowerCase();

    if (key.contains('instagram') || label.contains('instagram')) {
      return 'Daily verses, inspiration & behind the \nscenes.';
    }
    if (key.contains('facebook') || label.contains('facebook')) {
      return 'Join our community and stay updated \nwith the latest.';
    }
    if (key.contains('whatsapp') || label.contains('whatsapp')) {
      return 'Join our WhatsApp community for \nupdates and encouragement.';
    }
    if (key.contains('telegram') || label.contains('telegram')) {
      return 'Get notifications, resources and \nspecial announcements.';
    }
    return 'Stay connected with our community.';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final scaffoldBg = isVintage
        ? (isDark ? CommanColor.black : const Color(0xFFF5F0E6))
        : (isDark
        ? CommanColor.darkPrimaryColor
        : themeProvider.backgroundColor);
    final titleColor = isDark ? Colors.white : _brown;
    final mutedColor = isDark ? Colors.white70 : _muted;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: isVintage
            ? BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.fill,
          ),
        )
            : null,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : const Color(0xFFE8D7C4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          size: 26,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Social Links',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 14, 36, 12),
                child: Text(
                  'Follow us on social media and join our\ncommunity to stay inspired and connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(child: _buildBody(context, isDark, titleColor, mutedColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      bool isDark,
      Color titleColor,
      Color mutedColor,
      ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _fetchSocialLinks,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_socials.isEmpty) {
      return Center(
        child: Text(
          'No social links available',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        ..._socials.map(
              (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SocialLinkCard(
              title: item.label,
              subtitle: _subtitleFor(item),
              isDark: isDark,
              titleColor: titleColor,
              mutedColor: mutedColor,
              icon: _SocialPlatformIcon(
                platform: item.platform,
                iconKey: item.icon,
                iconUrl: item.iconUrl,
              ),
              onTap: () => _openUrl(item.url),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _CommunityCard(isDark: isDark, titleColor: titleColor, mutedColor: mutedColor),
        const SizedBox(height: 32),
        _QuoteBlock(titleColor: titleColor, mutedColor: mutedColor),
      ],
    );
  }
}

class _SocialLinkCard extends StatelessWidget {
  const _SocialLinkCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.titleColor,
    required this.mutedColor,
  });

  final String title;
  final String subtitle;
  final Widget icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color titleColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFFBF6EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.14)
                  : const Color(0xFFE6D8C8),
            ),
            boxShadow: isDark
                ? null
                : [
              BoxShadow(
                color: const Color(0xFF5C4033).withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: mutedColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: titleColor.withOpacity(0.85),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.isDark,
    required this.titleColor,
    required this.mutedColor,
  });

  final bool isDark;
  final Color titleColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    // Plain informational row — no card fill/border so it doesn't look tappable.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Image.asset(
              'assets/community.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              color: titleColor.withOpacity(isDark ? 0.92 : 0.85),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Be part of our growing community',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    height: 1.3,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect, share and grow together in faith.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: mutedColor,
                    fontWeight: FontWeight.w400,
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

class _QuoteBlock extends StatefulWidget {
  const _QuoteBlock({
    required this.titleColor,
    required this.mutedColor,
  });

  final Color titleColor;
  final Color mutedColor;

  @override
  State<_QuoteBlock> createState() => _QuoteBlockState();
}

class _QuoteBlockState extends State<_QuoteBlock> {
  static const List<({String text, String reference})> _quotes = [
    (
    text:
    'Let us not give up meeting together,\n as some are in the habit of doing,\n but let us encourage one another.',
    reference: 'Hebrews 10:25',
    ),
    (
    text:
    'For where two or three gather in my name, there am I with them.',
    reference: 'Matthew 18:20',
    ),
    (
    text:
    'How good and pleasant it is when God\'s people live together in unity!',
    reference: 'Psalm 133:1',
    ),
  ];

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _quoteMark({bool flip = false}) {
    final image = Image.asset(
      'assets/social/quotes_icon.png',
      width: 28,
      height: 22,
      fit: BoxFit.contain,
      color: widget.titleColor.withOpacity(0.35),
      colorBlendMode: BlendMode.srcATop,
      errorBuilder: (_, __, ___) => Text(
        flip ? '”' : '“',
        style: TextStyle(
          fontSize: 36,
          height: 0.7,
          color: widget.titleColor.withOpacity(0.28),
          fontFamily: 'Georgia',
        ),
      ),
    );
    if (!flip) return image;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationZ(3.14159),
      child: image,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 170,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _quotes.length,
          itemBuilder: (context, index) {
            final quote = _quotes[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _quoteMark(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quote.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                      color: widget.titleColor,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _quoteMark(flip: true),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quote.reference,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.mutedColor,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialLinkItem {
  const _SocialLinkItem({
    required this.platform,
    required this.label,
    required this.url,
    required this.icon,
    required this.iconUrl,
    required this.order,
  });

  final String platform;
  final String label;
  final String url;
  final String icon;
  final String iconUrl;
  final int order;

  factory _SocialLinkItem.fromJson(Map<String, dynamic> json) {
    return _SocialLinkItem(
      platform: (json['platform'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      iconUrl: (json['icon_url'] ?? '').toString(),
      order: int.tryParse('${json['order'] ?? 0}') ?? 0,
    );
  }
}

class _SocialPlatformIcon extends StatelessWidget {
  const _SocialPlatformIcon({
    required this.platform,
    required this.iconKey,
    required this.iconUrl,
  });

  final String platform;
  final String iconKey;
  final String iconUrl;

  String get _key {
    final raw = iconKey.toLowerCase().trim().isNotEmpty
        ? iconKey.toLowerCase().trim()
        : platform.toLowerCase().trim();
    if (raw.contains('facebook')) return 'facebook';
    if (raw.contains('instagram')) return 'instagram';
    if (raw.contains('whatsapp')) return 'whatsapp';
    if (raw.contains('telegram')) return 'telegram';
    return raw;
  }

  String? get _localAsset {
    switch (_key) {
      case 'facebook':
        return 'assets/social_links/facebook.png';
      case 'instagram':
        return 'assets/social_links/instagram.png';
      case 'whatsapp':
        return 'assets/social_links/whatsapp.png';
      case 'telegram':
        return 'assets/social_links/telegram.png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = _localAsset;
    if (local != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          local,
          height: 72,
          width: 72,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    if (iconUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          iconUrl,
          height: 72,
          width: 72,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.link, size: 42),
        ),
      );
    }
    return const Icon(Icons.link, size: 42);
  }
}
