import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(new ChewieDemo());

class ChewieDemo extends StatefulWidget {
  final String title;

  ChewieDemo({this.title = 'Chewie Demo'});

  @override
  State<StatefulWidget> createState() {
    return new _ChewieDemoState();
  }
}

class _ChewieDemoState extends State<ChewieDemo> {
  TargetPlatform _platform;
  VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: widget.title,
      theme: new ThemeData.light().copyWith(
        platform: _platform ?? Theme.of(context).platform,
      ),
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Column(
          children: <Widget>[
            new Expanded(
              child: new Center(
                child: new Chewie(
                  controller,
                  aspectRatio: 3 / 2,
                  autoPlay: true,
                  looping: true,
                  // Try playing around with some of these other options:
                  // progressColors: new VideoProgressColors(
                  //   playedColor: Colors.red,
                  //   handleColor: Colors.blue,
                  //   disabledColor: Colors.grey,
                  //   bufferedColor: Colors.lightGreen,
                  // ),
                  // placeholder: new Container(
                  //   color: Colors.grey,
                  // ),
                  // autoInitialize: true,
                ),
              ),
            ),
            new Row(
              children: <Widget>[
                new Expanded(
                    child: new FlatButton(
                  onPressed: () {
                    setState(() {
                      _platform = TargetPlatform.android;
                    });
                  },
                  child: new Padding(
                    child: new Text("Android controls"),
                    padding: new EdgeInsets.symmetric(vertical: 16.0),
                  ),
                )),
                new Expanded(
                  child: new FlatButton(
                    onPressed: () {
                      setState(() {
                        _platform = TargetPlatform.iOS;
                      });
                    },
                    child: new Padding(
                      padding: new EdgeInsets.symmetric(vertical: 16.0),
                      child: new Text("iOS controls"),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    controller = new VideoPlayerController(
      'https://flutter.github.io/assets-for-api-docs/videos/butterfly.mp4',
    );

    super.initState();
  }
}
