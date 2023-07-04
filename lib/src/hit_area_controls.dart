import 'package:flutter/material.dart';

import 'center_play_button.dart';
import 'seek_rewind_button.dart';

class HitAreaControls extends StatelessWidget {
  const HitAreaControls({
    Key? key,
    this.onTapPlay,
    this.onPressedPlay,
    this.seekRewind,
    this.seekForward,
    required this.backgroundColor,
    required this.iconColor,
    required this.isFinished,
    required this.isPlaying,
    required this.showPlayButton,
    required this.showSeekButton,
  }) : super(key: key);

  final Function()? onTapPlay;
  final Function()? onPressedPlay;
  final Function()? seekRewind;
  final Function()? seekForward;
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
        _buildSeekRewindButton(isSeekForward: false),
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
        _buildSeekRewindButton(isSeekForward: true),
      ],
    );
  }

  SeekRewindButton _buildSeekRewindButton({bool isSeekForward = true}) {
    return SeekRewindButton(
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      show: showSeekButton,
      onPressed: isSeekForward ? seekForward : seekRewind,
      onDoublePressed: isSeekForward ? seekForward : seekRewind,
      icon: isSeekForward ? Icons.fast_forward : Icons.fast_rewind,
    );
  }
}
