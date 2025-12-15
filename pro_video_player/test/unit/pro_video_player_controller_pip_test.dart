import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ControllerTestFixture fixture;

  setUpAll(registerFallbackValues);

  setUp(() {
    fixture = ControllerTestFixture();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  group('ProVideoPlayerController pip', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));
    });

    test('enterPip calls platform and returns result', () async {
      when(() => fixture.mockPlatform.isPipSupported()).thenAnswer((_) async => true);
      when(() => fixture.mockPlatform.enterPip(any(), options: any(named: 'options'))).thenAnswer((_) async => true);

      final result = await fixture.controller.enterPip();

      expect(result, isTrue);
      verify(() => fixture.mockPlatform.isPipSupported()).called(1);
      verify(() => fixture.mockPlatform.enterPip(1)).called(1);
    });

    test('enterPip passes options', () async {
      when(() => fixture.mockPlatform.isPipSupported()).thenAnswer((_) async => true);
      when(() => fixture.mockPlatform.enterPip(any(), options: any(named: 'options'))).thenAnswer((_) async => true);

      const options = PipOptions(aspectRatio: 1.78, autoEnterOnBackground: true);
      await fixture.controller.enterPip(options: options);

      verify(() => fixture.mockPlatform.enterPip(1, options: options)).called(1);
    });

    test('enterPip returns false when PiP is not supported', () async {
      when(() => fixture.mockPlatform.isPipSupported()).thenAnswer((_) async => false);

      final result = await fixture.controller.enterPip();

      expect(result, isFalse);
      verify(() => fixture.mockPlatform.isPipSupported()).called(1);
      verifyNever(() => fixture.mockPlatform.enterPip(any(), options: any(named: 'options')));
    });

    test('exitPip calls platform', () async {
      when(() => fixture.mockPlatform.exitPip(any())).thenAnswer((_) async {});

      await fixture.controller.exitPip();

      verify(() => fixture.mockPlatform.exitPip(1)).called(1);
    });

    test('isPipSupported calls platform', () async {
      when(() => fixture.mockPlatform.isPipSupported()).thenAnswer((_) async => true);

      final result = await fixture.controller.isPipSupported();

      expect(result, isTrue);
      verify(() => fixture.mockPlatform.isPipSupported()).called(1);
    });
  });

  group('ProVideoPlayerController pip availability', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);
    });

    test('isPipAvailable returns false when allowPip is false', () async {
      await fixture.controller.initialize(
        source: const VideoSource.network('https://example.com/video.mp4'),
        options: const VideoPlayerOptions(allowPip: false),
      );

      when(() => fixture.mockPlatform.isPipSupported()).thenAnswer((_) async => true);

      final result = await fixture.controller.isPipAvailable();

      expect(result, isFalse);
      // isPipSupported should not be called when allowPip is false
      verifyNever(() => fixture.mockPlatform.isPipSupported());
    });

    test('isPipAvailable returns platform support when allowPip is true', () async {
      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      when(() => fixture.mockPlatform.isPipSupported()).thenAnswer((_) async => true);

      final result = await fixture.controller.isPipAvailable();

      expect(result, isTrue);
      verify(() => fixture.mockPlatform.isPipSupported()).called(1);
    });

    test('enterPip returns false when allowPip is false', () async {
      await fixture.controller.initialize(
        source: const VideoSource.network('https://example.com/video.mp4'),
        options: const VideoPlayerOptions(allowPip: false),
      );

      final result = await fixture.controller.enterPip();

      expect(result, isFalse);
      verifyNever(() => fixture.mockPlatform.isPipSupported());
      verifyNever(() => fixture.mockPlatform.enterPip(any(), options: any(named: 'options')));
    });
  });
}
