class Subtitles {
  Subtitles(this.subtitle);

  final List<Subtitle?> subtitle;

  bool get isEmpty => subtitle.isEmpty;

  bool get isNotEmpty => !isEmpty;

  List<Subtitle?> getByPosition(Duration position) {
    final found = subtitle.where((item) {
      if (item != null) return position >= item.start && position <= item.end;
      return false;
    }).toList();

    return found;
  }
}

class Subtitle {
  Subtitle({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  Subtitle copyWith({
    int? index,
    Duration? start,
    Duration? end,
    dynamic text,
  }) {
    return Subtitle(
      index: index ?? this.index,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
    );
  }

  final int index;
  final Duration start;
  final Duration end;
  final dynamic text;

  @override
  String toString() {
    return 'Subtitle(index: $index, start: $start, end: $end, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Subtitle &&
        other.index == index &&
        other.start == start &&
        other.end == end &&
        other.text == text;
  }

  @override
  int get hashCode {
    return index.hashCode ^ start.hashCode ^ end.hashCode ^ text.hashCode;
  }
}
