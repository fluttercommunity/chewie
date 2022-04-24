import 'package:chewieLumen/src/animated_play_pause.dart';
import 'package:flutter/material.dart';

class CenterButtons extends StatelessWidget {
  const CenterButtons({
    Key? key,
    required this.backgroundPlayIconColor,
    this.playIconColor,
    this.prevNextIconsColor,
    required this.show,
    required this.isPlaying,
    required this.isFinished,
    this.withMaterialPrevAndNextButtons = false,
    this.isPrevButtonDisabled = true,
    this.isNextButtonDisabled = true,
    this.onPlayPressed,
    this.onNextClicked,
    this.onPrevClicked,
  }) : super(key: key);

  final Color backgroundPlayIconColor;
  final Color? playIconColor;
  final Color? prevNextIconsColor;
  final bool show;
  final bool isPlaying;
  final bool isFinished;
  final bool withMaterialPrevAndNextButtons;
  final bool isPrevButtonDisabled;
  final bool isNextButtonDisabled;
  final VoidCallback? onPlayPressed;
  final void Function()? onPrevClicked;
  final void Function()? onNextClicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: AnimatedOpacity(
          opacity: show ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (withMaterialPrevAndNextButtons)
                _NextPrevButton(
                  icon: Icons.skip_previous_sharp,
                  iconColor: isPrevButtonDisabled ? Colors.grey : prevNextIconsColor,
                  onPressed: isPrevButtonDisabled ? null : onPrevClicked,
                ),
              if (withMaterialPrevAndNextButtons) const SizedBox(width: 10.0),
              _PlayButton(
                backgroundColor: backgroundPlayIconColor,
                isFinished: isFinished,
                isPlaying: isPlaying,
                onPlayPressed: onPlayPressed,
                iconColor: playIconColor,
              ),
              if (withMaterialPrevAndNextButtons) const SizedBox(width: 10.0),
              if (withMaterialPrevAndNextButtons)
                _NextPrevButton(
                  icon: Icons.skip_next_sharp,
                  iconColor: isNextButtonDisabled ? Colors.grey : prevNextIconsColor,
                  onPressed: isNextButtonDisabled ? null : onNextClicked,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextPrevButton extends StatelessWidget {
  const _NextPrevButton({
    required this.icon,
    this.iconColor,
    this.onPressed,
  });
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 42.0,
      color: iconColor,
      icon: Icon(icon),
      onPressed: () {
        onPressed?.call();
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.backgroundColor,
    required this.isFinished,
    required this.isPlaying,
    this.iconColor,
    this.onPlayPressed,
  });

  final Color backgroundColor;
  final bool isFinished;
  final bool isPlaying;
  final Color? iconColor;
  final VoidCallback? onPlayPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        // Always set the iconSize on the IconButton, not on the Icon itself:
        // https://github.com/flutter/flutter/issues/52980
        child: IconButton(
          iconSize: 42.0,
          icon: isFinished
              ? Icon(Icons.replay, color: iconColor)
              : AnimatedPlayPause(
                  color: iconColor,
                  playing: isPlaying,
                ),
          onPressed: onPlayPressed,
        ),
      ),
    );
  }
}
