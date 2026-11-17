import 'package:chewie/src/cast/chewie_cast_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Whatever Chewie's controls are currently driving: the local video player,
/// or a cast receiver.
///
/// The controls read [value] and call the transport methods without caring
/// which of the two is behind them, so a single set of skins serves both. It
/// is a [Listenable], and the active target is the one to listen to for
/// playback updates.
abstract class ChewiePlaybackTarget implements Listenable {
  /// Current playback state, in `video_player`'s shape whether it came from
  /// the local player or a receiver.
  VideoPlayerValue get value;

  /// True when this target is a cast receiver rather than the local player.
  bool get isRemote;

  Future<void> play();

  Future<void> pause();

  Future<void> seekTo(Duration position);

  Future<void> setVolume(double volume);

  Future<void> setPlaybackSpeed(double speed);
}

/// The local [VideoPlayerController] as a playback target.
class LocalPlaybackTarget implements ChewiePlaybackTarget {
  const LocalPlaybackTarget(this.controller);

  final VideoPlayerController controller;

  @override
  VideoPlayerValue get value => controller.value;

  @override
  bool get isRemote => false;

  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> seekTo(Duration position) => controller.seekTo(position);

  @override
  Future<void> setVolume(double volume) => controller.setVolume(volume);

  @override
  Future<void> setPlaybackSpeed(double speed) =>
      controller.setPlaybackSpeed(speed);

  // Two wrappers around the same player are the same target. Widgets compare
  // targets to decide whether to move their listeners, and they get a fresh
  // wrapper on every build.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaybackTarget && other.controller == controller);

  @override
  int get hashCode => controller.hashCode;
}

/// A [ChewieCastController] as a playback target, used while a session is live.
class CastPlaybackTarget implements ChewiePlaybackTarget {
  const CastPlaybackTarget(this.castController);

  final ChewieCastController castController;

  @override
  VideoPlayerValue get value => castController.value;

  @override
  bool get isRemote => true;

  @override
  void addListener(VoidCallback listener) =>
      castController.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      castController.removeListener(listener);

  @override
  Future<void> play() => castController.play();

  @override
  Future<void> pause() => castController.pause();

  @override
  Future<void> seekTo(Duration position) => castController.seekTo(position);

  @override
  Future<void> setVolume(double volume) => castController.setVolume(volume);

  @override
  Future<void> setPlaybackSpeed(double speed) =>
      castController.setPlaybackSpeed(speed);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CastPlaybackTarget && other.castController == castController);

  @override
  int get hashCode => castController.hashCode;
}
