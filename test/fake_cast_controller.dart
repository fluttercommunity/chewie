import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

/// An in-memory [ChewieCastController] for tests and for the example app.
///
/// Records what Chewie asked it to do so tests can assert on the handover, and
/// exposes the state transitions directly so a test can drive a session
/// without a receiver on the network.
class FakeCastController extends ChewieCastController {
  FakeCastController({List<CastDevice> devices = const []})
    : _devices = List.of(devices);

  final List<CastDevice> _devices;

  CastConnectionState _connectionState = CastConnectionState.disconnected;
  CastDevice? _connectedDevice;
  bool _isDiscovering = false;
  String? _errorDescription;
  VideoPlayerValue _value = const VideoPlayerValue.uninitialized();

  /// Every [load] Chewie issued, in order.
  final List<({CastMedia media, Duration startAt, bool autoPlay})> loadCalls =
      [];

  /// Transport calls Chewie routed to the receiver, e.g. `play`, `seekTo`.
  final List<String> transportCalls = [];

  int startDiscoveryCount = 0;
  int stopDiscoveryCount = 0;

  @override
  List<CastDevice> get devices => List.unmodifiable(_devices);

  @override
  bool get isDiscovering => _isDiscovering;

  @override
  CastConnectionState get connectionState => _connectionState;

  @override
  CastDevice? get connectedDevice => _connectedDevice;

  @override
  String? get errorDescription => _errorDescription;

  @override
  VideoPlayerValue get value => _value;

  /// Reports the receiver as buffering, the way it does while it fetches.
  void reportBuffering({bool buffering = true}) {
    _value = _value.copyWith(isBuffering: buffering);
    notifyListeners();
  }

  @override
  CastMedia? get currentMedia => _currentMedia;

  CastMedia? _currentMedia;

  @override
  Future<void> startDiscovery() async {
    startDiscoveryCount++;
    _isDiscovering = true;
    notifyListeners();
  }

  @override
  Future<void> stopDiscovery() async {
    stopDiscoveryCount++;
    _isDiscovering = false;
    notifyListeners();
  }

  @override
  Future<void> connect(CastDevice device) async {
    _connectedDevice = device;
    _connectionState = CastConnectionState.connecting;
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    _connectionState = CastConnectionState.disconnecting;
    notifyListeners();
    _connectionState = CastConnectionState.disconnected;
    _connectedDevice = null;
    _currentMedia = null;
    notifyListeners();
  }

  @override
  Future<void> load(
    CastMedia media, {
    Duration startAt = Duration.zero,
    bool autoPlay = true,
  }) async {
    loadCalls.add((media: media, startAt: startAt, autoPlay: autoPlay));
    _currentMedia = media;
    _value = _value.copyWith(
      isInitialized: true,
      position: startAt,
      isPlaying: autoPlay,
    );
    notifyListeners();
  }

  @override
  Future<void> play() async {
    transportCalls.add('play');
    _value = _value.copyWith(isPlaying: true);
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    transportCalls.add('pause');
    _value = _value.copyWith(isPlaying: false);
    notifyListeners();
  }

  @override
  Future<void> seekTo(Duration position) async {
    transportCalls.add('seekTo:${position.inMilliseconds}');
    _value = _value.copyWith(position: position);
    notifyListeners();
  }

  @override
  Future<void> setVolume(double volume) async {
    transportCalls.add('setVolume:$volume');
    _value = _value.copyWith(volume: volume);
    notifyListeners();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    transportCalls.add('setPlaybackSpeed:$speed');
    _value = _value.copyWith(playbackSpeed: speed);
    notifyListeners();
  }

  // -- test hooks ------------------------------------------------------------

  /// Whether anything is still subscribed. Chewie should unsubscribe on
  /// dispose without disposing this controller, which the app owns.
  bool get hasAnyListeners => hasListeners;

  /// Completes a session the way a real backend would once the receiver is
  /// ready, which is what triggers Chewie's handover.
  void completeConnection() {
    _connectionState = CastConnectionState.connected;
    notifyListeners();
  }

  /// Adds a device mid-scan.
  void addDevice(CastDevice device) {
    _devices.add(device);
    notifyListeners();
  }

  /// Moves the receiver on, as playback progressing on the TV would.
  void emitRemoteValue(VideoPlayerValue value) {
    _value = value;
    notifyListeners();
  }

  void emitError(String message) {
    _errorDescription = message;
    notifyListeners();
  }
}
