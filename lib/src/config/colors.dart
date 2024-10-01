import 'package:flutter/material.dart';

class PlayerColors {
  static const black = Colors.black;

  static const white = Colors.white;

  static final whiteOpacity16 = white.withOpacity(0.16);

  static const primary = Color(0xFFFF4B00);

  static const dark14 = Color(0xFF141414);

  static const dark36 = Color(0xFF363636);

  static const greyB8 = Color(0xFFB8B8B8);

  static const grey95 = Color(0xFF959595);

  static const grey80 = Color(0xFF808080);

  static const yellow = Color(0xFFFFB800);

  static final highlightColor = white.withOpacity(0.2);
}

class PlayerColorsCustom {
  static CustomColorsV1 get v1 => CustomColorsV1();
}

class CustomColorsV1 {
  final primary = const Color(0xFF5A93E8);
}
