import 'package:flutter/material.dart';

class SeekControlButton extends StatefulWidget {
  const SeekControlButton({
    Key? key,
    required this.backgroundColor,
    required this.iconColor,
    required this.show,
    required this.icon,
    required this.onPressed,
    required this.onDoublePressed,
  }) : super(key: key);

  final Color backgroundColor;
  final Color iconColor;
  final bool show;
  final VoidCallback onPressed;
  final VoidCallback onDoublePressed;
  final IconData icon;

  @override
  State<SeekControlButton> createState() => _SeekControlButtonState();
}

class _SeekControlButtonState extends State<SeekControlButton> {
  @override
  void initState() {
    super.initState();
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
