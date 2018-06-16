import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/cupertino_progress_bar.dart';
import 'package:chewie/src/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_iconic_flutter/open_iconic_flutter.dart';
import 'package:video_player/video_player.dart';

class CupertinoControls extends StatefulWidget {
  final Color backgroundColor;
  final Color iconColor;
  final VideoPlayerController controller;
  final Future<dynamic> Function() onExpandCollapse;
  final bool fullScreen;
  final ChewieProgressColors progressColors;
  final bool autoPlay;

  CupertinoControls({
    @required this.backgroundColor,
    @required this.iconColor,
    @required this.controller,
    @required this.onExpandCollapse,
    @required this.fullScreen,
    @required this.progressColors,
    @required this.autoPlay,
  });

  @override
  State<StatefulWidget> createState() {
    return new _CupertinoControlsState();
  }
}

class _CupertinoControlsState extends State<CupertinoControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  final marginSize = 5.0;
  Timer _expandCollapseTimer;
  Timer _initTimer;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    final controller = widget.controller;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait ? 30.0 : 47.0;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;

    return new Column(
      children: <Widget>[
        _buildTopBar(
            backgroundColor, iconColor, controller, barHeight, buttonPadding),
        _buildHitArea(),
        _buildBottomBar(backgroundColor, iconColor, controller, barHeight),
      ],
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    widget.controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void initState() {
    _initialize();

    super.initState();
  }

  @override
  void didUpdateWidget(CupertinoControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller.dataSource != oldWidget.controller.dataSource) {
      _dispose();
      _initialize();
    }
  }

  AnimatedOpacity _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    VideoPlayerController controller,
    double barHeight,
  ) {
    return new AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: new Duration(milliseconds: 300),
      child: new Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        margin: new EdgeInsets.all(marginSize),
        child: new ClipRect(
          child: new BackdropFilter(
            filter: new ui.ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: new Container(
              height: barHeight,
              decoration: new BoxDecoration(
                color: backgroundColor,
                borderRadius: new BorderRadius.all(
                  new Radius.circular(10.0),
                ),
              ),
              child: new Row(
                children: <Widget>[
                  _buildSkipBack(iconColor, barHeight),
                  _buildPlayPause(controller, iconColor, barHeight),
                  _buildSkipForward(iconColor, barHeight),
                  _buildPosition(iconColor),
                  _buildProgressBar(),
                  _buildRemaining(iconColor)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return new GestureDetector(
      onTap: _onExpandCollapse,
      child: new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new ClipRect(
          child: new BackdropFilter(
            filter: new ui.ImageFilter.blur(sigmaX: 10.0),
            child: new Container(
              height: barHeight,
              padding: new EdgeInsets.only(
                left: buttonPadding,
                right: buttonPadding,
              ),
              decoration: new BoxDecoration(
                color: backgroundColor,
                borderRadius: new BorderRadius.all(
                  new Radius.circular(10.0),
                ),
              ),
              child: new Center(
                child: new Icon(
                  widget.fullScreen
                      ? OpenIconicIcons.fullscreenExit
                      : OpenIconicIcons.fullscreenEnter,
                  color: iconColor,
                  size: 12.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return new Expanded(
      child: new GestureDetector(
        onTap: _latestValue != null && _latestValue.isPlaying
            ? _cancelAndRestartTimer
            : () {
                _hideTimer?.cancel();

                setState(() {
                  _hideStuff = false;
                });
              },
        child: new Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return new GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new ClipRect(
          child: new BackdropFilter(
            filter: new ui.ImageFilter.blur(sigmaX: 10.0),
            child: new Container(
              decoration: new BoxDecoration(
                color: backgroundColor,
                borderRadius: new BorderRadius.all(
                  new Radius.circular(10.0),
                ),
              ),
              child: new Container(
                height: barHeight,
                padding: new EdgeInsets.only(
                  left: buttonPadding,
                  right: buttonPadding,
                ),
                child: new Icon(
                  (_latestValue != null && _latestValue.volume > 0)
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: iconColor,
                  size: 16.0,
                ),
              ),
            ),
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
    return new GestureDetector(
      onTap: _playPause,
      child: new Container(
        height: barHeight,
        color: Colors.transparent,
        padding: new EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: new Icon(
          controller.value.isPlaying
              ? OpenIconicIcons.mediaPause
              : OpenIconicIcons.mediaPlay,
          color: iconColor,
          size: 16.0,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position =
        _latestValue != null ? _latestValue.position : new Duration(seconds: 0);

    return new Padding(
      padding: new EdgeInsets.only(right: 12.0),
      child: new Text(
        formatDuration(position),
        style: new TextStyle(
          color: iconColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining(Color iconColor) {
    final position = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration - _latestValue.position
        : new Duration(seconds: 0);

    return new Padding(
      padding: new EdgeInsets.only(right: 12.0),
      child: new Text(
        '-${formatDuration(position)}',
        style: new TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(Color iconColor, double barHeight) {
    return new GestureDetector(
      onTap: _skipBack,
      child: new Container(
        height: barHeight,
        color: Colors.transparent,
        margin: new EdgeInsets.only(left: 10.0),
        padding: new EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: new Transform(
          alignment: Alignment.center,
          transform: new Matrix4.skewY(0.0)
            ..rotateX(math.pi)
            ..rotateZ(math.pi),
          child: new Icon(
            OpenIconicIcons.reload,
            color: iconColor,
            size: 12.0,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(Color iconColor, double barHeight) {
    return new GestureDetector(
      onTap: _skipForward,
      child: new Container(
        height: barHeight,
        color: Colors.transparent,
        padding: new EdgeInsets.only(
          left: 6.0,
          right: 8.0,
        ),
        margin: new EdgeInsets.only(
          right: 8.0,
        ),
        child: new Icon(
          OpenIconicIcons.reload,
          color: iconColor,
          size: 12.0,
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    VideoPlayerController controller,
    double barHeight,
    double buttonPadding,
  ) {
    return new Container(
      height: barHeight,
      margin: new EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: new Row(
        children: <Widget>[
          _buildExpandButton(
              backgroundColor, iconColor, barHeight, buttonPadding),
          new Expanded(child: new Container()),
          _buildMuteButton(
              controller, backgroundColor, iconColor, barHeight, buttonPadding),
        ],
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    setState(() {
      _hideStuff = false;

      _startHideTimer();
    });
  }

  Future<Null> _initialize() async {
    widget.controller.addListener(_updateState);

    _updateState();

    if ((widget.controller.value != null &&
            widget.controller.value.isPlaying) ||
        widget.autoPlay) {
      _startHideTimer();
    }

    _initTimer = new Timer(new Duration(milliseconds: 200), () {
      setState(() {
        _hideStuff = false;
      });
    });
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      widget.onExpandCollapse().then((dynamic _) {
        _expandCollapseTimer = new Timer(new Duration(milliseconds: 300), () {
          setState(() {
            _cancelAndRestartTimer();
          });
        });
      });
    });
  }

  Widget _buildProgressBar() {
    return new Expanded(
      child: new Padding(
        padding: new EdgeInsets.only(right: 12.0),
        child: new CupertinoVideoProgressBar(
          widget.controller,
          onDragStart: () {
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            _startHideTimer();
          },
          colors: widget.progressColors ??
              new ChewieProgressColors(
                playedColor: new Color.fromARGB(
                  120,
                  255,
                  255,
                  255,
                ),
                handleColor: new Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ),
                bufferedColor: new Color.fromARGB(
                  60,
                  255,
                  255,
                  255,
                ),
                backgroundColor: new Color.fromARGB(
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
    setState(() {
      if (widget.controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        widget.controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!widget.controller.value.initialized) {
          widget.controller.initialize().then((_) {
            widget.controller.play();
          });
        } else {
          widget.controller.play();
        }
      }
    });
  }

  void _skipBack() {
    _cancelAndRestartTimer();
    final beginning = new Duration(seconds: 0).inMilliseconds;
    final skip =
        (_latestValue.position - new Duration(seconds: 15)).inMilliseconds;
    widget.controller
        .seekTo(new Duration(milliseconds: math.max(skip, beginning)));
  }

  void _skipForward() {
    _cancelAndRestartTimer();
    final end = _latestValue.duration.inMilliseconds;
    final skip =
        (_latestValue.position + new Duration(seconds: 15)).inMilliseconds;
    widget.controller.seekTo(new Duration(milliseconds: math.min(skip, end)));
  }

  void _startHideTimer() {
    _hideTimer = new Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = widget.controller.value;
    });
  }
}
