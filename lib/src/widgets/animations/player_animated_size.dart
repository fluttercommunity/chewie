import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlayerAnimatedSize extends StatelessWidget {
  const PlayerAnimatedSize({
    required this.value,
    required this.child,
    this.duration,
    super.key,
  });

  final bool value;
  final Widget child;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration ?? 400.ms,
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration:
            duration != null ? (duration!.inMilliseconds - 100).ms : 300.ms,
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: value
            ? SizedBox(
                key: ValueKey('show-${context.hashCode}'),
                child: child,
              )
            : SizedBox(
                key: ValueKey('hide-${context.hashCode}'),
              ),
      ),
    );
  }
}
