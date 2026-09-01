import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The frosted, rounded background each button in Cupertino's control bars
/// wears.
///
/// The Cupertino skin gives every button its own blurred pill rather than
/// putting one behind the whole bar, so anything added to those bars has to
/// bring the same chrome or it sits flat against the video.
///
/// Deliberately does not fade itself: the bar has no shared opacity wrapper, so
/// callers wrap this (or the widget that carries several of these) in their own
/// [AnimatedOpacity].
class CupertinoFrostedPill extends StatelessWidget {
  const CupertinoFrostedPill({
    required this.backgroundColor,
    required this.barHeight,
    required this.child,
    super.key,
  });

  /// Fill behind the blur.
  final Color backgroundColor;

  /// Height of the bar the pill sits in.
  final double barHeight;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0),
        child: ColoredBox(
          color: backgroundColor,
          child: SizedBox(height: barHeight, child: child),
        ),
      ),
    );
  }
}
