import 'package:flutter/painting.dart';

/// Parses the inline markup found in WebVTT and SubRip cue text into an
/// [InlineSpan] ready to hand to `Text.rich`.
///
/// WebVTT specifies a cue text tag grammar — `<b>`, `<i>`, `<u>`, `<c.class>`,
/// `<v Speaker>`, `<lang xx>`, `<ruby>`/`<rt>`, timestamp tags such as
/// `<00:00:01.000>`, and character escapes like `&amp;`. SubRip has no formal
/// specification but conventionally uses `<b>`, `<i>`, `<u>` and
/// `<font color="…">`. Both are handled here.
///
/// Tag styles are merged onto [style], so a caller's font size and colour
/// survive: `<b>` adds `FontWeight.bold` to the caller's style rather than
/// replacing it.
///
/// Parsing covers the whole cue at once, so a tag that opens on one line and
/// closes on the next is honoured:
///
/// ```
/// <i>un paquet de muscles
/// qui ne pense qu'à lui.</i>
/// ```
///
/// Parsing is deliberately lenient, so cue text is never mangled by a `<` that
/// was never meant as markup:
///
/// * A `<` only starts a tag when what follows is a well-formed tag on the same
///   line. `5 < 10` and `<3` come out verbatim.
/// * Tags outside the supported set are dropped but their content is kept, so a
///   raw tag never reaches the screen.
/// * An unclosed tag applies through the end of the cue, and a stray closing
///   tag is ignored. Neither throws.
///
/// Chewie applies this by default when rendering cues; see
/// [ChewieController.subtitleStyle]. Call it directly to keep markup rendering
/// inside a custom [ChewieController.subtitleBuilder]:
///
/// ```dart
/// subtitleBuilder: (context, dynamic subtitle) => Container(
///   padding: const EdgeInsets.all(10),
///   child: Text.rich(
///     subtitle is String
///         ? parseSubtitleMarkup(subtitle)
///         : TextSpan(text: subtitle.toString()),
///   ),
/// ),
/// ```
TextSpan parseSubtitleMarkup(
  String cueText, {
  TextStyle style = const TextStyle(),
}) {
  final builder = _SpanBuilder(style);
  final buffer = StringBuffer();
  var i = 0;

  void flushText() {
    if (buffer.isEmpty) return;
    builder.addText(_decodeEntities(buffer.toString()));
    buffer.clear();
  }

  while (i < cueText.length) {
    final char = cueText[i];
    if (char == '<') {
      final tag = _matchTag(cueText, i);
      if (tag != null) {
        flushText();
        if (tag.isTimestamp) {
          // Karaoke-style progressive reveal needs the playhead, which the
          // renderer does not have here. Drop the tag, keep the text.
        } else if (tag.isClosing) {
          builder.close(tag.name);
        } else {
          builder.open(tag.name, _styleForTag(tag));
        }
        i = tag.end;
        continue;
      }
    }
    buffer.write(char);
    i++;
  }
  flushText();

  return builder.build();
}

/// A well-formed tag matched at some offset in the cue text.
class _Tag {
  const _Tag({
    required this.name,
    required this.attributes,
    required this.isClosing,
    required this.isTimestamp,
    required this.end,
  });

  final String name;
  final String attributes;
  final bool isClosing;
  final bool isTimestamp;

  /// Offset just past the closing `>`.
  final int end;
}

/// `<name>`, `<name attrs>` or `</name>`, all on one line — WebVTT tags never
/// span a line break, even though the content between them may.
final RegExp _tagPattern = RegExp(r'<(/?)([a-zA-Z][\w.-]*)((?:\s[^<>\n]*)?)>');

/// A WebVTT timestamp tag, e.g. `<00:00:01.000>` or `<01:23.456>`.
final RegExp _timestampPattern = RegExp(r'<(?:\d{2,}:)?\d{2}:\d{2}[.,]\d{3}>');

/// `&amp;`-style escapes, including numeric ones.
final RegExp _entityPattern = RegExp(r'&(#\d+|#[xX][0-9a-fA-F]+|\w+);');

/// `color="#rrggbb"` on a `<font>` tag, with or without quotes.
final RegExp _fontColorPattern = RegExp(
  '''color\\s*=\\s*(?:"([^"]*)"|'([^']*)'|([^\\s"'>]+))''',
  caseSensitive: false,
);

const Map<String, String> _namedEntities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'lrm': '‎',
  'rlm': '‏',
};

