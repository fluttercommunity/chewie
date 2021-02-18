import 'dart:async';

import 'package:chewie_audio/src/chewie_player.dart';
import 'package:chewie_audio/src/chewie_progress_colors.dart';
import 'package:chewie_audio/src/material_progress_bar.dart';
import 'package:chewie_audio/src/utils.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaterialControls extends StatefulWidget {
  const MaterialControls({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls> with SingleTickerProviderStateMixin {
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;

  final barHeight = 48.0;
  final marginSize = 5.0;

  VideoPlayerController? controller;
  ChewieAudioController? chewieController;
  AnimationController? playPauseIconAnimationController;

  @override
  Widget build(BuildContext context) {
    if (_latestValue!.hasError) {
      return chewieController!.errorBuilder != null
          ? chewieController!.errorBuilder!(
              context,
              chewieController!.videoPlayerController.value.errorDescription,
            )
          : const Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    return _buildBottomBar(context);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller!.removeListener(_updateState);
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
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

  Widget _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.button!.color;

    return Container(
      height: barHeight,
      color: Theme.of(context).dialogBackgroundColor,
      child: Row(
        children: <Widget>[
          _buildPlayPause(controller!),
          if (chewieController!.isLive) const Expanded(child: Text('LIVE')) else _buildPosition(iconColor),
          if (chewieController!.isLive) const SizedBox() else _buildProgressBar(),
          if (chewieController!.allowMuting) _buildMuteButton(controller),
        ],
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController? controller,
  ) {
    return GestureDetector(
      onTap: () {
        if (_latestValue!.volume == 0) {
          controller!.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller!.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: ClipRect(
        child: Container(
          height: barHeight,
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Icon(
            (_latestValue != null && _latestValue!.volume > 0) ? Icons.volume_up : Icons.volume_off,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
        padding: const EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  Widget _buildPosition(Color? iconColor) {
    final position = _latestValue != null && _latestValue!.position != null ? _latestValue!.position : Duration.zero;
    final duration = _latestValue != null && _latestValue!.duration != null ? _latestValue!.duration : Duration.zero;

    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: const TextStyle(
          fontSize: 14.0,
        ),
      ),
    );
  }

  Future<void> _initialize() async {
    controller!.addListener(_updateState);

    _updateState();
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
        playPauseIconAnimationController!.reverse();
        controller!.pause();
      } else {
        if (!controller!.value.isInitialized) {
          controller!.initialize().then((_) {
            controller!.play();
            playPauseIconAnimationController!.forward();
          });
        } else {
          if (isFinished) {
            controller!.seekTo(const Duration());
          }
          playPauseIconAnimationController!.forward();
          controller!.play();
        }
      }
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller!.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: MaterialVideoProgressBar(
          controller,
          onDragStart: () {},
          onDragEnd: () {},
          colors: chewieController!.materialProgressColors ??
              ChewieProgressColors(
                  playedColor: Theme.of(context).accentColor,
                  handleColor: Theme.of(context).accentColor,
                  bufferedColor: Theme.of(context).backgroundColor,
                  backgroundColor: Theme.of(context).disabledColor),
        ),
      ),
    );
  }
}
