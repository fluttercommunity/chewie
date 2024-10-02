import '../models/audio_track.dart';
import '../models/video_track.dart';

class HlsParser {
  HlsParser({
    required this.playlistContent,
  });

  final String playlistContent;

  List<AudioTrack> parseAudioTracks() {
    // Match only lines that start with #EXT-X-MEDIA:TYPE=AUDIO
    final audioTrackPattern = RegExp(
      '#EXT-X-MEDIA:TYPE=AUDIO(.*)',
    );
    final matches = audioTrackPattern.allMatches(playlistContent);

    return matches.map((match) {
      // The rest of the line after #EXT-X-MEDIA:TYPE=AUDIO
      final attributesString = match.group(1)!;

      // Parse attributes like GROUP-ID, LANGUAGE, etc.
      final attributes = _parseAttributes(attributesString);

      return AudioTrack(
        groupId: attributes['GROUP-ID'] ?? 'unknown',
        language: attributes['LANGUAGE'] ?? 'und', // Handle missing language
        name: attributes['NAME'] ?? 'unknown',
        isDefault: attributes['DEFAULT'] == 'YES',
        channels: attributes['CHANNELS'],
        uri: attributes['URI'] ?? '',
      );
    }).toList();
  }

  List<VideoTrack> parseVideoTracks() {
    final videoTrackPattern = RegExp(r'#EXT-X-STREAM-INF:(.*)\s*\n\s*(\S+)');
    final matches = videoTrackPattern.allMatches(playlistContent);

    return matches.map((match) {
      final attributes = _parseAttributes(match.group(1)!);
      return VideoTrack(
        bandwidth: attributes['BANDWIDTH'] != null
            ? int.tryParse(attributes['BANDWIDTH']!)
            : null,
        resolution: attributes['RESOLUTION'],
        codecs: attributes['CODECS'],
        audioGroupId: attributes['AUDIO'],
        uri: match.group(2),
      );
    }).toList()
      ..removeWhere(
        (item) => item.resolution == null,
      );
  }

  Map<String, String> _parseAttributes(String attributeString) {
    final attributes = <String, String>{};
    final attributePattern = RegExp(r'([A-Z\-]+)=("[^"]+"|[^,]+)');
    final matches = attributePattern.allMatches(attributeString);

    for (final match in matches) {
      final key = match.group(1)!;
      final value = match.group(2)!.replaceAll('"', '');
      attributes[key] = value;
    }

    return attributes;
  }

  String changeResolution(VideoTrack targetResolution) {
    final videoTracks = parseVideoTracks();
    final audioTracks = parseAudioTracks();

    final matchingTrack = videoTracks.firstWhere(
      (track) => track.resolution == targetResolution.resolution,
      orElse: () => throw Exception(
        'Resolution ${targetResolution.resolution} not found',
      ),
    );

    // Check for a matching audio track
    final matchingAudioTrack = audioTracks
        .where(
          (audioTrack) => audioTrack.groupId == matchingTrack.audioGroupId,
        )
        .firstOrNull;

    final buffer = StringBuffer()
      ..writeln('#EXTM3U')
      ..writeln('#EXT-X-VERSION:6');

    // Add all audio tracks if no matching audio is found
    if (matchingAudioTrack == null) {
      for (final audioTrack in audioTracks) {
        buffer.writeln(
          '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="${audioTrack.groupId}",NAME="${audioTrack.name}",DEFAULT=${audioTrack.isDefault ?? true ? "YES" : "NO"},LANGUAGE="${audioTrack.language}",CHANNELS="${audioTrack.channels ?? 2}",URI="${audioTrack.uri}"',
        );
      }
    } else {
      // Only add the matching audio track
      buffer.writeln(
        '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="${matchingAudioTrack.groupId}",NAME="${matchingAudioTrack.name}",DEFAULT=${matchingAudioTrack.isDefault ?? true ? "YES" : "NO"},LANGUAGE="${matchingAudioTrack.language}",CHANNELS="${matchingAudioTrack.channels ?? 2}",URI="${matchingAudioTrack.uri}"',
      );
    }

    // Add the selected video track
    buffer
      ..writeln(
        '#EXT-X-STREAM-INF:BANDWIDTH=${matchingTrack.bandwidth},RESOLUTION=${matchingTrack.resolution},CODECS="${matchingTrack.codecs}",AUDIO="${matchingTrack.audioGroupId}"',
      )
      ..writeln(matchingTrack.uri);

    return buffer.toString();
  }

  String changeAudio(
    AudioTrack targetAudioTrack, {
    VideoTrack? targetVideoTrack,
  }) {
    final videoTracks = parseVideoTracks();
    final audioTracks = parseAudioTracks();

    final matchingTracks = audioTracks
        .where(
          (audioTrack) => audioTrack.language == targetAudioTrack.language,
        )
        .toList();

    if (matchingTracks.isEmpty) {
      throw Exception(
        'No audio tracks found for language ${targetAudioTrack.language}',
      );
    }

    final buffer = StringBuffer()
      ..writeln('#EXTM3U')
      ..writeln('#EXT-X-VERSION:6');

    for (final track in matchingTracks) {
      buffer.writeln(
        '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="${track.groupId}",NAME="${track.name}",DEFAULT=${track.isDefault ?? true ? "YES" : "NO"},LANGUAGE="${track.language}",CHANNELS="${track.channels}",URI="${track.uri}"',
      );
    }

    if (targetVideoTrack != null) {
      buffer
        ..writeln(
          '#EXT-X-STREAM-INF:BANDWIDTH=${targetVideoTrack.bandwidth},RESOLUTION=${targetVideoTrack.resolution},CODECS="${targetVideoTrack.codecs}",AUDIO="${targetVideoTrack.audioGroupId}"',
        )
        ..writeln(targetVideoTrack.uri);
    } else {
      for (final videoTrack in videoTracks) {
        buffer
          ..writeln(
            '#EXT-X-STREAM-INF:BANDWIDTH=${videoTrack.bandwidth},RESOLUTION=${videoTrack.resolution},CODECS="${videoTrack.codecs}",AUDIO="${videoTrack.audioGroupId}"',
          )
          ..writeln(videoTrack.uri);
      }
    }

    return buffer.toString();
  }
}
