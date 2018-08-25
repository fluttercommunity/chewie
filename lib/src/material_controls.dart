import 'dart:async';

import 'package:custom_chewie/src/custom_chewie_progress_colors.dart';
import 'package:custom_chewie/src/material_progress_bar.dart';
import 'package:custom_chewie/src/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_android_pip/flutter_android_pip.dart';

class MaterialControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool fullScreen;
  final Future<dynamic> Function() onExpandCollapse;
  final ChewieProgressColors progressColors;
  final bool autoPlay;

  MaterialControls({
    @required this.controller,
    @required this.fullScreen,
    @required this.onExpandCollapse,
    @required this.progressColors,
    @required this.autoPlay,
  });

  @override
  State<StatefulWidget> createState() {
    return new _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _showTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;

  final barHeight = 48.0;
  final marginSize = 5.0;

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new Container(
          color: Colors.black38,
        ),
      ),
      new Column(
        children: <Widget>[
          _latestValue != null &&
                      !_latestValue.isPlaying &&
                      _latestValue.duration == null ||
                  _latestValue != null && _latestValue.isBuffering
              ? Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _buildHitArea(),
          _buildBottomBar(context, widget.controller),
        ],
      ),
      _hideStuff
          ? new Container()
          : new IconButton(
              icon: new Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () async {
                print("pressed true");
                widget.controller.pause();
                Navigator.pop(context);
                /*tempShowAd--;
            if (tempShowAd == 0 &&
                await retrieveData("no_ads") ==
                    null) {
              myInterstitial
                ..load()
                ..show().then((e) {
                  myInterstitial..load();
                });
              tempShowAd = initialShowAd;
            }*/
                //Navigator.pop(contextWidget);
              },
            ),
    ]);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    widget.controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void initState() {
    _initialize();

    super.initState();
  }

  @override
  void didUpdateWidget(MaterialControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.dataSource != oldWidget.controller.dataSource) {
      _dispose();
      _initialize();
    }
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
    VideoPlayerController controller,
  ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return new AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: new Duration(milliseconds: 300),
      child: new Container(
        height: barHeight,
        color: Colors.transparent,
        child: new Row(
          children: <Widget>[
            _buildPlayPause(controller),
            _buildPosition(Colors.white),
            _buildProgressBar(),
            _buildMuteButton(controller),
            widget.fullScreen ? _buildPipButton() : Container(),
            _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return new GestureDetector(
      onTap: _onExpandCollapse,
      child: new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new Container(
          height: barHeight,
          margin: new EdgeInsets.only(right: 12.0),
          padding: new EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: new Center(
            child: new Icon(
              widget.fullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
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
            ? () {
                _playPause();
                //_cancelAndRestartTimer;
                setState(() {
                  _hideStuff = false;
                });
              }
            : () {
                _playPause();
                setState(() {
                  _hideStuff = true;
                });
              },
        child: new Container(
          color: Colors.transparent,
          child: new Center(
            child: new AnimatedOpacity(
              opacity:
                  _latestValue != null && !_latestValue.isPlaying && !_dragging
                      ? 1.0
                      : 0.0,
              duration: new Duration(milliseconds: 300),
              child: new GestureDetector(
                child: new Container(
                  decoration: new BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: new BorderRadius.circular(48.0),
                  ),
                  child: new Padding(
                    padding: new EdgeInsets.only(top: 30.0),
                    child: new Icon(
                      Icons.play_arrow,
                      size: 50.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
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
          child: new Container(
            child: new Container(
              height: barHeight,
              padding: new EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: new Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPipButton() {
    return new GestureDetector(
      onTap: () {
        FlutterAndroidPip.enterPictureInPictureMode;
        _playPause();
        setState(() {
          _hideStuff = true;
        });
      },
      child: new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new ClipRect(
          child: new Container(
            child: new Container(
              height: barHeight,
              padding: new EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: new Icon(
                Icons.picture_in_picture,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return new GestureDetector(
      onTap: _playPause,
      child: new Container(
        height: barHeight,
        color: Colors.transparent,
        margin: new EdgeInsets.only(left: 8.0, right: 8.0),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return new Padding(
      padding: new EdgeInsets.only(right: 24.0),
      child: new Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: new TextStyle(
          fontSize: 14.0,
          color: Colors.white,
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
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

    _showTimer = new Timer(new Duration(milliseconds: 200), () {
      setState(() {
        _hideStuff = false;
      });
    });
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      widget.onExpandCollapse().then((dynamic _) {
        _showAfterExpandCollapseTimer =
            new Timer(new Duration(milliseconds: 300), () {
          setState(() {
            _cancelAndRestartTimer();
          });
        });
      });
    });
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

  Widget _buildProgressBar() {
    return new Expanded(
      child: new Padding(
        padding: new EdgeInsets.only(right: 20.0),
        child: new MaterialVideoProgressBar(
          widget.controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: widget.progressColors ??
              new ChewieProgressColors(
                  playedColor: Colors.red,
                  handleColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.grey),
        ),
      ),
    );
  }
}
