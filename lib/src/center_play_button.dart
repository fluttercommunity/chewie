import 'dart:ui';

import 'package:chewie/src/animated_play_pause.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CenterPlayButton extends StatelessWidget {
  const CenterPlayButton({
    Key? key,
    required this.backgroundColor,
    this.iconColor,
    required this.show,
    required this.isPlaying,
    required this.isFinished,
    this.onPressed,
  }) : super(key: key);

  final Color backgroundColor;
  final Color? iconColor;
  final bool show;
  final bool isPlaying;
  final bool isFinished;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16.0),
            width: 64,
            height: 64,
            child: isFinished
                ? Icon(Icons.replay, color: iconColor)
                : isPlaying
                    ? SvgPicture.asset(
                        'assets/svg/icon/player/player_stop.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        width: 36,
                        height: 36,
                      )
                    : SvgPicture.asset(
                        'assets/svg/icon/player/player_start.svg',
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                        width: 36,
                        height: 36,
                      ),
          ),
        ),
      ),
    );
  }
}
