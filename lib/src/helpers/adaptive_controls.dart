import 'package:chewie/chewie.dart';
import 'package:chewie/src/models/additional_button.dart';
import 'package:flutter/material.dart';

class AdaptiveControls extends StatelessWidget {
  const AdaptiveControls({
    Key? key,
    this.additionalButtons,
  }) : super(key: key);
  final List<AdditionalButton>? additionalButtons;

  @override
  Widget build(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return MaterialControls(additionalButtons: additionalButtons);

      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return const MaterialDesktopControls();

      case TargetPlatform.iOS:
        return CupertinoControls(
          backgroundColor: const Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: const Color.fromARGB(255, 200, 200, 200),
          additionalButtons: additionalButtons,
        );
      default:
        return MaterialControls(additionalButtons: additionalButtons);
    }
  }
}
