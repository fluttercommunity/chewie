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
    this.draggableProgressBar = true,
    this.playback,
    super.key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  }) : colors = colors ?? ChewieProgressColors();

  final VideoPlayerController controller;

  /// What the bar should read and seek — the local player, or a cast receiver
  /// while a session is live.
  ///
  /// Defaults to [controller], which keeps the bar behaving exactly as it did
  /// before casting existed for anyone constructing it directly.
  final ChewiePlaybackTarget? playback;

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

  /// The position the controller has been asked to seek to, kept around until
  /// the seek actually completes.
  ///
  /// [VideoPlayerController.seekTo] only updates
  /// [VideoPlayerValue.position] once the platform is done seeking, which can
  /// take a noticeable amount of time (especially on iOS, where an exact seek
  /// has to wait for `AVPlayer` to decode the target frame). Painting the
  /// requested position in the meantime keeps the handle where the user
  /// dropped it instead of letting it snap back to the stale position for a
  /// few frames.
  Duration? _pendingSeekPosition;

  /// Identifies the latest seek request so a stale one cannot clear the
  /// position requested by a newer one.
  int _latestSeekRequestId = 0;

  ChewiePlaybackTarget get controller =>
      widget.playback ?? LocalPlaybackTarget(widget.controller);

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void didUpdateWidget(VideoProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Playback moves between the local player and a receiver mid-life; follow
    // it, or the bar freezes on whichever one it first subscribed to.
    final previous =
        oldWidget.playback ?? LocalPlaybackTarget(oldWidget.controller);
    final current = controller;
    if (previous != current) {
      previous.removeListener(listener);
      current.addListener(listener);
    }
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  Future<void> _seekToRelativePosition(Offset globalPosition) {
    return _seekTo(
      context.calcRelativePosition(controller.value.duration, globalPosition),
    );
  }

  Future<void> _seekTo(Duration position) async {
    final int requestId = ++_latestSeekRequestId;

    setState(() {
      _pendingSeekPosition = position;
      _latestDraggableOffset = null;
    });

    try {
      await controller.seekTo(position);
    } finally {
      // A newer seek is already driving the handle, leave it alone.
      if (mounted && requestId == _latestSeekRequestId) {
        setState(() {
          _pendingSeekPosition = null;
        });
      }
    }
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
        pendingSeekPosition: _pendingSeekPosition,
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
            onHorizontalDragEnd: (DragEndDetails details) async {
              widget.onDragEnd?.call();

              final Offset? dragOffset = _latestDraggableOffset;
              if (dragOffset != null) {
                // Resume playback only once the seek landed, otherwise the
                // player briefly plays from the position it was left at.
                await _seekToRelativePosition(dragOffset);
              }

              if (_controllerWasPlaying) {
                controller.play();
              }
            },
            onTapDown: (TapDownDetails details) {
              if (!controller.value.isInitialized) {
                return;
              }
              _seekToRelativePosition(details.globalPosition);
            },
            child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
          )
        : child;
  }
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
    this.pendingSeekPosition,
  });

  final Offset? latestDraggableOffset;

  /// Position of a seek that has been requested but has not been reported by
  /// the controller yet. Painted while it is set, so the handle does not fall
  /// back to the stale [VideoPlayerValue.position] mid-seek.
  final Duration? pendingSeekPosition;
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
              : pendingSeekPosition,
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

  /// The position to paint instead of [VideoPlayerValue.position]: either the
  /// one currently being dragged, or the one of a seek that is still in
  /// flight. If null, neither is happening and the reported position is used.
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
    // A source can report itself initialized before it knows how long it is —
    // a cast receiver does exactly this between accepting the media and
    // reporting on it. Dividing by that zero produces a NaN that asserts its
    // way out of drawRRect, so draw only the empty track until a duration
    // arrives.
    if (value.duration.inMilliseconds <= 0) {
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
