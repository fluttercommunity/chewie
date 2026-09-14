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
    this.playback,
    super.key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    this.chapters = const [],
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

  /// The chapters of the video, sorted by ascending start time.
  ///
  /// When non-empty, the bar is painted as one segment per chapter and the
  /// pointed chapter's title is shown above the bar while hovering or
  /// scrubbing.
  final List<ChewieChapter> chapters;

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

  Offset? _hoverPosition;

  /// Latest pointer position over the bar, in global coordinates, used by the
  /// hover-time indicator.
  Offset? _latestHoverOffset;

  final LayerLink _indicatorLink = LayerLink();
  final OverlayPortalController _indicatorPortal = OverlayPortalController();

  ChewiePlaybackTarget get controller =>
      widget.playback ?? LocalPlaybackTarget(widget.controller);

  /// The pointer position that drives the hover-time indicator. A drag in
  /// progress takes priority over a plain hover; `null` when the pointer is
  /// away from the bar.
  Offset? get _indicatorOffset => _latestDraggableOffset ?? _latestHoverOffset;

  /// Shows or hides the overlay-based time indicator to match
  /// [_indicatorOffset]. Must be called from event handlers, not from build.
  ///
  /// Never shown when the bar has chapters: the chapter label already carries
  /// the pointed timecode.
  void _syncIndicatorVisibility() {
    final bool shouldShow =
        widget.chapters.isEmpty &&
        _indicatorOffset != null &&
        controller.value.isInitialized;
    if (shouldShow && !_indicatorPortal.isShowing) {
      _indicatorPortal.show();
    } else if (!shouldShow && _indicatorPortal.isShowing) {
      _indicatorPortal.hide();
    }
  }

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
        chapters: widget.chapters,
      ),
    );

    final interactive = widget.draggableProgressBar
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
              _syncIndicatorVisibility();
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
              _syncIndicatorVisibility();
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
                _syncIndicatorVisibility();
              },
              onExit: (PointerExitEvent event) {
                if (_latestHoverOffset == null) {
                  return;
                }
                setState(() => _latestHoverOffset = null);
                _syncIndicatorVisibility();
              },
              child: child,
            ),
          )
        : child;

    if (widget.chapters.isEmpty) {
      return OverlayPortal(
        controller: _indicatorPortal,
        overlayChildBuilder: _buildHoverTimeIndicator,
        child: CompositedTransformTarget(
          link: _indicatorLink,
          child: interactive,
        ),
      );
    }

    return MouseRegion(
      onHover: (event) => setState(() => _hoverPosition = event.localPosition),
      onExit: (_) => setState(() => _hoverPosition = null),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [interactive, ?_buildChapterLabel(constraints)],
          );
        },
      ),
    );
  }

  Widget? _buildChapterLabel(BoxConstraints constraints) {
    final value = controller.value;
    if (!value.isInitialized || value.duration <= Duration.zero) {
      return null;
    }

    double? pointedDx;
    if (_latestDraggableOffset != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        pointedDx = box.globalToLocal(_latestDraggableOffset!).dx;
      }
    } else if (_hoverPosition != null) {
      pointedDx = _hoverPosition!.dx;
    }
    if (pointedDx == null ||
        !constraints.maxWidth.isFinite ||
        constraints.maxWidth <= 0) {
      return null;
    }

    final clampedDx = pointedDx.clamp(0.0, constraints.maxWidth);
    final pointedPosition = value.duration * (clampedDx / constraints.maxWidth);

    ChewieChapter? pointedChapter;
    for (final chapter in widget.chapters) {
      if (chapter.start > pointedPosition) break;
      pointedChapter = chapter;
    }
    if (pointedChapter == null) {
      return null;
    }

    final stackHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : widget.barHeight * 2;

    return Positioned(
      left: clampedDx,
      bottom: stackHeight / 2 + widget.barHeight / 2 + widget.handleHeight + 4,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${pointedChapter.title} · ${formatDuration(pointedPosition)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  /// A floating pill that shows the timecode under the pointer while it hovers
  /// (or drags) the bar. Rendered through an [OverlayPortal] so ancestor clips
  /// (e.g. the rounded, blurred cupertino bottom bar) cannot cut it off; a
  /// [CompositedTransformFollower] keeps it glued to the bar. Renders nothing
  /// when the pointer is away, the video is not ready yet, or the bar hasn't
  /// been laid out.
  Widget _buildHoverTimeIndicator(BuildContext overlayContext) {
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

    final Size barSize = renderObject.size;
    final double relative =
        (renderObject.globalToLocal(offset).dx / barSize.width).clamp(0.0, 1.0);
    final String label = formatDuration(duration * relative);

    final double barTop = barSize.height / 2 - widget.barHeight / 2;

    return IgnorePointer(
      child: CompositedTransformFollower(
        link: _indicatorLink,
        showWhenUnlinked: false,
        offset: Offset(relative * barSize.width, barTop - 6.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: FractionalTranslation(
            // Center the pill on the pointer and place its bottom edge just
            // above the painted bar.
            translation: const Offset(-0.5, -1.0),
            child: _HoverTimeLabel(text: label),
          ),
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
    this.pendingSeekPosition,
    this.chapters = const [],
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

  /// The chapters of the video, sorted by ascending start time.
  ///
  /// When non-empty, the bar is painted as one segment per chapter.
  final List<ChewieChapter> chapters;

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
          chapters: chapters,
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
    this.chapters = const [],
  });

  VideoPlayerValue value;
  ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final List<ChewieChapter> chapters;

  /// The position to paint instead of [VideoPlayerValue.position]: either the
  /// one currently being dragged, or the one of a seek that is still in
  /// flight. If null, neither is happening and the reported position is used.
  final Duration? draggableValue;

  static const double _chapterGapWidth = 2.0;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  List<double> _chapterBoundaries(Size size) {
    final durationMs = value.duration.inMilliseconds;
    if (durationMs <= 0 || chapters.isEmpty) {
      return const [];
    }
    final boundaries = <double>[];
    for (final chapter in chapters) {
      final startMs = chapter.start.inMilliseconds;
      if (startMs <= 0 || startMs >= durationMs) continue;
      boundaries.add(startMs / durationMs * size.width);
    }
    return boundaries;
  }

  void _drawBar(
    Canvas canvas,
    double fromX,
    double toX,
    double baseOffset,
    Paint paint,
    List<double> boundaries,
  ) {
    if (toX <= fromX) return;
    var segmentStart = fromX;
    for (final boundary in boundaries) {
      if (boundary <= fromX || boundary >= toX) continue;
      final segmentEnd = boundary - _chapterGapWidth / 2;
      if (segmentEnd > segmentStart) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromPoints(
              Offset(segmentStart, baseOffset),
              Offset(segmentEnd, baseOffset + barHeight),
            ),
            const Radius.circular(4.0),
          ),
          paint,
        );
      }
      segmentStart = boundary + _chapterGapWidth / 2;
    }
    if (toX > segmentStart) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(segmentStart, baseOffset),
            Offset(toX, baseOffset + barHeight),
          ),
          const Radius.circular(4.0),
        ),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseOffset = size.height / 2 - barHeight / 2;
    final boundaries = _chapterBoundaries(size);

    _drawBar(
      canvas,
      0.0,
      size.width,
      baseOffset,
      colors.backgroundPaint,
      boundaries,
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
      _drawBar(
        canvas,
        start,
        end,
        baseOffset,
        colors.bufferedPaint,
        boundaries,
      );
    }
    _drawBar(
      canvas,
      0.0,
      playedPart,
      baseOffset,
      colors.playedPaint,
      boundaries,
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
