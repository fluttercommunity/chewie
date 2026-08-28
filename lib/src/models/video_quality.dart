/// A selectable video quality surfaced in the player's options menu.
///
/// This is intentionally decoupled from any particular source (separate
/// files per quality, HLS renditions...). The host supplies the qualities
/// and reacts to the user's selection through
/// [ChewieController.onVideoQualityChanged]; switching the playing stream is
/// left to the host — for separate files per quality,
/// [ChewieController.swapVideoSource] does the switch while preserving the
/// playback state.
class VideoQuality {
  const VideoQuality({required this.id, required this.label});

  /// Opaque identifier the host uses to recognise the quality on selection.
  final Object id;

  /// Human-readable name shown in the menu (e.g. '1080p', 'Auto').
  final String label;

  @override
  bool operator ==(Object other) =>
      other is VideoQuality && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'VideoQuality(id: $id, label: $label)';
}
