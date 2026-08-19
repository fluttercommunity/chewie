import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A minimal in-memory video platform so widget tests get a local player that
/// actually initializes.
///
/// Without one, `VideoPlayerController.initialize()` never completes under
/// `flutter test`, and anything that waits on the local player — such as
/// picking playback back up after a cast session ends — silently stalls.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  FakeVideoPlayerPlatform({this.duration = const Duration(minutes: 5)});

  /// Duration reported for every player created.
  final Duration duration;

  final Map<int, StreamController<VideoEvent>> _events = {};
  final Map<int, Duration> _positions = {};

  int _nextPlayerId = 1;

  /// Installs this platform for the current test.
  static FakeVideoPlayerPlatform install({
    Duration duration = const Duration(minutes: 5),
  }) {
    final platform = FakeVideoPlayerPlatform(duration: duration);
    VideoPlayerPlatform.instance = platform;
    return platform;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {
    await _events.remove(playerId)?.close();
    _positions.remove(playerId);
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final playerId = _nextPlayerId++;
    // Closed in dispose(), which the lint cannot see from here.
    // ignore: close_sinks
    _events[playerId] = StreamController<VideoEvent>.broadcast();
    _positions[playerId] = Duration.zero;

    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) async* {
    // Emitted on subscription rather than pushed from createWithOptions: the
    // controller only subscribes after create returns, so anything sent before
    // that lands on an empty broadcast stream and initialize() hangs forever.
    yield VideoEvent(
      eventType: VideoEventType.initialized,
      duration: duration,
      size: const Size(1920, 1080),
    );

    final events = _events[playerId]?.stream;
    if (events != null) {
      yield* events;
    }
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
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setWebOptions(
    int playerId,
    VideoPlayerWebOptions options,
  ) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
}
