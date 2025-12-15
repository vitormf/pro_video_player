import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('PipOptions', () {
    test('has correct default values', () {
      const options = PipOptions();

      expect(options.aspectRatio, isNull);
      expect(options.autoEnterOnBackground, isFalse);
    });

    test('creates with custom values', () {
      const options = PipOptions(aspectRatio: 16 / 9, autoEnterOnBackground: true);

      expect(options.aspectRatio, closeTo(16 / 9, 0.01));
      expect(options.autoEnterOnBackground, isTrue);
    });

    group('equality', () {
      test('equal options are equal', () {
        const options1 = PipOptions(aspectRatio: 16 / 9, autoEnterOnBackground: true);
        const options2 = PipOptions(aspectRatio: 16 / 9, autoEnterOnBackground: true);

        expect(options1, equals(options2));
      });

      test('options with different aspectRatio are not equal', () {
        const options1 = PipOptions(aspectRatio: 16 / 9);
        const options2 = PipOptions(aspectRatio: 4 / 3);

        expect(options1, isNot(equals(options2)));
      });

      test('options with different autoEnterOnBackground are not equal', () {
        const options1 = PipOptions(autoEnterOnBackground: true);
        const options2 = PipOptions();

        expect(options1, isNot(equals(options2)));
      });
    });

    test('hashCode is consistent with equality', () {
      const options1 = PipOptions(aspectRatio: 16 / 9, autoEnterOnBackground: true);
      const options2 = PipOptions(aspectRatio: 16 / 9, autoEnterOnBackground: true);

      expect(options1.hashCode, equals(options2.hashCode));
    });

    test('toString returns readable representation', () {
      const options = PipOptions(aspectRatio: 16 / 9, autoEnterOnBackground: true);

      final str = options.toString();
      expect(str, contains('PipOptions'));
      expect(str, contains('aspectRatio'));
      expect(str, contains('autoEnterOnBackground: true'));
    });
  });
}
