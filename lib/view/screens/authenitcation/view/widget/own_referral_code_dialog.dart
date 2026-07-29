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

Download the ${BibleInfo.bible_shortName} app and use my referral code $code when you sign up to start your own Bible journey.

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
    this.referredBy,
    this.referralRewardClaimed,
    this.onEnterReferralTap,
  });

  final String referralCode;
  final String? referredBy;
  final int? referralRewardClaimed;
  final VoidCallback? onEnterReferralTap;

  bool get _canEnterReferral {
    final hasReferrer =
        referredBy != null && referredBy!.trim().isNotEmpty;
    final claimed = (referralRewardClaimed ?? 0) > 0;
    return !hasReferrer && !claimed;
  }

  Widget _sectionDivider(BuildContext context) {
    return Divider(
      indent: 8,
      endIndent: 8,
      color: CommanColor.whiteBlack(context).withOpacity(0.5),
    );
  }

  Widget _circleIcon(BuildContext context, IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CommanColor.lightDarkPrimary200(context).withOpacity(0.35),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: CommanColor.lightDarkPrimary(context),
        size: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = referralCode.trim();
    final subtitleColor = CommanColor.whiteBlack(context).withOpacity(0.65);
    final showEnter = _canEnterReferral && onEnterReferralTap != null;
    final showOwn = code.isNotEmpty;

    if (!showEnter && !showOwn) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProfileReferralOrnamentalDivider(),
        if (showEnter) ...[
          _sectionDivider(context),
          InkWell(
            onTap: onEnterReferralTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _circleIcon(context, Icons.redeem_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Referral Code'.toUpperCase(),
                          style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: BibleInfo.fontSizeScale * 14,
                            fontWeight: FontWeight.bold,
                            color: CommanColor.whiteBlack(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enter a referral code to claim your welcome reward.',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: BibleInfo.fontSizeScale * 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_outlined,
                    color: CommanColor.whiteBlack(context),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          _sectionDivider(context),
        ],
        if (showOwn) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _circleIcon(context, Icons.groups_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Referral Code'.toUpperCase(),
                        style: TextStyle(
                          letterSpacing: BibleInfo.letterSpacing,
                          fontSize: BibleInfo.fontSizeScale * 14,
                          fontWeight: FontWeight.bold,
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        code,
                        style: TextStyle(
                          color: CommanColor.whiteBlack(context),
                          fontSize: BibleInfo.fontSizeScale * 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share your code and invite your friends.',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: BibleInfo.fontSizeScale * 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ReferralCodeShareActions(
                  referralCode: code,
                  includeAppLink: true,
                  stacked: true,
                ),
              ],
            ),
          ),
          _sectionDivider(context),
        ],
      ],
    );
  }
}

class _ProfileReferralOrnamentalDivider extends StatelessWidget {
  const _ProfileReferralOrnamentalDivider();

  @override
  Widget build(BuildContext context) {
    final lineColor = CommanColor.whiteBlack(context).withOpacity(0.45);
    final accent = CommanColor.lightDarkPrimary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.diamond_outlined, size: 9, color: accent),
          ),
          Text(
            '✝',
            style: TextStyle(
              color: accent,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.diamond_outlined, size: 9, color: accent),
          ),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}

class ReferralCodeShareActions extends StatefulWidget {
  const ReferralCodeShareActions({
    super.key,
    required this.referralCode,
    this.includeAppLink = false,
    this.compact = false,
    this.stacked = false,
  });

  final String referralCode;
  final bool includeAppLink;
  final bool compact;
  final bool stacked;

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
    final stacked = widget.stacked;
    final compact = widget.compact || stacked;
    final actionFontSize = BibleInfo.fontSizeScale * (compact ? 13 : 15);
    final actionIconSize = compact ? 15.0 : 18.0;
    final outlinedButtonStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: copyBorderColor),
      padding: EdgeInsets.symmetric(
        horizontal: stacked ? 8 : 12,
        vertical: stacked ? 5 : (compact ? 8 : 12),
      ),
      minimumSize: stacked ? const Size(0, 30) : null,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: stacked ? VisualDensity.compact : VisualDensity.standard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    if (stacked) {
      return SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => OwnReferralCodeDialog.copyReferralCode(
                  widget.referralCode,
                ),
                icon: Icon(Icons.copy_rounded,
                    color: copyActionColor, size: actionIconSize),
                label: Text(
                  'Copy',
                  style: TextStyle(
                    color: copyActionColor,
                    fontWeight: FontWeight.w600,
                    fontSize: actionFontSize,
                  ),
                ),
                style: outlinedButtonStyle,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: _shareButtonKey,
                onPressed: _share,
                icon: Icon(Icons.share_rounded,
                    color: copyActionColor, size: actionIconSize),
                label: Text(
                  'Share',
                  style: TextStyle(
                    color: copyActionColor,
                    fontWeight: FontWeight.w600,
                    fontSize: actionFontSize,
                  ),
                ),
                style: outlinedButtonStyle,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                OwnReferralCodeDialog.copyReferralCode(widget.referralCode),
            icon: Icon(Icons.copy_rounded,
                color: copyActionColor, size: actionIconSize),
            label: Text(
              'Copy',
              style: TextStyle(
                color: copyActionColor,
                fontWeight: FontWeight.w600,
                fontSize: actionFontSize,
              ),
            ),
            style: outlinedButtonStyle,
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: OutlinedButton.icon(
            key: _shareButtonKey,
            onPressed: _share,
            icon: Icon(Icons.share_rounded,
                color: copyActionColor, size: actionIconSize),
            label: Text(
              'Share',
              style: TextStyle(
                color: copyActionColor,
                fontWeight: FontWeight.w600,
                fontSize: actionFontSize,
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
