import 'package:flutter/material.dart';

import 'animated_play_pause.dart';
import 'widgets/animations/player_animation.dart';

class CenterPlayButton extends StatelessWidget {
  const CenterPlayButton({
    required this.backgroundColor,
    required this.show,
    required this.isPlaying,
    required this.isFinished,
    this.iconColor,
    this.onPressed,
    super.key,
  });

  final Color backgroundColor;
  final Color? iconColor;
  final bool show;
  final bool isPlaying;
  final bool isFinished;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Center(
        child: UnconstrainedBox(
          child: PlayerAnimation(
            value: show,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                iconSize: 48,
                padding: const EdgeInsets.all(6),
                icon: isFinished
                    ? Icon(Icons.replay, color: iconColor)
                    : AnimatedPlayPause(
                        color: iconColor,
                        playing: isPlaying,
                      ),
                onPressed: onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
