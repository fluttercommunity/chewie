import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_iconic_flutter/open_iconic_flutter.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(new MyApp());

const String butterflyUri =
    'https://flutter.github.io/assets-for-api-docs/videos/butterfly.mp4';

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

class CupertinoControls extends StatefulWidget {
  final Color backgroundColor;
  final Color iconColor;
  final VideoPlayerController controller;
  final Future<dynamic> Function() onExpandCollapse;
  final bool fullScreen;

  CupertinoControls({
    @required this.backgroundColor,
    @required this.iconColor,
    @required this.controller,
    @required this.onExpandCollapse,
    @required this.fullScreen,
  });

  @override
  State<StatefulWidget> createState() {
    return new CupertinoControlsState();
  }
}

class CupertinoControlsState extends State<CupertinoControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  bool _disposed = false;
  Timer _hideTimer;
  final barHeight = 30.0;
  final marginSize = 5.0;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    final controller = widget.controller;

    return new Column(
      children: <Widget>[
        _buildTopBar(backgroundColor, iconColor, controller),
        _buildHitArea(),
        _buildBottomBar(backgroundColor, iconColor, controller),
      ],
    );
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

  AnimatedOpacity _buildBottomBar(Color backgroundColor, Color iconColor,
      VideoPlayerController controller) {
    return new AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: new Duration(milliseconds: 300),
      child: new Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        margin: new EdgeInsets.all(marginSize),
        child: new ClipRect(
          child: new BackdropFilter(
            filter: new ImageFilter.blur(
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
                  _buildSkipBack(iconColor),
                  _buildPlayPause(controller, iconColor),
                  _buildSkipForward(iconColor),
                  _buildPosition(iconColor),
                  new ProgressBar(controller),
                  _buildRemaining(iconColor)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton(Color backgroundColor, Color iconColor) {
    return new GestureDetector(
      onTap: _onExpandCollapse,
      child: new AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: new Duration(milliseconds: 300),
        child: new ClipRect(
          child: new BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: 10.0),
            child: new Container(
              height: barHeight,
              padding: new EdgeInsets.only(
                left: 16.0,
                right: 16.0,
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
                _hideTimer.cancel();

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

  GestureDetector _buildMuteButton(VideoPlayerController controller,
      Color backgroundColor, Color iconColor) {
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
            filter: new ImageFilter.blur(sigmaX: 10.0),
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
                  left: 16.0,
                  right: 16.0,
                ),
                child: new Icon(
                  (_latestValue != null && _latestValue.volume > 0)
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
    );
  }

  GestureDetector _buildPlayPause(
      VideoPlayerController controller, Color iconColor) {
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
        _formatDuration(position),
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
        '-${_formatDuration(position)}',
        style: new TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(Color iconColor) {
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

  GestureDetector _buildSkipForward(Color iconColor) {
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

  Widget _buildTopBar(Color backgroundColor, Color iconColor,
      VideoPlayerController controller) {
    return new Container(
      height: barHeight,
      margin: new EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: new Row(
        children: <Widget>[
          _buildExpandButton(backgroundColor, iconColor),
          new Expanded(child: new Container()),
          _buildMuteButton(controller, backgroundColor, iconColor),
        ],
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

  void _startHideTimer() {
    _hideTimer = new Timer(const Duration(seconds: 3), () {
      if (!_disposed) {
        setState(() {
          _hideStuff = true;
        });
      }
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = widget.controller.value;
    });
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Chewie Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Chewie Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
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
  final bool fullScreen;

  VideoPlayerWithControls(
    this.controller,
    this.onExpandCollapse, {
    this.fullScreen = false,
  });

  @override
  State createState() {
    return new _VideoPlayerWithControlsState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = new VideoPlayerController(
    butterflyUri,
  );

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new VideoPlayerWithControls(controller, () {
        return _pushFullScreenWidget(context);
      }),
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
        child: new VideoPlayerWithControls(
          controller,
          () => new Future.value(Navigator.of(context).pop()),
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
    SystemChrome.setEnabledSystemUIOverlays([]);

    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation);
      },
    );
  }

  Future _initialize() async {
    await controller.setLooping(true);
    await controller.initialize();

    await controller.play();
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) {
    final TransitionRoute<Null> route = new PageRouteBuilder<Null>(
      settings: new RouteSettings(isInitialRoute: false),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    return Navigator.of(context).push(route).then((_) {
      new Timer(new Duration(milliseconds: 800), () {
        SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
      });
    });
  }
}

class _VideoPlayerWithControlsState extends State<VideoPlayerWithControls> {
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
                Theme.of(context).platform == TargetPlatform.android
                    ? new CupertinoControls(
                        backgroundColor: backgroundColor,
                        iconColor: iconColor,
                        controller: controller,
                        onExpandCollapse: widget.onExpandCollapse,
                        fullScreen: widget.fullScreen,
                      )
                    : new CupertinoControls(
                        backgroundColor: backgroundColor,
                        iconColor: iconColor,
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
