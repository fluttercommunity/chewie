import 'package:flutter/widgets.dart';

/// How the default subtitle box looks.
///
/// Chewie renders cues itself unless a `subtitleBuilder` is given, and this is
/// the knob for that default rendering: text style, alignment, the padding
/// inside the box and the box itself. Inline markup in the cue text is parsed
/// either way, so restyling subtitles no longer means giving up italics.
///
/// The defaults reproduce Chewie's long-standing look, so setting nothing
/// changes nothing.
///
/// ```dart
/// ChewieController(
///   videoPlayerController: controller,
///   subtitleStyle: const SubtitleStyle(
///     textStyle: TextStyle(fontSize: 22, color: Color(0xFFFFC107)),
///     decoration: BoxDecoration(color: Color(0xCC000000)),
///   ),
/// );
/// ```
///
/// Ignored when `subtitleBuilder` is set — that hook replaces the default
/// rendering wholesale.
class SubtitleStyle {
  const SubtitleStyle({
    this.textStyle = const TextStyle(fontSize: 18),
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.all(5),
    this.decoration = const BoxDecoration(
      color: Color(0x96000000),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    ),
    this.renderMarkup = true,
  });

  /// Base style for the cue text.
  ///
  /// Markup merges onto it rather than replacing it, so `<b>` inside a cue
  /// bolds text that keeps this style's size and colour. Leaving `color` unset
  /// inherits it from the surrounding [DefaultTextStyle], as Chewie has always
  /// done.
  final TextStyle textStyle;

  /// How cue lines are aligned against each other.
  final TextAlign textAlign;

  /// Space between the text and the edge of the box drawn by [decoration].
  final EdgeInsetsGeometry padding;

  /// The box painted behind the cue text.
  final Decoration decoration;

  /// Whether inline markup in the cue text is rendered.
  ///
  /// When `true` (the default), `<b>`, `<i>`, `<u>` and `<font color="…">` are
  /// applied, other WebVTT tags are dropped while keeping their text, and
  /// escapes such as `&amp;` are decoded. Text that only resembles a tag, like
  /// `5 < 10`, is left alone.
  ///
  /// Set to `false` to display cue text exactly as it arrives, tags included.
  final bool renderMarkup;

  SubtitleStyle copyWith({
    TextStyle? textStyle,
    TextAlign? textAlign,
    EdgeInsetsGeometry? padding,
    Decoration? decoration,
    bool? renderMarkup,
  }) {
    return SubtitleStyle(
      textStyle: textStyle ?? this.textStyle,
      textAlign: textAlign ?? this.textAlign,
      padding: padding ?? this.padding,
      decoration: decoration ?? this.decoration,
      renderMarkup: renderMarkup ?? this.renderMarkup,
    );
  }

  @override
  String toString() =>
      'SubtitleStyle(textStyle: $textStyle, textAlign: $textAlign, '
      'padding: $padding, decoration: $decoration, '
      'renderMarkup: $renderMarkup)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubtitleStyle &&
        other.textStyle == textStyle &&
        other.textAlign == textAlign &&
        other.padding == padding &&
        other.decoration == decoration &&
        other.renderMarkup == renderMarkup;
  }

  @override
  int get hashCode =>
      textStyle.hashCode ^
      textAlign.hashCode ^
      padding.hashCode ^
      decoration.hashCode ^
      renderMarkup.hashCode;
}
