/// A named section of a video, used to split the progress bar into
/// YouTube-style chapter segments.
///
/// Provide chapters to a video through [ChewieController.chapters], sorted by
/// ascending [start] time. The first chapter usually starts at
/// [Duration.zero].
class ChewieChapter {
  const ChewieChapter({required this.title, required this.start});

  /// The title displayed above the progress bar while the chapter is hovered
  /// or scrubbed.
  final String title;

  /// The position in the video at which this chapter begins.
  final Duration start;
}
