import 'dart:async';
import 'dart:ui';

import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/cupertino_controls.dart';
import 'package:chewie/src/material_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final Future<dynamic> Function() onExpandCollapse;
  final bool fullScreen;
  final ChewieProgressColors cupertinoProgressColors;
  final ChewieProgressColors materialProgressColors;
  final Widget placeholder;
  final double aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final bool isLive;

  PlayerWithControls({
    Key key,
    @required this.controller,
    @required this.onExpandCollapse,
    @required this.aspectRatio,
    this.fullScreen = false,
    this.showControls = true,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.placeholder,
    this.autoPlay,
    this.isLive = false,
  }) : super(key: key);

  @override
  State createState() {
    return _VideoPlayerWithControlsState();
  }
}

class _VideoPlayerWithControlsState extends State<PlayerWithControls> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: _buildPlayerWithControls(controller, context),
        ),
      ),
    );
  }

  Container _buildPlayerWithControls(
      VideoPlayerController controller, BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          widget.placeholder ?? Container(),
          Center(
            child: Hero(
              tag: controller,
              child: AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          _buildControls(context, controller),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    VideoPlayerController controller,
  ) {
    return widget.showControls
        ? Theme.of(context).platform == TargetPlatform.android
            ? MaterialControls(
                controller: controller,
                onExpandCollapse: widget.onExpandCollapse,
                fullScreen: widget.fullScreen,
                progressColors: widget.materialProgressColors,
                autoPlay: widget.autoPlay,
                isLive: widget.isLive,
              )
            : CupertinoControls(
                backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
                iconColor: Color.fromARGB(255, 200, 200, 200),
                controller: controller,
                onExpandCollapse: widget.onExpandCollapse,
                fullScreen: widget.fullScreen,
                progressColors: widget.cupertinoProgressColors,
                autoPlay: widget.autoPlay,
                isLive: widget.isLive,
              )
        : Container();
  }

  @override
  void initState() {
    // Hack to show the video when it starts playing. Should be fixed by the
    // Plugin IMO.
    widget.controller.addListener(_onPlay);

    super.initState();
  }

  @override
  void didUpdateWidget(PlayerWithControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller.dataSource != oldWidget.controller.dataSource) {
      widget.controller.addListener(_onPlay);
    }
  }

  @override
  dispose() {
    widget.controller.removeListener(_onPlay);
    super.dispose();
  }

  void _onPlay() {
    if (widget.controller.value.isPlaying) {
      setState(() {
        widget.controller.removeListener(_onPlay);
      });
    }
  }
}
