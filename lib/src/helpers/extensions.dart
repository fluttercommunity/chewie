import 'package:flutter/material.dart';

import '../config/colors.dart';

extension ContextExtension on BuildContext {
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;

  double vw(num value) => (1 / 1920 * width) * value;
  double vh(num value) => (1 / 1080 * height) * value;

  TextStyle get initial => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ).w400.white;

  TextStyle get s24 => initial.copyWith(
        fontSize: 24,
      );

  TextStyle get s20 => initial.copyWith(
        fontSize: 20,
      );

  TextStyle get s18 => initial.copyWith(
        fontSize: 18,
      );

  TextStyle get s16 => initial.copyWith(
        fontSize: 16,
      );

  TextStyle get s14 => initial.copyWith(
        fontSize: 14,
      );

  TextStyle get s24Tv => initial.copyWith(
        fontSize: vw(24),
      );

  TextStyle get s26Tv => initial.copyWith(
        fontSize: vw(26),
      );

  TextStyle get s32Tv => initial.copyWith(
        fontSize: vw(32),
      );
}

extension PlayerStyleExtension on TextStyle {
  TextStyle get white => copyWith(
        color: PlayerColors.white,
      );

  TextStyle get greyB8 => copyWith(
        color: PlayerColors.greyB8,
      );

  TextStyle get dark36 => copyWith(
        color: PlayerColors.dark36,
      );

  TextStyle get w400 => copyWith(
        fontWeight: FontWeight.w400,
      );

  TextStyle get w500 => copyWith(
        fontWeight: FontWeight.w500,
      );

  TextStyle get w600 => copyWith(
        fontWeight: FontWeight.w600,
      );

  TextStyle get w700 => copyWith(
        fontWeight: FontWeight.w700,
      );
}

extension BoxFitExtension on BoxFit {
  BoxFit get getNext {
    final fits = [
      BoxFit.fitWidth,
      BoxFit.cover,
      BoxFit.fill,
    ];
    final indexOf = fits.indexOf(this);
    return fits[(indexOf + 1) % fits.length];
  }
}
