import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

class AdaptiveControls extends StatelessWidget {
  const AdaptiveControls({
    super.key,
    this.showSubtitle = false,
  });

  final bool showSubtitle;

  @override
  Widget build(
    BuildContext context,
  ) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const MaterialControls();

      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return const MaterialDesktopControls();

      case TargetPlatform.iOS:
        return CupertinoControls(
          backgroundColor: const Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: const Color.fromARGB(255, 200, 200, 200),
          showSubtitle: showSubtitle,
        );
      default:
        return const MaterialControls();
    }
  }
}
