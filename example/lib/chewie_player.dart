import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:chewie_example/player_with_controls.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class ChewiePlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final bool autoPlay;
  final bool looping;
  final double aspectRatio;

  ChewiePlayer({
    Key key,
    @required this.controller,
    this.aspectRatio,
    this.autoPlay = false,
    this.looping = false,
  })
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _ChewiePlayerState();
  }
}

class _ChewiePlayerState extends State<ChewiePlayer> {
  @override
  Widget build(BuildContext context) {
    return new PlayerWithControls(
        controller: widget.controller,
        onExpandCollapse: () {
          return _pushFullScreenWidget(context);
        },
        aspectRatio: widget.aspectRatio ?? _calculateAspectRatio(context));
  }

  @override
  void initState() {
    _initialize();

    super.initState();
  }

  _buildFullScreenVideo(BuildContext context, Animation<double> animation) {
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      body: new Container(
        color: Colors.black,
        child: new PlayerWithControls(
          controller: widget.controller,
          onExpandCollapse: () => new Future.value(Navigator.of(context).pop()),
          aspectRatio: widget.aspectRatio,
          fullScreen: true,
        ),
      ),
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation);
      },
    );
  }

  Future _initialize() async {
    await widget.controller.setLooping(widget.looping);
    await widget.controller.initialize();

    if (widget.autoPlay) {
      await widget.controller.play();
    }
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) {
    final TransitionRoute<Null> route = new PageRouteBuilder<Null>(
      settings: new RouteSettings(isInitialRoute: false),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIOverlays([]);

    return Navigator.of(context).push(route).then((_) {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    });
  }

  double _calculateAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return width > height ? width / height : height / width;

  }
}
