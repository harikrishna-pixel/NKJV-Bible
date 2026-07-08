import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class OwnReferralCodeDialog {
  OwnReferralCodeDialog._();

  static const String referralCacheKey = 'referral_code';

  static Future<void> show({
    required BuildContext context,
    required String referralCode,
  }) async {
    final code = referralCode.trim();
    if (code.isEmpty) return;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _OwnReferralCodeDialogContent(referralCode: code);
      },
    );
  }

  static Future<void> copyReferralCode(String referralCode) async {
    final code = referralCode.trim();
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    Constants.showToast('Referral code copied');
  }

  static Rect sharePositionOrigin(BuildContext context) {
    final renderObject = context.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      final origin = box.localToGlobal(Offset.zero) & box.size;
      if (origin.width > 0 && origin.height > 0) {
        return origin;
      }
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 2,
      height: 2,
    );
  }

  static String _appStoreLink() {
    if (Platform.isIOS) {
      return 'https://apps.apple.com/app/id${BibleInfo.apple_AppId}';
    }
    return 'https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}';
  }

  static String _referralShareMessage(String code) {
    return '''Grow closer to God with me!

Download the Geneva Bible app and use my referral code $code when you sign up to start your own Bible journey.

Download here:
${_appStoreLink()}''';
  }

  static Future<void> shareReferralCode(
    BuildContext context,
    String referralCode, {
    bool includeAppLink = false,
  }) async {
    final code = referralCode.trim();
    if (code.isEmpty) return;

    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;

    final shareText = _referralShareMessage(code);

    try {
      await Share.share(
        shareText,
        sharePositionOrigin: sharePositionOrigin(context),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText));
      Constants.showToast('Referral code copied');
    }
  }
}

class ReferralCodeProfileSection extends StatelessWidget {
  const ReferralCodeProfileSection({
    super.key,
    required this.referralCode,
  });

  final String referralCode;

  @override
  Widget build(BuildContext context) {
    final code = referralCode.trim();
    if (code.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final primary = CommanColor.lightDarkPrimary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Referral Code'.toUpperCase(),
          style: const TextStyle(
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withOpacity(0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CommanColor.whiteBlack(context),
                  fontSize: screenWidth > 450
                      ? BibleInfo.fontSizeScale * 22
                      : BibleInfo.fontSizeScale * 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this code with friends or copy it anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CommanColor.whiteBlack(context).withOpacity(0.7),
                  fontSize: BibleInfo.fontSizeScale * 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              ReferralCodeShareActions(
                referralCode: code,
                includeAppLink: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ReferralCodeShareActions extends StatefulWidget {
  const ReferralCodeShareActions({
    super.key,
    required this.referralCode,
    this.includeAppLink = false,
  });

  final String referralCode;
  final bool includeAppLink;

  @override
  State<ReferralCodeShareActions> createState() =>
      _ReferralCodeShareActionsState();
}

class _ReferralCodeShareActionsState extends State<ReferralCodeShareActions> {
  final GlobalKey _shareButtonKey = GlobalKey();

  Future<void> _share() async {
    final buttonContext = _shareButtonKey.currentContext;
    if (buttonContext != null && buttonContext.mounted) {
      await OwnReferralCodeDialog.shareReferralCode(
        buttonContext,
        widget.referralCode,
        includeAppLink: widget.includeAppLink,
      );
      return;
    }
    if (!mounted) return;
    await OwnReferralCodeDialog.shareReferralCode(
      context,
      widget.referralCode,
      includeAppLink: widget.includeAppLink,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = CommanColor.lightDarkPrimary(context);
    final isDark = CommanColor.isDarkTheme(context);
    final copyActionColor =
        isDark ? CommanColor.whiteBlack(context) : primary;
    final copyBorderColor = isDark
        ? CommanColor.whiteBlack(context).withOpacity(0.45)
        : primary.withOpacity(0.5);
    final outlinedButtonStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: copyBorderColor),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                OwnReferralCodeDialog.copyReferralCode(widget.referralCode),
            icon: Icon(Icons.copy_rounded, color: copyActionColor, size: 18),
            label: Text(
              'Copy',
              style: TextStyle(
                color: copyActionColor,
                fontWeight: FontWeight.w600,
                fontSize: BibleInfo.fontSizeScale * 15,
              ),
            ),
            style: outlinedButtonStyle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            key: _shareButtonKey,
            onPressed: _share,
            icon: Icon(Icons.share_rounded, color: copyActionColor, size: 18),
            label: Text(
              'Share',
              style: TextStyle(
                color: copyActionColor,
                fontWeight: FontWeight.w600,
                fontSize: BibleInfo.fontSizeScale * 15,
              ),
            ),
            style: outlinedButtonStyle,
          ),
        ),
      ],
    );
  }
}

class _OwnReferralCodeDialogContent extends StatelessWidget {
  const _OwnReferralCodeDialogContent({required this.referralCode});

  final String referralCode;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final primary = CommanColor.lightDarkPrimary(context);

    return Dialog(
      backgroundColor: CommanColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 24),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 28 : 22,
          16,
          isTablet ? 28 : 22,
          isTablet ? 28 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.close,
                  size: 22,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Container(
              width: isTablet ? 64 : 56,
              height: isTablet ? 64 : 56,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.redeem_rounded,
                color: primary,
                size: isTablet ? 32 : 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Referral Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primary,
                fontSize: isTablet
                    ? BibleInfo.fontSizeScale * 22
                    : BibleInfo.fontSizeScale * 20,
                fontWeight: FontWeight.w700,
                letterSpacing: BibleInfo.letterSpacing,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This code is generated only once for your account.\nCopy it or share it with friends.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: isTablet
                    ? BibleInfo.fontSizeScale * 15
                    : BibleInfo.fontSizeScale * 14,
                height: 1.45,
                letterSpacing: BibleInfo.letterSpacing,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 18 : 16,
              ),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withOpacity(0.25)),
              ),
              child: Text(
                referralCode,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CommanColor.black,
                  fontSize: isTablet
                      ? BibleInfo.fontSizeScale * 24
                      : BibleInfo.fontSizeScale * 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ReferralCodeShareActions(referralCode: referralCode),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: BibleInfo.fontSizeScale * 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
