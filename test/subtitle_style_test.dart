import 'package:chewie/src/models/subtitle_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubtitleStyle', () {
    test('defaults match the box chewie has always drawn', () {
      const style = SubtitleStyle();

      expect(style.textStyle, const TextStyle(fontSize: 18));
      expect(style.textStyle.color, isNull, reason: 'colour is inherited');
      expect(style.textAlign, TextAlign.center);
      expect(style.padding, const EdgeInsets.all(5));
      expect(
        style.decoration,
        const BoxDecoration(
          color: Color(0x96000000),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      );
      expect(style.renderMarkup, isTrue);
    });

    test('copyWith replaces only what it is given', () {
      const style = SubtitleStyle();
      final updated = style.copyWith(textAlign: TextAlign.left);

      expect(updated.textAlign, TextAlign.left);
      expect(updated.textStyle, style.textStyle);
      expect(updated.padding, style.padding);
      expect(updated.decoration, style.decoration);
      expect(updated.renderMarkup, style.renderMarkup);
    });

    test('copyWith can turn markup rendering off', () {
      expect(
        const SubtitleStyle().copyWith(renderMarkup: false).renderMarkup,
        isFalse,
      );
    });

    test('value equality compares every field', () {
      const a = SubtitleStyle();
      const b = SubtitleStyle();

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(renderMarkup: false), isFalse);
      expect(a == a.copyWith(padding: EdgeInsets.zero), isFalse);
      expect(
        a == a.copyWith(textStyle: const TextStyle(fontSize: 30)),
        isFalse,
      );
    });

    test('toString includes the fields', () {
      final description = const SubtitleStyle().toString();

      expect(description, startsWith('SubtitleStyle('));
      expect(description, contains('renderMarkup: true'));
      expect(description, contains('textAlign: TextAlign.center'));
    });
  });
}
