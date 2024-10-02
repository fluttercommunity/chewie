import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../chewie.dart';
import 'helpers/vtt_parser.dart';
import 'widgets/animations/player_animation.dart';

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

  Offset? _latestDraggableOffset;

  VideoPlayerController get controller => widget.controller;

  bool _showThumbnail = false;

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
    final position = _latestDraggableOffset != null
        ? context.calcRelativePosition(
            controller.value.duration,
            _latestDraggableOffset!,
          )
        : null;

    final thumbnail = position != null
        ? widget.thumbnails?.where(
            (element) {
              return element.startTime.inMilliseconds <=
                      position.inMilliseconds &&
                  element.endTime.inMilliseconds >= position.inMilliseconds;
            },
          ).firstOrNull
        : null;

    final thumbnailPlaceholder = position != null
        ? widget.thumbnailsPlaceholder?.where(
            (element) {
              return element.startTime.inMilliseconds <=
                      position.inMilliseconds &&
                  element.endTime.inMilliseconds >= position.inMilliseconds;
            },
          ).firstOrNull
        : null;

    final child = Center(
      child: StaticProgressBar(
        thumbnail: thumbnail,
        colors: widget.colors,
        value: controller.value,
        barHeight: widget.barHeight,
        drawShadow: widget.drawShadow,
        showThumbnail: _showThumbnail,
        handleHeight: widget.handleHeight,
        latestDraggableOffset: _latestDraggableOffset,
        thumbnailPlaceholder: thumbnailPlaceholder,
      ),
    );

    return widget.draggableProgressBar
        ? GestureDetector(
            onHorizontalDragStart: (DragStartDetails details) {
              if (!controller.value.isInitialized) {
                return;
              }

              widget.onDragStart?.call();

              _showThumbnail = true;
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
              if (_latestDraggableOffset != null) {
                _seekToRelativePosition(details.globalPosition);
              }

              widget.onDragEnd?.call();

              _showThumbnail = false;
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
    this.thumbnailPlaceholder,
    this.showThumbnail = false,
    this.thumbnail,
    super.key,
  });

  final Offset? latestDraggableOffset;
  final VideoPlayerValue value;
  final ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final bool showThumbnail;

  final WebVTTEntry? thumbnail;
  final WebVTTEntry? thumbnailPlaceholder;

  @override
  State<StaticProgressBar> createState() => _StaticProgressBarState();
}

class _StaticProgressBarState extends State<StaticProgressBar> {
  ui.Image? _thumbImage;

  bool _largeImageLoaded = false;

  final Dio _dio = Dio()
    ..interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(
          store: MemCacheStore(),
          maxStale: const Duration(hours: 1),
        ),
      ),
    );

  Future<void> _loadImage() async {
    if (widget.thumbnail == null) return;

    try {
      if (widget.thumbnailPlaceholder != null) {
        final networkImage = widget.thumbnailPlaceholder!.url;

        _largeImageLoaded = false;

        final imageBytes = await _fetchImageBytesWithCache(networkImage);

        ui.decodeImageFromList(Uint8List.fromList(imageBytes), (img) {
          setState(() {
            _thumbImage = img;
          });
        });
      }

      unawaited(
        Future.microtask(() async {
          final networkImage = widget.thumbnail!.url;

          final imageBytes = await _fetchImageBytesWithCache(networkImage);

          ui.decodeImageFromList(Uint8List.fromList(imageBytes), (img) {
            setState(() {
              _thumbImage = img;
              _largeImageLoaded = true;
            });
          });
        }),
      );
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
    super.didUpdateWidget(oldWidget);

    if (widget.thumbnail != null &&
        widget.thumbnail?.url != oldWidget.thumbnail?.url) {
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: PlayerAnimation(
              value: widget.showThumbnail && widget.thumbnail != null,
              child: CustomPaint(
                painter: _ProgressBarThumbPainter(
                  imageEntry: _largeImageLoaded
                      ? widget.thumbnail
                      : widget.thumbnailPlaceholder,
                  handleHeight: widget.handleHeight,
                  value: widget.value,
                  draggableValue: widget.latestDraggableOffset != null
                      ? context.calcRelativePosition(
                          widget.value.duration,
                          widget.latestDraggableOffset!,
                        )
                      : null,
                  thumbImage: _thumbImage,
                ),
              ),
            ),
          ),
          Positioned.fill(
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
                showThumbnail: widget.showThumbnail,
                handleHeight: widget.handleHeight,
                drawShadow: widget.drawShadow,
                thumbImage: _thumbImage,
              ),
            ),
          ),
        ],
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
    this.showThumbnail = false,
    this.thumbImage,
  });

  VideoPlayerValue value;
  ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final bool showThumbnail;
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
  }
}

class _ProgressBarThumbPainter extends CustomPainter {
  _ProgressBarThumbPainter({
    required this.value,
    required this.imageEntry,
    required this.handleHeight,
    required this.draggableValue,
    this.thumbImage,
  });

  VideoPlayerValue value;
  final Duration? draggableValue;
  final ui.Image? thumbImage;
  final double handleHeight;
  final WebVTTEntry? imageEntry;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = Paint();

    final playedPartPercent = (draggableValue != null
            ? draggableValue!.inMilliseconds
            : value.position.inMilliseconds) /
        value.duration.inMilliseconds;

    final playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;

    const halfWidth = 200 / 2;

    var offset = playedPart;

    if (playedPart >= size.width - halfWidth) {
      offset = size.width - halfWidth;
    } else if (playedPart <= halfWidth) {
      offset = halfWidth;
    }

    final dst = Rect.fromLTWH(
      offset - halfWidth,
      -110,
      200,
      100,
    );

    const borderRadius = 12.0;

    final backgroundPaint = Paint()..color = Colors.black;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rRect = RRect.fromRectAndRadius(
      dst,
      const Radius.circular(
        borderRadius,
      ),
    );

    if (thumbImage != null && imageEntry != null) {
      const triangleBase = 20.0;

      final firstLineOffset = playedPart - triangleBase / 2;
      final secondLineOffset = playedPart + triangleBase / 2;

      final path = Path()
        ..moveTo(playedPart, 0)
        ..lineTo(
          playedPart <= triangleBase / 2 ? 0 : firstLineOffset,
          -triangleBase,
        )
        ..lineTo(
          playedPart > size.width - (triangleBase / 2)
              ? size.width
              : secondLineOffset,
          -triangleBase,
        )
        ..close();

      final trianglePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, trianglePaint);

      final src = Rect.fromLTWH(
        0,
        0,
        imageEntry!.size.width,
        imageEntry!.size.height,
      );

      canvas
        ..drawRRect(rRect, borderPaint)
        ..clipRRect(rRect)
        ..drawRect(dst, backgroundPaint)
        ..drawImageRect(thumbImage!, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
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
