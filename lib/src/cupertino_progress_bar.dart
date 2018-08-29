import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

class CupertinoVideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final Function() onDragStart;
  final Function() onDragEnd;
  final Function() onDragUpdate;

  CupertinoVideoProgressBar(
    this.controller, {
    ChewieProgressColors colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
  }) : colors = colors ?? new ChewieProgressColors();

  @override
  _VideoProgressBarState createState() {
    return new _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<CupertinoVideoProgressBar> {
  VoidCallback listener;

  bool _controllerWasPlaying = false;

  _VideoProgressBarState() {
    listener = () {
      setState(() {});
    };
  }

  VideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final RenderBox box = context.findRenderObject();
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
    }

    return new GestureDetector(
      child: (controller.value.hasError)
          ? new Text(controller.value.errorDescription)
          : new Center(
              child: new Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: new CustomPaint(
                  painter: new _ProgressBarPainter(
                    controller.value,
                    widget.colors,
                  ),
                ),
              ),
            ),
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          controller.play();
        }

        if (widget.onDragEnd != null) {
          widget.onDragEnd();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  VideoPlayerValue value;
  ChewieProgressColors colors;

  _ProgressBarPainter(this.value, this.colors);

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = 5.0;
    final handleHeight = 6.0;
    final baseOffset = size.height / 2 - barHeight / 2.0;

    canvas.drawRRect(
      new RRect.fromRectAndRadius(
        new Rect.fromPoints(
          new Offset(0.0, baseOffset),
          new Offset(size.width, baseOffset + barHeight),
        ),
        new Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.initialized) {
      return;
    }
    final double playedPart = value.position.inMilliseconds /
        value.duration.inMilliseconds *
        size.width;
    for (DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        new RRect.fromRectAndRadius(
          new Rect.fromPoints(
            new Offset(start, baseOffset),
            new Offset(end, baseOffset + barHeight),
          ),
          new Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      new RRect.fromRectAndRadius(
        new Rect.fromPoints(
          new Offset(0.0, baseOffset),
          new Offset(playedPart, baseOffset + barHeight),
        ),
        new Radius.circular(4.0),
      ),
      colors.playedPaint,
    );

    final shadowPath = new Path()
      ..addOval(new Rect.fromCircle(
          center: new Offset(playedPart, baseOffset + barHeight / 2),
          radius: handleHeight));

    canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    canvas.drawCircle(
      new Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}
