import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

class AdaptiveControls extends StatelessWidget {
  const AdaptiveControls({this.showPlayButton = true, super.key});

  final bool showPlayButton;

  @override
  Widget build(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return MaterialControls(showPlayButton: showPlayButton);

      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return MaterialDesktopControls(showPlayButton: showPlayButton);

      case TargetPlatform.iOS:
        return CupertinoControls(
          backgroundColor: const Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: const Color.fromARGB(255, 200, 200, 200),
          showPlayButton: showPlayButton,
        );
    }
  }
}
