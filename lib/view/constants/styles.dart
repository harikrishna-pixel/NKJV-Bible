import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';

int calculateTextLines({
  required BuildContext context,
  required String text,
}) {
  // Calculate the max width from MediaQuery
  double maxWidth = MediaQuery.of(context).size.width;

  final TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
          color: Colors.black,
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 20,
          fontWeight: FontWeight.w500,
          height: 1.3),
    ),
    maxLines: null,
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: maxWidth);

  final lineHeight = textPainter.preferredLineHeight;
  final textHeight = textPainter.height;
  final lines = (textHeight / lineHeight).ceil();

  return lines;
}
