import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('ExternalSubtitleTrack', () {
    test('creates with required parameters', () {
      const track = ExternalSubtitleTrack(
        id: 'ext-1',
        label: 'English',
        path: 'https://example.com/subtitles.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
      );

      expect(track.id, equals('ext-1'));
      expect(track.label, equals('English'));
      expect(track.path, equals('https://example.com/subtitles.srt'));
      expect(track.sourceType, equals('network'));
      expect(track.format, equals(SubtitleFormat.srt));
      expect(track.language, isNull);
      expect(track.isDefault, isFalse);
      expect(track.cues, isNull);
    });

    test('creates with all parameters', () {
      const cues = [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello')];
      const track = ExternalSubtitleTrack(
        id: 'ext-1',
        label: 'English (CC)',
        path: 'https://example.com/subtitles.vtt',
        sourceType: 'network',
        format: SubtitleFormat.vtt,
        language: 'en',
        isDefault: true,
        cues: cues,
      );

      expect(track.id, equals('ext-1'));
      expect(track.label, equals('English (CC)'));
      expect(track.path, equals('https://example.com/subtitles.vtt'));
      expect(track.sourceType, equals('network'));
      expect(track.format, equals(SubtitleFormat.vtt));
      expect(track.language, equals('en'));
      expect(track.isDefault, isTrue);
      expect(track.cues, equals(cues));
    });

    test('creates file source type', () {
      const track = ExternalSubtitleTrack(
        id: 'ext-file-1',
        label: 'Local Subtitles',
        path: '/path/to/subtitles.srt',
        sourceType: 'file',
        format: SubtitleFormat.srt,
      );

      expect(track.path, equals('/path/to/subtitles.srt'));
      expect(track.sourceType, equals('file'));
    });

    test('creates asset source type', () {
      const track = ExternalSubtitleTrack(
        id: 'ext-asset-1',
        label: 'Asset Subtitles',
        path: 'assets/subtitles/english.vtt',
        sourceType: 'asset',
        format: SubtitleFormat.vtt,
      );

      expect(track.path, equals('assets/subtitles/english.vtt'));
      expect(track.sourceType, equals('asset'));
    });

    test('is a SubtitleTrack', () {
      const track = ExternalSubtitleTrack(
        id: 'ext-1',
        label: 'English',
        path: 'https://example.com/subtitles.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
      );

      expect(track, isA<SubtitleTrack>());
    });

    group('isExternal', () {
      test('returns true for ExternalSubtitleTrack', () {
        const track = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subtitles.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
        );

        expect(track.isExternal, isTrue);
      });
    });

    group('copyWithCues', () {
      test('creates new instance with cues', () {
        const original = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subtitles.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
        );

        const cues = [
          SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello'),
          SubtitleCue(index: 2, start: Duration(seconds: 6), end: Duration(seconds: 10), text: 'World'),
        ];

        final withCues = original.copyWithCues(cues);

        expect(withCues.id, equals(original.id));
        expect(withCues.label, equals(original.label));
        expect(withCues.path, equals(original.path));
        expect(withCues.sourceType, equals(original.sourceType));
        expect(withCues.format, equals(original.format));
        expect(withCues.language, equals(original.language));
        expect(withCues.cues, equals(cues));
      });
    });

    group('equality', () {
      test('equal tracks are equal', () {
        const track1 = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subtitles.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
        );
        const track2 = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subtitles.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
        );

        expect(track1, equals(track2));
      });

      test('tracks with different path are not equal', () {
        const track1 = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subtitles1.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
        );
        const track2 = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subtitles2.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
        );

        expect(track1, isNot(equals(track2)));
      });

      test('tracks with different sourceType are not equal', () {
        const track1 = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: '/path/to/subtitles.srt',
          sourceType: 'file',
          format: SubtitleFormat.srt,
        );
        const track2 = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: '/path/to/subtitles.srt',
          sourceType: 'asset',
          format: SubtitleFormat.srt,
        );

        expect(track1, isNot(equals(track2)));
      });

      test('tracks with different format are not equal', () {
        const track1 = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subtitles.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
        );
        const track2 = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subtitles.srt',
          sourceType: 'network',
          format: SubtitleFormat.vtt,
        );

        expect(track1, isNot(equals(track2)));
      });

      test('ExternalSubtitleTrack is not equal to regular SubtitleTrack with same id', () {
        const external = ExternalSubtitleTrack(
          id: 'track-1',
          label: 'English',
          path: 'https://example.com/subtitles.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
        );
        const embedded = SubtitleTrack(id: 'track-1', label: 'English');

        expect(external, isNot(equals(embedded)));
      });
    });

    test('hashCode is consistent with equality', () {
      const track1 = ExternalSubtitleTrack(
        id: 'ext-1',
        label: 'English',
        path: 'https://example.com/subtitles.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
      );
      const track2 = ExternalSubtitleTrack(
        id: 'ext-1',
        label: 'English',
        path: 'https://example.com/subtitles.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
      );

      expect(track1.hashCode, equals(track2.hashCode));
    });

    test('toString returns readable representation', () {
      const track = ExternalSubtitleTrack(
        id: 'ext-1',
        label: 'English',
        path: 'https://example.com/subtitles.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
      );

      final str = track.toString();
      expect(str, contains('ExternalSubtitleTrack'));
      expect(str, contains('ext-1'));
      expect(str, contains('English'));
      expect(str, contains('srt'));
    });
  });

  group('SubtitleTrack.isExternal extension', () {
    test('returns false for regular SubtitleTrack', () {
      const track = SubtitleTrack(id: 'emb-1', label: 'English');
      expect(track.isExternal, isFalse);
    });

    test('returns true for ExternalSubtitleTrack', () {
      const track = ExternalSubtitleTrack(
        id: 'ext-1',
        label: 'English',
        path: 'https://example.com/subtitles.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
      );
      expect(track.isExternal, isTrue);
    });
  });
}
