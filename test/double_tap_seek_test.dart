import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/seek_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const _src =
    'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

const _videoDuration = Duration(minutes: 1);

/// A minimal in-memory video player so the controller actually initializes
/// (60s duration) and seeks update a real position we can assert on.
class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _events = {};
  final Map<int, Duration> _positions = {};
  int _nextPlayerId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async => _create();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      _create();

  int _create() {
    final playerId = _nextPlayerId++;
    _events[playerId] = StreamController<VideoEvent>()
      ..add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: _videoDuration,
          size: const Size(640, 360),
        ),
      );
    _positions[playerId] = Duration.zero;
    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    // Do NOT close the stream controller here: the controller's event
    // subscription is already canceled by this point, so awaiting close()
    // would never complete.
    _events.remove(playerId);
    _positions.remove(playerId);
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _positions[playerId] = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async =>
      _positions[playerId] ?? Duration.zero;

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.shrink();
}

ChewieController _controller({
  bool allowDoubleTapSeek = true,
  Duration doubleTapSeekDuration = const Duration(seconds: 10),
  bool allowDoubleTapToggleFullScreen = true,
  bool showSeekIndicator = true,
  bool isLive = false,
  Widget? customControls,
}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(Uri.parse(_src)),
    autoPlay: false,
    autoInitialize: true,
    looping: false,
    isLive: isLive,
    allowDoubleTapSeek: allowDoubleTapSeek,
    doubleTapSeekDuration: doubleTapSeekDuration,
    allowDoubleTapToggleFullScreen: allowDoubleTapToggleFullScreen,
    showSeekIndicator: showSeekIndicator,
    customControls: customControls ?? const MaterialControls(),
  );
}

Future<void> _pumpPlayer(
  WidgetTester tester,
  ChewieController controller,
) async {
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Chewie(controller: controller)),
    ),
  );
  await tester.pump();
  // Let showControlsOnInitialize reveal the controls so the hit area is
  // no longer absorbed.
  await tester.pump(const Duration(milliseconds: 250));
}

SeekIndicator _indicator(WidgetTester tester) =>
    tester.widget<SeekIndicator>(find.byType(SeekIndicator));

Duration _position(ChewieController controller) =>
    controller.videoPlayerController.value.position;

/// A point at [widthFraction] across the controls, at vertical center —
/// clear of the center play/seek button cluster for fractions near 0 or 1.
Offset _at(WidgetTester tester, double widthFraction) {
  final rect = tester.getRect(find.byType(MaterialControls));
  return Offset(rect.left + rect.width * widthFraction, rect.center.dy);
}

/// Pauses playback so no position-polling timer is left pending at teardown.
Future<void> _stopPlayback(
  WidgetTester tester,
  ChewieController controller,
) async {
  await controller.videoPlayerController.pause();
  await tester.pump();
}

Future<void> _doubleTapAt(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tapAt(position);
  // Flush the tap trackers' internal countdown timers.
  await tester.pump(const Duration(milliseconds: 50));
}

