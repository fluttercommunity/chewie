class OptionsTranslation {
  OptionsTranslation({
    this.resolutionButtonText,
    this.playbackSpeedButtonText,
    this.subtitlesButtonText,
    this.cancelButtonText,
  });

  String? resolutionButtonText;
  String? playbackSpeedButtonText;
  String? subtitlesButtonText;
  String? cancelButtonText;

  OptionsTranslation copyWith({
    String? resolutionButtonText,
    String? playbackSpeedButtonText,
    String? subtitlesButtonText,
    String? cancelButtonText,
  }) {
    return OptionsTranslation(
      resolutionButtonText: resolutionButtonText ?? this.resolutionButtonText,
      playbackSpeedButtonText:
          playbackSpeedButtonText ?? this.playbackSpeedButtonText,
      subtitlesButtonText: subtitlesButtonText ?? this.subtitlesButtonText,
      cancelButtonText: cancelButtonText ?? this.cancelButtonText,
    );
  }

  @override
  String toString() =>
      'OptionsTranslation(resolutionButtonText: $resolutionButtonText, playbackSpeedButtonText: $playbackSpeedButtonText, subtitlesButtonText: $subtitlesButtonText, cancelButtonText: $cancelButtonText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OptionsTranslation &&
        other.resolutionButtonText == resolutionButtonText &&
        other.playbackSpeedButtonText == playbackSpeedButtonText &&
        other.subtitlesButtonText == subtitlesButtonText &&
        other.cancelButtonText == cancelButtonText;
  }

  @override
  int get hashCode =>
      resolutionButtonText.hashCode ^
      playbackSpeedButtonText.hashCode ^
      subtitlesButtonText.hashCode ^
      cancelButtonText.hashCode;
}
