import 'package:chewie/src/subtitle_markup.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The text a viewer would actually read.
String plainText(TextSpan span) => span.toPlainText();

/// The style in effect over [needle], which must appear in exactly one leaf.
TextStyle styleOf(TextSpan span, String needle) {
  final matches = span.children!
      .cast<TextSpan>()
      .where((child) => child.text!.contains(needle))
      .toList();
  expect(
    matches,
    hasLength(1),
    reason: 'expected exactly one leaf containing "$needle"',
  );
  return matches.single.style!;
}

void main() {
  group('parseSubtitleMarkup', () {
    const base = TextStyle(fontSize: 18);

    test('passes tagless text through unchanged', () {
      final span = parseSubtitleMarkup(
        'Tu comprends ce qu\'ils disent ?',
        style: base,
      );

      expect(plainText(span), "Tu comprends ce qu'ils disent ?");
      expect(span.children, hasLength(1));
      expect(span.children!.first.style, base);
    });

    test('renders an empty cue without children', () {
      expect(plainText(parseSubtitleMarkup('')), '');
    });

    test('applies <i>', () {
      final span = parseSubtitleMarkup(
        '<i>La loi est la loi, M. Hancock.</i>',
        style: base,
      );

      expect(plainText(span), 'La loi est la loi, M. Hancock.');
      expect(styleOf(span, 'La loi').fontStyle, FontStyle.italic);
    });

    test('applies <b>', () {
      final span = parseSubtitleMarkup('<b>loud</b>', style: base);

      expect(plainText(span), 'loud');
      expect(styleOf(span, 'loud').fontWeight, FontWeight.bold);
    });

    test('applies <u>', () {
      final span = parseSubtitleMarkup('<u>title</u>', style: base);

      expect(plainText(span), 'title');
      expect(styleOf(span, 'title').decoration, TextDecoration.underline);
    });

    test('is case insensitive about tag names', () {
      final span = parseSubtitleMarkup('<I>oui</I>', style: base);

      expect(plainText(span), 'oui');
      expect(styleOf(span, 'oui').fontStyle, FontStyle.italic);
    });

    test('merges nested tags', () {
      final span = parseSubtitleMarkup('<b><i>both</i></b>', style: base);

      final style = styleOf(span, 'both');
      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontStyle, FontStyle.italic);
    });

    test('restores the outer style after a nested tag closes', () {
      final span = parseSubtitleMarkup(
        'plain <i>italic</i> plain again',
        style: base,
      );

      expect(plainText(span), 'plain italic plain again');
      expect(styleOf(span, 'italic').fontStyle, FontStyle.italic);
      expect(styleOf(span, 'plain again').fontStyle, isNull);
    });

    test('merges tag styles onto the caller style instead of replacing it', () {
      final span = parseSubtitleMarkup(
        '<b>x</b>',
        style: const TextStyle(fontSize: 20, color: Color(0xFF0000FF)),
      );

      final style = styleOf(span, 'x');
      expect(style.fontSize, 20);
      expect(style.color, const Color(0xFF0000FF));
      expect(style.fontWeight, FontWeight.bold);
    });

    test('keeps a tag styled across a line break inside one cue', () {
      final span = parseSubtitleMarkup(
        '<i>un paquet de muscles\nqui ne pense qu\'à lui.</i>',
        style: base,
      );

      expect(plainText(span), "un paquet de muscles\nqui ne pense qu'à lui.");
      expect(span.children, hasLength(1));
      expect(styleOf(span, 'paquet').fontStyle, FontStyle.italic);
    });

    group('<font color>', () {
      test('applies a #rrggbb colour', () {
        final span = parseSubtitleMarkup(
          '<font color="#ff0000">red</font>',
          style: base,
        );

        expect(plainText(span), 'red');
        expect(styleOf(span, 'red').color, const Color(0xFFFF0000));
      });

      test('applies a #rgb colour', () {
        final span = parseSubtitleMarkup(
          '<font color="#f00">red</font>',
          style: base,
        );

        expect(styleOf(span, 'red').color, const Color(0xFFFF0000));
      });

      test('applies an #aarrggbb colour', () {
        final span = parseSubtitleMarkup(
          '<font color="#80ff0000">red</font>',
          style: base,
        );

        expect(styleOf(span, 'red').color, const Color(0x80FF0000));
      });

      test('accepts an unquoted colour', () {
        final span = parseSubtitleMarkup(
          '<font color=#00ff00>green</font>',
          style: base,
        );

        expect(styleOf(span, 'green').color, const Color(0xFF00FF00));
      });

      test('drops the tag but keeps the text when the colour is unusable', () {
        final span = parseSubtitleMarkup(
          '<font color="chartreuse">x</font>',
          style: base,
        );

        expect(plainText(span), 'x');
        expect(styleOf(span, 'x').color, isNull);
      });

      test('drops a <font> tag carrying no colour at all', () {
        final span = parseSubtitleMarkup('<font face="Arial">x</font>');

        expect(plainText(span), 'x');
      });
    });

    group('structural WebVTT tags', () {
      test('keeps the text of a voice span', () {
        final span = parseSubtitleMarkup('<v Roger Bingham>Hello</v>');

        expect(plainText(span), 'Hello');
      });

      test('keeps the text of a class span', () {
        expect(plainText(parseSubtitleMarkup('<c.loud>shout</c>')), 'shout');
      });

      test('keeps the text of a language span', () {
        expect(
          plainText(parseSubtitleMarkup('<lang fr>bonjour</lang>')),
          'bonjour',
        );
      });

      test('keeps the text of a ruby annotation', () {
        expect(
          plainText(parseSubtitleMarkup('<ruby>base<rt>ann</rt></ruby>')),
          'baseann',
        );
      });

      test('drops timestamp tags', () {
        expect(
          plainText(parseSubtitleMarkup('<00:00:01.000>now<01:23.456>later')),
          'nowlater',
        );
      });

      test('drops an unknown tag but keeps its content', () {
        expect(plainText(parseSubtitleMarkup('<blink>x</blink>')), 'x');
      });
    });

    group('character escapes', () {
      test('decodes the named escapes', () {
        expect(plainText(parseSubtitleMarkup('&amp;')), '&');
        expect(plainText(parseSubtitleMarkup('&lt;')), '<');
        expect(plainText(parseSubtitleMarkup('&gt;')), '>');
        expect(plainText(parseSubtitleMarkup('a&nbsp;b')), 'a b');
        expect(plainText(parseSubtitleMarkup('&lrm;')), '‎');
        expect(plainText(parseSubtitleMarkup('&rlm;')), '‏');
      });

      test('decodes numeric escapes', () {
        expect(plainText(parseSubtitleMarkup('&#233;')), 'é');
        expect(plainText(parseSubtitleMarkup('&#xE9;')), 'é');
      });

      test('shows an escaped tag as literal characters', () {
        final span = parseSubtitleMarkup('&lt;i&gt;x&lt;/i&gt;', style: base);

        expect(plainText(span), '<i>x</i>');
        expect(styleOf(span, 'x').fontStyle, isNull);
      });

      test('leaves an unknown escape alone', () {
        expect(plainText(parseSubtitleMarkup('&fnord;')), '&fnord;');
      });

      test('leaves a bare ampersand alone', () {
        expect(plainText(parseSubtitleMarkup('Smith & Sons')), 'Smith & Sons');
      });
    });

    group('leniency', () {
      test('leaves a less-than sign that is not a tag', () {
        expect(plainText(parseSubtitleMarkup('5 < 10')), '5 < 10');
      });

      test('leaves an emoticon alone', () {
        expect(plainText(parseSubtitleMarkup('<3')), '<3');
      });

      test('leaves a trailing less-than sign alone', () {
        expect(plainText(parseSubtitleMarkup('what <')), 'what <');
      });

      test('leaves an unterminated tag alone', () {
        expect(
          plainText(parseSubtitleMarkup('<i not closed')),
          '<i not closed',
        );
      });

      test('applies an unclosed tag through the end of the cue', () {
        final span = parseSubtitleMarkup('<i>runs to the end', style: base);

        expect(plainText(span), 'runs to the end');
        expect(styleOf(span, 'runs').fontStyle, FontStyle.italic);
      });

      test('ignores a closing tag that was never opened', () {
        final span = parseSubtitleMarkup('</i>plain', style: base);

        expect(plainText(span), 'plain');
        expect(styleOf(span, 'plain').fontStyle, isNull);
      });

      test('repairs overlapping tags without dropping text', () {
        final span = parseSubtitleMarkup('<b>bold <i>both</b> tail</i>');

        expect(plainText(span), 'bold both tail');
        expect(styleOf(span, 'both').fontWeight, FontWeight.bold);
        expect(styleOf(span, 'both').fontStyle, FontStyle.italic);
        expect(styleOf(span, 'tail').fontWeight, isNull);
      });
    });
  });
}
