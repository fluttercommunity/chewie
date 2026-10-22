import 'package:chewie/src/cast/cast_connection_state.dart';
import 'package:chewie/src/cast/cast_device.dart';
import 'package:chewie/src/cast/cast_media.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// The seam between Chewie and whatever actually talks to a cast receiver.
///
/// Chewie ships the UI and the local/remote handover; it deliberately ships no
/// sender implementation, so that a pure-Flutter video player package does not
/// drag the Google Cast SDK — and its native, mobile-only, permission-hungry
/// dependencies — into every app that just wants play controls.
///
/// Implement this against the sender of your choice (the Cast SDK bindings, a
/// pure-Dart CASTv2 sender, AirPlay, DLNA — Chewie does not care which), then
/// hand the instance to `ChewieController.castController`.
///
/// The contract, in short:
///
/// * Call [notifyListeners] whenever [devices], [connectionState],
///   [connectedDevice], [value] or [errorDescription] change. Chewie drives
///   every visible piece of cast UI off those notifications.
/// * [connectionState] is the single source of truth for whether Chewie is
///   casting. Moving it to [CastConnectionState.connected] is what triggers the
///   handover: Chewie pauses the local player and calls [load] with the
///   position it left off at. Moving it back to
///   [CastConnectionState.disconnected] hands playback back, seeking the local
///   player to wherever the receiver got to.
/// * You own this object's lifetime. Chewie listens to it but never disposes
///   it, so one controller can outlive many [ChewieController]s and survive
///   navigation between videos.
abstract class ChewieCastController extends ChangeNotifier {
  /// Receivers currently known to be on the network.
  ///
  /// May be empty while discovery is still running — the picker shows a
  /// searching state rather than "none found" as long as [isDiscovering] is
  /// true.
  List<CastDevice> get devices;

  /// Whether a scan for receivers is in progress.
  bool get isDiscovering;

  /// Where the session currently is. See [CastConnectionState].
  CastConnectionState get connectionState;

  /// The receiver being cast to, or null when there is no session.
  ///
  /// Should be non-null from [CastConnectionState.connecting] onwards so the
  /// UI can name the device it is connecting to.
  CastDevice? get connectedDevice;

  /// The last error from the backend, e.g. a failed connect or a receiver that
  /// refused the media. Cleared on the next successful operation.
  String? get errorDescription;

  /// Playback state of the *receiver*, in the same shape the local player
  /// reports so Chewie's controls, progress bar and time labels render a
  /// remote session exactly as they render a local one.
  ///
  /// Only a handful of fields are read: `duration`, `position`, `buffered`,
  /// `isPlaying`, `isBuffering`, `isInitialized`, `volume`, `playbackSpeed`
  /// and `errorDescription`. Everything else can be left at its default —
  /// there is no texture behind a cast session, so `size` in particular is
  /// meaningless here.
  ///
  /// Before any media is loaded, return `VideoPlayerValue.uninitialized()`.
  VideoPlayerValue get value;

  /// The media the receiver currently holds, when the backend can say.
  ///
  /// Chewie uses this to avoid reloading media a receiver is already playing.
  /// Without it, rebuilding a [ChewieController] mid-session — which apps do
  /// routinely, via `copyWith` or when switching video — issues a fresh `load`
  /// and restarts playback on the TV for no reason.
  ///
  /// Returning null, the default, means "cannot say", and Chewie loads.
  CastMedia? get currentMedia => null;

  /// Whether a session is live. Convenience over [connectionState].
  bool get isConnected => connectionState.isConnected;

  /// Start scanning for receivers.
  ///
  /// Chewie calls this when the user opens the device picker. Implementations
  /// that discover continuously in the background can make it a no-op.
  Future<void> startDiscovery();

  /// Stop scanning. Chewie calls this when the picker closes, so discovery
  /// does not keep the radio busy for the life of the app.
  Future<void> stopDiscovery();

  /// Open a session with [device].
  ///
  /// Move [connectionState] to [CastConnectionState.connecting] immediately and
  /// to [CastConnectionState.connected] once the receiver is ready for media —
  /// Chewie calls [load] off the back of that transition, so connecting early
  /// means loading before the receiver can accept it.
  Future<void> connect(CastDevice device);

  /// Tear the session down and return playback to the device.
  Future<void> disconnect();

  /// Play [media] on the receiver, starting at [startAt].
  ///
  /// Called by Chewie on connect and whenever the media changes mid-session.
  /// [autoPlay] mirrors whether the local player was playing at handover, so
  /// casting a paused video leaves it paused on the TV.
  Future<void> load(
    CastMedia media, {
    Duration startAt = Duration.zero,
    bool autoPlay = true,
  });

  /// Resume the receiver.
  Future<void> play();

  /// Pause the receiver.
  Future<void> pause();

  /// Seek the receiver to [position].
  Future<void> seekTo(Duration position);

  /// Set the receiver's volume, 0.0 to 1.0.
  Future<void> setVolume(double volume);

  /// Set the receiver's playback speed.
  ///
  /// Not every receiver supports this. The default implementation does
  /// nothing, which leaves Chewie's speed menu inert rather than broken while
  /// casting.
  Future<void> setPlaybackSpeed(double speed) async {}
}
