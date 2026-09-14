import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/subtitle_markup.dart';
import 'package:flutter/widgets.dart';

/// Renders one subtitle cue.
///
/// Shared by the Material, Material desktop and Cupertino controls so the three
/// skins can't drift on how a cue is turned into pixels. Each skin still owns
/// when a cue is shown and how far it sits from the player edge — that is
/// [margin], the one thing they legitimately disagree about.
class SubtitleOverlay extends StatelessWidget {
  const SubtitleOverlay({
    super.key,
    required this.chewieController,
    required this.margin,
    required this.text,
  });

  final ChewieController chewieController;

  /// Space between the subtitle box and the surrounding controls.
  final EdgeInsetsGeometry margin;

  /// The cue payload: a `String` of cue text, a ready-made [InlineSpan], or
  /// anything else, which falls back to `toString()`.
  final dynamic text;

  @override
  Widget build(BuildContext context) {
    // The builder wins, and it sees the payload untouched — parsing it first
    // would change what every existing implementation receives.
    final subtitleBuilder = chewieController.subtitleBuilder;
    if (subtitleBuilder != null) {
      return subtitleBuilder(context, text);
    }

    final style = chewieController.subtitleStyle;
    final InlineSpan span = switch (text) {
      final InlineSpan span => span,
      final String cueText when style.renderMarkup => parseSubtitleMarkup(
        cueText,
        style: style.textStyle,
      ),
      _ => TextSpan(text: text.toString(), style: style.textStyle),
    };

    return Padding(
      padding: margin,
      child: Container(
        padding: style.padding,
        decoration: style.decoration,
        // Text.rich rather than RichText: RichText opts out of text scaling,
        // which would drop the user's font size preference.
        child: Text.rich(span, textAlign: style.textAlign),
      ),
    );
  }
}
