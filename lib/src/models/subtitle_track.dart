/// A selectable subtitle track surfaced in the player's options menu.
///
/// This is intentionally decoupled from any particular source (HLS, embedded,
/// sidecar files...). The host supplies the tracks and reacts to the user's
/// selection through [ChewieController.onSubtitleTrackChanged]; how cues are
/// produced and fed back (e.g. via [ChewieController.setLiveSubtitle] for a
/// streaming source, or via [ChewieController.setSubtitle] for a parsed cue
/// list) is left to the host.
class SubtitleTrack {
  const SubtitleTrack({required this.id, required this.label, this.language});

  /// Opaque identifier the host uses to recognise the track on selection.
  final Object id;

  /// Human-readable name shown in the menu.
  final String label;

  /// Optional BCP-47 language tag, shown as a hint next to [label].
  final String? language;

  @override
  bool operator ==(Object other) =>
      other is SubtitleTrack &&
      other.id == id &&
      other.label == label &&
      other.language == language;

  @override
  int get hashCode => Object.hash(id, label, language);

  @override
  String toString() =>
      'SubtitleTrack(id: $id, label: $label, language: $language)';
}
