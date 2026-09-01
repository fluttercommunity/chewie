import 'package:chewie/src/cast/chewie_cast_controller.dart';
import 'package:chewie/src/cast/widgets/cast_button.dart';
import 'package:chewie/src/cupertino/widgets/cupertino_frosted_pill.dart';
import 'package:chewie/src/models/cast_translations.dart';
import 'package:flutter/material.dart';

/// [CastButton] wrapped in the chrome Cupertino's control bar expects.
///
/// The Cupertino skin gives each top-bar button its own blurred, rounded
/// background rather than sharing one behind the whole bar, so the cast button
/// has to bring its own. It also fades itself: Cupertino has no shared opacity
/// wrapper, and without [hidden] the cast icon stayed on screen after the rest
/// of the controls had gone, looking like it was not part of them.
class CupertinoCastButton extends StatelessWidget {
  const CupertinoCastButton({
    required this.castController,
    required this.translations,
    required this.backgroundColor,
    required this.barHeight,
    required this.buttonPadding,
    this.hidden = false,
    this.iconColor = Colors.white,
    this.useRootNavigator = true,
    this.cancelButtonText,
    this.onMenuOpened,
    this.onMenuClosed,
    super.key,
  });

  final ChewieCastController castController;
  final CastTranslations translations;

  /// Fill behind the blur, matching the bar's other buttons.
  final Color backgroundColor;
  final double barHeight;
  final double buttonPadding;

  /// Whether the controls are currently hidden; fades the button with them.
  final bool hidden;

  final Color iconColor;
  final bool useRootNavigator;
  final String? cancelButtonText;

  /// Called as the picker opens, so the skin can hold its hide timer.
  final VoidCallback? onMenuOpened;

  /// Called once the picker is dismissed.
  final VoidCallback? onMenuClosed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: hidden ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: CupertinoFrostedPill(
        backgroundColor: backgroundColor,
        barHeight: barHeight,
        child: CastButton(
          castController: castController,
          translations: translations,
          useRootNavigator: useRootNavigator,
          cancelButtonText: cancelButtonText,
          iconColor: iconColor,
          iconSize: 16,
          padding: EdgeInsets.symmetric(horizontal: buttonPadding),
          onMenuOpened: onMenuOpened,
          onMenuClosed: onMenuClosed,
        ),
      ),
    );
  }
}
