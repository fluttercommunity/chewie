import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dart:async';

import 'dart:ui';
import 'package:chewie_example/material_controls.dart';
import 'package:chewie_example/cupertino_controls.dart';

class PlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final Future<dynamic> Function() onExpandCollapse;
  final bool fullScreen;

  final double aspectRatio;

  PlayerWithControls(
      {@required this.controller,
      @required this.onExpandCollapse,
      @required this.aspectRatio,
      this.fullScreen = false});

  @override
  State createState() {
    return new _VideoPlayerWithControlsState();
  }
}

class _VideoPlayerWithControlsState extends State<PlayerWithControls> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return new Center(
      child: new Container(
        width: MediaQuery.of(context).size.width,
        child: new AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: new Container(
            child: new Stack(
              children: <Widget>[
                new Hero(
                  tag: controller,
                  child: new Center(
                    child: new AspectRatio(
                        aspectRatio: widget.aspectRatio,
                        child: new VideoPlayer(controller)),
                  ),
                ),
                Theme.of(context).platform == TargetPlatform.android
                    ? new MaterialControls(
                        controller: controller,
                        onExpandCollapse: widget.onExpandCollapse,
                        fullScreen: widget.fullScreen,
                      )
                    : new CupertinoControls(
                        backgroundColor: new Color.fromRGBO(41, 41, 41, 0.7),
                        iconColor: new Color.fromARGB(255, 200, 200, 200),
                        controller: controller,
                        onExpandCollapse: widget.onExpandCollapse,
                        fullScreen: widget.fullScreen,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    // Hack to show the video when it starts playing. Should be fixed by the
    // Plugin IMO.
    widget.controller.addListener(_onPlay);

    super.initState();
  }

  void _onPlay() {
    if (widget.controller.value.isPlaying) {
      setState(() {
        widget.controller.removeListener(_onPlay);
      });
    }
  }
}
