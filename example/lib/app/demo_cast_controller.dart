import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

/// A simulated cast backend, so the example demonstrates the casting UI
/// end-to-end without pulling the Google Cast SDK into a demo app.
///
/// It fakes discovery, a connection delay and a receiver whose position ticks
/// forward on its own. Swap it for a real [ChewieCastController] — one backed
/// by the Cast SDK, a Dart CASTv2 sender, or anything else — and nothing else
/// in the app has to change.
class DemoCastController extends ChewieCastController {
  static const _fakeDevices = [
    CastDevice(
      id: 'living-room',
      name: 'Living Room TV',
      modelName: 'Chromecast Ultra',
    ),
    CastDevice(id: 'kitchen', name: 'Kitchen Display', modelName: 'Nest Hub'),
  ];

  final List<CastDevice> _devices = [];

  CastConnectionState _connectionState = CastConnectionState.disconnected;
  CastDevice? _connectedDevice;
  bool _isDiscovering = false;
  String? _errorDescription;
  VideoPlayerValue _value = const VideoPlayerValue.uninitialized();

  Timer? _discoveryTimer;
  Timer? _connectTimer;
  Timer? _tickTimer;

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

  @override
  Future<void> startDiscovery() async {
    _isDiscovering = true;
    _devices.clear();
    notifyListeners();

    // Trickle the devices in, the way a real mDNS scan resolves them.
    _discoveryTimer?.cancel();
    var index = 0;
    _discoveryTimer = Timer.periodic(const Duration(milliseconds: 600), (
      timer,
    ) {
      if (index >= _fakeDevices.length) {
        timer.cancel();
        _isDiscovering = false;
        notifyListeners();
        return;
      }
      _devices.add(_fakeDevices[index++]);
      notifyListeners();
    });
  }

  @override
  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _isDiscovering = false;
    notifyListeners();
  }

  @override
  Future<void> connect(CastDevice device) async {
    _errorDescription = null;
    _connectedDevice = device;
    _connectionState = CastConnectionState.connecting;
    notifyListeners();

    // Real receivers take a moment to accept a session; Chewie shows the
    // pulsing cast button until this lands.
    _connectTimer?.cancel();
    _connectTimer = Timer(const Duration(seconds: 2), () {
      _connectionState = CastConnectionState.connected;
      notifyListeners();
    });
  }

  @override
  Future<void> disconnect() async {
    _connectTimer?.cancel();
    _tickTimer?.cancel();

    _connectionState = CastConnectionState.disconnecting;
    notifyListeners();

    _connectionState = CastConnectionState.disconnected;
    _connectedDevice = null;
    notifyListeners();
  }

  @override
  Future<void> load(
    CastMedia media, {
    Duration startAt = Duration.zero,
    bool autoPlay = true,
  }) async {
    _value = VideoPlayerValue(
      // A real receiver reports the duration once it has parsed the stream;
      // pretend we already know it.
      duration: const Duration(minutes: 10),
      position: startAt,
      isInitialized: true,
      isPlaying: autoPlay,
    );
    notifyListeners();

    if (autoPlay) {
      _startTicking();
    }
  }

  @override
  Future<void> play() async {
    _value = _value.copyWith(isPlaying: true);
    _startTicking();
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    _tickTimer?.cancel();
    _value = _value.copyWith(isPlaying: false);
    notifyListeners();
  }

  @override
  Future<void> seekTo(Duration position) async {
    _value = _value.copyWith(position: position);
    notifyListeners();
  }

  @override
  Future<void> setVolume(double volume) async {
    _value = _value.copyWith(volume: volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _connectTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  /// Walks the fake receiver's position forward once a second.
  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _value.position + const Duration(seconds: 1);
      if (next >= _value.duration) {
        _tickTimer?.cancel();
        _value = _value.copyWith(position: _value.duration, isPlaying: false);
      } else {
        _value = _value.copyWith(position: next);
      }
      notifyListeners();
    });
  }
}
