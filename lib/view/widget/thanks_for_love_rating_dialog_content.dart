import 'dart:io';

import 'package:biblebookapp/utils/emoji_text_style.dart';
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
    final rateLabel =
        Platform.isIOS ? 'Rate on App Store' : 'Rate on Play Store';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
          const SizedBox(height: 4),
          SizedBox(
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(top: 4, left: 52, child: _Sparkle(size: 14)),
                const Positioned(top: 0, right: 58, child: _Sparkle(size: 18)),
                const Positioned(bottom: 8, left: 38, child: _Sparkle(size: 12)),
                const Positioned(bottom: 2, right: 44, child: _Sparkle(size: 16)),
                const Positioned(top: 28, left: 24, child: _Sparkle(size: 10)),
                const Positioned(top: 24, right: 28, child: _Sparkle(size: 11)),
                emojiText('😍', fontSize: isTablet ? 52 : 48),
              ],
            ),
          ),
          const SizedBox(height: 12),
          textWithTrailingEmoji(
            prefix: 'Thanks for the love! ',
            emoji: '💛',
            emojiFontSize: titleSize,
            prefixStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: titleSize,
              color: _titleBrown,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Could you leave a quick rating?\nIt helps more people discover God's Word.",
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onMaybeLater,
            style: TextButton.styleFrom(
              foregroundColor: _bodyGrey,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                fontSize: isTablet ? 17 : 16,
                fontWeight: FontWeight.w500,
                color: _bodyGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: ThanksForLoveRatingDialogContent._sparkleGold.withOpacity(0.9),
    );
  }
}
