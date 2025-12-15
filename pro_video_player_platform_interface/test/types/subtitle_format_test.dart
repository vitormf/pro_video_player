import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('SubtitleFormat', () {
    test('has all expected values', () {
      expect(SubtitleFormat.values, hasLength(5));
      expect(SubtitleFormat.values, contains(SubtitleFormat.srt));
      expect(SubtitleFormat.values, contains(SubtitleFormat.vtt));
      expect(SubtitleFormat.values, contains(SubtitleFormat.ssa));
      expect(SubtitleFormat.values, contains(SubtitleFormat.ass));
      expect(SubtitleFormat.values, contains(SubtitleFormat.ttml));
    });

    group('fromFileExtension', () {
      test('detects SRT format', () {
        expect(SubtitleFormat.fromFileExtension('.srt'), equals(SubtitleFormat.srt));
        expect(SubtitleFormat.fromFileExtension('.SRT'), equals(SubtitleFormat.srt));
        expect(SubtitleFormat.fromFileExtension('srt'), equals(SubtitleFormat.srt));
      });

      test('detects VTT format', () {
        expect(SubtitleFormat.fromFileExtension('.vtt'), equals(SubtitleFormat.vtt));
        expect(SubtitleFormat.fromFileExtension('.VTT'), equals(SubtitleFormat.vtt));
        expect(SubtitleFormat.fromFileExtension('vtt'), equals(SubtitleFormat.vtt));
      });

      test('detects SSA format', () {
        expect(SubtitleFormat.fromFileExtension('.ssa'), equals(SubtitleFormat.ssa));
        expect(SubtitleFormat.fromFileExtension('.SSA'), equals(SubtitleFormat.ssa));
        expect(SubtitleFormat.fromFileExtension('ssa'), equals(SubtitleFormat.ssa));
      });

      test('detects ASS format', () {
        expect(SubtitleFormat.fromFileExtension('.ass'), equals(SubtitleFormat.ass));
        expect(SubtitleFormat.fromFileExtension('.ASS'), equals(SubtitleFormat.ass));
        expect(SubtitleFormat.fromFileExtension('ass'), equals(SubtitleFormat.ass));
      });

      test('detects TTML format', () {
        expect(SubtitleFormat.fromFileExtension('.ttml'), equals(SubtitleFormat.ttml));
        expect(SubtitleFormat.fromFileExtension('.TTML'), equals(SubtitleFormat.ttml));
        expect(SubtitleFormat.fromFileExtension('ttml'), equals(SubtitleFormat.ttml));
      });

      test('returns null for unknown extensions', () {
        expect(SubtitleFormat.fromFileExtension('.mp4'), isNull);
        expect(SubtitleFormat.fromFileExtension('.txt'), isNull);
        expect(SubtitleFormat.fromFileExtension(''), isNull);
      });
    });

    group('fromUrl', () {
      test('detects format from URL path', () {
        expect(SubtitleFormat.fromUrl('https://example.com/subtitles/english.srt'), equals(SubtitleFormat.srt));
        expect(SubtitleFormat.fromUrl('https://example.com/subtitles/english.vtt'), equals(SubtitleFormat.vtt));
        expect(SubtitleFormat.fromUrl('https://example.com/subtitles/english.ass'), equals(SubtitleFormat.ass));
      });

      test('ignores query parameters when detecting format', () {
        expect(SubtitleFormat.fromUrl('https://example.com/sub.srt?token=abc'), equals(SubtitleFormat.srt));
        expect(SubtitleFormat.fromUrl('https://example.com/sub.vtt?v=1&lang=en'), equals(SubtitleFormat.vtt));
      });

      test('returns null for URLs without subtitle extensions', () {
        expect(SubtitleFormat.fromUrl('https://example.com/video.mp4'), isNull);
        expect(SubtitleFormat.fromUrl('https://example.com/'), isNull);
      });
    });

    group('fileExtension', () {
      test('returns correct extension for each format', () {
        expect(SubtitleFormat.srt.fileExtension, equals('.srt'));
        expect(SubtitleFormat.vtt.fileExtension, equals('.vtt'));
        expect(SubtitleFormat.ssa.fileExtension, equals('.ssa'));
        expect(SubtitleFormat.ass.fileExtension, equals('.ass'));
        expect(SubtitleFormat.ttml.fileExtension, equals('.ttml'));
      });
    });

    group('mimeType', () {
      test('returns correct MIME type for each format', () {
        expect(SubtitleFormat.srt.mimeType, equals('application/x-subrip'));
        expect(SubtitleFormat.vtt.mimeType, equals('text/vtt'));
        expect(SubtitleFormat.ssa.mimeType, equals('text/x-ssa'));
        expect(SubtitleFormat.ass.mimeType, equals('text/x-ass'));
        expect(SubtitleFormat.ttml.mimeType, equals('application/ttml+xml'));
      });
    });
  });
}
