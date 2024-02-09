import 'package:flutter/material.dart';

import 'center_play_button.dart';
import 'seek_control_button.dart';

class HitAreaControls extends StatelessWidget {
  const HitAreaControls({
    Key? key,
    required this.onTapPlay,
    required this.onPressedPlay,
    required this.backgroundColor,
    required this.iconColor,
    required this.isFinished,
    required this.isPlaying,
    required this.showPlayButton,
    required this.showSeekButton,
    this.seekRewind,
    this.seekForward,
  }) : super(key: key);

  final VoidCallback onTapPlay;
  final VoidCallback onPressedPlay;
  final VoidCallback? seekRewind;
  final VoidCallback? seekForward;
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
        showSeekButton
            ? SeekControlButton(
                backgroundColor: backgroundColor,
                iconColor: iconColor,
                onPressed: seekRewind,
                onDoublePressed: seekRewind,
                icon: Icons.fast_rewind,
              )
            : const SizedBox.shrink(),
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
        showSeekButton
            ? SeekControlButton(
                backgroundColor: backgroundColor,
                iconColor: iconColor,
                onPressed: seekForward,
                onDoublePressed: seekForward,
                icon: Icons.fast_forward,
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
