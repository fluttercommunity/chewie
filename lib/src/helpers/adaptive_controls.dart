// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

class AdaptiveControls extends StatelessWidget {
  const AdaptiveControls({
    Key? key,
    required this.controlBarBackgroundColor,
    required this.controlBarButtonsColor,
  }) : super(key: key);
  final Color? controlBarBackgroundColor;
  final Color? controlBarButtonsColor;
  @override
  Widget build(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return MaterialControls(
          buttonColor: controlBarBackgroundColor,
          backgroundColor: controlBarButtonsColor,
        );

      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return const MaterialDesktopControls();

      case TargetPlatform.iOS:
        return const CupertinoControls(
          backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: Color.fromARGB(255, 200, 200, 200),
        );
      default:
        return MaterialControls(
          buttonColor: controlBarBackgroundColor ?? Colors.green,
          backgroundColor: controlBarButtonsColor ?? Colors.red,
        );
    }
  }
}
