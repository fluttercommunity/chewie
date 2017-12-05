import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:chewie/src/player_with_controls.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class Chewie extends StatefulWidget {
  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Whether or not the video should loop
  final bool looping;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// The colors to use for the Progress Bar. By default, the Material player
  /// uses the colors from your Theme. The Cupertino player uses colors taken
  /// from iOS designs.
  final VideoProgressColors progressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  // THe internal controller created from the URI.
  final VideoPlayerController _controller;

  Chewie(
    String uri, {
    Key key,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.looping = false,
    this.progressColors,
    this.placeholder,
  })
      : assert(uri != null, 'You must provide a URI to a video'),
        this._controller = new VideoPlayerController(uri),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _ChewiePlayerState();
  }
}

class _ChewiePlayerState extends State<Chewie> {
  @override
  Widget build(BuildContext context) {
    return new PlayerWithControls(
      controller: widget._controller,
      onExpandCollapse: () {
        return _pushFullScreenWidget(context);
      },
      aspectRatio: widget.aspectRatio ?? _calculateAspectRatio(context),
      progressColors: widget.progressColors,
      placeholder: widget.placeholder,
      autoPlay: widget.autoPlay,
    );
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
          controller: widget._controller,
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
    await widget._controller.setLooping(widget.looping);

    if (widget.autoInitialize || widget.autoPlay) {
      await widget._controller.initialize();
    }

    if (widget.autoPlay) {
      await widget._controller.play();
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
