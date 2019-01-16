import 'dart:ui';

import 'package:chewie/src/chewie_controller.dart';
import 'package:chewie/src/cupertino_controls.dart';
import 'package:chewie/src/material_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  PlayerWithControls({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController =
        ChewieControllerProvider.of(context);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio:
              chewieController.aspectRatio ?? _calculateAspectRatio(context),
          child: _buildPlayerWithControls(chewieController, context),
        ),
      ),
    );
  }

  Container _buildPlayerWithControls(
      ChewieController chewieController, BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          chewieController.placeholder ?? Container(),
          Center(
            child: Hero(
              tag: chewieController.value.videoPlayerController,
              child: AspectRatio(
                aspectRatio: chewieController.aspectRatio ??
                    _calculateAspectRatio(context),
                child:
                    VideoPlayer(chewieController.value.videoPlayerController),
              ),
            ),
          ),
          _buildControls(context, chewieController),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    ChewieController chewieController,
  ) {
    return chewieController.showControls
        ? Theme.of(context).platform == TargetPlatform.android
            ? MaterialControls()
            : CupertinoControls(
                backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
                iconColor: Color.fromARGB(255, 200, 200, 200),
              )
        : Container();
  }

  double _calculateAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return width > height ? width / height : height / width;
  }

// TODO: Add playback hack somewhere or better: fix in the VideoPlayer plugin
//  @override
//  void initState() {
//    // Hack to show the video when it starts playing. Should be fixed by the
//    // Plugin IMO.
//    widget.controller.addListener(_onPlay);
//
//    super.initState();
//  }
//
//  @override
//  void didUpdateWidget(PlayerWithControls oldWidget) {
//    super.didUpdateWidget(oldWidget);
//
//    if (widget.controller.dataSource != oldWidget.controller.dataSource) {
//      widget.controller.addListener(_onPlay);
//    }
//  }
//
//  @override
//  dispose() {
//    widget.controller.removeListener(_onPlay);
//    super.dispose();
//  }
//
//  void _onPlay() {
//    if (widget.controller.value.isPlaying) {
//      setState(() {
//        widget.controller.removeListener(_onPlay);
//      });
//    }
//  }
}
