import 'package:chewie/chewie.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProgressBar extends StatefulWidget {
  VideoProgressBar(
    this.controller, {
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.draggableProgressBar = true,
    super.key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  }) : colors = colors ?? ChewieProgressColors();

  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final bool draggableProgressBar;

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
  Offset? _latestHoverOffset;

  VideoPlayerController get controller => widget.controller;

  /// The pointer position that drives the hover-time indicator. A drag in
  /// progress takes priority over a plain hover; `null` when the pointer is
  /// away from the bar.
  Offset? get _indicatorOffset => _latestDraggableOffset ?? _latestHoverOffset;

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
    controller.seekTo(
      context.calcRelativePosition(controller.value.duration, globalPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: StaticProgressBar(
        value: controller.value,
        colors: widget.colors,
        barHeight: widget.barHeight,
        handleHeight: widget.handleHeight,
        drawShadow: widget.drawShadow,
        latestDraggableOffset: _latestDraggableOffset,
      ),
    );

    if (!widget.draggableProgressBar) {
      return child;
    }

    return GestureDetector(
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (PointerHoverEvent event) {
          if (!controller.value.isInitialized) {
            return;
          }
          setState(() => _latestHoverOffset = event.position);
        },
        onExit: (PointerExitEvent event) {
          if (_latestHoverOffset == null) {
            return;
          }
          setState(() => _latestHoverOffset = null);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            _buildHoverTimeIndicator(context),
          ],
        ),
      ),
    );
  }

  /// A floating pill that shows the timecode under the pointer while it hovers
  /// (or drags) the bar. Renders nothing when the pointer is away, the video is
  /// not ready yet, or the bar hasn't been laid out — so touch devices, which
  /// never emit hover events, are unaffected.
  Widget _buildHoverTimeIndicator(BuildContext context) {
    final Offset? offset = _indicatorOffset;
    final Duration duration = controller.value.duration;
    if (offset == null ||
        !controller.value.isInitialized ||
        duration.inMilliseconds <= 0) {
      return const SizedBox.shrink();
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        renderObject.size.width <= 0) {
      return const SizedBox.shrink();
    }

    final double relative =
        (renderObject.globalToLocal(offset).dx / renderObject.size.width)
            .clamp(0.0, 1.0);
    final String label = formatDuration(duration * relative);

    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;
            if (!width.isFinite || !height.isFinite) {
              return const SizedBox.shrink();
            }
            final double barTop = height / 2 - widget.barHeight / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: (relative * width).clamp(0.0, width),
                  bottom: height - barTop + 6.0,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0.0),
                    child: _HoverTimeLabel(text: label),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A small dark pill with a downward caret, showing the hovered timecode above
/// the progress bar.
class _HoverTimeLabel extends StatelessWidget {
  const _HoverTimeLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10.0, 5.0),
          painter: _CaretPainter(color: Colors.black.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

/// Draws the downward-pointing caret beneath [_HoverTimeLabel].
class _CaretPainter extends CustomPainter {
  _CaretPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => oldDelegate.color != color;
}

class StaticProgressBar extends StatelessWidget {
  const StaticProgressBar({
    super.key,
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    this.latestDraggableOffset,
  });

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
          draggableValue: latestDraggableOffset != null
              ? context.calcRelativePosition(
                  value.duration,
                  latestDraggableOffset!,
                )
              : null,
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

  /// The value of the draggable progress bar.
  /// If null, the progress bar is not being dragged.
  final Duration? draggableValue;

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
    final double playedPartPercent =
        (draggableValue != null
            ? draggableValue!.inMilliseconds
            : value.position.inMilliseconds) /
        value.duration.inMilliseconds;
    final double playedPart = playedPartPercent > 1
        ? size.width
        : playedPartPercent * size.width;
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
  Duration calcRelativePosition(Duration videoDuration, Offset globalPosition) {
    final box = findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = (tapPos.dx / box.size.width).clamp(0, 1);
    final Duration position = videoDuration * relative;
    return position;
  }
}
