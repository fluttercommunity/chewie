import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

class HlsDownloaded {
  const HlsDownloaded({
    required this.master,
    required this.origin,
  });

  final File master;
  final File origin;
}

class HlsDownloadManager {
  HlsDownloadManager(this.directory);

  final Directory directory;

  late final tmpPath = '${directory.path}/tmp-media';

  Future<HlsDownloaded> downloadHlsFromUrl({
    required String url,
    Map<String, dynamic>? headers,
  }) async {
    try {
      await cleanTmpFiles();

      final master = File('$tmpPath/master.m3u8');
      final origin = File('$tmpPath/origin.m3u8');

      await Dio(BaseOptions(headers: headers)).download(url, master.path);

      await origin.writeAsString(
        await master.readAsString(),
      );

      await parseAndDownloadPlaylists(
        data: await master.readAsString(),
        url: url,
      );

      return HlsDownloaded(
        master: master,
        origin: origin,
      );
    } catch (err) {
      log('Error downloading master playlist: $err');
      rethrow;
    }
  }

  Future<void> cleanTmpFiles() async {
    final tempDr = Directory(tmpPath);

    if (tempDr.existsSync()) {
      await tempDr.delete(recursive: true);
    }
  }

  Future<void> parseAndDownloadPlaylists({
    required String data,
    required String url,
  }) async {
    final lines = data.split('\n');
    final baseUrl = url.substring(0, url.lastIndexOf('/') + 1);

    final futureList = <Future<dynamic>>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('#EXT-X-STREAM-INF')) {
        final resolutionUrl = resolveUrl(baseUrl, lines[i + 1].trim());

        futureList.add(
          downloadAndProcessPlaylist(
            resolutionUrl,
            lines[i + 1].trim(),
          ),
        );
      }

      if (line.startsWith('#EXT-X-MEDIA') && line.contains('TYPE=AUDIO')) {
        final audioUrl = extractUrlFromLine(lines[i + 1].trim(), baseUrl);
        if (audioUrl != null) {
          futureList.add(
            downloadAndProcessPlaylist(
              audioUrl,
              lines[i + 1].trim(),
            ),
          );
        }
      }
    }

    await Future.wait(futureList);
  }

  Future<void> downloadAndProcessPlaylist(
    String playlistUrl,
    String fileName,
  ) async {
    try {
      final playlistFile = File('$tmpPath/$fileName');

      final response = await Dio().download(playlistUrl, playlistFile.path);

      if (response.statusCode == 200) {
        await updatePlaylistUrls(
          file: playlistFile,
          url: playlistUrl,
        );
      }
    } catch (err) {
      log('Error downloading and processing playlist $fileName: $err');
      rethrow;
    }
  }

  Future<void> updatePlaylistUrls({
    required File file,
    required String url,
  }) async {
    try {
      final baseUrl = url.substring(0, url.lastIndexOf('/') + 1);
      final data = await file.readAsString();

      final lines = data.split('\n');
      final updatedLines = <String>[];

      for (var line in lines) {
        if (line.startsWith('#EXT-X-KEY')) {
          final keyUrl = extractKeyUri(line);
          if (keyUrl != null) {
            final fullKeyUrl = resolveUrl(baseUrl, keyUrl);
            line = line.replaceFirst(keyUrl, fullKeyUrl);
          }
        }

        if (line.trim().endsWith('.ts')) {
          final fullSegmentUrl = resolveUrl(baseUrl, line.trim());
          updatedLines.add(fullSegmentUrl);
        } else {
          updatedLines.add(line);
        }
      }

      final updatedData = updatedLines.join('\n');
      await file.writeAsString(updatedData);
    } catch (err) {
      log('Error updating playlist URLs: $err');
      rethrow;
    }
  }

  String? extractKeyUri(String line) {
    final uriPattern = RegExp('URI="([^"]+)"');
    final match = uriPattern.firstMatch(line);
    return match?.group(1);
  }

  String resolveUrl(String baseUrl, String url) {
    if (url.startsWith('http')) {
      return url;
    } else {
      return Uri.parse(baseUrl).resolve(url).toString();
    }
  }

  String? extractUrlFromLine(String line, String baseUrl) {
    if (line.startsWith('http')) {
      return line;
    } else if (line.endsWith('.m3u8')) {
      return resolveUrl(baseUrl, line);
    }
    return null;
  }

  String getFileNameFromUrl(String url) {
    return url.split('/').last;
  }
}
