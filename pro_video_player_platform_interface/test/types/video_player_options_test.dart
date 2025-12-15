import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoPlayerOptions', () {
    test('has correct default values', () {
      const options = VideoPlayerOptions();

      expect(options.autoPlay, isFalse);
      expect(options.looping, isFalse);
      expect(options.volume, equals(1.0));
      expect(options.playbackSpeed, equals(1.0));
      expect(options.allowBackgroundPlayback, isFalse);
      expect(options.mixWithOthers, isFalse);
      expect(options.allowPip, isTrue);
      expect(options.autoEnterPipOnBackground, isFalse);
      expect(options.subtitlesEnabled, isTrue);
      expect(options.showSubtitlesByDefault, isFalse);
      expect(options.preferredSubtitleLanguage, isNull);
      expect(options.fullscreenOrientation, equals(FullscreenOrientation.landscapeBoth));
      expect(options.fullscreenOnly, isFalse);
      expect(options.subtitleRenderMode, equals(SubtitleRenderMode.auto));
    });

    test('creates with custom values', () {
      const options = VideoPlayerOptions(
        autoPlay: true,
        looping: true,
        volume: 0.5,
        playbackSpeed: 1.5,
        allowBackgroundPlayback: true,
        mixWithOthers: true,
        allowPip: false,
        autoEnterPipOnBackground: true,
        subtitlesEnabled: false,
        showSubtitlesByDefault: true,
        preferredSubtitleLanguage: 'en',
        fullscreenOrientation: FullscreenOrientation.all,
        fullscreenOnly: true,
      );

      expect(options.autoPlay, isTrue);
      expect(options.looping, isTrue);
      expect(options.volume, equals(0.5));
      expect(options.playbackSpeed, equals(1.5));
      expect(options.allowBackgroundPlayback, isTrue);
      expect(options.mixWithOthers, isTrue);
      expect(options.allowPip, isFalse);
      expect(options.autoEnterPipOnBackground, isTrue);
      expect(options.subtitlesEnabled, isFalse);
      expect(options.showSubtitlesByDefault, isTrue);
      expect(options.preferredSubtitleLanguage, equals('en'));
      expect(options.fullscreenOrientation, equals(FullscreenOrientation.all));
      expect(options.fullscreenOnly, isTrue);
    });

    group('copyWith', () {
      test('copies with new autoPlay', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(autoPlay: true);

        expect(copied.autoPlay, isTrue);
        expect(original.autoPlay, isFalse);
      });

      test('copies with new looping', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(looping: true);

        expect(copied.looping, isTrue);
      });

      test('copies with new volume', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(volume: 0.5);

        expect(copied.volume, equals(0.5));
      });

      test('copies with new playbackSpeed', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(playbackSpeed: 2);

        expect(copied.playbackSpeed, equals(2.0));
      });

      test('copies with new allowBackgroundPlayback', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(allowBackgroundPlayback: true);

        expect(copied.allowBackgroundPlayback, isTrue);
      });

      test('copies with new mixWithOthers', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(mixWithOthers: true);

        expect(copied.mixWithOthers, isTrue);
      });

      test('copies with new allowPip', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(allowPip: false);

        expect(copied.allowPip, isFalse);
      });

      test('copies with new autoEnterPipOnBackground', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(autoEnterPipOnBackground: true);

        expect(copied.autoEnterPipOnBackground, isTrue);
      });

      test('copies with new subtitlesEnabled', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(subtitlesEnabled: false);

        expect(copied.subtitlesEnabled, isFalse);
      });

      test('copies with new showSubtitlesByDefault', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(showSubtitlesByDefault: true);

        expect(copied.showSubtitlesByDefault, isTrue);
      });

      test('copies with new preferredSubtitleLanguage', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(preferredSubtitleLanguage: 'es');

        expect(copied.preferredSubtitleLanguage, equals('es'));
      });

      test('copies with new fullscreenOrientation', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(fullscreenOrientation: FullscreenOrientation.portraitBoth);

        expect(copied.fullscreenOrientation, equals(FullscreenOrientation.portraitBoth));
        expect(original.fullscreenOrientation, equals(FullscreenOrientation.landscapeBoth));
      });

      test('copies with new fullscreenOnly', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(fullscreenOnly: true);

        expect(copied.fullscreenOnly, isTrue);
        expect(original.fullscreenOnly, isFalse);
      });

      test('copies with new subtitleRenderMode', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(subtitleRenderMode: SubtitleRenderMode.flutter);

        expect(copied.subtitleRenderMode, equals(SubtitleRenderMode.flutter));
        expect(original.subtitleRenderMode, equals(SubtitleRenderMode.auto));
      });

      test('preserves unchanged values', () {
        const original = VideoPlayerOptions(
          autoPlay: true,
          volume: 0.7,
          playbackSpeed: 1.5,
          allowBackgroundPlayback: true,
          mixWithOthers: true,
        );
        final copied = original.copyWith(looping: true);

        expect(copied.autoPlay, isTrue);
        expect(copied.volume, equals(0.7));
        expect(copied.playbackSpeed, equals(1.5));
        expect(copied.looping, isTrue);
        expect(copied.allowBackgroundPlayback, isTrue);
        expect(copied.mixWithOthers, isTrue);
      });
    });

    group('equality', () {
      test('equal options are equal', () {
        const options1 = VideoPlayerOptions(autoPlay: true, volume: 0.5);
        const options2 = VideoPlayerOptions(autoPlay: true, volume: 0.5);

        expect(options1, equals(options2));
      });

      test('different options are not equal', () {
        const options1 = VideoPlayerOptions(autoPlay: true);
        const options2 = VideoPlayerOptions();

        expect(options1, isNot(equals(options2)));
      });

      test('hashCode is consistent with equality', () {
        const options1 = VideoPlayerOptions(autoPlay: true, volume: 0.5);
        const options2 = VideoPlayerOptions(autoPlay: true, volume: 0.5);

        expect(options1.hashCode, equals(options2.hashCode));
      });
    });

    test('toString returns readable representation', () {
      const options = VideoPlayerOptions(autoPlay: true, volume: 0.5, fullscreenOrientation: FullscreenOrientation.all);

      final str = options.toString();
      expect(str, contains('VideoPlayerOptions'));
      expect(str, contains('autoPlay: true'));
      expect(str, contains('volume: 0.5'));
      expect(str, contains('fullscreenOrientation: FullscreenOrientation.all'));
    });

    group('boundary values', () {
      test('accepts volume at minimum (0.0)', () {
        const options = VideoPlayerOptions(volume: 0);
        expect(options.volume, equals(0));
      });

      test('accepts volume at maximum (1.0)', () {
        const options = VideoPlayerOptions();
        expect(options.volume, equals(1));
      });

      test('accepts very slow playback speed (0.25)', () {
        const options = VideoPlayerOptions(playbackSpeed: 0.25);
        expect(options.playbackSpeed, equals(0.25));
      });

      test('accepts fast playback speed (2.0)', () {
        const options = VideoPlayerOptions(playbackSpeed: 2);
        expect(options.playbackSpeed, equals(2));
      });
    });

    group('option combinations', () {
      test('allowPip=false with autoEnterPipOnBackground=true is valid', () {
        // This configuration means: don't allow PiP, but if it were allowed,
        // auto-enter on background. The allowPip flag takes precedence.
        const options = VideoPlayerOptions(allowPip: false, autoEnterPipOnBackground: true);

        expect(options.allowPip, isFalse);
        expect(options.autoEnterPipOnBackground, isTrue);
      });

      test('subtitlesEnabled=false with showSubtitlesByDefault=true is valid', () {
        // showSubtitlesByDefault is ignored when subtitles are disabled
        const options = VideoPlayerOptions(subtitlesEnabled: false, showSubtitlesByDefault: true);

        expect(options.subtitlesEnabled, isFalse);
        expect(options.showSubtitlesByDefault, isTrue);
      });

      test('subtitles with preferred language', () {
        const options = VideoPlayerOptions(showSubtitlesByDefault: true, preferredSubtitleLanguage: 'en');

        expect(options.subtitlesEnabled, isTrue);
        expect(options.showSubtitlesByDefault, isTrue);
        expect(options.preferredSubtitleLanguage, equals('en'));
      });

      test('background playback with mixWithOthers', () {
        const options = VideoPlayerOptions(allowBackgroundPlayback: true, mixWithOthers: true);

        expect(options.allowBackgroundPlayback, isTrue);
        expect(options.mixWithOthers, isTrue);
      });
    });

    group('copyWith edge cases', () {
      test('copyWith with no parameters returns equivalent options', () {
        const original = VideoPlayerOptions(autoPlay: true, volume: 0.8, looping: true);
        final copied = original.copyWith();

        expect(copied.autoPlay, equals(original.autoPlay));
        expect(copied.volume, equals(original.volume));
        expect(copied.looping, equals(original.looping));
        expect(copied, equals(original));
      });

      test('copyWith can change multiple values at once', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(
          autoPlay: true,
          looping: true,
          volume: 0.5,
          playbackSpeed: 1.5,
          subtitlesEnabled: false,
        );

        expect(copied.autoPlay, isTrue);
        expect(copied.looping, isTrue);
        expect(copied.volume, equals(0.5));
        expect(copied.playbackSpeed, equals(1.5));
        expect(copied.subtitlesEnabled, isFalse);
      });

      test('copyWith can set preferredSubtitleLanguage', () {
        const original = VideoPlayerOptions();
        final copied = original.copyWith(preferredSubtitleLanguage: 'es');

        expect(copied.preferredSubtitleLanguage, equals('es'));
      });
    });

    group('equality edge cases', () {
      test('options with different fullscreenOrientation are not equal', () {
        const options1 = VideoPlayerOptions();
        const options2 = VideoPlayerOptions(fullscreenOrientation: FullscreenOrientation.all);

        expect(options1, isNot(equals(options2)));
      });

      test('options with different preferredSubtitleLanguage are not equal', () {
        const options1 = VideoPlayerOptions(preferredSubtitleLanguage: 'en');
        const options2 = VideoPlayerOptions(preferredSubtitleLanguage: 'es');

        expect(options1, isNot(equals(options2)));
      });

      test('options with null vs non-null preferredSubtitleLanguage are not equal', () {
        const options1 = VideoPlayerOptions();
        const options2 = VideoPlayerOptions(preferredSubtitleLanguage: 'en');

        expect(options1, isNot(equals(options2)));
      });

      test('identical options are equal', () {
        const options = VideoPlayerOptions(autoPlay: true);
        expect(options, equals(options));
      });
    });
  });

  group('FullscreenOrientation', () {
    test('has all expected values', () {
      expect(FullscreenOrientation.values, hasLength(7));
      expect(FullscreenOrientation.values, contains(FullscreenOrientation.portraitUp));
      expect(FullscreenOrientation.values, contains(FullscreenOrientation.portraitDown));
      expect(FullscreenOrientation.values, contains(FullscreenOrientation.portraitBoth));
      expect(FullscreenOrientation.values, contains(FullscreenOrientation.landscapeLeft));
      expect(FullscreenOrientation.values, contains(FullscreenOrientation.landscapeRight));
      expect(FullscreenOrientation.values, contains(FullscreenOrientation.landscapeBoth));
      expect(FullscreenOrientation.values, contains(FullscreenOrientation.all));
    });

    test('landscapeBoth is the default for fullscreen video', () {
      // This is the most common use case for video fullscreen
      const options = VideoPlayerOptions();
      expect(options.fullscreenOrientation, equals(FullscreenOrientation.landscapeBoth));
    });
  });
}
