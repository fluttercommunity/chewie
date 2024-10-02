import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class WebVTTEntry extends Equatable {
  WebVTTEntry({
    required this.startTime,
    required this.gridSize,
    required this.endTime,
    required this.offset,
    required this.size,
    required this.url,
  });

  Size size;
  String url;
  int gridSize;
  Offset offset;
  final Duration endTime;
  final Duration startTime;

  @override
  String toString() {
    // ignore: lines_longer_than_80_chars
    return 'Start: $startTime, End: $endTime, Offset: $offset, Size: $size, Url: $url, GridSize: $gridSize';
  }

  @override
  List<Object?> get props => [url, size, endTime, startTime];
}

class WebVTTParser {
  WebVTTParser();

  List<WebVTTEntry> parse(String fileContent) {
    final entries = <WebVTTEntry>[];
    final lines = fileContent.split('\n');
    WebVTTEntry? currentEntry;
    final content = <String>[];
    var xywh = <double>[];
    var size = Size.zero;
    var offset = Offset.zero;
    var url = '';
    var gridSize = 0;

    for (final line in lines) {
      if (line.isEmpty) {
        if (currentEntry != null) {
          size = Size(xywh[2], xywh[3]);
          offset = Offset(xywh[0], xywh[1]);

          url = content.isNotEmpty ? content.first : '';
          gridSize = extractGridSize(url);

          currentEntry
            ..url = url
            ..size = size
            ..offset = offset
            ..gridSize = gridSize;

          entries.add(currentEntry);
          content.clear();
          xywh = [];
        }
        currentEntry = null;
      } else if (line.contains('-->')) {
        final headerParts = line.split(' ');

        final startTime = headerParts[0];
        final endTime = headerParts[2];

        currentEntry = WebVTTEntry(
          startTime: parseDuration(startTime),
          endTime: parseDuration(endTime),
          size: Size.zero,
          offset: Offset.zero,
          gridSize: 5,
          url: '',
        );
      } else if (line.contains('#xywh=')) {
        xywh = line
            .substring(line.indexOf('#xywh=') + 6)
            .split(',')
            .map(double.parse)
            .toList();

        content.add(line.split('#')[0]);
      } else if (!line.startsWith('NOTE') &&
          !line.startsWith('WEBVTT') &&
          currentEntry != null) {
        content.add(line);
      }
    }

    if (currentEntry != null && content.isNotEmpty) {
      size = Size(xywh[2], xywh[3]);
      offset = Offset(xywh[0], xywh[1]);

      url = content.isNotEmpty ? content.first : '';
      gridSize = extractGridSize(url);

      currentEntry
        ..size = size
        ..offset = offset
        ..gridSize = gridSize
        ..url = url;

      entries.add(currentEntry);
    }

    return entries;
  }

  Duration parseDuration(String timestamp) {
    final parts = timestamp.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  int extractGridSize(String url) {
    final regExp = RegExp(r'\d+x\d+');
    final match = regExp.firstMatch(url);

    return int.parse((match?.group(0) ?? '5x5').split('x').first);
  }

  Future<List<WebVTTEntry>> loadVttAndParse(File file) async {
    final data = await file.readAsString();

    final parsed = parse(data);

    return parsed;
  }
}
