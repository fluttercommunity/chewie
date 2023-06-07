import 'package:flutter/material.dart';

class AdditionalButton {
  AdditionalButton({
    required this.icon,
    this.onTap,
    this.padding,
    this.margin,
  });

  final Widget icon;
  final Function()? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
}
