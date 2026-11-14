import 'package:chewie/src/models/subtitle_model.dart';

/// Returns the cues of a [SubtitleTrack]. See [SubtitleTrack.loader].
typedef SubtitleLoader = Future<List<Subtitle>> Function();

/// A selectable subtitle track surfaced in the player's options menu.
///
/// A track can load itself: give it a [url] to a WebVTT or SubRip file, or a
/// [loader], and Chewie fetches the cues the first time the track is selected
/// and shows them in sync with the video.
///
/// A track with neither stays decoupled from any particular source (HLS,
/// embedded...): the host reacts to the user's selection through
/// [ChewieController.onSubtitleTrackChanged] and feeds cues back itself, e.g.
/// via [ChewieController.setLiveSubtitle].
class SubtitleTrack {
  const SubtitleTrack({
    required this.id,
    required this.label,
    this.language,
    this.url,
    this.loader,
  });

  /// Opaque identifier the host uses to recognise the track on selection.
  final Object id;

  /// Human-readable name shown in the menu.
  final String label;

  /// Optional BCP-47 language tag, shown as a hint next to [label].
  final String? language;

  /// A WebVTT (`.vtt`) or SubRip (`.srt`) file Chewie downloads with a plain
  /// GET when the track is first selected. Ignored when [loader] is set.
  final Uri? url;

  /// Produces the cues when the track is first selected, for anything a plain
  /// GET of [url] does not cover: signed URLs, request headers, bundled
  /// assets, other formats. `parseSubtitles` turns WebVTT or SubRip text into
  /// cues.
  final SubtitleLoader? loader;

  /// Whether Chewie loads and displays this track's cues by itself.
  bool get hasSource => url != null || loader != null;

  @override
  bool operator ==(Object other) =>
      other is SubtitleTrack &&
      other.id == id &&
      other.label == label &&
      other.language == language &&
      other.url == url &&
      other.loader == loader;

  @override
  int get hashCode => Object.hash(id, label, language, url, loader);

  @override
  String toString() =>
      'SubtitleTrack(id: $id, label: $label, language: $language)';
}
