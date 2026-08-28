import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'fake_video_player_platform.dart';

const String _srcA = 'https://example.com/video-a.mp4';
const String _srcB = 'https://example.com/video-b.mp4';
const String _srcBad =
    'https://example.com/${FakeVideoPlayerPlatform.failingSource}.mp4';

VideoPlayerController _network(String src) =>
    VideoPlayerController.networkUrl(Uri.parse(src));

/// Drives one frame outside of pumpWidget, so post-frame callbacks — like the
/// deferred disposal in [ChewieController.swapVideoSource] — get to run.
Future<void> _driveFrame() async {
  final binding = TestWidgetsFlutterBinding.instance;
  binding.handleBeginFrame(Duration.zero);
  binding.handleDrawFrame();
  await Future<void>.delayed(Duration.zero);
}

class _PopCountingObserver extends NavigatorObserver {
  int pops = 0;
  int pushes = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVideoPlayerPlatform platform;

  setUp(() {
    platform = FakeVideoPlayerPlatform.install();
  });

  // Controller-level tests use test(), not testWidgets(): under fake async,
  // VideoPlayerController.dispose() stalls on its event-subscription cleanup
  // and can never be awaited to completion.
  group('ChewieController.swapVideoSource', () {
    test(
      'initializes the new controller and preserves playback state',
      () async {
        final oldVpc = _network(_srcA);
        await oldVpc.initialize();
        final chewieController = ChewieController(
          videoPlayerController: oldVpc,
          looping: true,
        );
        await oldVpc.seekTo(const Duration(seconds: 42));
        await oldVpc.setPlaybackSpeed(1.5);
        await oldVpc.setVolume(0.5);
        await oldVpc.play();

        final newVpc = _network(_srcB);
        await chewieController.swapVideoSource(newVpc);

        expect(chewieController.videoPlayerController, same(newVpc));
        expect(newVpc.value.isInitialized, isTrue);
        expect(newVpc.value.position, const Duration(seconds: 42));
        expect(newVpc.value.playbackSpeed, 1.5);
        expect(newVpc.value.volume, 0.5);
        expect(newVpc.value.isPlaying, isTrue);
        expect(platform.isLooping(platform.playerIdFor(_srcB)), isTrue);

        await _driveFrame();
        await newVpc.dispose();
        chewieController.dispose();
      },
    );

    test('notifies listeners exactly once', () async {
      final oldVpc = _network(_srcA);
      await oldVpc.initialize();
      final chewieController = ChewieController(videoPlayerController: oldVpc);
      var notified = 0;
      chewieController.addListener(() => notified++);

      final newVpc = _network(_srcB);
      await chewieController.swapVideoSource(newVpc);

      expect(notified, 1);

      await _driveFrame();
      await newVpc.dispose();
      chewieController.dispose();
    });

    test('disposes the old controller after the next frame', () async {
      final oldVpc = _network(_srcA);
      await oldVpc.initialize();
      final oldPlayerId = platform.playerIdFor(_srcA);
      final chewieController = ChewieController(videoPlayerController: oldVpc);

      final newVpc = _network(_srcB);
      await chewieController.swapVideoSource(newVpc);
      expect(platform.disposedPlayerIds, isEmpty);

      await _driveFrame();
      expect(platform.disposedPlayerIds, [oldPlayerId]);

      await newVpc.dispose();
      chewieController.dispose();
    });

    test('keeps the old controller with disposeOldController: false', () async {
      final oldVpc = _network(_srcA);
      await oldVpc.initialize();
      final chewieController = ChewieController(videoPlayerController: oldVpc);

      final newVpc = _network(_srcB);
      await chewieController.swapVideoSource(
        newVpc,
        disposeOldController: false,
      );
      await _driveFrame();

      expect(platform.disposedPlayerIds, isEmpty);

      await oldVpc.dispose();
      await newVpc.dispose();
      chewieController.dispose();
    });

    test(
      'rethrows on initialization failure and keeps the old source',
      () async {
        final oldVpc = _network(_srcA);
        await oldVpc.initialize();
        final chewieController = ChewieController(
          videoPlayerController: oldVpc,
        );
        var notified = 0;
        chewieController.addListener(() => notified++);

        // Not disposed at the end: a controller whose platform create() threw
        // cannot complete dispose(), and it holds no timers or platform state.
        final badVpc = _network(_srcBad);
        await expectLater(
          chewieController.swapVideoSource(badVpc),
          throwsStateError,
        );

        expect(chewieController.videoPlayerController, same(oldVpc));
        expect(notified, 0);
        await _driveFrame();
        expect(platform.disposedPlayerIds, isEmpty);

        await oldVpc.dispose();
        chewieController.dispose();
      },
    );
  });

  // Widget tests run under fake async, where awaiting
  // VideoPlayerController.dispose() never completes — cleanup disposals are
  // fire-and-forget there (they still cancel their timers).
  group('swapVideoSource widget integration', () {
    testWidgets('re-attaches the video widget and controls after a swap', (
      tester,
    ) async {
      final oldVpc = _network(_srcA);
      await oldVpc.initialize();
      final chewieController = ChewieController(videoPlayerController: oldVpc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Chewie(controller: chewieController)),
        ),
      );
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(oldVpc),
      );

      final newVpc = _network(_srcB);
      await chewieController.swapVideoSource(newVpc);
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(newVpc),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      unawaited(newVpc.dispose());
      await tester.pump();
      chewieController.dispose();
    });

    testWidgets('does not pop the fullscreen route (#618)', (tester) async {
      final oldVpc = _network(_srcA);
      await oldVpc.initialize();
      final chewieController = ChewieController(videoPlayerController: oldVpc);
      final observer = _PopCountingObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(body: Chewie(controller: chewieController)),
        ),
      );

      chewieController.enterFullScreen();
      await tester.pumpAndSettle();
      expect(chewieController.isFullScreen, isTrue);

      final newVpc = _network(_srcB);
      await chewieController.swapVideoSource(newVpc);
      await tester.pumpAndSettle();

      expect(chewieController.isFullScreen, isTrue);
      expect(observer.pops, 0);

      chewieController.exitFullScreen();
      await tester.pumpAndSettle();
      expect(observer.pops, 1);

      await tester.pumpWidget(const SizedBox());
      unawaited(newVpc.dispose());
      await tester.pump();
      chewieController.dispose();
    });

    testWidgets(
      're-targets its listener when rebuilt with a different controller',
      (tester) async {
        final vpcA = _network(_srcA);
        await vpcA.initialize();
        final vpcB = _network(_srcB);
        await vpcB.initialize();
        final controllerA = ChewieController(videoPlayerController: vpcA);
        final controllerB = ChewieController(videoPlayerController: vpcB);
        final observer = _PopCountingObserver();

        Widget app(ChewieController controller) => MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(body: Chewie(controller: controller)),
        );

        await tester.pumpWidget(app(controllerA));
        await tester.pumpWidget(app(controllerB));
        final pushesAfterMount = observer.pushes;

        // The old controller no longer drives this Chewie.
        controllerA.enterFullScreen();
        await tester.pumpAndSettle();
        expect(observer.pushes, pushesAfterMount);

        // The new one does.
        controllerB.enterFullScreen();
        await tester.pumpAndSettle();
        expect(observer.pushes, pushesAfterMount + 1);

        controllerB.exitFullScreen();
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox());
        unawaited(vpcA.dispose());
        unawaited(vpcB.dispose());
        await tester.pump();
        controllerA.dispose();
        controllerB.dispose();
      },
    );
  });
}
