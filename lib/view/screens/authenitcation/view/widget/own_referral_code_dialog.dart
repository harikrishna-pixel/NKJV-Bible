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

  void _showHowItWorks(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFFFDF6EA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'How it works',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w700,
                          fontSize: BibleInfo.fontSizeScale * 20,
                          color: const Color(0xFF472F1F),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 20, color: Color(0xFF472F1F)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _HowItWorksStep(
                  number: '1',
                  title: 'Share your referral code',
                  body:
                  'Share your unique referral code with your friends via any platform.',
                  icon: Icons.share_rounded,
                  showConnector: true,
                ),
                const _HowItWorksStep(
                  number: '2',
                  title: 'Friend signs up using your code',
                  body:
                  'Your friend installs the app and signs up using your referral code.',
                  icon: Icons.person_add_alt_1_rounded,
                  showConnector: true,
                ),
                const _HowItWorksStep(
                  number: '3',
                  title: 'Both get 100 Free Credits',
                  body:
                  'You and your friend will both receive 100 Free Credits instantly!',
                  icon: Icons.card_giftcard_rounded,
                  showConnector: false,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E7D5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 18, color: Color(0xFF6B8F71)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This referral code is unique to you and is valid for up to 10 users only.',
                          style: TextStyle(
                            fontSize: BibleInfo.fontSizeScale * 12,
                            height: 1.35,
                            color: const Color(0xFF472F1F).withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF472F1F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Got it!',
                      style: TextStyle(
                        fontSize: BibleInfo.fontSizeScale * 15,
                        fontWeight: FontWeight.w700,
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

  Widget _leafIcon({bool mirror = false}) {
    final leaf = Image.asset(
      'assets/referral_leaf.png',
      width: 36,
      height: 34,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (!mirror) return leaf;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
      child: leaf,
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = referralCode.trim();
    final titleColor = CommanColor.whiteBlack(context);
    final subtitleColor = titleColor.withOpacity(0.62);
    final showEnter = _canEnterReferral && onEnterReferralTap != null;
    final showOwn = code.isNotEmpty;
    final cardFill =
    CommanColor.lightDarkPrimary200(context).withOpacity(0.28);
    final buttonFill = const Color(0xFF472F1F);

    if (!showEnter && !showOwn) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showEnter) ...[
          InkWell(
            onTap: onEnterReferralTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: cardFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: buttonFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.redeem_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Referral Code'.toUpperCase(),
                          style: TextStyle(
                            letterSpacing: 0.7,
                            fontSize: BibleInfo.fontSizeScale * 13,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Enter a referral code to claim your welcome reward.',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: BibleInfo.fontSizeScale * 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: titleColor.withOpacity(0.7),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (showOwn) const SizedBox(height: 16),
        ],
        if (showOwn) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Referral Code'.toUpperCase(),
                  style: TextStyle(
                    letterSpacing: 0.7,
                    fontSize: BibleInfo.fontSizeScale * 13,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showHowItWorks(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: titleColor.withOpacity(0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'How it works?',
                        style: TextStyle(
                          fontSize: BibleInfo.fontSizeScale * 11.5,
                          fontWeight: FontWeight.w600,
                          color: titleColor.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.help_outline,
                        size: 14,
                        color: titleColor.withOpacity(0.75),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Share your code with friends and earn together!',
            style: TextStyle(
              color: subtitleColor,
              fontSize: BibleInfo.fontSizeScale * 12.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: cardFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _leafIcon(),
                  const SizedBox(width: 6),
                  Text(
                    code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: BibleInfo.fontSizeScale * 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Georgia',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _leafIcon(mirror: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ReferralCodeShareActions(
            referralCode: code,
            includeAppLink: true,
            profileFilled: true,
          ),
        ],
      ],
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    required this.showConnector,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B8F71),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFF6B8F71).withOpacity(0.45),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 14 : 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF472F1F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: BibleInfo.fontSizeScale * 13.5,
                            color: const Color(0xFF472F1F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: BibleInfo.fontSizeScale * 12,
                            height: 1.35,
                            color: const Color(0xFF472F1F).withOpacity(0.72),
                          ),
                        ),
                      ],
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

class ReferralCodeShareActions extends StatefulWidget {
  const ReferralCodeShareActions({
    super.key,
    required this.referralCode,
    this.includeAppLink = false,
    this.compact = false,
    this.stacked = false,
    this.profileFilled = false,
  });

  final String referralCode;
  final bool includeAppLink;
  final bool compact;
  final bool stacked;
  final bool profileFilled;

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

    if (widget.profileFilled) {
      final filledStyle = ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF472F1F),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => OwnReferralCodeDialog.copyReferralCode(
                widget.referralCode,
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(
                'Copy',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: BibleInfo.fontSizeScale * 14,
                ),
              ),
              style: filledStyle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              key: _shareButtonKey,
              onPressed: _share,
              icon: const Icon(Icons.share_rounded, size: 16),
              label: Text(
                'Share',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: BibleInfo.fontSizeScale * 14,
                ),
              ),
              style: filledStyle,
            ),
          ),
        ],
      );
    }

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
        width: 84,
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
            const SizedBox(height: 8),
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