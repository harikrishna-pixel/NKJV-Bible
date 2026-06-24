import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class OwnReferralCodeDialog {
  OwnReferralCodeDialog._();

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
}

class _OwnReferralCodeDialogContent extends StatelessWidget {
  const _OwnReferralCodeDialogContent({required this.referralCode});

  final String referralCode;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: referralCode));
    Constants.showToast('Referral code copied');
  }

  Future<void> _shareCode(BuildContext context) async {
    final storeLink = Platform.isIOS
        ? 'https://itunes.apple.com/app/id${BibleInfo.apple_AppId}'
        : 'https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}';
    final message =
        'Join me on ${BibleInfo.bible_shortName}! Use my referral code: $referralCode\n$storeLink';
    await Share.share(message);
  }

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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyCode(context),
                    icon: Icon(Icons.copy_rounded, color: primary, size: 18),
                    label: Text(
                      'Copy',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: BibleInfo.fontSizeScale * 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primary.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareCode(context),
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    label: Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: BibleInfo.fontSizeScale * 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
