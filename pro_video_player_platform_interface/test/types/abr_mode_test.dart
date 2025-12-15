import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('AbrMode', () {
    test('has all expected values', () {
      expect(AbrMode.values, hasLength(2));
      expect(AbrMode.values, contains(AbrMode.auto));
      expect(AbrMode.values, contains(AbrMode.manual));
    });

    test('values are in correct order', () {
      expect(AbrMode.auto.index, 0);
      expect(AbrMode.manual.index, 1);
    });

    test('name property returns correct string', () {
      expect(AbrMode.auto.name, 'auto');
      expect(AbrMode.manual.name, 'manual');
    });
  });

  group('VideoPlayerOptions with ABR settings', () {
    test('default abrMode is auto', () {
      const options = VideoPlayerOptions();
      expect(options.abrMode, AbrMode.auto);
    });

    test('default minBitrate is null (no limit)', () {
      const options = VideoPlayerOptions();
      expect(options.minBitrate, isNull);
    });

    test('default maxBitrate is null (no limit)', () {
      const options = VideoPlayerOptions();
      expect(options.maxBitrate, isNull);
    });

    test('can be created with abrMode.manual', () {
      const options = VideoPlayerOptions(abrMode: AbrMode.manual);
      expect(options.abrMode, AbrMode.manual);
    });

    test('can be created with minBitrate', () {
      const options = VideoPlayerOptions(minBitrate: 500000);
      expect(options.minBitrate, 500000);
    });

    test('can be created with maxBitrate', () {
      const options = VideoPlayerOptions(maxBitrate: 5000000);
      expect(options.maxBitrate, 5000000);
    });

    test('can be created with both min and max bitrate', () {
      const options = VideoPlayerOptions(minBitrate: 500000, maxBitrate: 5000000);
      expect(options.minBitrate, 500000);
      expect(options.maxBitrate, 5000000);
    });

    test('can combine abrMode with bitrate constraints', () {
      const options = VideoPlayerOptions(minBitrate: 1000000, maxBitrate: 8000000);
      expect(options.abrMode, AbrMode.auto);
      expect(options.minBitrate, 1000000);
      expect(options.maxBitrate, 8000000);
    });

    group('copyWith', () {
      test('preserves abrMode when not specified', () {
        const original = VideoPlayerOptions(abrMode: AbrMode.manual);
        final copy = original.copyWith(autoPlay: true);
        expect(copy.abrMode, AbrMode.manual);
        expect(copy.autoPlay, true);
      });

      test('updates abrMode when specified', () {
        const original = VideoPlayerOptions();
        final copy = original.copyWith(abrMode: AbrMode.manual);
        expect(copy.abrMode, AbrMode.manual);
      });

      test('preserves minBitrate when not specified', () {
        const original = VideoPlayerOptions(minBitrate: 1000000);
        final copy = original.copyWith(autoPlay: true);
        expect(copy.minBitrate, 1000000);
      });

      test('updates minBitrate when specified', () {
        const original = VideoPlayerOptions(minBitrate: 500000);
        final copy = original.copyWith(minBitrate: 1000000);
        expect(copy.minBitrate, 1000000);
      });

      test('preserves maxBitrate when not specified', () {
        const original = VideoPlayerOptions(maxBitrate: 5000000);
        final copy = original.copyWith(autoPlay: true);
        expect(copy.maxBitrate, 5000000);
      });

      test('updates maxBitrate when specified', () {
        const original = VideoPlayerOptions(maxBitrate: 5000000);
        final copy = original.copyWith(maxBitrate: 8000000);
        expect(copy.maxBitrate, 8000000);
      });
    });

    group('equality', () {
      test('options with same abrMode are equal', () {
        const options1 = VideoPlayerOptions(abrMode: AbrMode.manual);
        const options2 = VideoPlayerOptions(abrMode: AbrMode.manual);
        expect(options1, equals(options2));
      });

      test('options with different abrMode are not equal', () {
        const options1 = VideoPlayerOptions();
        const options2 = VideoPlayerOptions(abrMode: AbrMode.manual);
        expect(options1, isNot(equals(options2)));
      });

      test('options with same minBitrate are equal', () {
        const options1 = VideoPlayerOptions(minBitrate: 1000000);
        const options2 = VideoPlayerOptions(minBitrate: 1000000);
        expect(options1, equals(options2));
      });

      test('options with different minBitrate are not equal', () {
        const options1 = VideoPlayerOptions(minBitrate: 500000);
        const options2 = VideoPlayerOptions(minBitrate: 1000000);
        expect(options1, isNot(equals(options2)));
      });

      test('options with same maxBitrate are equal', () {
        const options1 = VideoPlayerOptions(maxBitrate: 5000000);
        const options2 = VideoPlayerOptions(maxBitrate: 5000000);
        expect(options1, equals(options2));
      });

      test('options with different maxBitrate are not equal', () {
        const options1 = VideoPlayerOptions(maxBitrate: 5000000);
        const options2 = VideoPlayerOptions(maxBitrate: 8000000);
        expect(options1, isNot(equals(options2)));
      });

      test('options with null vs non-null minBitrate are not equal', () {
        const options1 = VideoPlayerOptions();
        const options2 = VideoPlayerOptions(minBitrate: 1000000);
        expect(options1, isNot(equals(options2)));
      });

      test('options with null vs non-null maxBitrate are not equal', () {
        const options1 = VideoPlayerOptions();
        const options2 = VideoPlayerOptions(maxBitrate: 5000000);
        expect(options1, isNot(equals(options2)));
      });
    });

    group('hashCode', () {
      test('same abrMode produces same hashCode', () {
        const options1 = VideoPlayerOptions(abrMode: AbrMode.manual);
        const options2 = VideoPlayerOptions(abrMode: AbrMode.manual);
        expect(options1.hashCode, equals(options2.hashCode));
      });

      test('different abrMode produces different hashCode', () {
        const options1 = VideoPlayerOptions();
        const options2 = VideoPlayerOptions(abrMode: AbrMode.manual);
        expect(options1.hashCode, isNot(equals(options2.hashCode)));
      });

      test('same bitrate constraints produce same hashCode', () {
        const options1 = VideoPlayerOptions(minBitrate: 1000000, maxBitrate: 5000000);
        const options2 = VideoPlayerOptions(minBitrate: 1000000, maxBitrate: 5000000);
        expect(options1.hashCode, equals(options2.hashCode));
      });
    });

    group('toString', () {
      test('includes abrMode in string representation', () {
        const options = VideoPlayerOptions(abrMode: AbrMode.manual);
        expect(options.toString(), contains('abrMode: AbrMode.manual'));
      });

      test('includes minBitrate in string representation', () {
        const options = VideoPlayerOptions(minBitrate: 1000000);
        expect(options.toString(), contains('minBitrate: 1000000'));
      });

      test('includes maxBitrate in string representation', () {
        const options = VideoPlayerOptions(maxBitrate: 5000000);
        expect(options.toString(), contains('maxBitrate: 5000000'));
      });
    });
  });

  group('ABR option combinations', () {
    test('manual mode with bitrate constraints is valid', () {
      // In manual mode, bitrate constraints can still be set but won't cause auto-switching
      const options = VideoPlayerOptions(abrMode: AbrMode.manual, minBitrate: 500000, maxBitrate: 5000000);

      expect(options.abrMode, AbrMode.manual);
      expect(options.minBitrate, 500000);
      expect(options.maxBitrate, 5000000);
    });

    test('auto mode with bitrate constraints limits ABR range', () {
      // In auto mode, bitrate constraints limit the quality range for ABR
      const options = VideoPlayerOptions(
        minBitrate: 1000000, // At least 1 Mbps
        maxBitrate: 4000000, // At most 4 Mbps
      );

      expect(options.abrMode, AbrMode.auto);
      expect(options.minBitrate, 1000000);
      expect(options.maxBitrate, 4000000);
    });

    test('only maxBitrate without minBitrate is valid', () {
      const options = VideoPlayerOptions(maxBitrate: 2000000);
      expect(options.minBitrate, isNull);
      expect(options.maxBitrate, 2000000);
    });

    test('only minBitrate without maxBitrate is valid', () {
      const options = VideoPlayerOptions(minBitrate: 500000);
      expect(options.minBitrate, 500000);
      expect(options.maxBitrate, isNull);
    });
  });

  group('ABR bitrate values', () {
    test('accepts typical SD bitrate (1.5 Mbps)', () {
      const options = VideoPlayerOptions(maxBitrate: 1500000);
      expect(options.maxBitrate, 1500000);
    });

    test('accepts typical HD bitrate (5 Mbps)', () {
      const options = VideoPlayerOptions(maxBitrate: 5000000);
      expect(options.maxBitrate, 5000000);
    });

    test('accepts typical 4K bitrate (25 Mbps)', () {
      const options = VideoPlayerOptions(maxBitrate: 25000000);
      expect(options.maxBitrate, 25000000);
    });

    test('accepts very low bitrate for mobile (200 kbps)', () {
      const options = VideoPlayerOptions(minBitrate: 200000);
      expect(options.minBitrate, 200000);
    });

    test('accepts zero as minBitrate (no minimum)', () {
      const options = VideoPlayerOptions(minBitrate: 0);
      expect(options.minBitrate, 0);
    });
  });
}
