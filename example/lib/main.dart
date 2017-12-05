import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:open_iconic_flutter/open_iconic_flutter.dart';

const String butterflyUri =
    'https://flutter.github.io/assets-for-api-docs/videos/butterfly.mp4';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Chewie Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Chewie Controls Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = new VideoPlayerController(
    butterflyUri,
  );

  bool _enableFrame;

  @override
  void initState() {
    _initialize();

    super.initState();
  }

  Widget fullScreenRoutePageBuilder(BuildContext context,
      Animation<double> animation, Animation<double> secondaryAnimation) {
    animation.addListener(() {
      if (animation.isCompleted) {
        new Timer(new Duration(milliseconds: 300), () {
          SystemChrome.setEnabledSystemUIOverlays([]);
        });
      }
    });

    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation);
      },
    );
  }

  Future<dynamic> pushFullScreenWidget(BuildContext context) {
    final TransitionRoute<Null> route = new PageRouteBuilder<Null>(
      settings: new RouteSettings(isInitialRoute: false),
      pageBuilder: fullScreenRoutePageBuilder,
    );

    _enableFrame = false;

    return Navigator.of(context).push(route).then((_) {
      new Timer(new Duration(milliseconds: 800), () {
        SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
      });
      _enableFrame = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new VideoPlayerWithControls(controller, () {
        return pushFullScreenWidget(context);
      }),
    );
  }

  _buildFullScreenVideo(BuildContext context, Animation<double> animation) {
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      body: new Container(
        color: Colors.black,
        child: new VideoPlayerWithControls(controller, () {
          return new Future.value(Navigator.of(context).pop());
        }),
      ),
    );
  }

  Future _initialize() async {
    await controller.setLooping(true);
    await controller.initialize();

    await controller.play();
  }
}

class ProgressBar extends StatelessWidget {
  final VideoPlayerController controller;

  ProgressBar(this.controller);

