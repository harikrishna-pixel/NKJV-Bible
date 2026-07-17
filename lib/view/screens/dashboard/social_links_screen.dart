import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
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
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Get.back(),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: CommanColor.whiteBlack(context),
                      ),
                    ),
                  ),
                  Text(
                    'Social Links',
                    style: CommanStyle.appBarStyle(context),
                  ),
                  const SizedBox(width: 35),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
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
                style: CommanStyle.bothPrimary16600(context),
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
          style: CommanStyle.bothPrimary16600(context),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _socials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _socials[index];
        return ListTile(
          onTap: () => _openUrl(item.url),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: _SocialPlatformIcon(
            platform: item.platform,
            iconKey: item.icon,
            iconUrl: item.iconUrl,
          ),
          title: Text(
            item.label,
            style: CommanStyle.bothPrimary16600(context),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: CommanColor.whiteBlack(context),
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    if (iconUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          iconUrl,
          height: 32,
          width: 32,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    final key = iconKey.toLowerCase().trim().isNotEmpty
        ? iconKey.toLowerCase().trim()
        : platform.toLowerCase().trim();

    switch (key) {
      case 'facebook':
        return Image.asset(
          'assets/facebook.png',
          height: 32,
          width: 32,
        );
      case 'instagram':
        return SvgPicture.string(
          _instagramSvg,
          height: 32,
          width: 32,
        );
      case 'whatsapp':
        return SvgPicture.string(
          _whatsappSvg,
          height: 32,
          width: 32,
        );
      case 'telegram':
        return SvgPicture.string(
          _telegramSvg,
          height: 32,
          width: 32,
        );
      default:
        return const Icon(Icons.link, size: 28);
    }
  }
}

const String _instagramSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="ig" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#F58529"/>
      <stop offset="50%" stop-color="#DD2A7B"/>
      <stop offset="100%" stop-color="#8134AF"/>
    </linearGradient>
  </defs>
  <rect x="2" y="2" width="20" height="20" rx="5" fill="url(#ig)"/>
  <circle cx="12" cy="12" r="4.2" fill="none" stroke="#fff" stroke-width="1.8"/>
  <circle cx="17.2" cy="6.8" r="1.2" fill="#fff"/>
</svg>
''';

const String _whatsappSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="11" fill="#25D366"/>
  <path fill="#fff" d="M16.6 13.9c-.2-.1-1.3-.6-1.5-.7-.2-.1-.4-.1-.5.1-.2.2-.6.7-.7.8-.1.1-.3.1-.5 0-.2-.1-.9-.3-1.7-1.1-.6-.6-1.1-1.3-1.2-1.5-.1-.2 0-.3.1-.4.1-.1.2-.3.3-.4.1-.1.1-.2.2-.3.1-.1.0-.2 0-.4-.1-.1-.5-1.3-.7-1.8-.2-.5-.4-.4-.5-.4h-.4c-.1 0-.4.1-.6.3-.2.2-.8.8-.8 1.9s.8 2.2.9 2.3c.1.2 1.6 2.4 3.8 3.3 2.2.9 2.2.6 2.6.6.4 0 1.3-.5 1.5-1 .2-.5.2-.9.1-1-.1-.1-.2-.1-.4-.2z"/>
  <path fill="#fff" d="M12.1 4.4c-4.1 0-7.4 3.3-7.4 7.4 0 1.3.3 2.5.9 3.6L4.8 19l3.7-.9c1 .6 2.2.9 3.5.9 4.1 0 7.4-3.3 7.4-7.4s-3.2-7.2-7.3-7.2zm0 13.4c-1.2 0-2.3-.3-3.3-.9l-.2-.1-2.2.6.6-2.1-.1-.2c-.6-1-1-2.1-1-3.3 0-3.4 2.8-6.2 6.2-6.2 3.4 0 6.2 2.8 6.2 6.2 0 3.4-2.8 6-6.2 6z"/>
</svg>
''';

const String _telegramSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="12" fill="#2AABEE"/>
  <path fill="#fff" d="M5.38 11.82l12.66-4.9c.59-.23 1.11.14.92 1.04l-2.16 10.18c-.15.72-.58.9-1.17.56l-3.24-2.39-1.56 1.51c-.17.17-.32.32-.65.32l.23-3.29 5.99-5.42c.26-.23-.06-.36-.4-.13l-7.41 4.67-3.19-1c-.69-.22-.71-.69.14-1.03z"/>
</svg>
''';
