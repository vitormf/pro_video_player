import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('BufferingTier', () {
    test('has all expected values', () {
      expect(BufferingTier.values, hasLength(5));
      expect(BufferingTier.values, contains(BufferingTier.min));
      expect(BufferingTier.values, contains(BufferingTier.low));
      expect(BufferingTier.values, contains(BufferingTier.medium));
      expect(BufferingTier.values, contains(BufferingTier.high));
      expect(BufferingTier.values, contains(BufferingTier.max));
    });

    test('values are in correct order', () {
      expect(BufferingTier.min.index, 0);
      expect(BufferingTier.low.index, 1);
      expect(BufferingTier.medium.index, 2);
      expect(BufferingTier.high.index, 3);
      expect(BufferingTier.max.index, 4);
    });

    test('name property returns correct string', () {
      expect(BufferingTier.min.name, 'min');
      expect(BufferingTier.low.name, 'low');
      expect(BufferingTier.medium.name, 'medium');
      expect(BufferingTier.high.name, 'high');
      expect(BufferingTier.max.name, 'max');
    });
  });

  group('VideoPlayerOptions with bufferingTier', () {
    test('default bufferingTier is medium', () {
      const options = VideoPlayerOptions();
      expect(options.bufferingTier, BufferingTier.medium);
    });

    test('can be created with custom bufferingTier', () {
      const options = VideoPlayerOptions(bufferingTier: BufferingTier.high);
      expect(options.bufferingTier, BufferingTier.high);
    });

    test('can be created with min bufferingTier', () {
      const options = VideoPlayerOptions(bufferingTier: BufferingTier.min);
      expect(options.bufferingTier, BufferingTier.min);
    });

    test('can be created with max bufferingTier', () {
      const options = VideoPlayerOptions(bufferingTier: BufferingTier.max);
      expect(options.bufferingTier, BufferingTier.max);
    });

    group('copyWith', () {
      test('preserves bufferingTier when not specified', () {
        const original = VideoPlayerOptions(bufferingTier: BufferingTier.high);
        final copy = original.copyWith(autoPlay: true);
        expect(copy.bufferingTier, BufferingTier.high);
        expect(copy.autoPlay, true);
      });

      test('updates bufferingTier when specified', () {
        const original = VideoPlayerOptions(bufferingTier: BufferingTier.low);
        final copy = original.copyWith(bufferingTier: BufferingTier.max);
        expect(copy.bufferingTier, BufferingTier.max);
      });
    });

    group('equality', () {
      test('options with same bufferingTier are equal', () {
        const options1 = VideoPlayerOptions(bufferingTier: BufferingTier.high);
        const options2 = VideoPlayerOptions(bufferingTier: BufferingTier.high);
        expect(options1, equals(options2));
      });

      test('options with different bufferingTier are not equal', () {
        const options1 = VideoPlayerOptions(bufferingTier: BufferingTier.low);
        const options2 = VideoPlayerOptions(bufferingTier: BufferingTier.high);
        expect(options1, isNot(equals(options2)));
      });
    });

    group('hashCode', () {
      test('same bufferingTier produces same hashCode', () {
        const options1 = VideoPlayerOptions(bufferingTier: BufferingTier.min);
        const options2 = VideoPlayerOptions(bufferingTier: BufferingTier.min);
        expect(options1.hashCode, equals(options2.hashCode));
      });

      test('different bufferingTier produces different hashCode', () {
        const options1 = VideoPlayerOptions(bufferingTier: BufferingTier.min);
        const options2 = VideoPlayerOptions(bufferingTier: BufferingTier.max);
        expect(options1.hashCode, isNot(equals(options2.hashCode)));
      });
    });

    group('toString', () {
      test('includes bufferingTier in string representation', () {
        const options = VideoPlayerOptions(bufferingTier: BufferingTier.high);
        expect(options.toString(), contains('bufferingTier: BufferingTier.high'));
      });
    });
  });
}
