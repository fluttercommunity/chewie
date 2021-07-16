import 'package:flutter/material.dart';
import '../../in_app_picture_in_picture.dart';
import '../../src/material/material_desktop_controls.dart';

class AdaptiveControls extends StatelessWidget {
  const AdaptiveControls({
    required this.onClose,
    Key? key,
  }) : super(key: key);

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return MaterialControls(
          onClose: onClose,
        );

      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return const MaterialDesktopControls();

      case TargetPlatform.iOS:
        return CupertinoControls(
          onClose: onClose,
          backgroundColor: const Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: const Color.fromARGB(255, 200, 200, 200),
        );
      default:
        return const MaterialControls();
    }
  }
}
