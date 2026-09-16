import 'dart:async';

import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const Duration _videoDuration = Duration(minutes: 1);

/// A platform implementation whose seeks only complete when the test says so,
/// which is what makes the seek latency of a real platform (notably iOS)
/// observable.
class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  // Single-subscription so the initialized event is buffered until
  // `initialize()` gets around to listening.
  final StreamController<VideoEvent> _events = StreamController<VideoEvent>();

  final List<Completer<void>> pendingSeeks = <Completer<void>>[];
  final List<String> calls = <String>[];

  Duration position = Duration.zero;

  void completePendingSeeks() {
    for (final Completer<void> seek in pendingSeeks) {
      if (!seek.isCompleted) {
        seek.complete();
      }
    }
    pendingSeeks.clear();
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    _events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: _videoDuration,
        size: const Size(640, 360),
      ),
    );
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events.stream;

  @override
  Future<void> seekTo(int playerId, Duration position) {
    calls.add('seekTo');
    final Completer<void> completer = Completer<void>();
    pendingSeeks.add(completer);
    return completer.future.then((_) => this.position = position);
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool prevent,
  ) async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.shrink();
}

/// Returns a controller backed by the fake platform.
///
/// It is deliberately not disposed: `dispose()` awaits a subscription
/// cancellation that never resolves under the fake async of `testWidgets`, and
/// the controllers do not outlive the test anyway.
Future<VideoPlayerController> _initializedController() async {
  final VideoPlayerController controller = VideoPlayerController.networkUrl(
    Uri.parse('https://example.com/video.mp4'),
  );
  await controller.initialize();
  return controller;
}

StaticProgressBar _progressBar(WidgetTester tester) =>
    tester.widget<StaticProgressBar>(find.byType(StaticProgressBar));

/// Drags from [from] to [to] without lifting the finger.
///
/// The move that makes the recognizer win the arena does not report an update
/// on its own, hence the extra step past the touch slop first.
Future<TestGesture> _dragTo(
  WidgetTester tester, {
  required Offset from,
  required Offset to,
}) async {
  final TestGesture gesture = await tester.startGesture(from);
  await gesture.moveBy(const Offset(kDragSlopDefault, 0));
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  return gesture;
}

void main() {
  late _FakeVideoPlayerPlatform platform;

  setUp(() {
    platform = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  Future<void> pumpProgressBar(
    WidgetTester tester,
    VideoPlayerController controller,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoProgressBar(
            controller,
            barHeight: 5,
            handleHeight: 6,
            drawShadow: false,
          ),
        ),
      ),
    );
  }

  testWidgets('keeps the dropped position painted until the seek completes', (
    WidgetTester tester,
  ) async {
    final VideoPlayerController controller = await _initializedController();

    await pumpProgressBar(tester, controller);

    // The bar spans the whole test surface (800px), so dropping at 75% of it
    // targets 45s of the 60s video.
    final Size surface =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    final double dropX = surface.width * 0.75;

    final TestGesture gesture = await _dragTo(
      tester,
      from: Offset(surface.width * 0.1, surface.height / 2),
      to: Offset(dropX, surface.height / 2),
    );

    expect(_progressBar(tester).latestDraggableOffset, isNotNull);

    await gesture.up();
    await tester.pump();

    // The platform has not acknowledged the seek yet, so the controller still
    // reports the old position...
    expect(platform.pendingSeeks, hasLength(1));
    expect(controller.value.position, Duration.zero);

    // ...but the bar must keep painting where the handle was dropped instead of
    // snapping back to it.
    expect(_progressBar(tester).latestDraggableOffset, isNull);
    expect(
      _progressBar(tester).pendingSeekPosition,
      const Duration(seconds: 45),
    );

    platform.completePendingSeeks();
    await tester.pump();
    await tester.pump();

    expect(controller.value.position, const Duration(seconds: 45));
    expect(_progressBar(tester).pendingSeekPosition, isNull);
  });

  testWidgets('resumes playback only once the seek has landed', (
    WidgetTester tester,
  ) async {
    final VideoPlayerController controller = await _initializedController();

    await controller.play();
    await pumpProgressBar(tester, controller);
    platform.calls.clear();

    final Size surface =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    final TestGesture gesture = await _dragTo(
      tester,
      from: Offset(surface.width * 0.1, surface.height / 2),
      to: Offset(surface.width * 0.75, surface.height / 2),
    );
    await gesture.up();
    await tester.pump();

    // Playing before the seek lands would play back from the old position.
    expect(platform.calls, <String>['pause', 'seekTo']);

    platform.completePendingSeeks();
    await tester.pump();
    await tester.pump();

    expect(platform.calls, <String>['pause', 'seekTo', 'play']);

    // Stop the position polling the controller starts when playing, so no
    // timer outlives the test.
    await controller.pause();
  });

  testWidgets('a tap paints the tapped position while the seek is in flight', (
    WidgetTester tester,
  ) async {
    final VideoPlayerController controller = await _initializedController();

    await pumpProgressBar(tester, controller);

    final Size surface =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(surface.width / 2, surface.height / 2));
    await tester.pump();

    expect(platform.pendingSeeks, hasLength(1));
    expect(controller.value.position, Duration.zero);
    expect(
      _progressBar(tester).pendingSeekPosition,
      const Duration(seconds: 30),
    );

    platform.completePendingSeeks();
    await tester.pump();
    await tester.pump();

    expect(_progressBar(tester).pendingSeekPosition, isNull);
  });

  testWidgets('a stale seek does not clear the position of a newer one', (
    WidgetTester tester,
  ) async {
    final VideoPlayerController controller = await _initializedController();

    await pumpProgressBar(tester, controller);

    final Size surface =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(surface.width * 0.25, surface.height / 2));
    await tester.pump();
    final Completer<void> firstSeek = platform.pendingSeeks.first;

    await tester.tapAt(Offset(surface.width * 0.75, surface.height / 2));
    await tester.pump();
    expect(platform.pendingSeeks, hasLength(2));

    // The first seek lands late, after a newer one was requested.
    firstSeek.complete();
    await tester.pump();
    await tester.pump();

    expect(
      _progressBar(tester).pendingSeekPosition,
      const Duration(seconds: 45),
    );

    platform.completePendingSeeks();
    await tester.pump();
    await tester.pump();

    expect(_progressBar(tester).pendingSeekPosition, isNull);
  });
}
