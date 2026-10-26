import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:flutter/material.dart';

/// Visual layout for the "Thanks for the love!" rating popup.
class ThanksForLoveRatingDialogContent extends StatelessWidget {
  const ThanksForLoveRatingDialogContent({
    super.key,
    required this.onClose,
    required this.onRate,
    required this.onMaybeLater,
  });

  final VoidCallback onClose;
  final VoidCallback onRate;
  final VoidCallback onMaybeLater;

  static const Color _titleBrown = Color(0xFF6B4423);
  static const Color _bodyGrey = Color(0xFF4A4A4A);
  static const Color _sparkleGold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = isTablet ? 24.0 : (screenWidth < 380 ? 20.0 : 22.0);
    final bodySize = isTablet ? 17.0 : (screenWidth < 380 ? 14.0 : 15.5);
    final rateLabel = Platform.isIOS
        ? 'Rate Us on the App Store'
        : 'Rate Us on the Play Store';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 22,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          _StarsHeader(big: isTablet ? 56 : 50),
          const SizedBox(height: 14),
          Text(
            'Enjoying the app?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: titleSize + 4,
              color: _titleBrown,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "If you're finding this app helpful for your Bible reading, "
            'please take a moment to rate us.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              height: 1.45,
              color: _bodyGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF9B6B4F),
                    Color(0xFF5C3D2E),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C3D2E).withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRate,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: _sparkleGold,
                          size: isTablet ? 22 : 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rateLabel,
                          style: TextStyle(
                            color: CommanColor.white,
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mockup header: big filled gold star with rays, smaller outlined stars.
class _StarsHeader extends StatelessWidget {
  const _StarsHeader({required this.big});

  final double big;

  static const Color _gold = ThanksForLoveRatingDialogContent._sparkleGold;

  @override
  Widget build(BuildContext context) {
    Widget outline(double s) =>
        Icon(Icons.star_border_rounded, size: s, color: _gold);
    Widget ray(double angle) => Transform.rotate(
          angle: angle,
          child: Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
    return SizedBox(
      height: big + 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          outline(big * 0.42),
          const SizedBox(width: 2),
          outline(big * 0.52),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ray(-0.6),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ray(0),
                  ),
                  const SizedBox(width: 10),
                  ray(0.6),
                ],
              ),
              Icon(Icons.star_rounded, size: big, color: _gold),
            ],
          ),
          const SizedBox(width: 4),
          outline(big * 0.52),
          const SizedBox(width: 2),
          outline(big * 0.42),
        ],
      ),
    );
  }
}
