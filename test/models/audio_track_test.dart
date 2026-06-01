import 'package:chewie/chewie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioTrack equality', () {
    test('two tracks with the same id, label and language are equal', () {
      const a = AudioTrack(id: '0', label: 'English', language: 'en');
      const b = AudioTrack(id: '0', label: 'English', language: 'en');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('tracks differing in id are not equal', () {
      const a = AudioTrack(id: '0', label: 'English', language: 'en');
      const b = AudioTrack(id: '1', label: 'English', language: 'en');
      expect(a, isNot(equals(b)));
    });

    test('tracks differing in label are not equal', () {
      const a = AudioTrack(id: '0', label: 'English', language: 'en');
      const b = AudioTrack(id: '0', label: 'Anglais', language: 'en');
      expect(a, isNot(equals(b)));
    });

    test('tracks differing in language are not equal', () {
      const a = AudioTrack(id: '0', label: 'English', language: 'en');
      const b = AudioTrack(id: '0', label: 'English', language: 'fr');
      expect(a, isNot(equals(b)));
    });

    test('an AudioTrack is not equal to another type', () {
      const a = AudioTrack(id: '0', label: 'English');
      expect(a == Object(), isFalse);
    });

    test('the id may be any Object, not just a String', () {
      const a = AudioTrack(id: 0, label: 'English');
      const b = AudioTrack(id: 0, label: 'English');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  test('language is optional and defaults to null', () {
    const track = AudioTrack(id: '0', label: 'English');
    expect(track.language, isNull);
  });

  test('toString lists the fields', () {
    const track = AudioTrack(id: '0', label: 'English', language: 'en');
    expect(track.toString(), 'AudioTrack(id: 0, label: English, language: en)');
  });
}
