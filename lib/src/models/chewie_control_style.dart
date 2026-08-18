import 'package:flutter/widgets.dart';

/// How the surrounding control bar draws its own buttons.
///
/// Chewie cannot style an arbitrary widget handed to
/// `ChewieController.additionalControls`, but it can say what "matching" looks
/// like. Skins install this above the widgets they were given; those widgets
/// read it and size, tint and decorate themselves accordingly.
///
/// Without it, a control has to hard-code per-skin values — the Cupertino bar
/// is 30 logical pixels tall with 16px glyphs on frosted pills, the Material
/// bars are taller with 24px icons — and gets it wrong on the others.
class ChewieControlStyle extends InheritedWidget {
  const ChewieControlStyle({
    required this.iconSize,
    required this.iconColor,
    required this.decorate,
    this.padding = EdgeInsets.zero,
    required super.child,
    super.key,
  });

  /// Size the bar's own glyphs are drawn at.
  final double iconSize;

  /// Colour the bar's own glyphs are drawn in.
  final Color iconColor;

  /// Padding the bar puts around its own glyphs.
  ///
  /// Worth respecting rather than picking a value: a control bar is often
  /// shorter than it looks — the desktop bar gives its buttons about 28
  /// logical pixels once the progress bar has taken its share — so padding
  /// the bar does not use squeezes the glyph's box below the glyph, and it
  /// paints outside its own bounds instead of sitting where its neighbours do.
  final EdgeInsets padding;

  /// Wraps a control in whatever chrome the skin puts around its buttons —
  /// Cupertino's frosted pill, the desktop bar's 48x48 tap target — so a
  /// supplied control sits among them rather than beside them.
  final Widget Function(Widget child) decorate;

  /// The surrounding bar's style, or null when not inside one.
  static ChewieControlStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChewieControlStyle>();

  @override
  bool updateShouldNotify(ChewieControlStyle oldWidget) =>
      iconSize != oldWidget.iconSize ||
      iconColor != oldWidget.iconColor ||
      padding != oldWidget.padding;
}
