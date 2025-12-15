import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:pro_video_player_web/src/web_player_helpers.dart';

void main() {
  group('isHlsUrl', () {
    test('returns true for .m3u8 extension', () {
      expect(isHlsUrl('https://example.com/video.m3u8'), isTrue);
    });

    test('returns true for .m3u8 with query params', () {
      expect(isHlsUrl('https://example.com/video.m3u8?token=abc123'), isTrue);
    });

    test('returns true for uppercase .M3U8', () {
      expect(isHlsUrl('https://example.com/video.M3U8'), isTrue);
    });

    test('returns false for .mp4 extension', () {
      expect(isHlsUrl('https://example.com/video.mp4'), isFalse);
    });

    test('returns false for .mpd extension', () {
      expect(isHlsUrl('https://example.com/video.mpd'), isFalse);
    });

    test('returns false for m3u8 in path segment', () {
      expect(isHlsUrl('https://example.com/m3u8/video.mp4'), isFalse);
    });
  });

  group('isDashUrl', () {
    test('returns true for .mpd extension', () {
      expect(isDashUrl('https://example.com/manifest.mpd'), isTrue);
    });

    test('returns true for .mpd with query params', () {
      expect(isDashUrl('https://example.com/manifest.mpd?token=abc123'), isTrue);
    });

    test('returns true for uppercase .MPD', () {
      expect(isDashUrl('https://example.com/manifest.MPD'), isTrue);
    });

    test('returns false for .m3u8 extension', () {
      expect(isDashUrl('https://example.com/video.m3u8'), isFalse);
    });

    test('returns false for .mp4 extension', () {
      expect(isDashUrl('https://example.com/video.mp4'), isFalse);
    });

    test('returns false for mpd in path segment', () {
      expect(isDashUrl('https://example.com/mpd/video.mp4'), isFalse);
    });
  });

  group('getObjectFitFromScalingMode', () {
    test('returns contain for fit mode', () {
      expect(getObjectFitFromScalingMode(VideoScalingMode.fit), equals('contain'));
    });

    test('returns cover for fill mode', () {
      expect(getObjectFitFromScalingMode(VideoScalingMode.fill), equals('cover'));
    });

    test('returns fill for stretch mode', () {
      expect(getObjectFitFromScalingMode(VideoScalingMode.stretch), equals('fill'));
    });
  });

  group('getPreloadFromBufferingTier', () {
    test('returns metadata for min tier', () {
      expect(getPreloadFromBufferingTier(BufferingTier.min), equals('metadata'));
    });

    test('returns metadata for low tier', () {
      expect(getPreloadFromBufferingTier(BufferingTier.low), equals('metadata'));
    });

    test('returns auto for medium tier', () {
      expect(getPreloadFromBufferingTier(BufferingTier.medium), equals('auto'));
    });

    test('returns auto for high tier', () {
      expect(getPreloadFromBufferingTier(BufferingTier.high), equals('auto'));
    });

    test('returns auto for max tier', () {
      expect(getPreloadFromBufferingTier(BufferingTier.max), equals('auto'));
    });
  });

  group('inferContainerFormat', () {
    test('returns mp4 for .mp4 extension', () {
      expect(inferContainerFormat('https://example.com/video.mp4'), equals('mp4'));
    });

    test('returns mp4 for .mp4 with query params', () {
      expect(inferContainerFormat('https://example.com/video.mp4?quality=hd'), equals('mp4'));
    });

    test('returns webm for .webm extension', () {
      expect(inferContainerFormat('https://example.com/video.webm'), equals('webm'));
    });

    test('returns matroska for .mkv extension', () {
      expect(inferContainerFormat('https://example.com/video.mkv'), equals('matroska'));
    });

    test('returns hls for .m3u8 extension', () {
      expect(inferContainerFormat('https://example.com/stream.m3u8'), equals('hls'));
    });

    test('returns dash for .mpd extension', () {
      expect(inferContainerFormat('https://example.com/manifest.mpd'), equals('dash'));
    });

    test('returns ogg for .ogg extension', () {
      expect(inferContainerFormat('https://example.com/video.ogg'), equals('ogg'));
    });

    test('returns quicktime for .mov extension', () {
      expect(inferContainerFormat('https://example.com/video.mov'), equals('quicktime'));
    });

    test('returns null for unknown extension', () {
      expect(inferContainerFormat('https://example.com/video.avi'), isNull);
    });

    test('returns null for no extension', () {
      expect(inferContainerFormat('https://example.com/video'), isNull);
    });

    test('handles uppercase extensions', () {
      expect(inferContainerFormat('https://example.com/video.MP4'), equals('mp4'));
    });
  });

  group('detectSubtitleFormat', () {
    test('returns vtt for .vtt extension', () {
      expect(detectSubtitleFormat('https://example.com/subs.vtt'), equals(SubtitleFormat.vtt));
    });

    test('returns vtt for .vtt with query params', () {
      expect(detectSubtitleFormat('https://example.com/subs.vtt?lang=en'), equals(SubtitleFormat.vtt));
    });

    test('returns srt for .srt extension', () {
      expect(detectSubtitleFormat('https://example.com/subs.srt'), equals(SubtitleFormat.srt));
    });

    test('returns ass for .ass extension', () {
      expect(detectSubtitleFormat('https://example.com/subs.ass'), equals(SubtitleFormat.ass));
    });

    test('returns ssa for .ssa extension', () {
      expect(detectSubtitleFormat('https://example.com/subs.ssa'), equals(SubtitleFormat.ssa));
    });

    test('returns ttml for .ttml extension', () {
      expect(detectSubtitleFormat('https://example.com/subs.ttml'), equals(SubtitleFormat.ttml));
    });

    test('returns ttml for .xml extension', () {
      expect(detectSubtitleFormat('https://example.com/subs.xml'), equals(SubtitleFormat.ttml));
    });

    test('returns null for unknown extension', () {
      expect(detectSubtitleFormat('https://example.com/subs.txt'), isNull);
    });

    test('handles uppercase extensions', () {
      expect(detectSubtitleFormat('https://example.com/subs.VTT'), equals(SubtitleFormat.vtt));
    });
  });

  group('labelFromUrl', () {
    test('extracts filename without extension', () {
      expect(labelFromUrl('https://example.com/path/subtitles.vtt'), equals('subtitles'));
    });

    test('handles filename with multiple dots', () {
      expect(labelFromUrl('https://example.com/video.en.srt'), equals('video.en'));
    });

    test('handles filename without extension', () {
      expect(labelFromUrl('https://example.com/path/subtitles'), equals('subtitles'));
    });

    test('handles URL with query parameters', () {
      expect(labelFromUrl('https://example.com/subs.vtt?token=abc'), equals('subs'));
    });

    test('returns default for empty path', () {
      expect(labelFromUrl('https://example.com/'), equals('External Subtitle'));
    });

    test('returns filename for relative path', () {
      // Uri.parse handles relative paths as path segments
      expect(labelFromUrl('not-a-valid-url'), equals('not-a-valid-url'));
    });

    test('handles deeply nested paths', () {
      expect(labelFromUrl('https://example.com/a/b/c/d/subtitles.srt'), equals('subtitles'));
    });
  });

  group('getSourceUrl', () {
    test('returns url for NetworkVideoSource', () {
      const source = VideoSource.network('https://example.com/video.mp4');
      expect(getSourceUrl(source), equals('https://example.com/video.mp4'));
    });

    test('returns path for FileVideoSource', () {
      const source = VideoSource.file('/path/to/video.mp4');
      expect(getSourceUrl(source), equals('/path/to/video.mp4'));
    });

    test('returns assets path for AssetVideoSource', () {
      const source = VideoSource.asset('videos/intro.mp4');
      expect(getSourceUrl(source), equals('assets/videos/intro.mp4'));
    });

    test('throws for PlaylistVideoSource', () {
      const source = VideoSource.playlist('https://example.com/playlist.m3u8');
      expect(() => getSourceUrl(source), throwsA(isA<UnsupportedError>()));
    });
  });

  group('validatePlaybackSpeed', () {
    test('does not throw for valid speed 1', () {
      expect(() => validatePlaybackSpeed(1), returnsNormally);
    });

    test('does not throw for valid speed 0.5', () {
      expect(() => validatePlaybackSpeed(0.5), returnsNormally);
    });

    test('does not throw for valid speed 2', () {
      expect(() => validatePlaybackSpeed(2), returnsNormally);
    });

    test('does not throw for maximum valid speed 10', () {
      expect(() => validatePlaybackSpeed(10), returnsNormally);
    });

    test('does not throw for minimum valid speed', () {
      expect(() => validatePlaybackSpeed(0.01), returnsNormally);
    });

    test('throws for speed 0', () {
      expect(() => validatePlaybackSpeed(0), throwsA(isA<ArgumentError>()));
    });

    test('throws for negative speed', () {
      expect(() => validatePlaybackSpeed(-1), throwsA(isA<ArgumentError>()));
    });

    test('throws for speed greater than 10', () {
      expect(() => validatePlaybackSpeed(10.1), throwsA(isA<ArgumentError>()));
    });
  });

  group('validateVolume', () {
    test('does not throw for valid volume 0', () {
      expect(() => validateVolume(0), returnsNormally);
    });

    test('does not throw for valid volume 0.5', () {
      expect(() => validateVolume(0.5), returnsNormally);
    });

    test('does not throw for valid volume 1', () {
      expect(() => validateVolume(1), returnsNormally);
    });

    test('throws for negative volume', () {
      expect(() => validateVolume(-0.1), throwsA(isA<ArgumentError>()));
    });

    test('throws for volume greater than 1', () {
      expect(() => validateVolume(1.1), throwsA(isA<ArgumentError>()));
    });
  });

  group('validateSeekPosition', () {
    test('does not throw for zero position', () {
      expect(() => validateSeekPosition(Duration.zero), returnsNormally);
    });

    test('does not throw for positive position', () {
      expect(() => validateSeekPosition(const Duration(seconds: 30)), returnsNormally);
    });

    test('throws for negative position', () {
      expect(() => validateSeekPosition(const Duration(seconds: -1)), throwsA(isA<ArgumentError>()));
    });
  });
}
