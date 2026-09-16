import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/material.dart';

BoxDecoration journeyParchmentDecoration(BuildContext context) {
  return BoxDecoration(
    image: DecorationImage(
      image: AssetImage(Images.bgImage(context)),
      fit: BoxFit.fill,
    ),
  );
}
