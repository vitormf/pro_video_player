import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../shared/test_constants.dart';
import '../shared/test_matchers.dart';
import '../shared/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerTestFixture fixture;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    fixture = VideoPlayerTestFixture()..setUp();
  });

  tearDown(() async {
    await fixture.tearDown();
  });

  group('ProVideoPlayerController settings', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
    });

    test('setPlaybackSpeed calls platform and updates value', () async {
      when(() => fixture.mockPlatform.setPlaybackSpeed(any(), any())).thenAnswer((_) async {});

      await fixture.controller.setPlaybackSpeed(1.5);

      verify(() => fixture.mockPlatform.setPlaybackSpeed(1, 1.5)).called(1);
      expect(fixture.controller, hasSpeed(1.5));
    });

    test('setPlaybackSpeed throws for invalid speed', () async {
      expect(() => fixture.controller.setPlaybackSpeed(0), throwsA(isA<ArgumentError>()));
      expect(() => fixture.controller.setPlaybackSpeed(-1), throwsA(isA<ArgumentError>()));
    });

    test('setVolume calls platform and updates value', () async {
      when(() => fixture.mockPlatform.setVolume(any(), any())).thenAnswer((_) async {});

      await fixture.controller.setVolume(0.5);

      verify(() => fixture.mockPlatform.setVolume(1, 0.5)).called(1);
      expect(fixture.controller, hasVolume(0.5));
    });

    test('setVolume throws for invalid volume', () async {
      expect(() => fixture.controller.setVolume(-0.1), throwsA(isA<ArgumentError>()));
      expect(() => fixture.controller.setVolume(1.1), throwsA(isA<ArgumentError>()));
    });

    test('setLooping calls platform and updates value', () async {
      when(() => fixture.mockPlatform.setLooping(any(), any())).thenAnswer((_) async {});

      await fixture.controller.setLooping(true);

      verify(() => fixture.mockPlatform.setLooping(1, true)).called(1);
      expect(fixture.controller, isLooping);
    });

    test('setSubtitleTrack calls platform and updates value', () async {
      when(() => fixture.mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});

      const track = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      await fixture.controller.setSubtitleTrack(track);

      verify(() => fixture.mockPlatform.setSubtitleTrack(1, track)).called(1);
      expect(fixture.controller.value.selectedSubtitleTrack, equals(track));
    });

    test('setSubtitleTrack with null clears selection', () async {
      when(() => fixture.mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});

      await fixture.controller.setSubtitleTrack(null);

      verify(() => fixture.mockPlatform.setSubtitleTrack(1, null)).called(1);
      expect(fixture.controller.value.selectedSubtitleTrack, isNull);
    });

    test('setAudioTrack calls platform and updates value', () async {
      when(() => fixture.mockPlatform.setAudioTrack(any(), any())).thenAnswer((_) async {});

      const track = AudioTrack(id: 'en', label: 'English (5.1)', language: 'en');
      await fixture.controller.setAudioTrack(track);

      verify(() => fixture.mockPlatform.setAudioTrack(1, track)).called(1);
      expect(fixture.controller.value.selectedAudioTrack, equals(track));
    });

    test('setAudioTrack with null clears selection', () async {
      when(() => fixture.mockPlatform.setAudioTrack(any(), any())).thenAnswer((_) async {});

      await fixture.controller.setAudioTrack(null);

      verify(() => fixture.mockPlatform.setAudioTrack(1, null)).called(1);
      expect(fixture.controller.value.selectedAudioTrack, isNull);
    });
  });

  group('ProVideoPlayerController scaling mode', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
    });

    test('setScalingMode calls platform', () async {
      when(() => fixture.mockPlatform.setScalingMode(any(), any())).thenAnswer((_) async {});

      await fixture.controller.setScalingMode(VideoScalingMode.fill);

      verify(() => fixture.mockPlatform.setScalingMode(1, VideoScalingMode.fill)).called(1);
    });

    test('setScalingMode throws when not initialized', () async {
      final uninitializedController = ProVideoPlayerController();

      expect(() => uninitializedController.setScalingMode(VideoScalingMode.fit), throwsA(isA<StateError>()));
    });
  });

  group('ProVideoPlayerController background playback', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
    });

    test('setBackgroundPlayback calls platform and updates value on success', () async {
      when(
        () => fixture.mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled')),
      ).thenAnswer((_) async => true);

      final result = await fixture.controller.setBackgroundPlayback(enabled: true);

      expect(result, isTrue);
      verify(() => fixture.mockPlatform.setBackgroundPlayback(1, enabled: true)).called(1);
      expect(fixture.controller.value.isBackgroundPlaybackEnabled, isTrue);
    });

    test('setBackgroundPlayback does not update value on failure', () async {
      when(
        () => fixture.mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled')),
      ).thenAnswer((_) async => false);

      final result = await fixture.controller.setBackgroundPlayback(enabled: true);

      expect(result, isFalse);
      expect(fixture.controller.value.isBackgroundPlaybackEnabled, isFalse);
    });

    test('isBackgroundPlaybackSupported calls platform', () async {
      when(() => fixture.mockPlatform.isBackgroundPlaybackSupported()).thenAnswer((_) async => true);

      final result = await fixture.controller.isBackgroundPlaybackSupported();

      expect(result, isTrue);
      verify(() => fixture.mockPlatform.isBackgroundPlaybackSupported()).called(1);
    });

    test('isBackgroundPlaybackEnabled returns value', () async {
      when(
        () => fixture.mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled')),
      ).thenAnswer((_) async => true);

      expect(fixture.controller.isBackgroundPlaybackEnabled, isFalse);

      await fixture.controller.setBackgroundPlayback(enabled: true);

      expect(fixture.controller.isBackgroundPlaybackEnabled, isTrue);
    });

    test('updates value on BackgroundPlaybackChangedEvent', () async {
      fixture.emitEvent(const BackgroundPlaybackChangedEvent(isEnabled: true));
      await fixture.waitForEvents();

      expect(fixture.controller.value.isBackgroundPlaybackEnabled, isTrue);
    });

    test('setBackgroundPlayback is no-op on macOS and always returns true', () async {
      // Override target platform to macOS
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      // Should not call platform since macOS always has background playback enabled
      final result = await fixture.controller.setBackgroundPlayback(enabled: false);

      expect(result, isTrue);
      // Value should be set to true regardless of enabled parameter
      expect(fixture.controller.value.isBackgroundPlaybackEnabled, isTrue);
      // Platform method should NOT have been called
      verifyNever(() => fixture.mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled')));
    });
  });
}