_Tag? _matchTag(String source, int start) {
  final timestamp = _timestampPattern.matchAsPrefix(source, start);
  if (timestamp != null) {
    return _Tag(
      name: '',
      attributes: '',
      isClosing: false,
      isTimestamp: true,
      end: timestamp.end,
    );
  }

  final match = _tagPattern.matchAsPrefix(source, start);
  if (match == null) return null;

  return _Tag(
    name: match.group(2)!.toLowerCase(),
    attributes: match.group(3) ?? '',
    isClosing: match.group(1) == '/',
    isTimestamp: false,
    end: match.end,
  );
}

/// The style a tag contributes, or `null` when it only carries structure.
///
/// Unsupported tags land here too: they are stripped without changing the
/// style, which keeps their text on screen and the tag itself off it.
TextStyle? _styleForTag(_Tag tag) {
  switch (tag.name) {
    case 'b':
      return const TextStyle(fontWeight: FontWeight.bold);
    case 'i':
      return const TextStyle(fontStyle: FontStyle.italic);
    case 'u':
      return const TextStyle(decoration: TextDecoration.underline);
    case 'font':
      final color = _parseFontColor(tag.attributes);
      return color == null ? null : TextStyle(color: color);
    default:
      return null;
  }
}

/// Reads `color="#rrggbb"` off a `<font>` tag. `#rgb`, `#rrggbb` and
/// `#aarrggbb` are accepted; anything else yields `null`, which drops the tag
/// without touching the style.
Color? _parseFontColor(String attributes) {
  final match = _fontColorPattern.firstMatch(attributes);
  if (match == null) return null;

  final value = (match.group(1) ?? match.group(2) ?? match.group(3) ?? '')
      .trim();
  if (!value.startsWith('#')) return null;

  final digits = value.substring(1);
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(digits)) return null;

  switch (digits.length) {
    case 3:
      final r = digits[0];
      final g = digits[1];
      final b = digits[2];
      return Color(int.parse('ff$r$r$g$g$b$b', radix: 16));
    case 6:
      return Color(int.parse('ff$digits', radix: 16));
    case 8:
      return Color(int.parse(digits, radix: 16));
    default:
      return null;
  }
}

/// Replaces character escapes in a run of text.
///
/// Only applied to text, never across a tag, so `&lt;b&gt;` shows the literal
/// characters `<b>` instead of turning into a bold tag.
String _decodeEntities(String text) {
  if (!text.contains('&')) return text;

  return text.replaceAllMapped(_entityPattern, (match) {
    final body = match.group(1)!;
    if (body.startsWith('#')) {
      final isHex = body[1] == 'x' || body[1] == 'X';
      final digits = isHex ? body.substring(2) : body.substring(1);
      final code = int.tryParse(digits, radix: isHex ? 16 : 10);
      if (code == null || code < 0 || code > 0x10FFFF) return match.group(0)!;
      return String.fromCharCode(code);
    }
    return _namedEntities[body.toLowerCase()] ?? match.group(0)!;
  });
}

/// Accumulates leaf spans while a stack of open tags tracks the style in
/// effect.
///
/// The result is flat: every leaf carries its own fully merged style, which
/// renders identically to a nested tree and is far easier to reason about.
class _SpanBuilder {
  _SpanBuilder(this.baseStyle) : _styles = <TextStyle>[baseStyle];

  final TextStyle baseStyle;
  final List<TextStyle> _styles;
  final List<String> _openTags = <String>[];
  final List<TextSpan> _spans = <TextSpan>[];

  void addText(String text) {
    if (text.isEmpty) return;
    _spans.add(TextSpan(text: text, style: _styles.last));
  }

  void open(String name, TextStyle? style) {
    _openTags.add(name);
    _styles.add(style == null ? _styles.last : _styles.last.merge(style));
  }

  /// Closes [name]. A tag that was never opened is ignored; a tag that was
  /// opened below others closes those too, the way browsers repair overlapping
  /// markup such as `<b><i>x</b></i>`.
  void close(String name) {
    final index = _openTags.lastIndexOf(name);
    if (index < 0) return;
    _openTags.removeRange(index, _openTags.length);
    _styles.removeRange(index + 1, _styles.length);
  }

  /// Unclosed tags need no unwinding: their style simply applied to every leaf
  /// added while they were open.
  TextSpan build() => TextSpan(style: baseStyle, children: _spans);
}
