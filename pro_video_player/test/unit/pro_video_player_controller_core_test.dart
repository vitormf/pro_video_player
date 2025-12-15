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

  group('ProVideoPlayerController initialization', () {
    test('initial value has uninitialized state', () {
      expect(fixture.controller.value.playbackState, PlaybackState.uninitialized);
      expect(fixture.controller.isInitialized, isFalse);
      expect(fixture.controller.playerId, isNull);
    });

    test('initialize creates player and updates state', () async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      expect(fixture.controller.playerId, equals(1));
      expect(fixture.controller.isInitialized, isTrue);
      expect(fixture.controller.value.playbackState, PlaybackState.ready);
    });

    test('initialize with autoPlay calls play', () async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);
      when(() => fixture.mockPlatform.play(any())).thenAnswer((_) async {});

      await fixture.controller.initialize(
        source: const VideoSource.network('https://example.com/video.mp4'),
        options: const VideoPlayerOptions(autoPlay: true),
      );

      verify(() => fixture.mockPlatform.play(1)).called(1);
    });

    test('initialize throws if already initialized', () async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      expect(
        () => fixture.controller.initialize(source: const VideoSource.network('https://example.com/other.mp4')),
        throwsA(isA<StateError>()),
      );
    });

    test('initialize throws if disposed', () async {
      when(() => fixture.mockPlatform.dispose(any())).thenAnswer((_) async {});
      await fixture.controller.dispose();

      expect(
        () => fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4')),
        throwsA(isA<StateError>()),
      );
    });

    test('methods throw if not initialized', () {
      expect(() => fixture.controller.play(), throwsA(isA<StateError>()));
      expect(() => fixture.controller.pause(), throwsA(isA<StateError>()));
      expect(() => fixture.controller.stop(), throwsA(isA<StateError>()));
      expect(() => fixture.controller.seekTo(Duration.zero), throwsA(isA<StateError>()));
      expect(() => fixture.controller.setPlaybackSpeed(1), throwsA(isA<StateError>()));
      expect(() => fixture.controller.setVolume(1), throwsA(isA<StateError>()));
      expect(() => fixture.controller.setLooping(looping: true), throwsA(isA<StateError>()));
      expect(() => fixture.controller.setSubtitleTrack(null), throwsA(isA<StateError>()));
      expect(() => fixture.controller.setAudioTrack(null), throwsA(isA<StateError>()));
      expect(() => fixture.controller.enterPip(), throwsA(isA<StateError>()));
      expect(() => fixture.controller.exitPip(), throwsA(isA<StateError>()));
    });

    test('initialize sets error state on failure', () async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('Failed to create player'));

      await expectLater(
        fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4')),
        throwsA(isA<Exception>()),
      );

      expect(fixture.controller.value.playbackState, PlaybackState.error);
      expect(fixture.controller.value.errorMessage, isNotNull);
    });
  });

  group('ProVideoPlayerController disposal', () {
    test('dispose calls platform dispose', () async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);
      when(() => fixture.mockPlatform.dispose(any())).thenAnswer((_) async {});

      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));
      await fixture.controller.dispose();

      verify(() => fixture.mockPlatform.dispose(1)).called(1);
      expect(fixture.controller.isDisposed, isTrue);
      expect(fixture.controller.value.playbackState, PlaybackState.disposed);
    });

    test('methods throw after dispose', () async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);
      when(() => fixture.mockPlatform.dispose(any())).thenAnswer((_) async {});

      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));
      await fixture.controller.dispose();

      expect(() => fixture.controller.play(), throwsA(isA<StateError>()));
      expect(() => fixture.controller.pause(), throwsA(isA<StateError>()));
      expect(() => fixture.controller.seekTo(Duration.zero), throwsA(isA<StateError>()));
    });

    test('double dispose is safe', () async {
      when(() => fixture.mockPlatform.dispose(any())).thenAnswer((_) async {});

      await fixture.controller.dispose();
      await fixture.controller.dispose();

      // Should not throw
    });
  });

  group('ProVideoPlayerController options getter', () {
    test('returns options passed during initialization', () async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      when(() => fixture.mockPlatform.play(any())).thenAnswer((_) async {});

      const customOptions = VideoPlayerOptions(autoPlay: true, looping: true, volume: 0.5);

      await fixture.controller.initialize(
        source: const VideoSource.network('https://example.com/video.mp4'),
        options: customOptions,
      );

      expect(fixture.controller.options.autoPlay, isTrue);
      expect(fixture.controller.options.looping, isTrue);
      expect(fixture.controller.options.volume, equals(0.5));
    });
  });
}
