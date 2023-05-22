import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProgressBar extends StatefulWidget {
  VideoProgressBar(
    this.controller, {
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    Key? key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  })  : colors = colors ?? ChewieProgressColors(),
        super(key: key);

  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  // ignore: library_private_types_in_public_api
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  void listener() {
    if (!mounted) return;
    setState(() {});
  }

  bool _controllerWasPlaying = false;

  Offset? _latestDraggableOffset;

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

  void _seekToRelativePosition(Offset globalPosition) {
    controller.seekTo(context.calcRelativePosition(
      controller.value.duration,
      globalPosition,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    final child = Center(
      child: StaticProgressBar(
        value: controller.value,
        colors: widget.colors,
        barHeight: widget.barHeight,
        handleHeight: widget.handleHeight,
        drawShadow: widget.drawShadow,
      ),
    );

    return chewieController.draggableProgressBar
        ? GestureDetector(
            onHorizontalDragStart: (DragStartDetails details) {
              if (!controller.value.isInitialized) {
                return;
              }
              _controllerWasPlaying = controller.value.isPlaying;
              if (_controllerWasPlaying) {
                controller.pause();
              }

              widget.onDragStart?.call();
            },
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              if (!controller.value.isInitialized) {
                return;
              }
              _latestDraggableOffset = details.globalPosition;
              listener();

              widget.onDragUpdate?.call();
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              if (_controllerWasPlaying) {
                controller.play();
              }

              if (_latestDraggableOffset != null) {
                _seekToRelativePosition(_latestDraggableOffset!);
                _latestDraggableOffset = null;
              }

              widget.onDragEnd?.call();
            },
            onTapDown: (TapDownDetails details) {
              if (!controller.value.isInitialized) {
                return;
              }
              _seekToRelativePosition(details.globalPosition);
            },
            child: child,
          )
        : child;
  }
}

class StaticProgressBar extends StatelessWidget {
  const StaticProgressBar({
    Key? key,
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    this.latestDraggableOffset,
  }) : super(key: key);

  final Offset? latestDraggableOffset;
  final VideoPlayerValue value;
  final ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: CustomPaint(
        painter: _ProgressBarPainter(
          value: value,
          draggableValue: context.calcRelativePosition(
            value.duration,
            latestDraggableOffset,
          ),
          colors: colors,
          barHeight: barHeight,
          handleHeight: handleHeight,
          drawShadow: drawShadow,
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    required this.draggableValue,
  });

  VideoPlayerValue value;
  ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final Duration draggableValue;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseOffset = size.height / 2 - barHeight / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.isInitialized) {
      return;
    }
    final double playedPartPercent = (draggableValue != Duration.zero
            ? draggableValue.inMilliseconds
            : value.position.inMilliseconds) /
        value.duration.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          const Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );

    if (drawShadow) {
      final Path shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(playedPart, baseOffset + barHeight / 2),
            radius: handleHeight,
          ),
        );

      canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    }

    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}

extension RelativePositionExtensions on BuildContext {
  Duration calcRelativePosition(
    Duration videoDuration,
    Offset? globalPosition,
  ) {
    if (globalPosition == null) return Duration.zero;
    final box = findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    final Duration position = videoDuration * relative;
    return position;
  }
}
