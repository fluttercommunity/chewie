class OptionsTranslation {
  OptionsTranslation({
    this.playbackSpeedButtonText,
    this.subtitlesButtonText,
    this.cancelButtonText,
    this.qualityButtonText,
  });

  String? playbackSpeedButtonText;
  String? subtitlesButtonText;
  String? cancelButtonText;
  String? qualityButtonText;

  OptionsTranslation copyWith({
    String? playbackSpeedButtonText,
    String? subtitlesButtonText,
    String? cancelButtonText,
    String? qualityButtonText,
  }) {
    return OptionsTranslation(
      playbackSpeedButtonText:
          playbackSpeedButtonText ?? this.playbackSpeedButtonText,
      subtitlesButtonText: subtitlesButtonText ?? this.subtitlesButtonText,
      cancelButtonText: cancelButtonText ?? this.cancelButtonText,
      qualityButtonText: qualityButtonText ?? this.qualityButtonText,
    );
  }

  @override
  String toString() =>
      'OptionsTranslation(playbackSpeedButtonText: $playbackSpeedButtonText, subtitlesButtonText: $subtitlesButtonText, cancelButtonText: $cancelButtonText, qualityButtonText: $qualityButtonText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OptionsTranslation &&
        other.playbackSpeedButtonText == playbackSpeedButtonText &&
        other.subtitlesButtonText == subtitlesButtonText &&
        other.cancelButtonText == cancelButtonText && 
        other.qualityButtonText == qualityButtonText;
  }

  @override
  int get hashCode =>
      playbackSpeedButtonText.hashCode ^
      subtitlesButtonText.hashCode ^
      cancelButtonText.hashCode ^ 
      qualityButtonText.hashCode;
}
