import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chewie_audio/src/chewie_player.dart';
import 'package:chewie_audio/src/chewie_progress_colors.dart';
import 'package:chewie_audio/src/cupertino_progress_bar.dart';
import 'package:chewie_audio/src/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CupertinoControls extends StatefulWidget {
  const CupertinoControls({
    required this.backgroundColor,
    required this.iconColor,
    Key? key,
  }) : super(key: key);

  final Color backgroundColor;
  final Color iconColor;

  @override
  State<StatefulWidget> createState() {
    return _CupertinoControlsState();
  }
}

class _CupertinoControlsState extends State<CupertinoControls> with SingleTickerProviderStateMixin {
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  final marginSize = 5.0;
  Timer? _expandCollapseTimer;
  Timer? _initTimer;

  VideoPlayerController? controller;
  ChewieAudioController? chewieController;
  AnimationController? playPauseIconAnimationController;

  @override
  Widget build(BuildContext context) {
    chewieController = ChewieAudioController.of(context);

    if (_latestValue!.hasError) {
      return chewieController!.errorBuilder != null
          ? chewieController!.errorBuilder!(
              context,
              chewieController!.videoPlayerController.value.errorDescription,
            )
          : const Center(
              child: Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    chewieController = ChewieAudioController.of(context);
    controller = chewieController!.videoPlayerController;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait ? 30.0 : 47.0;

    return _buildBottomBar(backgroundColor, iconColor, barHeight);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller!.removeListener(_updateState);
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieAudioController.of(context);
    controller = chewieController!.videoPlayerController;

    playPauseIconAnimationController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Container _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      margin: EdgeInsets.all(marginSize),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 10.0,
            sigmaY: 10.0,
          ),
          child: Container(
            height: barHeight,
            color: backgroundColor,
            child: chewieController!.isLive
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _buildPlayPause(controller!, iconColor, barHeight),
                      _buildLive(iconColor),
                      _buildMuteButton(controller, iconColor, barHeight),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      _buildSkipBack(iconColor, barHeight),
                      _buildPlayPause(controller!, iconColor, barHeight),
                      _buildSkipForward(iconColor, barHeight),
                      _buildPosition(iconColor),
                      _buildProgressBar(),
                      _buildRemaining(iconColor),
                      _buildMuteButton(controller, iconColor, barHeight),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLive(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        'LIVE',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  Widget _buildMuteButton(
    VideoPlayerController? controller,
    Color iconColor,
    double barHeight,
  ) {
    if (!chewieController!.allowMuting) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (_latestValue!.volume == 0) {
            controller!.setVolume(_latestVolume ?? 0.5);
          } else {
            _latestVolume = controller!.value.volume;
            controller.setVolume(0.0);
          }
        },
        child: SizedBox(
          height: barHeight,
          child: Icon(
            (_latestValue != null && _latestValue!.volume > 0) ? Icons.volume_up : Icons.volume_off,
            color: iconColor,
            size: 16.0,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(
    VideoPlayerController controller,
    Color iconColor,
    double barHeight,
  ) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null ? _latestValue!.position : const Duration();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        formatDuration(position),
        style: TextStyle(
          color: iconColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining(Color iconColor) {
    final position = _latestValue != null && _latestValue!.duration != null
        ? _latestValue!.duration - _latestValue!.position
        : const Duration();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        '-${formatDuration(position)}',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipBack,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 10.0),
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
          CupertinoIcons.gobackward_15,
          color: iconColor,
          size: 18.0,
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipForward,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 8.0,
        ),
        margin: const EdgeInsets.only(
          right: 8.0,
        ),
        child: Icon(
          CupertinoIcons.goforward_15,
          color: iconColor,
          size: 18.0,
        ),
      ),
    );
  }

  Future<void> _initialize() async {
    controller!.addListener(_updateState);

    _updateState();
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: CupertinoVideoProgressBar(
          controller,
          onDragStart: () {},
          onDragEnd: () {},
          colors: chewieController!.cupertinoProgressColors ??
              ChewieProgressColors(
                playedColor: const Color.fromARGB(
                  120,
                  255,
                  255,
                  255,
                ),
                handleColor: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ),
                bufferedColor: const Color.fromARGB(
                  60,
                  255,
                  255,
                  255,
                ),
                backgroundColor: const Color.fromARGB(
                  20,
                  255,
                  255,
                  255,
                ),
              ),
        ),
      ),
    );
  }

  void _playPause() {
    bool isFinished;
    if (_latestValue!.duration != null) {
      isFinished = _latestValue!.position >= _latestValue!.duration;
    } else {
      isFinished = false;
    }

    setState(() {
      if (controller!.value.isPlaying) {
        controller!.pause();
      } else {
        if (!controller!.value.isInitialized) {
          controller!.initialize().then((_) {
            controller!.play();
          });
        } else {
          if (isFinished) {
            controller!.seekTo(const Duration());
          }
          controller!.play();
        }
      }
    });
  }

  void _skipBack() {
    final beginning = const Duration().inMilliseconds;
    final skip = (_latestValue!.position - const Duration(seconds: 15)).inMilliseconds;
    controller!.seekTo(Duration(milliseconds: math.max(skip, beginning)));
  }

  void _skipForward() {
    final end = _latestValue!.duration.inMilliseconds;
    final skip = (_latestValue!.position + const Duration(seconds: 15)).inMilliseconds;
    controller!.seekTo(Duration(milliseconds: math.min(skip, end)));
  }

  void _updateState() {
    setState(() {
      _latestValue = controller!.value;
    });
  }
}
