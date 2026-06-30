import 'package:biblebookapp/view/widget/ai_important_notice_dialog.dart';
import 'package:flutter/material.dart';

/// Bottom-sheet banner that opens the AI Important Notice dialog (UI only).
class AiGeminiPrivacyBanner extends StatelessWidget {
  const AiGeminiPrivacyBanner({
    super.key,
    this.onNoticeSeen,
  });

  final VoidCallback? onNoticeSeen;

  static const Color _textColor = Color(0xFF5C4030);
  static const Color _bgColor = Color(0xFFF0E4D4);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 22,
            color: _textColor.withOpacity(0.9),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'AI Chat uses Google Gemini to provide Bible-based guidance.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => AiImportantNoticeDialog.show(
                context,
                onDismissed: onNoticeSeen,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: _textColor.withOpacity(0.85),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
