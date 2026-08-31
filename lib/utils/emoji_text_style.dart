import 'dart:io';

import 'package:flutter/material.dart';

/// TextStyle for emoji glyphs (avoids custom Bible/Georgia font tofu boxes).
TextStyle emojiTextStyle({double fontSize = 22, double height = 1.1}) {
  return TextStyle(
    fontSize: fontSize,
    height: height,
    inherit: false,
    fontFamily: Platform.isIOS ? 'Apple Color Emoji' : null,
    fontFamilyFallback: const [
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Noto Color Emoji',
    ],
  );
}

Widget emojiText(String character, {double fontSize = 22, TextAlign? textAlign}) {
  return Text(
    character,
    textAlign: textAlign,
    style: emojiTextStyle(fontSize: fontSize),
  );
}

/// Plain [prefix] + trailing [emoji] without inheriting the app serif font.
Widget textWithTrailingEmoji({
  required String prefix,
  required String emoji,
  required TextStyle prefixStyle,
  double emojiFontSize = 18,
  TextAlign textAlign = TextAlign.center,
}) {
  return RichText(
    textAlign: textAlign,
    text: TextSpan(
      children: [
        TextSpan(text: prefix, style: prefixStyle),
        TextSpan(
          text: emoji,
          style: emojiTextStyle(fontSize: emojiFontSize),
        ),
      ],
    ),
  );
}
