import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../chewie_progress_colors.dart';
import '../../helpers/vtt_parser.dart';
import '../../progress_bar.dart';

class MaterialVideoProgressBar extends StatelessWidget {
  MaterialVideoProgressBar(
    this.controller, {
    this.height = kToolbarHeight,
    this.barHeight = 6,
    this.handleHeight = 8,
    this.onDragEnd,
    this.onDragStart,
    this.thumbnailsPlaceholder,
    this.thumbnails,
    this.onDragUpdate,
    super.key,
    this.draggableProgressBar = true,
    ChewieProgressColors? colors,
  }) : colors = colors ?? ChewieProgressColors();

  final double height;
  final double barHeight;
  final double handleHeight;
  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragUpdate;
  final bool draggableProgressBar;
  final List<WebVTTEntry>? thumbnails;
  final List<WebVTTEntry>? thumbnailsPlaceholder;

  @override
  Widget build(BuildContext context) {
    return VideoProgressBar(
      controller,
      barHeight: barHeight,
      handleHeight: handleHeight,
      drawShadow: true,
      colors: colors,
      onDragEnd: onDragEnd,
      thumbnails: thumbnails,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      thumbnailsPlaceholder: thumbnailsPlaceholder,
      draggableProgressBar: draggableProgressBar,
    );
  }
}
