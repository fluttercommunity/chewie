import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

enum ControlsType { cupertino, material, materialDesktop, adaptive }

class AdaptiveControls extends StatelessWidget {
  const AdaptiveControls({
    Key? key,
    required this.controlsType,
  }) : super(key: key);

  final ControlsType controlsType;

  @override
  Widget build(BuildContext context) {
    switch (controlsType) {
      case ControlsType.cupertino:
        return const CupertinoControls(
          backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: Color.fromARGB(255, 200, 200, 200),
        );
      case ControlsType.material:
        return const MaterialControls();
      case ControlsType.materialDesktop:
        return const MaterialDesktopControls();
      case ControlsType.adaptive:
        break;
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const MaterialControls();

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
        return const MaterialControls();
    }
  }
}
