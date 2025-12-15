import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoFormatUtils', () {
    group('getQualityLabel', () {
      test('returns 4K for >= 2160p', () {
        expect(VideoFormatUtils.getQualityLabel(2160), '4K');
        expect(VideoFormatUtils.getQualityLabel(3840), '4K');
      });

      test('returns 1440p for >= 1440p', () {
        expect(VideoFormatUtils.getQualityLabel(1440), '1440p');
        expect(VideoFormatUtils.getQualityLabel(1600), '1440p');
      });

      test('returns standard quality labels', () {
        expect(VideoFormatUtils.getQualityLabel(1080), '1080p');
        expect(VideoFormatUtils.getQualityLabel(720), '720p');
        expect(VideoFormatUtils.getQualityLabel(480), '480p');
        expect(VideoFormatUtils.getQualityLabel(360), '360p');
        expect(VideoFormatUtils.getQualityLabel(240), '240p');
        expect(VideoFormatUtils.getQualityLabel(144), '144p');
      });

      test('returns custom label for non-standard heights', () {
        expect(VideoFormatUtils.getQualityLabel(100), '100p');
        expect(VideoFormatUtils.getQualityLabel(540), '480p');
      });

      test('includes frame rate when > 30', () {
        expect(VideoFormatUtils.getQualityLabel(1080, 60), '1080p60');
        expect(VideoFormatUtils.getQualityLabel(1080, 30), '1080p');
        expect(VideoFormatUtils.getQualityLabel(1080, 24), '1080p');
        expect(VideoFormatUtils.getQualityLabel(2160, 60), '4K60');
      });
    });

    group('formatBitrate', () {
      test('formats megabits correctly', () {
        expect(VideoFormatUtils.formatBitrate(2500000), '2.5 Mbps');
        expect(VideoFormatUtils.formatBitrate(1000000), '1.0 Mbps');
        expect(VideoFormatUtils.formatBitrate(10500000), '10.5 Mbps');
      });

      test('formats kilobits correctly', () {
        expect(VideoFormatUtils.formatBitrate(500000), '500 Kbps');
        expect(VideoFormatUtils.formatBitrate(1000), '1 Kbps');
        expect(VideoFormatUtils.formatBitrate(64000), '64 Kbps');
      });

      test('formats bits correctly', () {
        expect(VideoFormatUtils.formatBitrate(800), '800 bps');
        expect(VideoFormatUtils.formatBitrate(999), '999 bps');
      });
    });

    group('calculateExponentialBackoff', () {
      test('returns base delay for retry 0', () {
        expect(VideoFormatUtils.calculateExponentialBackoff(0), const Duration(seconds: 1));
      });

      test('doubles delay for each retry', () {
        expect(VideoFormatUtils.calculateExponentialBackoff(1), const Duration(seconds: 2));
        expect(VideoFormatUtils.calculateExponentialBackoff(2), const Duration(seconds: 4));
        expect(VideoFormatUtils.calculateExponentialBackoff(3), const Duration(seconds: 8));
      });

      test('respects max delay', () {
        expect(VideoFormatUtils.calculateExponentialBackoff(10), const Duration(seconds: 30));
        expect(VideoFormatUtils.calculateExponentialBackoff(100), const Duration(seconds: 30));
      });

      test('uses custom base and max delay', () {
        expect(
          VideoFormatUtils.calculateExponentialBackoff(0, baseDelay: const Duration(milliseconds: 500)),
          const Duration(milliseconds: 500),
        );
        expect(
          VideoFormatUtils.calculateExponentialBackoff(10, maxDelay: const Duration(seconds: 60)),
          const Duration(seconds: 60),
        );
      });

      test('handles negative retry count', () {
        expect(VideoFormatUtils.calculateExponentialBackoff(-1), const Duration(seconds: 1));
      });
    });

    group('shouldUpdateBandwidth', () {
      test('returns true for first report', () {
        expect(VideoFormatUtils.shouldUpdateBandwidth(1000000, 0), isTrue);
      });

      test('returns false for invalid bandwidth', () {
        expect(VideoFormatUtils.shouldUpdateBandwidth(0, 1000000), isFalse);
        expect(VideoFormatUtils.shouldUpdateBandwidth(-100, 1000000), isFalse);
      });

      test('returns false for change below threshold', () {
        // 5% change (below 10% threshold)
        expect(VideoFormatUtils.shouldUpdateBandwidth(1050000, 1000000), isFalse);
      });

      test('returns true for change above threshold', () {
        // 20% change (above 10% threshold)
        expect(VideoFormatUtils.shouldUpdateBandwidth(1200000, 1000000), isTrue);
        // Exactly 10% change
        expect(VideoFormatUtils.shouldUpdateBandwidth(1100000, 1000000), isTrue);
      });

      test('respects custom threshold', () {
        // 15% change with 20% threshold
        expect(VideoFormatUtils.shouldUpdateBandwidth(1150000, 1000000, changeThreshold: 0.2), isFalse);
        // 25% change with 20% threshold
        expect(VideoFormatUtils.shouldUpdateBandwidth(1250000, 1000000, changeThreshold: 0.2), isTrue);
      });
    });

    group('shouldUpdatePosition', () {
      test('returns false for change below threshold', () {
        expect(VideoFormatUtils.shouldUpdatePosition(1050, 1000), isFalse);
      });

      test('returns true for change at or above threshold', () {
        expect(VideoFormatUtils.shouldUpdatePosition(1100, 1000), isTrue);
        expect(VideoFormatUtils.shouldUpdatePosition(1200, 1000), isTrue);
      });

      test('respects custom threshold', () {
        expect(VideoFormatUtils.shouldUpdatePosition(1050, 1000, thresholdMs: 50), isTrue);
        expect(VideoFormatUtils.shouldUpdatePosition(1050, 1000), isFalse);
      });
    });
  });

  // Note: SubtitleFormatDetector tests removed - use SubtitleFormat.fromUrl() tests instead.
  // See test/types/subtitle_format_test.dart for comprehensive subtitle format detection tests.

  group('ContainerFormatDetector', () {
    group('detectFromUrl', () {
      test('returns null for null input', () {
        expect(ContainerFormatDetector.detectFromUrl(null), isNull);
      });

      test('detects MP4 format', () {
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.mp4'), 'mp4');
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.m4v'), 'mp4');
      });

      test('detects MKV format', () {
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.mkv'), 'matroska');
      });

      test('detects WebM format', () {
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.webm'), 'webm');
      });

      test('detects HLS format', () {
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/stream.m3u8'), 'hls');
      });

      test('detects DASH format', () {
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/manifest.mpd'), 'dash');
      });

      test('detects other formats', () {
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.mov'), 'quicktime');
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.flv'), 'flash');
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.ts'), 'mpegts');
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.avi'), 'avi');
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.wmv'), 'wmv');
      });

      test('removes query parameters', () {
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.mp4?token=abc'), 'mp4');
      });

      test('returns null for unknown format', () {
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video.unknown'), isNull);
        expect(ContainerFormatDetector.detectFromUrl('https://example.com/video'), isNull);
      });
    });

    group('isAdaptiveStreaming', () {
      test('returns true for HLS', () {
        expect(ContainerFormatDetector.isAdaptiveStreaming('https://example.com/stream.m3u8'), isTrue);
      });

      test('returns true for DASH', () {
        expect(ContainerFormatDetector.isAdaptiveStreaming('https://example.com/manifest.mpd'), isTrue);
      });

      test('returns false for progressive formats', () {
        expect(ContainerFormatDetector.isAdaptiveStreaming('https://example.com/video.mp4'), isFalse);
        expect(ContainerFormatDetector.isAdaptiveStreaming('https://example.com/video.mkv'), isFalse);
      });
    });
  });

  group('TrackIdParser', () {
    group('parse', () {
      test('parses valid track ID', () {
        final result = TrackIdParser.parse('0:1');
        expect(result, isNotNull);
        expect(result!.$1, 0);
        expect(result.$2, 1);
      });

      test('parses multi-digit indices', () {
        final result = TrackIdParser.parse('10:25');
        expect(result, isNotNull);
        expect(result!.$1, 10);
        expect(result.$2, 25);
      });

      test('returns null for invalid format', () {
        expect(TrackIdParser.parse('invalid'), isNull);
        expect(TrackIdParser.parse('0'), isNull);
        expect(TrackIdParser.parse('0:1:2'), isNull);
        expect(TrackIdParser.parse('a:b'), isNull);
        expect(TrackIdParser.parse(':1'), isNull);
        expect(TrackIdParser.parse('1:'), isNull);
      });
    });

    group('create', () {
      test('creates valid track ID', () {
        expect(TrackIdParser.create(0, 1), '0:1');
        expect(TrackIdParser.create(10, 25), '10:25');
      });
    });
  });
}
