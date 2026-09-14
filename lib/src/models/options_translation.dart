class OptionsTranslation {
  OptionsTranslation({
    this.playbackSpeedButtonText,
    this.subtitlesButtonText,
    this.cancelButtonText,
  });

  String? playbackSpeedButtonText;
  String? subtitlesButtonText;
  String? cancelButtonText;

  OptionsTranslation copyWith({
    String? playbackSpeedButtonText,
    String? subtitlesButtonText,
    String? cancelButtonText,
  }) {
    return OptionsTranslation(
      playbackSpeedButtonText:
          playbackSpeedButtonText ?? this.playbackSpeedButtonText,
      subtitlesButtonText: subtitlesButtonText ?? this.subtitlesButtonText,
      cancelButtonText: cancelButtonText ?? this.cancelButtonText,
    );
  }

  @override
  String toString() =>
      'OptionsTranslation(playbackSpeedButtonText: $playbackSpeedButtonText, subtitlesButtonText: $subtitlesButtonText, cancelButtonText: $cancelButtonText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OptionsTranslation &&
        other.playbackSpeedButtonText == playbackSpeedButtonText &&
        other.subtitlesButtonText == subtitlesButtonText &&
        other.cancelButtonText == cancelButtonText;
  }

  @override
  int get hashCode =>
      playbackSpeedButtonText.hashCode ^
      subtitlesButtonText.hashCode ^
      cancelButtonText.hashCode;
}
