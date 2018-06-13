import 'dart:async';

import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class Chewie extends StatefulWidget {
  /// The Controller for the Video you want to play
  final VideoPlayerController controller;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Whether or not to show the controls
  final bool showControls;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final ChewieProgressColors cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final ChewieProgressColors materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  Chewie(
    this.controller, {
    Key key,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.placeholder,
    this.showControls = true,
  })  : assert(controller != null,
            'You must provide a controller to play a video'),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _ChewiePlayerState();
  }
}

class _ChewiePlayerState extends State<Chewie> {
  VideoPlayerController _controller;

  @override
  Widget build(BuildContext context) {
    return new PlayerWithControls(
      controller: _controller,
      onExpandCollapse: () => _pushFullScreenWidget(context),
      aspectRatio: widget.aspectRatio ?? _calculateAspectRatio(context),
      cupertinoProgressColors: widget.cupertinoProgressColors,
      materialProgressColors: widget.materialProgressColors,
      placeholder: widget.placeholder,
      autoPlay: widget.autoPlay,
      showControls: widget.showControls,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _initialize();
  }

  Widget _buildFullScreenVideo(
      BuildContext context, Animation<double> animation) {
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      body: new Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: new PlayerWithControls(
          controller: _controller,
          onExpandCollapse: () =>
              new Future<dynamic>.value(Navigator.of(context).pop()),
          aspectRatio: widget.aspectRatio ?? _calculateAspectRatio(context),
          fullScreen: true,
          cupertinoProgressColors: widget.cupertinoProgressColors,
          materialProgressColors: widget.materialProgressColors,
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
    await _controller.setLooping(widget.looping);

    if (widget.autoInitialize || widget.autoPlay) {
      await _controller.initialize();
    }

    if (widget.autoPlay) {
      await _controller.play();
    }

    if (widget.startAt != null) {
      await _controller.seekTo(widget.startAt);
    }
  }

  @override
  void didUpdateWidget(Chewie oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller.dataSource != _controller.dataSource) {
      _controller.dispose();
      _controller = widget.controller;
      _initialize();
    }
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<Null> route = new PageRouteBuilder<Null>(
      settings: new RouteSettings(isInitialRoute: false),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    await Navigator.of(context).push(route);

    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  double _calculateAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return width > height ? width / height : height / width;
  }
}
