import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('Chapter', () {
    test('creates with required parameters', () {
      const chapter = Chapter(id: 'chap-0', title: 'Introduction', startTime: Duration.zero);

      expect(chapter.id, equals('chap-0'));
      expect(chapter.title, equals('Introduction'));
      expect(chapter.startTime, equals(Duration.zero));
      expect(chapter.endTime, isNull);
      expect(chapter.thumbnailUrl, isNull);
    });

    test('creates with all parameters', () {
      const chapter = Chapter(
        id: 'chap-1',
        title: 'Chapter 1: Getting Started',
        startTime: Duration(minutes: 1, seconds: 30),
        endTime: Duration(minutes: 5),
        thumbnailUrl: 'https://example.com/thumb1.jpg',
      );

      expect(chapter.id, equals('chap-1'));
      expect(chapter.title, equals('Chapter 1: Getting Started'));
      expect(chapter.startTime, equals(const Duration(minutes: 1, seconds: 30)));
      expect(chapter.endTime, equals(const Duration(minutes: 5)));
      expect(chapter.thumbnailUrl, equals('https://example.com/thumb1.jpg'));
    });

    group('duration', () {
      test('returns null when endTime is null', () {
        const chapter = Chapter(id: 'chap-0', title: 'Test', startTime: Duration(seconds: 10));

        expect(chapter.duration, isNull);
      });

      test('returns difference between end and start', () {
        const chapter = Chapter(
          id: 'chap-0',
          title: 'Test',
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 60),
        );

        expect(chapter.duration, equals(const Duration(seconds: 50)));
      });

      test('handles milliseconds', () {
        const chapter = Chapter(
          id: 'chap-0',
          title: 'Test',
          startTime: Duration(minutes: 1, seconds: 30, milliseconds: 500),
          endTime: Duration(minutes: 2, seconds: 15, milliseconds: 200),
        );

        expect(chapter.duration, equals(const Duration(seconds: 44, milliseconds: 700)));
      });
    });

    group('isActiveAt', () {
      const chapter = Chapter(
        id: 'chap-0',
        title: 'Test',
        startTime: Duration(seconds: 10),
        endTime: Duration(seconds: 60),
      );

      test('returns false before start time', () {
        expect(chapter.isActiveAt(const Duration(seconds: 5)), isFalse);
        expect(chapter.isActiveAt(const Duration(seconds: 9, milliseconds: 999)), isFalse);
      });

      test('returns true at start time', () {
        expect(chapter.isActiveAt(const Duration(seconds: 10)), isTrue);
      });

      test('returns true during chapter', () {
        expect(chapter.isActiveAt(const Duration(seconds: 30)), isTrue);
        expect(chapter.isActiveAt(const Duration(seconds: 59, milliseconds: 999)), isTrue);
      });

      test('returns false at end time (exclusive)', () {
        expect(chapter.isActiveAt(const Duration(seconds: 60)), isFalse);
      });

      test('returns false after end time', () {
        expect(chapter.isActiveAt(const Duration(seconds: 120)), isFalse);
      });

      test('returns true when endTime is null and position >= startTime', () {
        const chapterNoEnd = Chapter(id: 'chap-0', title: 'Test', startTime: Duration(seconds: 10));

        expect(chapterNoEnd.isActiveAt(const Duration(seconds: 10)), isTrue);
        expect(chapterNoEnd.isActiveAt(const Duration(seconds: 1000)), isTrue);
        expect(chapterNoEnd.isActiveAt(const Duration(seconds: 5)), isFalse);
      });
    });

    group('equality', () {
      test('equal chapters are equal', () {
        const chapter1 = Chapter(
          id: 'chap-0',
          title: 'Introduction',
          startTime: Duration.zero,
          endTime: Duration(seconds: 60),
          thumbnailUrl: 'https://example.com/thumb.jpg',
        );
        const chapter2 = Chapter(
          id: 'chap-0',
          title: 'Introduction',
          startTime: Duration.zero,
          endTime: Duration(seconds: 60),
          thumbnailUrl: 'https://example.com/thumb.jpg',
        );

        expect(chapter1, equals(chapter2));
      });

      test('chapters with different id are not equal', () {
        const chapter1 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero);
        const chapter2 = Chapter(id: 'chap-1', title: 'Test', startTime: Duration.zero);

        expect(chapter1, isNot(equals(chapter2)));
      });

      test('chapters with different title are not equal', () {
        const chapter1 = Chapter(id: 'chap-0', title: 'Title 1', startTime: Duration.zero);
        const chapter2 = Chapter(id: 'chap-0', title: 'Title 2', startTime: Duration.zero);

        expect(chapter1, isNot(equals(chapter2)));
      });

      test('chapters with different startTime are not equal', () {
        const chapter1 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero);
        const chapter2 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration(seconds: 10));

        expect(chapter1, isNot(equals(chapter2)));
      });

      test('chapters with different endTime are not equal', () {
        const chapter1 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero, endTime: Duration(seconds: 30));
        const chapter2 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero, endTime: Duration(seconds: 60));

        expect(chapter1, isNot(equals(chapter2)));
      });

      test('chapters with different thumbnailUrl are not equal', () {
        const chapter1 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero, thumbnailUrl: 'url1');
        const chapter2 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero, thumbnailUrl: 'url2');

        expect(chapter1, isNot(equals(chapter2)));
      });

      test('chapter with null vs non-null optional fields are not equal', () {
        const chapter1 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero);
        const chapter2 = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero, endTime: Duration(seconds: 30));

        expect(chapter1, isNot(equals(chapter2)));
      });
    });

    test('hashCode is consistent with equality', () {
      const chapter1 = Chapter(
        id: 'chap-0',
        title: 'Introduction',
        startTime: Duration.zero,
        endTime: Duration(seconds: 60),
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );
      const chapter2 = Chapter(
        id: 'chap-0',
        title: 'Introduction',
        startTime: Duration.zero,
        endTime: Duration(seconds: 60),
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );

      expect(chapter1.hashCode, equals(chapter2.hashCode));
    });

    test('toString returns readable representation', () {
      const chapter = Chapter(
        id: 'chap-0',
        title: 'Introduction',
        startTime: Duration(seconds: 30),
        endTime: Duration(seconds: 90),
      );

      final str = chapter.toString();
      expect(str, contains('Chapter'));
      expect(str, contains('chap-0'));
      expect(str, contains('Introduction'));
      expect(str, contains('30'));
    });

    group('copyWith', () {
      const original = Chapter(
        id: 'chap-0',
        title: 'Original Title',
        startTime: Duration(seconds: 10),
        endTime: Duration(seconds: 60),
        thumbnailUrl: 'https://example.com/original.jpg',
      );

      test('creates copy with same values when no arguments provided', () {
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('updates id', () {
        final copy = original.copyWith(id: 'chap-1');
        expect(copy.id, equals('chap-1'));
        expect(copy.title, equals(original.title));
      });

      test('updates title', () {
        final copy = original.copyWith(title: 'New Title');
        expect(copy.title, equals('New Title'));
        expect(copy.id, equals(original.id));
      });

      test('updates startTime', () {
        final copy = original.copyWith(startTime: const Duration(seconds: 20));
        expect(copy.startTime, equals(const Duration(seconds: 20)));
      });

      test('updates endTime', () {
        final copy = original.copyWith(endTime: const Duration(seconds: 120));
        expect(copy.endTime, equals(const Duration(seconds: 120)));
      });

      test('updates thumbnailUrl', () {
        final copy = original.copyWith(thumbnailUrl: 'https://example.com/new.jpg');
        expect(copy.thumbnailUrl, equals('https://example.com/new.jpg'));
      });

      test('clears endTime with clearEndTime', () {
        final copy = original.copyWith(clearEndTime: true);
        expect(copy.endTime, isNull);
      });

      test('clears thumbnailUrl with clearThumbnailUrl', () {
        final copy = original.copyWith(clearThumbnailUrl: true);
        expect(copy.thumbnailUrl, isNull);
      });
    });

    group('toMap and fromMap', () {
      test('round-trips correctly with all fields', () {
        const original = Chapter(
          id: 'chap-1',
          title: 'Chapter 1: Getting Started',
          startTime: Duration(minutes: 1, seconds: 30, milliseconds: 500),
          endTime: Duration(minutes: 5, milliseconds: 250),
          thumbnailUrl: 'https://example.com/thumb1.jpg',
        );

        final map = original.toMap();
        final restored = Chapter.fromMap(map);

        expect(restored, equals(original));
      });

      test('round-trips correctly with required fields only', () {
        const original = Chapter(id: 'chap-0', title: 'Introduction', startTime: Duration.zero);

        final map = original.toMap();
        final restored = Chapter.fromMap(map);

        expect(restored, equals(original));
      });

      test('toMap produces expected keys', () {
        const chapter = Chapter(
          id: 'chap-0',
          title: 'Test Chapter',
          startTime: Duration(seconds: 30),
          endTime: Duration(minutes: 2),
          thumbnailUrl: 'https://example.com/thumb.jpg',
        );

        final map = chapter.toMap();
        expect(map, containsPair('id', 'chap-0'));
        expect(map, containsPair('title', 'Test Chapter'));
        expect(map, containsPair('startTimeMs', 30000));
        expect(map, containsPair('endTimeMs', 120000));
        expect(map, containsPair('thumbnailUrl', 'https://example.com/thumb.jpg'));
      });

      test('toMap omits null values', () {
        const chapter = Chapter(id: 'chap-0', title: 'Test', startTime: Duration.zero);

        final map = chapter.toMap();
        expect(map.containsKey('endTimeMs'), isFalse);
        expect(map.containsKey('thumbnailUrl'), isFalse);
      });

      test('fromMap handles null optional fields', () {
        final map = {'id': 'chap-0', 'title': 'Test', 'startTimeMs': 10000};

        final chapter = Chapter.fromMap(map);
        expect(chapter.id, equals('chap-0'));
        expect(chapter.title, equals('Test'));
        expect(chapter.startTime, equals(const Duration(seconds: 10)));
        expect(chapter.endTime, isNull);
        expect(chapter.thumbnailUrl, isNull);
      });

      test('fromMap handles dynamic map types', () {
        final map = <dynamic, dynamic>{
          'id': 'chap-0',
          'title': 'Test',
          'startTimeMs': 5000,
          'endTimeMs': 10000,
          'thumbnailUrl': 'https://example.com/thumb.jpg',
        };

        final chapter = Chapter.fromMap(map);
        expect(chapter.id, equals('chap-0'));
        expect(chapter.title, equals('Test'));
        expect(chapter.startTime, equals(const Duration(seconds: 5)));
        expect(chapter.endTime, equals(const Duration(seconds: 10)));
        expect(chapter.thumbnailUrl, equals('https://example.com/thumb.jpg'));
      });
    });

    group('formattedStartTime', () {
      test('formats seconds correctly', () {
        const chapter = Chapter(id: '0', title: 'Test', startTime: Duration(seconds: 45));
        expect(chapter.formattedStartTime, equals('0:45'));
      });

      test('formats minutes and seconds correctly', () {
        const chapter = Chapter(id: '0', title: 'Test', startTime: Duration(minutes: 3, seconds: 15));
        expect(chapter.formattedStartTime, equals('3:15'));
      });

      test('formats hours correctly', () {
        const chapter = Chapter(id: '0', title: 'Test', startTime: Duration(hours: 1, minutes: 30, seconds: 5));
        expect(chapter.formattedStartTime, equals('1:30:05'));
      });

      test('pads seconds with zero', () {
        const chapter = Chapter(id: '0', title: 'Test', startTime: Duration(minutes: 5, seconds: 3));
        expect(chapter.formattedStartTime, equals('5:03'));
      });

      test('pads minutes with zero when hours present', () {
        const chapter = Chapter(id: '0', title: 'Test', startTime: Duration(hours: 2, minutes: 5, seconds: 30));
        expect(chapter.formattedStartTime, equals('2:05:30'));
      });
    });
  });
}
