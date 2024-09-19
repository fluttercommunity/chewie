import '../models/audio_track.dart';
import '../models/video_track.dart';

class HlsParser {
  HlsParser({
    required this.playlistContent,
  });

  final String playlistContent;

  List<AudioTrack> parseAudioTracks() {
    final audioTrackPattern = RegExp(
      '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="([^"]+)",NAME="([^"]+)",DEFAULT=(YES|NO),LANGUAGE="([^"]+)",CHANNELS="([^"]+)",URI="([^"]+)"',
    );
    final matches = audioTrackPattern.allMatches(playlistContent);

    return matches.map((match) {
      return AudioTrack(
        groupId: match.group(1),
        name: match.group(2),
        isDefault: match.group(3) == 'YES',
        language: match.group(4),
        channels: match.group(5),
        uri: match.group(6),
      );
    }).toList();
  }

  List<VideoTrack> parseVideoTracks() {
    final videoTrackPattern = RegExp(r'#EXT-X-STREAM-INF:(.*?)\n(.*?)\n');
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
    }).toList();
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
}
