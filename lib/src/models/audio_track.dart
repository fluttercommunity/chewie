/// A selectable audio track surfaced in the player's options menu.
///
/// This is intentionally decoupled from any particular source (HLS, embedded
/// renditions...). The host supplies the tracks and reacts to the user's
/// selection through [ChewieController.onAudioTrackChanged]; switching the
/// playing rendition is left to the host. Unlike subtitles, audio is never
/// "off": one track is always active.
class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.label,
    this.language,
  });

  /// Opaque identifier the host uses to recognise the track on selection.
  final Object id;

  /// Human-readable name shown in the menu.
  final String label;

  /// Optional BCP-47 language tag, shown as a hint next to [label].
  final String? language;

  @override
  bool operator ==(Object other) =>
      other is AudioTrack &&
      other.id == id &&
      other.label == label &&
      other.language == language;

  @override
  int get hashCode => Object.hash(id, label, language);

  @override
  String toString() => 'AudioTrack(id: $id, label: $label, language: $language)';
}
