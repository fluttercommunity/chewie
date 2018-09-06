import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(
    new ChewieDemo(),
  );
}

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
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new VideoPlayerController.network(
      'https://github.com/flutter/assets-for-api-docs/blob/master/assets/videos/butterfly.mp4?raw=true',
    );
  }

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
                  _controller,
                  aspectRatio: 3 / 2,
                  autoPlay: true,
                  looping: true,

                  // Try playing around with some of these other options:

                  // showControls: false,
                  // materialProgressColors: new ChewieProgressColors(
                  //   playedColor: Colors.red,
                  //   handleColor: Colors.blue,
                  //   backgroundColor: Colors.grey,
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
                        _controller = new VideoPlayerController.network(
                          'https://github.com/flutter/assets-for-api-docs/blob/master/assets/videos/butterfly.mp4?raw=true',
                        );
                      });
                    },
                    child: new Padding(
                      child: new Text("Video 1"),
                      padding: new EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                ),
                new Expanded(
                  child: new FlatButton(
                    onPressed: () {
                      setState(() {
                        _controller = new VideoPlayerController.network(
                          'http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_20mb.mp4',
                        );
                      });
                    },
                    child: new Padding(
                      padding: new EdgeInsets.symmetric(vertical: 16.0),
                      child: new Text("Video 2"),
                    ),
                  ),
                )
              ],
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
                  ),
                ),
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
}
