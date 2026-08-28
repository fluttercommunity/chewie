import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A minimal in-memory [VideoPlayerPlatform] so tests can drive controllers
/// whose `initialize()` actually completes.
///
/// Without one, `VideoPlayerController.initialize()` never finishes under
/// `flutter test`, and anything that waits on it — such as
/// `ChewieController.swapVideoSource` — stalls forever.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  FakeVideoPlayerPlatform({this.duration = const Duration(minutes: 5)});

  /// Duration reported for every player created.
  final Duration duration;

  /// Sources containing this marker make [createWithOptions] throw, so tests
  /// can exercise initialization failures.
  static const String failingSource = 'fake-init-failure';

  final Map<int, StreamController<VideoEvent>> _events = {};
  final Map<int, Duration> _positions = {};
  final Map<int, bool> _playing = {};
  final Map<int, bool> _looping = {};
  final Map<int, double> _speeds = {};
  final Map<int, double> _volumes = {};

  /// Player ids that have been disposed, in dispose order.
  final List<int> disposedPlayerIds = [];

  /// Player id created for each data-source URI, most recent wins.
  final Map<String, int> playerIdsBySource = {};

  int _nextPlayerId = 1;

  /// Installs a fresh fake platform for the current test and returns it.
  static FakeVideoPlayerPlatform install() {
    final platform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
    return platform;
  }

  int playerIdFor(String source) => playerIdsBySource[source]!;
  bool isPlaying(int playerId) => _playing[playerId] ?? false;
  bool isLooping(int playerId) => _looping[playerId] ?? false;
  double speedOf(int playerId) => _speeds[playerId] ?? 1.0;
  double volumeOf(int playerId) => _volumes[playerId] ?? 1.0;
  Duration positionOf(int playerId) => _positions[playerId] ?? Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final source =
        options.dataSource.uri ?? options.dataSource.asset ?? 'unknown';
    if (source.contains(failingSource)) {
      throw StateError('FakeVideoPlayerPlatform refused source: $source');
    }
    final playerId = _nextPlayerId++;
    // Closed in dispose(), which the lint cannot see from here.
    // ignore: close_sinks
    _events[playerId] = StreamController<VideoEvent>.broadcast();
    _positions[playerId] = Duration.zero;
    playerIdsBySource[source] = playerId;
    return playerId;
  }

  @override
  Future<void> dispose(int playerId) async {
    disposedPlayerIds.add(playerId);
    await _events.remove(playerId)?.close();
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    // A plain broadcast stream, not an async* generator: cancelling a
    // generator's subscription never completes under the test framework's
    // fake async, which would stall VideoPlayerController.dispose().
    // The initialized event goes out in a microtask so the controller —
    // which listens synchronously after this call — is subscribed by then.
    scheduleMicrotask(() {
      _events[playerId]?.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: duration,
          size: const Size(1920, 1080),
        ),
      );
    });
    return _events[playerId]!.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    _looping[playerId] = looping;
  }

  @override
  Future<void> play(int playerId) async {
    _playing[playerId] = true;
  }

  @override
  Future<void> pause(int playerId) async {
    _playing[playerId] = false;
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    _volumes[playerId] = volume;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    _speeds[playerId] = speed;
  }

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
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleep,
  ) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.expand();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
}
