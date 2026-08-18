import 'package:chewie/src/cast/chewie_playback_target.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaterialVideoProgressBar extends StatelessWidget {
  MaterialVideoProgressBar(
    this.controller, {
    this.height = kToolbarHeight,
    this.barHeight = 10,
    this.handleHeight = 6,
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    super.key,
    this.draggableProgressBar = true,
    this.playback,
  }) : colors = colors ?? ChewieProgressColors();

  final double height;
  final double barHeight;
  final double handleHeight;
  final VideoPlayerController controller;

  /// What to read and seek. Defaults to [controller]; Chewie passes the cast
  /// receiver here while a session is live.
  final ChewiePlaybackTarget? playback;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;
  final bool draggableProgressBar;

  @override
  Widget build(BuildContext context) {
    return VideoProgressBar(
      controller,
      barHeight: barHeight,
      handleHeight: handleHeight,
      drawShadow: true,
      colors: colors,
      onDragEnd: onDragEnd,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      draggableProgressBar: draggableProgressBar,
      playback: playback,
    );
  }
}
