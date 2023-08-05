import 'package:flutter/material.dart';

import 'center_play_button.dart';
import 'seek_control_button.dart';

class HitAreaControls extends StatelessWidget {
  const HitAreaControls({
    Key? key,
    required this.onTapPlay,
    required this.onPressedPlay,
    required this.seekRewind,
    required this.seekForward,
    required this.backgroundColor,
    required this.iconColor,
    required this.isFinished,
    required this.isPlaying,
    required this.showPlayButton,
    required this.showSeekButton,
  }) : super(key: key);

  final VoidCallback onTapPlay;
  final VoidCallback onPressedPlay;
  final VoidCallback seekRewind;
  final VoidCallback seekForward;
  final Color backgroundColor;
  final Color iconColor;
  final bool isFinished;
  final bool isPlaying;
  final bool showPlayButton;
  final bool showSeekButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SeekControlButton(
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          show: showSeekButton,
          onPressed: seekRewind,
          onDoublePressed: seekRewind,
          icon: Icons.fast_rewind,
        ),
        GestureDetector(
          onTap: onTapPlay,
          child: CenterPlayButton(
            backgroundColor: backgroundColor,
            iconColor: iconColor,
            isFinished: isFinished,
            isPlaying: isPlaying,
            show: showPlayButton,
            onPressed: onPressedPlay,
          ),
        ),
        SeekControlButton(
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          show: showSeekButton,
          onPressed: seekForward,
          onDoublePressed: seekForward,
          icon: Icons.fast_forward,
        ),
      ],
    );
  }
}
