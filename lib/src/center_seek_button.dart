import 'package:flutter/material.dart';

class CenterSeekButton extends StatelessWidget {
  const CenterSeekButton({
    super.key,
    required this.iconData,
    required this.backgroundColor,
    this.iconColor,
    required this.show,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.iconSize = 26,
    this.onPressed,
  });

  final IconData iconData;
  final Color backgroundColor;
  final Color? iconColor;
  final bool show;
  final VoidCallback? onPressed;
  final Duration fadeDuration;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Center(
        child: UnconstrainedBox(
          child: AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: fadeDuration,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              // Always set the iconSize on the IconButton, not on the Icon itself:
              // https://github.com/flutter/flutter/issues/52980
              child: IconButton(
                iconSize: iconSize,
                padding: const EdgeInsets.all(8.0),
                icon: Icon(iconData, color: iconColor),
                onPressed: onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
