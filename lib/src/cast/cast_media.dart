import 'package:flutter/foundation.dart';

/// What Chewie asks the cast backend to play on the remote device.
///
/// Chewie cannot derive this from the `VideoPlayerController` on its own: the
/// receiver needs an absolute URL it can reach itself over the network, plus
/// metadata the local player never has (title, artwork). A `file://` or asset
/// data source has no remote equivalent at all, which is why this is supplied
/// explicitly rather than guessed.
@immutable
class CastMedia {
  const CastMedia({
    required this.url,
    this.mimeType,
    this.title,
    this.subtitle,
    this.posterUrl,
    this.headers = const {},
    this.isLive = false,
  });

  /// Absolute URL of the stream, reachable from the receiver device — not from
  /// the phone. `localhost` and LAN-only URLs will fail on the receiver.
  final String url;

  /// e.g. `video/mp4`, `application/x-mpegURL`. Backends that need a content
  /// type and get none here typically fall back to sniffing the extension.
  final String? mimeType;

  /// Title shown on the TV while casting.
  final String? title;

  /// Secondary line shown on the TV, e.g. a series or chapter name.
  final String? subtitle;

  /// Artwork shown on the TV, usually while audio-only or buffering.
  final String? posterUrl;

  /// Extra HTTP headers the receiver should send when fetching [url], for
  /// signed or authenticated streams. Not every backend supports these.
  final Map<String, String> headers;

  /// Whether this is a live stream. Receivers use it to pick a live UI and to
  /// skip seek affordances.
  final bool isLive;

  CastMedia copyWith({
    String? url,
    String? mimeType,
    String? title,
    String? subtitle,
    String? posterUrl,
    Map<String, String>? headers,
    bool? isLive,
  }) {
    return CastMedia(
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      posterUrl: posterUrl ?? this.posterUrl,
      headers: headers ?? this.headers,
      isLive: isLive ?? this.isLive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CastMedia &&
        other.url == url &&
        other.mimeType == mimeType &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.posterUrl == posterUrl &&
        other.isLive == isLive &&
        mapEquals(other.headers, headers);
  }

  @override
  int get hashCode => Object.hash(
    url,
    mimeType,
    title,
    subtitle,
    posterUrl,
    isLive,
    Object.hashAllUnordered(
      headers.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'CastMedia(url: $url, title: $title)';
}