/// A single tap that waits out the double-tap detection window so the
/// delayed `onTapUp` fires.
Future<void> _singleTapAt(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  setUp(() {
    VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();
  });

  group('double-tap seek zones (MaterialControls)', () {
    testWidgets('double-tapping the right zone seeks forward', (tester) async {
      final controller = _controller();
      await _pumpPlayer(tester, controller);

      await _doubleTapAt(tester, _at(tester, 0.9));

      expect(_position(controller), const Duration(seconds: 10));
      final indicator = _indicator(tester);
      expect(indicator.show, isTrue);
      expect(indicator.forward, isTrue);
      expect(indicator.seconds, 10);
    });

    testWidgets('double-tapping the left zone seeks backward and clamps to 0', (
      tester,
    ) async {
      final controller = _controller();
      await _pumpPlayer(tester, controller);

      await _doubleTapAt(tester, _at(tester, 0.1));

      expect(_position(controller), Duration.zero);
      final indicator = _indicator(tester);
      expect(indicator.show, isTrue);
      expect(indicator.forward, isFalse);
      expect(indicator.seconds, 10);
    });

    testWidgets('uses the configured doubleTapSeekDuration', (tester) async {
      final controller = _controller(
        doubleTapSeekDuration: const Duration(seconds: 5),
      );
      await _pumpPlayer(tester, controller);

      await _doubleTapAt(tester, _at(tester, 0.9));

      expect(_position(controller), const Duration(seconds: 5));
      expect(_indicator(tester).seconds, 5);
    });

    testWidgets('the center zone is dead', (tester) async {
      final controller = _controller();
      await _pumpPlayer(tester, controller);

      // Off vertical center to avoid the play button's own tap handler.
      final rect = tester.getRect(find.byType(MaterialControls));
      await _doubleTapAt(
        tester,
        Offset(rect.center.dx, rect.top + rect.height * 0.25),
      );

      expect(_position(controller), Duration.zero);
      expect(_indicator(tester).show, isFalse);
    });

    testWidgets('does not seek when allowDoubleTapSeek is false', (
      tester,
    ) async {
      final controller = _controller(allowDoubleTapSeek: false);
      await _pumpPlayer(tester, controller);

      await _doubleTapAt(tester, _at(tester, 0.9));
      // Without the double-tap recognizer these resolve as single taps; wait
      // out their tap handling.
      await tester.pump(const Duration(milliseconds: 350));

      expect(_position(controller), Duration.zero);
      expect(_indicator(tester).show, isFalse);
      // The taps fell through to play/pause; stop playback before teardown.
      await _stopPlayback(tester, controller);
    });

    testWidgets('does not seek on live streams', (tester) async {
      final controller = _controller(isLive: true);
      await _pumpPlayer(tester, controller);

      await _doubleTapAt(tester, _at(tester, 0.9));
      await tester.pump(const Duration(milliseconds: 350));

      expect(_position(controller), Duration.zero);
      expect(_indicator(tester).show, isFalse);
      await _stopPlayback(tester, controller);
    });
  });

  group('tap-to-repeat while the indicator is visible', () {
    testWidgets('a single tap in the same zone keeps seeking', (tester) async {
      final controller = _controller();
      await _pumpPlayer(tester, controller);

      await _doubleTapAt(tester, _at(tester, 0.9));
      expect(_indicator(tester).seconds, 10);

      await _singleTapAt(tester, _at(tester, 0.9));

      expect(_position(controller), const Duration(seconds: 20));
      final indicator = _indicator(tester);
      expect(indicator.show, isTrue);
      expect(indicator.forward, isTrue);
      expect(indicator.seconds, 20);
    });

    testWidgets('a single tap in the opposite zone does not repeat', (
      tester,
    ) async {
      final controller = _controller();
      await _pumpPlayer(tester, controller);

      await _doubleTapAt(tester, _at(tester, 0.9));
      expect(_indicator(tester).seconds, 10);

      await _singleTapAt(tester, _at(tester, 0.1));

      // The tap fell through to the regular hit-area handling instead.
      expect(_position(controller), const Duration(seconds: 10));
      expect(_indicator(tester).forward, isTrue);
      expect(_indicator(tester).seconds, 10);
      await _stopPlayback(tester, controller);
    });

    testWidgets('a single tap after the indicator fades does not seek', (
      tester,
    ) async {
      final controller = _controller();
      await _pumpPlayer(tester, controller);

      await _doubleTapAt(tester, _at(tester, 0.9));
      await tester.pump(const Duration(seconds: 1));
      expect(_indicator(tester).show, isFalse);

      await _singleTapAt(tester, _at(tester, 0.9));

      expect(_position(controller), const Duration(seconds: 10));
      expect(_indicator(tester).show, isFalse);
      await _stopPlayback(tester, controller);
    });
  });

  group('single tap without an active indicator', () {
    testWidgets('still reaches the regular hit-area handling', (tester) async {
      final controller = _controller();
      await _pumpPlayer(tester, controller);
      expect(find.byType(CenterPlayButton), findsOneWidget);

      await _singleTapAt(tester, _at(tester, 0.9));

      // No seek happened; the tap started playback as before.
      expect(_position(controller), Duration.zero);
      expect(_indicator(tester).show, isFalse);
      expect(controller.videoPlayerController.value.isPlaying, isTrue);

      await _stopPlayback(tester, controller);
    });
  });

  group('double-click fullscreen (MaterialDesktopControls)', () {
    testWidgets('toggles fullscreen when enabled', (tester) async {
      final controller = _controller(
        customControls: const MaterialDesktopControls(),
      );
      await _pumpPlayer(tester, controller);

      final rect = tester.getRect(find.byType(MaterialDesktopControls));
      // Off center to avoid the play button's own tap handler.
      await _doubleTapAt(
        tester,
        Offset(rect.center.dx, rect.top + rect.height * 0.25),
      );
      await tester.pumpAndSettle();

      expect(controller.isFullScreen, isTrue);
    });

    testWidgets('does nothing when allowDoubleTapToggleFullScreen is false', (
      tester,
    ) async {
      final controller = _controller(
        allowDoubleTapToggleFullScreen: false,
        customControls: const MaterialDesktopControls(),
      );
      await _pumpPlayer(tester, controller);

      final rect = tester.getRect(find.byType(MaterialDesktopControls));
      await _doubleTapAt(
        tester,
        Offset(rect.center.dx, rect.top + rect.height * 0.25),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.isFullScreen, isFalse);
    });
  });

  group('ChewieController options', () {
    test('allowDoubleTapSeek defaults to true and survives copyWith', () {
      final controller = ChewieController(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(_src),
        ),
      );
      expect(controller.allowDoubleTapSeek, isTrue);
      expect(
        controller.copyWith(allowDoubleTapSeek: false).allowDoubleTapSeek,
        isFalse,
      );
    });

    test('doubleTapSeekDuration defaults to 10s and survives copyWith', () {
      final controller = ChewieController(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(_src),
        ),
      );
      expect(controller.doubleTapSeekDuration, const Duration(seconds: 10));
      expect(
        controller
            .copyWith(doubleTapSeekDuration: const Duration(seconds: 30))
            .doubleTapSeekDuration,
        const Duration(seconds: 30),
      );
    });

    test(
      'allowDoubleTapToggleFullScreen defaults to true and survives copyWith',
      () {
        final controller = ChewieController(
          videoPlayerController: VideoPlayerController.networkUrl(
            Uri.parse(_src),
          ),
        );
        expect(controller.allowDoubleTapToggleFullScreen, isTrue);
        expect(
          controller
              .copyWith(allowDoubleTapToggleFullScreen: false)
              .allowDoubleTapToggleFullScreen,
          isFalse,
        );
      },
    );
  });
}
