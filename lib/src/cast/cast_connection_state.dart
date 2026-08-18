/// Where a cast session currently is between "nothing" and "playing on the TV".
enum CastConnectionState {
  /// No session. The cast button is idle and playback is local.
  disconnected,

  /// A session is being established. The cast button pulses; playback is still
  /// local until [connected] arrives.
  connecting,

  /// A session is live. Chewie's controls drive the receiver, and the video
  /// surface is replaced by the casting overlay.
  connected,

  /// The session is being torn down. Playback returns to local once
  /// [disconnected] arrives.
  disconnecting,
}

extension CastConnectionStateX on CastConnectionState {
  bool get isConnected => this == CastConnectionState.connected;

  bool get isDisconnected => this == CastConnectionState.disconnected;

  /// True while a session is being set up or torn down, i.e. neither fully on
  /// nor fully off. Useful for showing a busy affordance.
  bool get isTransitioning =>
      this == CastConnectionState.connecting ||
      this == CastConnectionState.disconnecting;
}
