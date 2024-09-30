import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../chewie.dart';
import 'helpers/vtt_parser.dart';

class VideoProgressBar extends StatefulWidget {
  VideoProgressBar(
    this.controller, {
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    this.draggableProgressBar = true,
    this.thumbnailsPlaceholder,
    this.onDragUpdate,
    this.onDragStart,
    this.onDragEnd,
    this.thumbnails,
    ChewieProgressColors? colors,
    super.key,
  }) : colors = colors ?? ChewieProgressColors();

  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final bool draggableProgressBar;

  final List<WebVTTEntry>? thumbnails;
  final List<WebVTTEntry>? thumbnailsPlaceholder;

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
    controller
        .seekTo(
      context.calcRelativePosition(
        controller.value.duration,
        globalPosition,
      ),
    )
        .then(
      (_) {
        _latestDraggableOffset = null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: StaticProgressBar(
        colors: widget.colors,
        value: controller.value,
        barHeight: widget.barHeight,
        drawShadow: widget.drawShadow,
        thumbnails: widget.thumbnails,
        handleHeight: widget.handleHeight,
        latestDraggableOffset: _latestDraggableOffset,
        thumbnailsPlaceholder: widget.thumbnailsPlaceholder,
      ),
    );

    return widget.draggableProgressBar
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
                // _latestDraggableOffset = null;
              }

              widget.onDragEnd?.call();
            },
            onTapUp: (TapUpDetails details) {
              if (!controller.value.isInitialized) {
                return;
              }
              _latestDraggableOffset = details.globalPosition;
              _seekToRelativePosition(details.globalPosition);
            },
            child: child,
          )
        : child;
  }
}

class StaticProgressBar extends StatefulWidget {
  const StaticProgressBar({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    this.latestDraggableOffset,
    this.thumbnailsPlaceholder,
    this.thumbnails,
    super.key,
  });

  final Offset? latestDraggableOffset;
  final VideoPlayerValue value;
  final ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  final List<WebVTTEntry>? thumbnails;
  final List<WebVTTEntry>? thumbnailsPlaceholder;

  @override
  State<StaticProgressBar> createState() => _StaticProgressBarState();
}

class _StaticProgressBarState extends State<StaticProgressBar> {
  ui.Image? _thumbImage;
  final Dio _dio = Dio();

  Future<void> _loadImage() async {
    const networkImage = 'https://picsum.photos/500/300';

    try {
      final imageBytes = await _fetchImageBytesWithCache(networkImage);

      ui.decodeImageFromList(Uint8List.fromList(imageBytes), (img) {
        setState(() {
          _thumbImage = img;
        });
      });
    } catch (e) {
      print('Failed to load image: $e');
    }
  }

  Future<Uint8List> _fetchImageBytesWithCache(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data!);
    } catch (e) {
      throw Exception('Failed to fetch image with Dio: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _loadImage();
  }

  @override
  void didUpdateWidget(covariant StaticProgressBar oldWidget) {
    if (oldWidget.latestDraggableOffset != widget.latestDraggableOffset) {
      log(oldWidget.latestDraggableOffset.toString());
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: CustomPaint(
        painter: _ProgressBarPainter(
          value: widget.value,
          draggableValue: widget.latestDraggableOffset != null
              ? context.calcRelativePosition(
                  widget.value.duration,
                  widget.latestDraggableOffset!,
                )
              : null,
          colors: widget.colors,
          barHeight: widget.barHeight,
          handleHeight: widget.handleHeight,
          drawShadow: widget.drawShadow,
          thumbImage: _thumbImage,
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
    this.thumbImage,
  });

  VideoPlayerValue value;
  ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  /// The value of the draggable progress bar.
  /// If null, the progress bar is not being dragged.
  final Duration? draggableValue;

  final ui.Image? thumbImage;

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
          Offset(0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4),
      ),
      colors.backgroundPaint,
    );
    if (!value.isInitialized) {
      return;
    }
    final playedPartPercent = (draggableValue != null
            ? draggableValue!.inMilliseconds
            : value.position.inMilliseconds) /
        value.duration.inMilliseconds;
    final playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final range in value.buffered) {
      final start = range.startFraction(value.duration) * size.width;
      final end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          const Radius.circular(4),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4),
      ),
      colors.playedPaint,
    );

    if (drawShadow) {
      final shadowPath = Path()
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

    // final paint = Paint();

    // final dst = Rect.fromLTWH(
    //   playedPart - 200 / 2,
    //   -110,
    //   200,
    //   100,
    // );

    // const borderRadius = 12.0;

    // final backgroundPaint = Paint()..color = Colors.black;

    // canvas.drawRect(dst, backgroundPaint);

    // final borderPaint = Paint()
    //   ..color = Colors.white
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 3;

    // final rRect = RRect.fromRectAndRadius(
    //   dst,
    //   const Radius.circular(
    //     borderRadius,
    //   ),
    // );

    // canvas
    //   ..drawRRect(rRect, borderPaint)
    //   ..clipRRect(rRect);

    // if (thumbImage != null) {
    //   final src = Rect.fromLTWH(
    //     0,
    //     0,
    //     thumbImage!.width.toDouble(),
    //     thumbImage!.height.toDouble(),
    //   );

    //   canvas.drawImageRect(thumbImage!, src, dst, paint);
    // }
  }
}

extension RelativePositionExtensions on BuildContext {
  Duration calcRelativePosition(
    Duration videoDuration,
    Offset globalPosition,
  ) {
    final box = findRenderObject()! as RenderBox;
    final tapPos = box.globalToLocal(globalPosition);
    final relative = (tapPos.dx / box.size.width).clamp(0, 1);
    final position = videoDuration * relative;
    return position;
  }
}
