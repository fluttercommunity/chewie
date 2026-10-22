import 'package:chewie/src/cupertino/widgets/cupertino_frosted_pill.dart';
import 'package:chewie/src/models/chewie_control_style.dart';
import 'package:flutter/material.dart';

/// `ChewieController.additionalControls` as Cupertino's top bar wants them.
///
/// Hands the supplied controls a [ChewieControlStyle] carrying the bar's icon
/// sizing, tint and frosted pill, so a control written once looks native in
/// either skin, and fades them with the rest of the bar.
class CupertinoAdditionalControls extends StatelessWidget {
  const CupertinoAdditionalControls({
    required this.additionalControls,
    required this.backgroundColor,
    required this.barHeight,
    required this.buttonPadding,
    required this.marginSize,
    this.hidden = false,
    this.iconColor = Colors.white,
    super.key,
  });

  final List<Widget> Function(BuildContext context) additionalControls;

  final Color backgroundColor;
  final double barHeight;
  final double buttonPadding;

  /// Gap between pills, matching the bar's own buttons.
  final double marginSize;

  /// Whether the controls are currently hidden; fades them with the bar.
  final bool hidden;

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    // This bar has no shared opacity wrapper — each button fades itself — so
    // supplied controls need one too, or they stay put while everything around
    // them fades.
    return AnimatedOpacity(
      opacity: hidden ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: ChewieControlStyle(
        iconSize: 16,
        iconColor: iconColor,
        padding: EdgeInsets.symmetric(horizontal: buttonPadding),
        decorate: (child) => CupertinoFrostedPill(
          backgroundColor: backgroundColor,
          barHeight: barHeight,
          child: child,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Each supplied control wears its own frosted pill, so they need
            // the gap the bar's own buttons have between them; without it two
            // of them sit pill against pill.
            for (final control in additionalControls(context)) ...[
              control,
              SizedBox(width: marginSize),
            ],
          ],
        ),
      ),
    );
  }
}
