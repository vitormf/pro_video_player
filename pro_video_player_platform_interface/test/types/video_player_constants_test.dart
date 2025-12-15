import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoPlayerConstants', () {
    group('getLanguageDisplayName', () {
      test('returns display name for ISO 639-1 codes', () {
        expect(VideoPlayerConstants.getLanguageDisplayName('en'), 'English');
        expect(VideoPlayerConstants.getLanguageDisplayName('es'), 'Spanish');
        expect(VideoPlayerConstants.getLanguageDisplayName('fr'), 'French');
        expect(VideoPlayerConstants.getLanguageDisplayName('de'), 'German');
        expect(VideoPlayerConstants.getLanguageDisplayName('ja'), 'Japanese');
        expect(VideoPlayerConstants.getLanguageDisplayName('zh'), 'Chinese');
        expect(VideoPlayerConstants.getLanguageDisplayName('ko'), 'Korean');
        expect(VideoPlayerConstants.getLanguageDisplayName('ar'), 'Arabic');
      });

      test('returns display name for ISO 639-2 codes', () {
        expect(VideoPlayerConstants.getLanguageDisplayName('eng'), 'English');
        expect(VideoPlayerConstants.getLanguageDisplayName('spa'), 'Spanish');
        expect(VideoPlayerConstants.getLanguageDisplayName('fra'), 'French');
        expect(VideoPlayerConstants.getLanguageDisplayName('deu'), 'German');
        expect(VideoPlayerConstants.getLanguageDisplayName('jpn'), 'Japanese');
        expect(VideoPlayerConstants.getLanguageDisplayName('zho'), 'Chinese');
        expect(VideoPlayerConstants.getLanguageDisplayName('kor'), 'Korean');
        expect(VideoPlayerConstants.getLanguageDisplayName('ara'), 'Arabic');
      });

      test('handles case-insensitive codes', () {
        expect(VideoPlayerConstants.getLanguageDisplayName('EN'), 'English');
        expect(VideoPlayerConstants.getLanguageDisplayName('En'), 'English');
        expect(VideoPlayerConstants.getLanguageDisplayName('ENG'), 'English');
        expect(VideoPlayerConstants.getLanguageDisplayName('Eng'), 'English');
      });

      test('returns uppercase code for unknown languages', () {
        expect(VideoPlayerConstants.getLanguageDisplayName('xyz'), 'XYZ');
        expect(VideoPlayerConstants.getLanguageDisplayName('abc'), 'ABC');
      });

      test('returns Unknown for null or empty', () {
        expect(VideoPlayerConstants.getLanguageDisplayName(null), 'Unknown');
        expect(VideoPlayerConstants.getLanguageDisplayName(''), 'Unknown');
      });

      test('handles special codes', () {
        expect(VideoPlayerConstants.getLanguageDisplayName('und'), 'Undetermined');
        expect(VideoPlayerConstants.getLanguageDisplayName('mul'), 'Multiple Languages');
        expect(VideoPlayerConstants.getLanguageDisplayName('zxx'), 'No Linguistic Content');
      });
    });

    group('getBufferDurationForTier', () {
      test('returns correct duration for each tier', () {
        expect(VideoPlayerConstants.getBufferDurationForTier('min'), 2.0);
        expect(VideoPlayerConstants.getBufferDurationForTier('low'), 5.0);
        expect(VideoPlayerConstants.getBufferDurationForTier('medium'), 0.0);
        expect(VideoPlayerConstants.getBufferDurationForTier('high'), 30.0);
        expect(VideoPlayerConstants.getBufferDurationForTier('max'), 60.0);
      });

      test('handles case-insensitive tier names', () {
        expect(VideoPlayerConstants.getBufferDurationForTier('MIN'), 2.0);
        expect(VideoPlayerConstants.getBufferDurationForTier('Low'), 5.0);
        expect(VideoPlayerConstants.getBufferDurationForTier('MEDIUM'), 0.0);
      });

      test('returns automatic (0) for null or unknown tier', () {
        expect(VideoPlayerConstants.getBufferDurationForTier(null), 0.0);
        expect(VideoPlayerConstants.getBufferDurationForTier('unknown'), 0.0);
      });
    });

    group('getExoPlayerBufferConfig', () {
      test('returns correct config for min tier', () {
        final config = VideoPlayerConstants.getExoPlayerBufferConfig('min');
        expect(config['minBufferMs'], 500);
        expect(config['maxBufferMs'], 2000);
        expect(config['bufferForPlaybackMs'], 500);
        expect(config['bufferForPlaybackAfterRebufferMs'], 1000);
      });

      test('returns correct config for medium tier (default)', () {
        final config = VideoPlayerConstants.getExoPlayerBufferConfig('medium');
        expect(config['minBufferMs'], 2500);
        expect(config['maxBufferMs'], 15000);
      });

      test('returns correct config for max tier', () {
        final config = VideoPlayerConstants.getExoPlayerBufferConfig('max');
        expect(config['minBufferMs'], 10000);
        expect(config['maxBufferMs'], 60000);
      });

      test('returns medium config for null', () {
        final config = VideoPlayerConstants.getExoPlayerBufferConfig(null);
        expect(config['minBufferMs'], 2500);
        expect(config['maxBufferMs'], 15000);
      });
    });

    group('getAVLayerVideoGravity', () {
      test('returns correct gravity for each mode', () {
        expect(VideoPlayerConstants.getAVLayerVideoGravity('fit'), 'resizeAspect');
        expect(VideoPlayerConstants.getAVLayerVideoGravity('fill'), 'resizeAspectFill');
        expect(VideoPlayerConstants.getAVLayerVideoGravity('stretch'), 'resize');
      });

      test('handles case-insensitive mode names', () {
        expect(VideoPlayerConstants.getAVLayerVideoGravity('FIT'), 'resizeAspect');
        expect(VideoPlayerConstants.getAVLayerVideoGravity('Fill'), 'resizeAspectFill');
      });

      test('returns fit for null or unknown mode', () {
        expect(VideoPlayerConstants.getAVLayerVideoGravity(null), 'resizeAspect');
        expect(VideoPlayerConstants.getAVLayerVideoGravity('unknown'), 'resizeAspect');
      });
    });

    group('getExoPlayerResizeMode', () {
      test('returns correct mode constants', () {
        expect(VideoPlayerConstants.getExoPlayerResizeMode('fit'), 0);
        expect(VideoPlayerConstants.getExoPlayerResizeMode('fill'), 4);
        expect(VideoPlayerConstants.getExoPlayerResizeMode('stretch'), 3);
      });

      test('returns fit (0) for null or unknown mode', () {
        expect(VideoPlayerConstants.getExoPlayerResizeMode(null), 0);
        expect(VideoPlayerConstants.getExoPlayerResizeMode('unknown'), 0);
      });
    });

    group('getCssObjectFit', () {
      test('returns correct CSS values', () {
        expect(VideoPlayerConstants.getCssObjectFit('fit'), 'contain');
        expect(VideoPlayerConstants.getCssObjectFit('fill'), 'cover');
        expect(VideoPlayerConstants.getCssObjectFit('stretch'), 'fill');
      });

      test('returns contain for null or unknown mode', () {
        expect(VideoPlayerConstants.getCssObjectFit(null), 'contain');
        expect(VideoPlayerConstants.getCssObjectFit('unknown'), 'contain');
      });
    });

    group('formatTrackId', () {
      test('formats track ID correctly', () {
        expect(VideoPlayerConstants.formatTrackId(0, 0), '0:0');
        expect(VideoPlayerConstants.formatTrackId(0, 1), '0:1');
        expect(VideoPlayerConstants.formatTrackId(2, 3), '2:3');
        expect(VideoPlayerConstants.formatTrackId(10, 20), '10:20');
      });
    });

    group('parseTrackId', () {
      test('parses valid track IDs', () {
        final result1 = VideoPlayerConstants.parseTrackId('0:0');
        expect(result1?.groupIndex, 0);
        expect(result1?.trackIndex, 0);

        final result2 = VideoPlayerConstants.parseTrackId('2:3');
        expect(result2?.groupIndex, 2);
        expect(result2?.trackIndex, 3);

        final result3 = VideoPlayerConstants.parseTrackId('10:20');
        expect(result3?.groupIndex, 10);
        expect(result3?.trackIndex, 20);
      });

      test('returns null for invalid formats', () {
        expect(VideoPlayerConstants.parseTrackId(null), isNull);
        expect(VideoPlayerConstants.parseTrackId(''), isNull);
        expect(VideoPlayerConstants.parseTrackId('invalid'), isNull);
        expect(VideoPlayerConstants.parseTrackId('0'), isNull);
        expect(VideoPlayerConstants.parseTrackId('0:1:2'), isNull);
        expect(VideoPlayerConstants.parseTrackId('a:b'), isNull);
      });
    });

    group('calculateRetryDelay', () {
      test('uses exponential backoff', () {
        expect(VideoPlayerConstants.calculateRetryDelay(0), const Duration(seconds: 1));
        expect(VideoPlayerConstants.calculateRetryDelay(1), const Duration(seconds: 2));
        expect(VideoPlayerConstants.calculateRetryDelay(2), const Duration(seconds: 4));
        expect(VideoPlayerConstants.calculateRetryDelay(3), const Duration(seconds: 8));
        expect(VideoPlayerConstants.calculateRetryDelay(4), const Duration(seconds: 16));
      });

      test('caps at maxRetryDelaySeconds', () {
        expect(VideoPlayerConstants.calculateRetryDelay(5), const Duration(seconds: 30));
        expect(VideoPlayerConstants.calculateRetryDelay(6), const Duration(seconds: 30));
        expect(VideoPlayerConstants.calculateRetryDelay(10), const Duration(seconds: 30));
      });
    });

    group('constants', () {
      test('has expected default values', () {
        expect(VideoPlayerConstants.defaultMaxNetworkRetries, 3);
        expect(VideoPlayerConstants.maxRetryDelaySeconds, 30);
      });
    });
  });
}
