import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('SubtitleCue', () {
    test('creates with required parameters', () {
      const cue = SubtitleCue(start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello, world!');

      expect(cue.start, equals(const Duration(seconds: 1)));
      expect(cue.end, equals(const Duration(seconds: 5)));
      expect(cue.text, equals('Hello, world!'));
      expect(cue.index, isNull);
    });

    test('creates with optional index', () {
      const cue = SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello, world!');

      expect(cue.index, equals(1));
    });

    test('duration returns difference between end and start', () {
      const cue = SubtitleCue(start: Duration(seconds: 10), end: Duration(seconds: 15), text: 'Test');

      expect(cue.duration, equals(const Duration(seconds: 5)));
    });

    test('duration handles milliseconds', () {
      const cue = SubtitleCue(
        start: Duration(minutes: 1, seconds: 30, milliseconds: 500),
        end: Duration(minutes: 1, seconds: 33, milliseconds: 200),
        text: 'Test',
      );

      expect(cue.duration, equals(const Duration(seconds: 2, milliseconds: 700)));
    });

    group('isActiveAt', () {
      const cue = SubtitleCue(start: Duration(seconds: 10), end: Duration(seconds: 15), text: 'Test');

      test('returns false before start time', () {
        expect(cue.isActiveAt(const Duration(seconds: 5)), isFalse);
        expect(cue.isActiveAt(const Duration(seconds: 9, milliseconds: 999)), isFalse);
      });

      test('returns true at start time', () {
        expect(cue.isActiveAt(const Duration(seconds: 10)), isTrue);
      });

      test('returns true during cue', () {
        expect(cue.isActiveAt(const Duration(seconds: 12)), isTrue);
        expect(cue.isActiveAt(const Duration(seconds: 14, milliseconds: 999)), isTrue);
      });

      test('returns false at end time (exclusive)', () {
        expect(cue.isActiveAt(const Duration(seconds: 15)), isFalse);
      });

      test('returns false after end time', () {
        expect(cue.isActiveAt(const Duration(seconds: 20)), isFalse);
      });
    });

    group('equality', () {
      test('equal cues are equal', () {
        const cue1 = SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');
        const cue2 = SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');

        expect(cue1, equals(cue2));
      });

      test('cues with different index are not equal', () {
        const cue1 = SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');
        const cue2 = SubtitleCue(index: 2, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');

        expect(cue1, isNot(equals(cue2)));
      });

      test('cues with different start are not equal', () {
        const cue1 = SubtitleCue(start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');
        const cue2 = SubtitleCue(start: Duration(seconds: 2), end: Duration(seconds: 5), text: 'Hello');

        expect(cue1, isNot(equals(cue2)));
      });

      test('cues with different end are not equal', () {
        const cue1 = SubtitleCue(start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');
        const cue2 = SubtitleCue(start: Duration(seconds: 1), end: Duration(seconds: 6), text: 'Hello');

        expect(cue1, isNot(equals(cue2)));
      });

      test('cues with different text are not equal', () {
        const cue1 = SubtitleCue(start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');
        const cue2 = SubtitleCue(start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Goodbye');

        expect(cue1, isNot(equals(cue2)));
      });
    });

    test('hashCode is consistent with equality', () {
      const cue1 = SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');
      const cue2 = SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');

      expect(cue1.hashCode, equals(cue2.hashCode));
    });

    test('toString returns readable representation', () {
      const cue = SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello');

      final str = cue.toString();
      expect(str, contains('SubtitleCue'));
      expect(str, contains('1'));
      expect(str, contains('Hello'));
    });

    group('toMap and fromMap', () {
      test('round-trips correctly', () {
        const original = SubtitleCue(
          index: 42,
          start: Duration(minutes: 1, seconds: 30, milliseconds: 500),
          end: Duration(minutes: 1, seconds: 35, milliseconds: 250),
          text: 'Multi-line\nsubtitle text',
        );

        final map = original.toMap();
        final restored = SubtitleCue.fromMap(map);

        expect(restored, equals(original));
      });

      test('toMap produces expected keys', () {
        const cue = SubtitleCue(index: 1, start: Duration(seconds: 10), end: Duration(seconds: 15), text: 'Test');

        final map = cue.toMap();
        expect(map, containsPair('index', 1));
        expect(map, containsPair('startMs', 10000));
        expect(map, containsPair('endMs', 15000));
        expect(map, containsPair('text', 'Test'));
      });

      test('fromMap handles null index', () {
        final map = {'startMs': 1000, 'endMs': 5000, 'text': 'Hello'};

        final cue = SubtitleCue.fromMap(map);
        expect(cue.index, isNull);
        expect(cue.start, equals(const Duration(seconds: 1)));
        expect(cue.end, equals(const Duration(seconds: 5)));
        expect(cue.text, equals('Hello'));
      });
    });
  });
}
