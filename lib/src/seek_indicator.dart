import 'package:flutter/material.dart';

/// A YouTube-style transient indicator that flashes the amount of time seeked
/// when the user seeks with the keyboard.
///
/// Repeated presses in the same direction keep it visible and accumulate
/// [seconds] (e.g. 10 → 20 → 30). It is purely visual and never intercepts
/// pointer events.
class SeekIndicator extends StatelessWidget {
  const SeekIndicator({
    super.key,
    required this.show,
    required this.forward,
    required this.seconds,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  /// Whether the indicator is currently visible.
  final bool show;

  /// `true` when seeking forward, `false` when seeking backward. Drives both
  /// the icon and which side of the screen the pill sits on.
  final bool forward;

  /// The accumulated number of seconds seeked, shown as text.
  final int seconds;

  /// How long the fade in/out animation takes.
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: forward
            ? const Alignment(0.6, 0.0)
            : const Alignment(-0.6, 0.0),
        child: AnimatedOpacity(
          opacity: show ? 1.0 : 0.0,
          duration: fadeDuration,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    forward
                        ? Icons.fast_forward_rounded
                        : Icons.fast_rewind_rounded,
                    color: Colors.white,
                    size: 22.0,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    '$seconds s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
