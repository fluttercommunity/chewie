import 'dart:async';

import 'package:flutter/widgets.dart';

/// Shared state for the YouTube-style transient seek indicator.
///
/// Tracks visibility, direction, and the accumulated seeked amount while the
/// user keeps seeking in the same direction (keyboard arrows on the desktop
/// controls, double-taps on the mobile controls). Seeking the opposite way —
/// or letting the indicator fade out — resets the counter.
mixin SeekIndicatorStateMixin<T extends StatefulWidget> on State<T> {
  /// How long the indicator stays visible after the last seek.
  static const _seekIndicatorDisplayDuration = Duration(milliseconds: 900);

  Timer? _seekIndicatorTimer;
  bool _seekIndicatorVisible = false;
  bool _seekIndicatorForward = true;
  int _seekIndicatorSeconds = 0;

  /// Whether the indicator is currently shown. While `true`, further seeks in
  /// [seekIndicatorForward]'s direction accumulate onto [seekIndicatorSeconds].
  bool get seekIndicatorVisible => _seekIndicatorVisible;

  /// The direction of the seek currently displayed.
  bool get seekIndicatorForward => _seekIndicatorForward;

  /// The accumulated number of seconds displayed.
  int get seekIndicatorSeconds => _seekIndicatorSeconds;

  /// Shows the indicator and accumulates [stepSeconds] while the user keeps
  /// seeking in the same direction. Seeking the opposite direction (or after
  /// the indicator has faded out) resets the counter.
  void bumpSeekIndicator({required bool forward, required int stepSeconds}) {
    setState(() {
      if (_seekIndicatorVisible && _seekIndicatorForward == forward) {
        _seekIndicatorSeconds += stepSeconds;
      } else {
        _seekIndicatorForward = forward;
        _seekIndicatorSeconds = stepSeconds;
      }
      _seekIndicatorVisible = true;
    });

    _seekIndicatorTimer?.cancel();
    _seekIndicatorTimer = Timer(_seekIndicatorDisplayDuration, () {
      if (!mounted) return;
      setState(() => _seekIndicatorVisible = false);
    });
  }

  /// Cancels the auto-hide timer. Call this from `dispose`.
  void disposeSeekIndicator() {
    _seekIndicatorTimer?.cancel();
  }
}
