import 'package:chewie/src/helpers/fetch_text.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/models/subtitle_track.dart';

final _timing = RegExp(
  r'((?:\d+:)?\d{1,2}:\d{2}[.,]\d{1,3})\s+-->\s+((?:\d+:)?\d{1,2}:\d{2}[.,]\d{1,3})',
);

/// Parses the contents of a WebVTT (`.vtt`) or SubRip (`.srt`) file into cues.
///
/// The two formats differ only in details this parser accepts either way, so
/// the format never has to be stated. Cue text keeps its inline markup
/// (`<i>`, `<b>`…), which Chewie renders; headers, notes, styles, cue
/// identifiers and cue settings are skipped, as is any block without a valid
/// timing line.
///
/// Useful inside a [SubtitleTrack.loader] that fetches the file itself, e.g.
/// to send headers:
///
/// ```dart
/// loader: () async =>
///     parseSubtitles((await http.get(url, headers: headers)).body),
/// ```
List<Subtitle> parseSubtitles(String content) {
  final cues = <Subtitle>[];
  final blocks = content
      .replaceFirst('﻿', '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split(RegExp(r'\n[ \t]*\n'));
  for (final block in blocks) {
    final lines = block.split('\n');
    final timingLine = lines.indexWhere(_timing.hasMatch);
    if (timingLine < 0) continue;
    final match = _timing.firstMatch(lines[timingLine])!;
    final text = lines.sublist(timingLine + 1).join('\n').trim();
    if (text.isEmpty) continue;
    cues.add(
      Subtitle(
        index: cues.length,
        start: _parseTimestamp(match.group(1)!),
        end: _parseTimestamp(match.group(2)!),
        text: text,
      ),
    );
  }
  return cues;
}

Duration _parseTimestamp(String timestamp) {
  final parts = timestamp.replaceFirst(',', '.').split(':');
  final seconds = parts.last.split('.');
  return Duration(
    hours: parts.length == 3 ? int.parse(parts[0]) : 0,
    minutes: int.parse(parts[parts.length - 2]),
    seconds: int.parse(seconds[0]),
    milliseconds: int.parse(seconds[1].padRight(3, '0')),
  );
}

/// Loads the cues of a track that carries its own source.
Future<List<Subtitle>> loadSubtitleTrack(SubtitleTrack track) async {
  final loader = track.loader;
  if (loader != null) return loader();
  // Without a limit, a server that never answers would keep the track
  // loading for good: the pending fetch is cached, so no retry would happen.
  final text = await fetchText(track.url!).timeout(const Duration(seconds: 30));
  return parseSubtitles(text);
}
