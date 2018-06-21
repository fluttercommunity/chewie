import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class fadeoutPlaceholder extends StatefulWidget {
  final VideoPlayerController controller;
  final Widget placeholder;
  final Duration fadeAfter;

  fadeoutPlaceholder({this.controller, this.placeholder, this.fadeAfter});

  @override
  _fadeoutPlaceholderState createState() => _fadeoutPlaceholderState();
}

class _fadeoutPlaceholderState extends State<fadeoutPlaceholder> {
  VoidCallback listener;

  VideoPlayerController get controller => widget.controller;

  _fadeoutPlaceholderState() {
    listener = () {
      setState(() {});
    };
  }

  @override
  void didUpdateWidget(fadeoutPlaceholder oldWidget) {
    if (oldWidget.controller != controller) {
      controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        opacity: controller.value.position > widget.fadeAfter ? 0.0 : 1.0,
        duration: Duration(milliseconds: 200),
        child: widget.placeholder ?? Container());
  }
}