  @override
  Widget build(BuildContext context) {
    return new Expanded(
      child: new Padding(
        padding: new EdgeInsets.only(right: 12.0),
        child: new ClipRRect(
          borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
          child: new Container(
            height: 5.0,
            child: new VideoProgressBar(
              controller,
              colors: new VideoProgressColors(
                playedColor: new Color.fromARGB(
                  255,
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
                  140,
                  255,
                  255,
                  255,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoPlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final Future<dynamic> Function() onExpandCollapse;
  final Duration hideDuration;

  VideoPlayerWithControls(this.controller, this.onExpandCollapse,
      {this.hideDuration: const Duration(seconds: 3)});

  @override
  State createState() {
    return new _VideoPlayerWithControlsState();
  }
}

class _VideoPlayerWithControlsState extends State<VideoPlayerWithControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  bool _disposed = false;
  Timer _hideTimer;

  void _updateState() {
    setState(() {
      _latestValue = widget.controller.value;
    });
  }

  Future<Null> _initialize() async {
    widget.controller.addListener(_updateState);

    _updateState();

    _startHideTimer();

    new Timer(new Duration(milliseconds: 200), () {
      setState(() {
        _hideStuff = false;
      });
    });
  }

  void _startHideTimer() {
    _hideTimer = new Timer(widget.hideDuration, () {
      if (!_disposed) {
        setState(() {
          _hideStuff = true;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    _disposed = true;
    super.dispose();
  }

  @override
  void initState() {
    _initialize();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = new Color.fromARGB(255, 200, 200, 200);
    final backgroundColor = new Color.fromRGBO(41, 41, 41, 0.7);
    final controller = widget.controller;

    return new Center(
      child: new Container(
        width: MediaQuery.of(context).size.width,
        child: new AspectRatio(
          aspectRatio: 3 / 2,
          child: new Container(
            child: new Stack(
              children: <Widget>[
                new Hero(
                  tag: controller,
                  child: new VideoPlayer(controller),
                ),
                new Column(
                  children: <Widget>[
                    new GestureDetector(
                      onTap: _onExpandCollapse,
                      child: new Container(
                        height: 30.0,
                        margin: new EdgeInsets.only(
                          top: 5.0,
                          right: 5.0,
                          left: 5.0,
                        ),
                        child: new Row(
                          children: <Widget>[
                            new AnimatedOpacity(
                              opacity: _hideStuff ? 0.0 : 1.0,
                              duration: new Duration(
                                  milliseconds: _hideStuff ? 300 : 100),
                              child: new ClipRect(
                                child: new BackdropFilter(
                                  filter: new ImageFilter.blur(sigmaX: 10.0),
                                  child: new Container(
                                    decoration: new BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius: new BorderRadius.all(
                                        new Radius.circular(10.0),
                                      ),
                                    ),
                                    child: new Container(
                                      height: 30.0,
                                      padding: new EdgeInsets.only(
                                        left: 16.0,
                                        right: 16.0,
                                      ),
                                      child: new Icon(
                                        OpenIconicIcons.fullscreenEnter,
                                        color: iconColor,
                                        size: 12.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            new Expanded(child: new Container()),
                            new GestureDetector(
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
                                duration: new Duration(
                                    milliseconds: _hideStuff ? 300 : 100),
                                child: new ClipRect(
                                  child: new BackdropFilter(
                                    filter: new ImageFilter.blur(sigmaX: 10.0),
                                    child: new Container(
                                      decoration: new BoxDecoration(
                                        color: backgroundColor,
                                        borderRadius: new BorderRadius.all(
                                          new Radius.circular(10.0),
                                        ),
                                      ),
                                      child: new Container(
                                        height: 30.0,
                                        padding: new EdgeInsets.only(
                                          left: 16.0,
                                          right: 16.0,
                                        ),
                                        child: new Icon(
                                          (_latestValue != null &&
                                                  _latestValue.volume > 0)
                                              ? Icons.volume_up
                                              : Icons.volume_mute,
                                          color: iconColor,
                                          size: 16.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Expanded(
                      child: new GestureDetector(
                        onTap: _latestValue != null && _latestValue.isPlaying
                            ? _cancelAndRestartTimer
                            : () {
                                _hideTimer.cancel();

                                setState(() {
                                  _hideStuff = false;
                                });
                              },
                        child: new Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    new AnimatedOpacity(
                      opacity: _hideStuff ? 0.0 : 1.0,
                      duration:
                          new Duration(milliseconds: _hideStuff ? 300 : 100),
                      child: new Container(
                        color: Colors.transparent,
                        alignment: Alignment.bottomCenter,
                        margin: new EdgeInsets.all(5.0),
                        child: new ClipRect(
                          child: new BackdropFilter(
                            filter: new ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: new Container(
                              height: 30.0,
                              decoration: new BoxDecoration(
                                color: backgroundColor,
                                borderRadius: new BorderRadius.all(
                                  new Radius.circular(10.0),
                                ),
                              ),
                              child: new Row(
                                children: <Widget>[
                                  new GestureDetector(
                                    onTap: _skipBack,
                                    child: new Padding(
                                      padding: new EdgeInsets.only(
                                        left: 16.0,
                                        right: 12.0,
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
                                  ),
                                  new GestureDetector(
                                    onTap: _playPause,
                                    child: new Padding(
                                      padding: new EdgeInsets.only(
                                        right: 10.0,
                                      ),
                                      child: new Icon(
                                        controller.value.isPlaying
                                            ? OpenIconicIcons.mediaPause
                                            : OpenIconicIcons.mediaPlay,
                                        color: iconColor,
                                        size: 16.0,
                                      ),
                                    ),
                                  ),
                                  new GestureDetector(
                                    onTap: _skipForward,
                                    child: new Padding(
                                      padding: new EdgeInsets.only(
                                        right: 16.0,
                                      ),
                                      child: new Icon(
                                        OpenIconicIcons.reload,
                                        color: iconColor,
                                        size: 12.0,
                                      ),
                                    ),
                                  ),
                                  position(iconColor),
                                  new ProgressBar(controller),
                                  remaining(iconColor)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _cancelAndRestartTimer() {
    _hideTimer.cancel();

    setState(() {
      _hideStuff = false;

      _startHideTimer();
    });
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      widget.onExpandCollapse().then((_) {
        _cancelAndRestartTimer();

        new Timer(new Duration(milliseconds: 300), () {
          if (!_disposed) {
            setState(() {
              _hideStuff = false;
            });
          }
        });
      });
    });
  }

  Widget position(Color iconColor) {
    final position =
        _latestValue != null ? _latestValue.position : new Duration(seconds: 0);

    return new Padding(
      padding: new EdgeInsets.only(right: 12.0),
      child: new Text(
        _formatDuration(position),
        style: new TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  Widget remaining(Color iconColor) {
    final position = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration - _latestValue.position
        : new Duration(seconds: 0);

    return new Padding(
      padding: new EdgeInsets.only(right: 12.0),
      child: new Text(
        '-${_formatDuration(position)}',
        style: new TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  String _formatDuration(Duration position) {
    final ms = position.inMilliseconds;

    int seconds = ms ~/ 1000;
    final int hours = seconds ~/ 3600;
    seconds = seconds % 3600;
    var minutes = seconds ~/ 60;
    seconds = seconds % 60;

    final hoursString = hours > 10 ? '$hours' : hours == 0 ? '00' : '0$hours';

    final minutesString =
        minutes > 10 ? '$minutes' : minutes == 0 ? '00' : '0$minutes';

    final secondsString =
        seconds > 10 ? '$seconds' : seconds == 0 ? '00' : '0$seconds';

    final formattedTime = '${hoursString == '00' ? '' : hoursString +
        ':'}$minutesString:$secondsString';
    return formattedTime;
  }

  void _playPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer.cancel();
        widget.controller.pause();
      } else {
        _cancelAndRestartTimer();
        widget.controller.play();
      }
    });
  }

  void _skipBack() {
    final beginning = new Duration(seconds: 0).inMicroseconds;
    final skip =
        (_latestValue.position - new Duration(seconds: 15)).inMicroseconds;
    widget.controller
        .seekTo(new Duration(milliseconds: math.max(skip, beginning)));
  }

  void _skipForward() {
    final end = _latestValue.duration.inMicroseconds;
    final skip =
        (_latestValue.position + new Duration(seconds: 15)).inMicroseconds;
    widget.controller.seekTo(new Duration(milliseconds: math.min(skip, end)));
  }
}
