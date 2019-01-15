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
  final bool isLive;

  CupertinoControls({
    @required this.backgroundColor,
    @required this.iconColor,
    @required this.controller,
    @required this.onExpandCollapse,
    @required this.fullScreen,
    @required this.progressColors,
    @required this.autoPlay,
    @required this.isLive,
  });

  @override
  State<StatefulWidget> createState() {
    return _CupertinoControlsState();
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

    return Column(
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
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.all(marginSize),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              child: widget.isLive
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _buildPlayPause(controller, iconColor, barHeight),
                        _buildLive(iconColor),
                      ],
                    )
                  : Row(
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

  Widget _buildLive(Color iconColor) {
    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: Text(
        'LIVE',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildExpandButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: buttonPadding,
                right: buttonPadding,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              child: Center(
                child: Icon(
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
    return Expanded(
      child: GestureDetector(
        onTap: _latestValue != null && _latestValue.isPlaying
            ? _cancelAndRestartTimer
            : () {
                _hideTimer?.cancel();

                setState(() {
                  _hideStuff = false;
                });
              },
        child: Container(
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
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              child: Container(
                height: barHeight,
                padding: EdgeInsets.only(
                  left: buttonPadding,
                  right: buttonPadding,
                ),
                child: Icon(
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
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
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
        _latestValue != null ? _latestValue.position : Duration(seconds: 0);

    return Padding(
      padding: EdgeInsets.only(right: 12.0),
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
    final position = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration - _latestValue.position
        : Duration(seconds: 0);

    return Padding(
      padding: EdgeInsets.only(right: 12.0),
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
        margin: EdgeInsets.only(left: 10.0),
        padding: EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.skewY(0.0)
            ..rotateX(math.pi)
            ..rotateZ(math.pi),
          child: Icon(
            OpenIconicIcons.reload,
            color: iconColor,
            size: 12.0,
          ),
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
        padding: EdgeInsets.only(
          left: 6.0,
          right: 8.0,
        ),
        margin: EdgeInsets.only(
          right: 8.0,
        ),
        child: Icon(
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
    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: Row(
        children: <Widget>[
          _buildExpandButton(
              backgroundColor, iconColor, barHeight, buttonPadding),
          Expanded(child: Container()),
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

    _initTimer = Timer(Duration(milliseconds: 200), () {
      setState(() {
        _hideStuff = false;
      });
    });
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      widget.onExpandCollapse().then((dynamic _) {
        _expandCollapseTimer = Timer(Duration(milliseconds: 300), () {
          setState(() {
            _cancelAndRestartTimer();
          });
        });
      });
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 12.0),
        child: CupertinoVideoProgressBar(
          widget.controller,
          onDragStart: () {
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            _startHideTimer();
          },
          colors: widget.progressColors ??
              ChewieProgressColors(
                playedColor: Color.fromARGB(
                  120,
                  255,
                  255,
                  255,
                ),
                handleColor: Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ),
                bufferedColor: Color.fromARGB(
                  60,
                  255,
                  255,
                  255,
                ),
                backgroundColor: Color.fromARGB(
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
    final beginning = Duration(seconds: 0).inMilliseconds;
    final skip = (_latestValue.position - Duration(seconds: 15)).inMilliseconds;
    widget.controller.seekTo(Duration(milliseconds: math.max(skip, beginning)));
  }

  void _skipForward() {
    _cancelAndRestartTimer();
    final end = _latestValue.duration.inMilliseconds;
    final skip = (_latestValue.position + Duration(seconds: 15)).inMilliseconds;
    widget.controller.seekTo(Duration(milliseconds: math.min(skip, end)));
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
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
