import 'package:flutter/material.dart';

class SeekRewindButton extends StatefulWidget {
  const SeekRewindButton({
    Key? key,
    required this.backgroundColor,
    this.iconColor,
    required this.show,
    required this.icon,
    this.onPressed,
    this.onDoublePressed,
  }) : super(key: key);

  final Color backgroundColor;
  final Color? iconColor;
  final bool show;
  final VoidCallback? onPressed;
  final VoidCallback? onDoublePressed;
  final IconData? icon;

  @override
  State<SeekRewindButton> createState() => _SeekRewindButtonState();
}

class _SeekRewindButtonState extends State<SeekRewindButton>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.show
        ? Expanded(
            child: GestureDetector(
              onDoubleTap: widget.onDoublePressed,
              child: ColoredBox(
                color: Colors.transparent,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    // Always set the iconSize on the IconButton, not on the Icon itself:
                    // https://github.com/flutter/flutter/issues/52980
                    child: IconButton(
                      iconSize: 32,
                      padding: const EdgeInsets.all(12.0),
                      icon: Icon(widget.icon, color: widget.iconColor),
                      onPressed: widget.onPressed,
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
