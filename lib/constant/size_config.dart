import 'package:flutter/material.dart';

class Sizecf {
  static MediaQueryData? _mediaQueryData;
  static double? scrnHeight;
  static double? scrnWidth;
  static double? blockSizeHorizontal;
  static double? blockSizeVertical;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    scrnWidth = _mediaQueryData!.size.width;
    scrnHeight = _mediaQueryData!.size.height;
    blockSizeHorizontal = scrnWidth! / 100;
    blockSizeVertical = scrnHeight! / 100;
  }
}
