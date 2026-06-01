import 'package:chewie/src/models/subtitle_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubtitleTrack', () {
    test('exposes the values it was constructed with', () {
      const track = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      expect(track.id, 'en');
      expect(track.label, 'English');
      expect(track.language, 'en');
    });

    test('language is optional', () {
      const track = SubtitleTrack(id: 1, label: 'Track 1');
      expect(track.language, isNull);
    });

    test('value equality compares id, label and language', () {
      const a = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      const b = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      const differentId = SubtitleTrack(
        id: 'fr',
        label: 'English',
        language: 'en',
      );
      const differentLabel = SubtitleTrack(
        id: 'en',
        label: 'Anglais',
        language: 'en',
      );
      const differentLanguage = SubtitleTrack(
        id: 'en',
        label: 'English',
        language: 'gb',
      );

      expect(a, equals(b));
      expect(a == differentId, isFalse);
      expect(a == differentLabel, isFalse);
      expect(a == differentLanguage, isFalse);
      expect(a == Object(), isFalse);
    });

    test('hashCode is consistent with equality', () {
      const a = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      const b = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes the fields', () {
      const track = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      expect(
        track.toString(),
        'SubtitleTrack(id: en, label: English, language: en)',
      );
    });
  });
}
