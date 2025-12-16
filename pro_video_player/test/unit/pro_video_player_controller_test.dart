import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../shared/mocks.dart';
import '../shared/test_constants.dart';
import '../shared/test_matchers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late ProVideoPlayerController controller;
  late StreamController<VideoPlayerEvent> eventController;

  setUpAll(() {
    // Register fallback values for mocktail using actual instances
    // since VideoSource is a sealed class
    registerFallbackValue(const VideoSource.network('https://example.com'));
    registerFallbackValue(const VideoPlayerOptions());
    registerFallbackValue(const PipOptions());
    registerFallbackValue(const SubtitleTrack(id: 'test', label: 'Test'));
    registerFallbackValue(const AudioTrack(id: 'test', label: 'Test'));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(VideoScalingMode.fit);
    registerFallbackValue(VideoQualityTrack.auto);
    registerFallbackValue(MediaMetadata.empty);
    registerFallbackValue(const SubtitleSource.network('https://example.com/subs.vtt'));
    registerFallbackValue(FullscreenOrientation.landscapeBoth);
  });

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    ProVideoPlayerPlatform.instance = mockPlatform;
    controller = ProVideoPlayerController();
    eventController = StreamController<VideoPlayerEvent>.broadcast();

    when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);
  });

  tearDown(() async {
    await eventController.close();
    if (!controller.isDisposed) {
      when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
      await controller.dispose();
    }
  });

  group('ProVideoPlayerController', () {
    group('initialization', () {
      test('initial value has uninitialized state', () {
        expect(controller, isUninitialized);
        expect(controller.isInitialized, isFalse);
        expect(controller.playerId, isNull);
      });

      test('initialize creates player and updates state', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        expect(controller.playerId, equals(1));
        expect(controller.isInitialized, isTrue);
        expect(controller, isReady);
      });

      test('initialize with autoPlay calls play', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(autoPlay: true),
        );

        verify(() => mockPlatform.play(1)).called(1);
      });

      test('initialize throws if already initialized', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        expect(
          () => controller.initialize(source: const VideoSource.network('https://example.com/other.mp4')),
          throwsA(isA<StateError>()),
        );
      });

      test('initialize throws if disposed', () async {
        when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
        await controller.dispose();

        expect(
          () => controller.initialize(source: const VideoSource.network(TestMedia.networkUrl)),
          throwsA(isA<StateError>()),
        );
      });

      test('methods throw if not initialized', () {
        expect(() => controller.play(), throwsA(isA<StateError>()));
        expect(() => controller.pause(), throwsA(isA<StateError>()));
        expect(() => controller.stop(), throwsA(isA<StateError>()));
        expect(() => controller.seekTo(Duration.zero), throwsA(isA<StateError>()));
        expect(() => controller.setPlaybackSpeed(1), throwsA(isA<StateError>()));
        expect(() => controller.setVolume(1), throwsA(isA<StateError>()));
        expect(() => controller.setLooping(true), throwsA(isA<StateError>()));
        expect(() => controller.setSubtitleTrack(null), throwsA(isA<StateError>()));
        expect(() => controller.setAudioTrack(null), throwsA(isA<StateError>()));
        expect(() => controller.enterPip(), throwsA(isA<StateError>()));
        expect(() => controller.exitPip(), throwsA(isA<StateError>()));
      });

      test('initialize sets error state on failure', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenThrow(Exception('Failed to create player'));

        await expectLater(
          controller.initialize(source: const VideoSource.network(TestMedia.networkUrl)),
          throwsA(isA<Exception>()),
        );

        expect(controller, hasError);
        expect(controller.value.errorMessage, isNotNull);
      });
    });

    group('playback control', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('play calls platform play', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        await controller.play();

        verify(() => mockPlatform.play(1)).called(1);
      });

      test('pause calls platform pause', () async {
        when(() => mockPlatform.pause(any())).thenAnswer((_) async {});

        await controller.pause();

        verify(() => mockPlatform.pause(1)).called(1);
      });

      test('stop calls platform stop', () async {
        when(() => mockPlatform.stop(any())).thenAnswer((_) async {});

        await controller.stop();

        verify(() => mockPlatform.stop(1)).called(1);
      });

      test('seekTo calls platform seekTo', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        await controller.seekTo(const Duration(seconds: 30));

        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 30))).called(1);
      });

      test('seekForward seeks forward by duration', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        // Set initial position and duration via events
        eventController
          ..add(const PositionChangedEvent(Duration(seconds: 30)))
          ..add(const DurationChangedEvent(TestMetadata.duration));
        await Future<void>.delayed(Duration.zero);

        await controller.seekForward(const Duration(seconds: 10));

        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 40))).called(1);
      });

      test('seekForward clamps to duration', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        // Set position near end
        eventController
          ..add(const PositionChangedEvent(Duration(seconds: 55)))
          ..add(const DurationChangedEvent(Duration(minutes: 1)));
        await Future<void>.delayed(Duration.zero);

        await controller.seekForward(const Duration(seconds: 10));

        verify(() => mockPlatform.seekTo(1, const Duration(minutes: 1))).called(1);
      });

      test('seekBackward seeks backward by duration', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        // Set initial position
        eventController.add(const PositionChangedEvent(Duration(seconds: 30)));
        await Future<void>.delayed(Duration.zero);

        await controller.seekBackward(const Duration(seconds: 10));

        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 20))).called(1);
      });

      test('seekBackward clamps to zero', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        // Set position near start
        eventController.add(const PositionChangedEvent(Duration(seconds: 5)));
        await Future<void>.delayed(Duration.zero);

        await controller.seekBackward(const Duration(seconds: 10));

        verify(() => mockPlatform.seekTo(1, Duration.zero)).called(1);
      });

      test('togglePlayPause pauses when playing', () async {
        when(() => mockPlatform.pause(any())).thenAnswer((_) async {});

        eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
        await Future<void>.delayed(Duration.zero);

        await controller.togglePlayPause();

        verify(() => mockPlatform.pause(1)).called(1);
      });

      test('togglePlayPause plays when paused', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
        await Future<void>.delayed(Duration.zero);

        await controller.togglePlayPause();

        verify(() => mockPlatform.play(1)).called(1);
      });
    });

    group('settings', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('setPlaybackSpeed calls platform and updates value', () async {
        when(() => mockPlatform.setPlaybackSpeed(any(), any())).thenAnswer((_) async {});

        await controller.setPlaybackSpeed(1.5);

        verify(() => mockPlatform.setPlaybackSpeed(1, 1.5)).called(1);
        expect(controller, hasSpeed(1.5));
      });

      test('setPlaybackSpeed throws for invalid speed', () async {
        expect(() => controller.setPlaybackSpeed(0), throwsA(isA<ArgumentError>()));
        expect(() => controller.setPlaybackSpeed(-1), throwsA(isA<ArgumentError>()));
      });

      test('setVolume calls platform and updates value', () async {
        when(() => mockPlatform.setVolume(any(), any())).thenAnswer((_) async {});

        await controller.setVolume(0.5);

        verify(() => mockPlatform.setVolume(1, 0.5)).called(1);
        expect(controller, hasVolume(0.5));
      });

      test('setVolume throws for invalid volume', () async {
        expect(() => controller.setVolume(-0.1), throwsA(isA<ArgumentError>()));
        expect(() => controller.setVolume(1.1), throwsA(isA<ArgumentError>()));
      });

      test('setLooping calls platform and updates value', () async {
        when(() => mockPlatform.setLooping(any(), any())).thenAnswer((_) async {});

        await controller.setLooping(true);

        verify(() => mockPlatform.setLooping(1, true)).called(1);
        expect(controller, isLooping);
      });

      test('setSubtitleTrack calls platform and updates value', () async {
        when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});

        const track = SubtitleTrack(id: 'en', label: 'English', language: 'en');
        await controller.setSubtitleTrack(track);

        verify(() => mockPlatform.setSubtitleTrack(1, track)).called(1);
        expect(controller.value.selectedSubtitleTrack, equals(track));
      });

      test('setSubtitleTrack with null clears selection', () async {
        when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});

        await controller.setSubtitleTrack(null);

        verify(() => mockPlatform.setSubtitleTrack(1, null)).called(1);
        expect(controller.value.selectedSubtitleTrack, isNull);
      });

      test('setAudioTrack calls platform and updates value', () async {
        when(() => mockPlatform.setAudioTrack(any(), any())).thenAnswer((_) async {});

        const track = AudioTrack(id: 'en', label: 'English (5.1)', language: 'en');
        await controller.setAudioTrack(track);

        verify(() => mockPlatform.setAudioTrack(1, track)).called(1);
        expect(controller.value.selectedAudioTrack, equals(track));
      });

      test('setAudioTrack with null clears selection', () async {
        when(() => mockPlatform.setAudioTrack(any(), any())).thenAnswer((_) async {});

        await controller.setAudioTrack(null);

        verify(() => mockPlatform.setAudioTrack(1, null)).called(1);
        expect(controller.value.selectedAudioTrack, isNull);
      });
    });

    group('pip', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('enterPip calls platform and returns result', () async {
        when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);
        when(() => mockPlatform.enterPip(any(), options: any(named: 'options'))).thenAnswer((_) async => true);

        final result = await controller.enterPip();

        expect(result, isTrue);
        verify(() => mockPlatform.isPipSupported()).called(1);
        verify(() => mockPlatform.enterPip(1)).called(1);
      });

      test('enterPip passes options', () async {
        when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);
        when(() => mockPlatform.enterPip(any(), options: any(named: 'options'))).thenAnswer((_) async => true);

        const options = PipOptions(aspectRatio: 1.78, autoEnterOnBackground: true);
        await controller.enterPip(options: options);

        verify(() => mockPlatform.enterPip(1, options: options)).called(1);
      });

      test('enterPip returns false when PiP is not supported', () async {
        when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => false);

        final result = await controller.enterPip();

        expect(result, isFalse);
        verify(() => mockPlatform.isPipSupported()).called(1);
        verifyNever(() => mockPlatform.enterPip(any(), options: any(named: 'options')));
      });

      test('exitPip calls platform', () async {
        when(() => mockPlatform.exitPip(any())).thenAnswer((_) async {});

        await controller.exitPip();

        verify(() => mockPlatform.exitPip(1)).called(1);
      });

      test('isPipSupported calls platform', () async {
        when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);

        final result = await controller.isPipSupported();

        expect(result, isTrue);
        verify(() => mockPlatform.isPipSupported()).called(1);
      });
    });

    group('fullscreen', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        // Mock SystemChrome calls
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async => null,
        );

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('enterFullscreen calls platform and updates value', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        final result = await controller.enterFullscreen();

        expect(result, isTrue);
        expect(controller, isInFullscreen);
        verify(() => mockPlatform.enterFullscreen(1)).called(1);
      });

      test('enterFullscreen with custom orientation calls platform', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        await controller.enterFullscreen(orientation: FullscreenOrientation.portraitBoth);

        expect(controller, isInFullscreen);
        verify(() => mockPlatform.enterFullscreen(1)).called(1);
      });

      test('enterFullscreen with all orientation options', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
        when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

        // Test all orientation options work without error
        for (final orientation in FullscreenOrientation.values) {
          await controller.enterFullscreen(orientation: orientation);
          await controller.exitFullscreen();
        }
      });

      test('exitFullscreen calls platform and updates value', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
        when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

        // Enter fullscreen first
        await controller.enterFullscreen();
        expect(controller, isInFullscreen);

        // Exit fullscreen
        await controller.exitFullscreen();

        expect(controller, isNotInFullscreen);
        verify(() => mockPlatform.exitFullscreen(1)).called(1);
      });

      test('toggleFullscreen enters fullscreen when not in fullscreen', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        await controller.toggleFullscreen();

        expect(controller, isInFullscreen);
        verify(() => mockPlatform.enterFullscreen(1)).called(1);
      });

      test('toggleFullscreen exits fullscreen when in fullscreen', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
        when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

        // Enter fullscreen first
        await controller.enterFullscreen();

        // Toggle should exit
        await controller.toggleFullscreen();

        expect(controller, isNotInFullscreen);
        verify(() => mockPlatform.exitFullscreen(1)).called(1);
      });

      test('enterFullscreen throws when not initialized', () async {
        final uninitializedController = ProVideoPlayerController();

        expect(uninitializedController.enterFullscreen, throwsA(isA<StateError>()));
      });

      test('exitFullscreen throws when not initialized', () async {
        final uninitializedController = ProVideoPlayerController();

        expect(uninitializedController.exitFullscreen, throwsA(isA<StateError>()));
      });

      test('updates value on FullscreenStateChangedEvent', () async {
        eventController.add(const FullscreenStateChangedEvent(isFullscreen: true));
        await Future<void>.delayed(Duration.zero);

        expect(controller, isInFullscreen);

        eventController.add(const FullscreenStateChangedEvent(isFullscreen: false));
        await Future<void>.delayed(Duration.zero);

        expect(controller, isNotInFullscreen);
      });
    });

    group('event handling', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('updates value on PlaybackStateChangedEvent', () async {
        eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
        await Future<void>.delayed(Duration.zero);

        expect(controller, isPlaying);
      });

      test('updates value on PositionChangedEvent', () async {
        eventController.add(const PositionChangedEvent(Duration(seconds: 30)));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.position, const Duration(seconds: 30));
      });

      test('updates value on DurationChangedEvent', () async {
        eventController.add(const DurationChangedEvent(TestMetadata.duration));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.duration, TestMetadata.duration);
      });

      test('updates value on VideoSizeChangedEvent', () async {
        eventController.add(const VideoSizeChangedEvent(width: 1920, height: 1080));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.size, equals((width: 1920, height: 1080)));
      });

      test('updates value on ErrorEvent', () async {
        eventController.add(ErrorEvent('Playback error'));
        await Future<void>.delayed(Duration.zero);

        expect(controller, hasError);
        expect(controller.value.errorMessage, 'Playback error');
      });

      test('updates value on PipStateChangedEvent', () async {
        eventController.add(const PipStateChangedEvent(isActive: true));
        await Future<void>.delayed(Duration.zero);

        expect(controller, isInPip);
      });

      test('updates value on BufferedPositionChangedEvent', () async {
        eventController.add(const BufferedPositionChangedEvent(Duration(seconds: 60)));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.bufferedPosition, const Duration(seconds: 60));
      });

      test('updates value on PlaybackCompletedEvent', () async {
        eventController.add(const PlaybackCompletedEvent());
        await Future<void>.delayed(Duration.zero);

        expect(controller, isCompleted);
      });

      test('updates value on SubtitleTracksChangedEvent', () async {
        const tracks = [
          SubtitleTrack(id: 'en', label: 'English', language: 'en'),
          SubtitleTrack(id: 'es', label: 'Spanish', language: 'es'),
        ];
        eventController.add(const SubtitleTracksChangedEvent(tracks));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.subtitleTracks, equals(tracks));
      });

      test('updates value on SelectedSubtitleChangedEvent', () async {
        const track = SubtitleTrack(id: 'en', label: 'English', language: 'en');
        eventController.add(const SelectedSubtitleChangedEvent(track));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.selectedSubtitleTrack, equals(track));
      });

      test('updates value on SelectedSubtitleChangedEvent with null', () async {
        eventController.add(const SelectedSubtitleChangedEvent(null));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.selectedSubtitleTrack, isNull);
      });

      test('updates value on PlaybackSpeedChangedEvent', () async {
        eventController.add(const PlaybackSpeedChangedEvent(2));
        await Future<void>.delayed(Duration.zero);

        expect(controller, hasSpeed(2));
      });

      test('updates value on VolumeChangedEvent', () async {
        eventController.add(const VolumeChangedEvent(0.5));
        await Future<void>.delayed(Duration.zero);

        expect(controller, hasVolume(0.5));
      });

      test('updates value on AudioTracksChangedEvent', () async {
        const tracks = [
          AudioTrack(id: 'en', label: 'English (5.1)', language: 'en'),
          AudioTrack(id: 'es', label: 'Spanish', language: 'es'),
        ];
        eventController.add(const AudioTracksChangedEvent(tracks));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.audioTracks, equals(tracks));
      });

      test('updates value on SelectedAudioChangedEvent', () async {
        const track = AudioTrack(id: 'en', label: 'English (5.1)', language: 'en');
        eventController.add(const SelectedAudioChangedEvent(track));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.selectedAudioTrack, equals(track));
      });

      test('updates value on SelectedAudioChangedEvent with null', () async {
        eventController.add(const SelectedAudioChangedEvent(null));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.selectedAudioTrack, isNull);
      });
    });

    group('disposal', () {
      test('dispose calls platform dispose', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);
        when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
        await controller.dispose();

        verify(() => mockPlatform.dispose(1)).called(1);
        expect(controller, isDisposed);
        expect(controller.value.playbackState, PlaybackState.disposed);
      });

      test('methods throw after dispose', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);
        when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
        await controller.dispose();

        expect(() => controller.play(), throwsA(isA<StateError>()));
        expect(() => controller.pause(), throwsA(isA<StateError>()));
        expect(() => controller.seekTo(Duration.zero), throwsA(isA<StateError>()));
      });

      test('double dispose is safe', () async {
        when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});

        await controller.dispose();
        await controller.dispose();

        // Should not throw
      });
    });

    group('scaling mode', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('setScalingMode calls platform', () async {
        when(() => mockPlatform.setScalingMode(any(), any())).thenAnswer((_) async {});

        await controller.setScalingMode(VideoScalingMode.fill);

        verify(() => mockPlatform.setScalingMode(1, VideoScalingMode.fill)).called(1);
      });

      test('setScalingMode throws when not initialized', () async {
        final uninitializedController = ProVideoPlayerController();

        expect(() => uninitializedController.setScalingMode(VideoScalingMode.fit), throwsA(isA<StateError>()));
      });
    });

    group('video quality', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('setVideoQuality calls platform and updates value on success', () async {
        const track = VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000);
        when(() => mockPlatform.setVideoQuality(any(), any())).thenAnswer((_) async => true);

        final result = await controller.setVideoQuality(track);

        expect(result, isTrue);
        verify(() => mockPlatform.setVideoQuality(1, track)).called(1);
        expect(controller.value.selectedQualityTrack, equals(track));
      });

      test('setVideoQuality does not update value on failure', () async {
        const track = VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000);
        when(() => mockPlatform.setVideoQuality(any(), any())).thenAnswer((_) async => false);

        final result = await controller.setVideoQuality(track);

        expect(result, isFalse);
        expect(controller.value.selectedQualityTrack, isNull);
      });

      test('setVideoQuality with auto clears selection', () async {
        when(() => mockPlatform.setVideoQuality(any(), any())).thenAnswer((_) async => true);

        await controller.setVideoQuality(VideoQualityTrack.auto);

        expect(controller.value.selectedQualityTrack, isNull);
      });

      test('getVideoQualities calls platform', () async {
        const tracks = [
          VideoQualityTrack.auto,
          VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
        ];
        when(() => mockPlatform.getVideoQualities(any())).thenAnswer((_) async => tracks);

        final result = await controller.getVideoQualities();

        expect(result, equals(tracks));
        verify(() => mockPlatform.getVideoQualities(1)).called(1);
      });

      test('getCurrentVideoQuality calls platform', () async {
        const track = VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000);
        when(() => mockPlatform.getCurrentVideoQuality(any())).thenAnswer((_) async => track);

        final result = await controller.getCurrentVideoQuality();

        expect(result, equals(track));
        verify(() => mockPlatform.getCurrentVideoQuality(1)).called(1);
      });

      test('isQualitySelectionSupported calls platform', () async {
        when(() => mockPlatform.isQualitySelectionSupported(any())).thenAnswer((_) async => true);

        final result = await controller.isQualitySelectionSupported();

        expect(result, isTrue);
        verify(() => mockPlatform.isQualitySelectionSupported(1)).called(1);
      });

      test('updates value on VideoQualityTracksChangedEvent', () async {
        const tracks = [
          VideoQualityTrack.auto,
          VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
        ];
        eventController.add(const VideoQualityTracksChangedEvent(tracks));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.qualityTracks, equals(tracks));
      });

      test('updates value on SelectedQualityChangedEvent', () async {
        const track = VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000);
        eventController.add(const SelectedQualityChangedEvent(track));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.selectedQualityTrack, equals(track));
      });
    });

    group('background playback', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('setBackgroundPlayback calls platform and updates value on success', () async {
        when(
          () => mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled')),
        ).thenAnswer((_) async => true);

        final result = await controller.setBackgroundPlayback(enabled: true);

        expect(result, isTrue);
        verify(() => mockPlatform.setBackgroundPlayback(1, enabled: true)).called(1);
        expect(controller.value.isBackgroundPlaybackEnabled, isTrue);
      });

      test('setBackgroundPlayback does not update value on failure', () async {
        when(
          () => mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled')),
        ).thenAnswer((_) async => false);

        final result = await controller.setBackgroundPlayback(enabled: true);

        expect(result, isFalse);
        expect(controller.value.isBackgroundPlaybackEnabled, isFalse);
      });

      test('isBackgroundPlaybackSupported calls platform', () async {
        when(() => mockPlatform.isBackgroundPlaybackSupported()).thenAnswer((_) async => true);

        final result = await controller.isBackgroundPlaybackSupported();

        expect(result, isTrue);
        verify(() => mockPlatform.isBackgroundPlaybackSupported()).called(1);
      });

      test('isBackgroundPlaybackEnabled returns value', () async {
        when(
          () => mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled')),
        ).thenAnswer((_) async => true);

        expect(controller.isBackgroundPlaybackEnabled, isFalse);

        await controller.setBackgroundPlayback(enabled: true);

        expect(controller.isBackgroundPlaybackEnabled, isTrue);
      });

      test('updates value on BackgroundPlaybackChangedEvent', () async {
        eventController.add(const BackgroundPlaybackChangedEvent(isEnabled: true));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.isBackgroundPlaybackEnabled, isTrue);
      });

      test('setBackgroundPlayback is no-op on macOS and always returns true', () async {
        // Override target platform to macOS
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        // Should not call platform since macOS always has background playback enabled
        final result = await controller.setBackgroundPlayback(enabled: false);

        expect(result, isTrue);
        // Value should be set to true regardless of enabled parameter
        expect(controller.value.isBackgroundPlaybackEnabled, isTrue);
        // Platform method should NOT have been called
        verifyNever(() => mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled')));
      });
    });

    group('media metadata', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('setMediaMetadata calls platform', () async {
        when(() => mockPlatform.setMediaMetadata(any(), any())).thenAnswer((_) async {});

        const metadata = MediaMetadata(title: 'Test Video', artist: 'Test Artist');
        await controller.setMediaMetadata(metadata);

        verify(() => mockPlatform.setMediaMetadata(1, metadata)).called(1);
      });

      test('setMediaMetadata throws when not initialized', () async {
        final uninitializedController = ProVideoPlayerController();

        expect(() => uninitializedController.setMediaMetadata(MediaMetadata.empty), throwsA(isA<StateError>()));
      });

      test('updates value on MetadataChangedEvent', () async {
        eventController.add(const MetadataChangedEvent(title: 'New Title'));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.title, equals('New Title'));
      });

      test('updates value on EmbeddedSubtitleCueEvent with cue', () async {
        const cue = SubtitleCue(text: 'Hello world', start: Duration(seconds: 1), end: Duration(seconds: 3));
        eventController.add(const EmbeddedSubtitleCueEvent(cue: cue, trackId: 'track-1'));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.currentEmbeddedCue, equals(cue));
      });

      test('updates value on EmbeddedSubtitleCueEvent with null cue (hides subtitle)', () async {
        // First set a cue
        const cue = SubtitleCue(text: 'Hello world', start: Duration(seconds: 1), end: Duration(seconds: 3));
        eventController.add(const EmbeddedSubtitleCueEvent(cue: cue));
        await Future<void>.delayed(Duration.zero);
        expect(controller.value.currentEmbeddedCue, equals(cue));

        // Then clear it with null
        eventController.add(const EmbeddedSubtitleCueEvent(cue: null));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.currentEmbeddedCue, isNull);
      });
    });

    group('pip availability', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);
      });

      test('isPipAvailable returns false when allowPip is false', () async {
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(allowPip: false),
        );

        when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);

        final result = await controller.isPipAvailable();

        expect(result, isFalse);
        // isPipSupported should not be called when allowPip is false
        verifyNever(() => mockPlatform.isPipSupported());
      });

      test('isPipAvailable returns platform support when allowPip is true', () async {
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);

        final result = await controller.isPipAvailable();

        expect(result, isTrue);
        verify(() => mockPlatform.isPipSupported()).called(1);
      });

      test('enterPip returns false when allowPip is false', () async {
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(allowPip: false),
        );

        final result = await controller.enterPip();

        expect(result, isFalse);
        verifyNever(() => mockPlatform.isPipSupported());
        verifyNever(() => mockPlatform.enterPip(any(), options: any(named: 'options')));
      });
    });

    group('subtitles configuration', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);
      });

      test('subtitlesEnabled returns options value', () async {
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(subtitlesEnabled: false),
        );

        expect(controller.subtitlesEnabled, isFalse);
      });

      test('setSubtitleTrack returns early when subtitles disabled', () async {
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(subtitlesEnabled: false),
        );

        const track = SubtitleTrack(id: 'en', label: 'English');
        await controller.setSubtitleTrack(track);

        // Should not call platform method when disabled
        verifyNever(() => mockPlatform.setSubtitleTrack(any(), any()));
      });

      test('SubtitleTracksChangedEvent is ignored when subtitles disabled', () async {
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(subtitlesEnabled: false),
        );

        const tracks = [SubtitleTrack(id: 'en', label: 'English')];
        eventController.add(const SubtitleTracksChangedEvent(tracks));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.subtitleTracks, isEmpty);
      });

      test('auto-selects subtitle when showSubtitlesByDefault is true', () async {
        when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});

        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(showSubtitlesByDefault: true),
        );

        const tracks = [SubtitleTrack(id: 'en', label: 'English', language: 'en')];
        eventController.add(const SubtitleTracksChangedEvent(tracks));
        await Future<void>.delayed(Duration.zero);

        // Auto-selection should trigger setSubtitleTrack
        verify(() => mockPlatform.setSubtitleTrack(1, tracks[0])).called(1);
      });

      test('auto-selects preferred language subtitle', () async {
        when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});

        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(showSubtitlesByDefault: true, preferredSubtitleLanguage: 'es'),
        );

        const tracks = [
          SubtitleTrack(id: 'en', label: 'English', language: 'en'),
          SubtitleTrack(id: 'es', label: 'Spanish', language: 'es'),
        ];
        eventController.add(const SubtitleTracksChangedEvent(tracks));
        await Future<void>.delayed(Duration.zero);

        // Should select Spanish (preferred language)
        verify(() => mockPlatform.setSubtitleTrack(1, tracks[1])).called(1);
      });
    });

    group('error recovery', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});
        when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('clearError resets error state', () async {
        // Set error state
        eventController.add(ErrorEvent('Test error'));
        await Future<void>.delayed(Duration.zero);
        expect(controller.value.hasError, isTrue);

        controller.clearError();

        expect(controller.value.hasError, isFalse);
        expect(controller, isReady);
      });

      test('clearError does nothing if no error', () async {
        expect(controller, isReady);

        controller.clearError();

        expect(controller, isReady);
      });

      test('retry throws when no error', () async {
        expect(controller.retry, throwsA(isA<StateError>()));
      });

      test('retry throws when disposed', () async {
        await controller.dispose();

        expect(controller.retry, throwsA(isA<StateError>()));
      });

      test('retry calls play and returns true on success', () async {
        // Set error state
        eventController.add(ErrorEvent('Test error'));
        await Future<void>.delayed(Duration.zero);

        final result = await controller.retry();

        expect(result, isTrue);
        verify(() => mockPlatform.play(1)).called(1);
      });

      test('retry returns false when max retries exceeded', () async {
        // Create error that cannot retry
        const error = VideoPlayerError(
          message: 'Test error',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          maxRetries: 0,
        );
        eventController.add(ErrorEvent.withError(error));
        await Future<void>.delayed(Duration.zero);

        final result = await controller.retry();

        expect(result, isFalse);
        verifyNever(() => mockPlatform.play(any()));
      });

      test('reinitialize throws when disposed', () async {
        await controller.dispose();

        expect(controller.reinitialize, throwsA(isA<StateError>()));
      });

      test('reinitialize throws when no source', () async {
        final newController = ProVideoPlayerController();

        expect(newController.reinitialize, throwsA(isA<StateError>()));
      });

      test('reinitialize disposes and recreates player', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 2);

        await controller.reinitialize();

        verify(() => mockPlatform.dispose(1)).called(1);
        verify(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).called(2); // Original + reinitialize
        expect(controller.playerId, equals(2));
      });

      test('cancelAutoRetry cancels pending retry', () async {
        controller.cancelAutoRetry();

        expect(controller.isRetrying, isFalse);
      });

      test('errorRecoveryOptions returns configured options', () async {
        expect(controller.errorRecoveryOptions, equals(ErrorRecoveryOptions.defaultOptions));
      });
    });

    group('playlist management', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);
        when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});
      });

      test('initializeWithPlaylist throws on empty playlist', () async {
        expect(
          () => controller.initializeWithPlaylist(playlist: Playlist(items: const [])),
          throwsA(isA<AssertionError>()),
        );
      });

      test('initializeWithPlaylist sets playlist state', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
          ],
        );

        await controller.initializeWithPlaylist(playlist: playlist);

        expect(controller.value.playlist, equals(playlist));
        expect(controller.value.playlistIndex, equals(0));
        expect(controller.value.playlistRepeatMode, equals(PlaylistRepeatMode.none));
        expect(controller.value.isShuffled, isFalse);
      });

      test('initializeWithPlaylist respects initialIndex', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
          ],
          initialIndex: 1,
        );

        await controller.initializeWithPlaylist(playlist: playlist);

        expect(controller.value.playlistIndex, equals(1));
      });

      test('initializeWithPlaylist clamps invalid initialIndex', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
          ],
          initialIndex: 99,
        );

        await controller.initializeWithPlaylist(playlist: playlist);

        expect(controller.value.playlistIndex, equals(1)); // Clamped to last index
      });

      test('playlistNext throws when no playlist', () async {
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        expect(controller.playlistNext, throwsA(isA<StateError>()));
      });

      test('playlistNext moves to next track', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
          ],
        );

        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 2);

        await controller.initializeWithPlaylist(playlist: playlist);

        final result = await controller.playlistNext();

        expect(result, isTrue);
        expect(controller.value.playlistIndex, equals(1));
      });

      test('playlistNext returns false at end of playlist', () async {
        final playlist = Playlist(items: [const VideoSource.network('https://example.com/video1.mp4')]);

        await controller.initializeWithPlaylist(playlist: playlist);

        final result = await controller.playlistNext();

        expect(result, isFalse);
        expect(controller, isCompleted);
      });

      test('playlistNext wraps with repeat all', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
          ],
        );

        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 2);

        await controller.initializeWithPlaylist(playlist: playlist);
        controller.setPlaylistRepeatMode(PlaylistRepeatMode.all);

        // Move to last track
        await controller.playlistNext();
        expect(controller.value.playlistIndex, equals(1));

        // Next should wrap to beginning
        final result = await controller.playlistNext();
        expect(result, isTrue);
        expect(controller.value.playlistIndex, equals(0));
      });

      test('playlistPrevious throws when no playlist', () async {
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        expect(controller.playlistPrevious, throwsA(isA<StateError>()));
      });

      test('playlistPrevious moves to previous track', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
          ],
          initialIndex: 1,
        );

        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 2);

        await controller.initializeWithPlaylist(playlist: playlist);

        final result = await controller.playlistPrevious();

        expect(result, isTrue);
        expect(controller.value.playlistIndex, equals(0));
      });

      test('playlistPrevious returns false at beginning', () async {
        final playlist = Playlist(items: [const VideoSource.network('https://example.com/video1.mp4')]);

        await controller.initializeWithPlaylist(playlist: playlist);

        final result = await controller.playlistPrevious();

        expect(result, isFalse);
      });

      test('playlistJumpTo throws when no playlist', () async {
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        expect(() => controller.playlistJumpTo(0), throwsA(isA<StateError>()));
      });

      test('playlistJumpTo throws on invalid index', () async {
        final playlist = Playlist(items: [const VideoSource.network('https://example.com/video1.mp4')]);

        await controller.initializeWithPlaylist(playlist: playlist);

        expect(() => controller.playlistJumpTo(5), throwsA(isA<RangeError>()));
        expect(() => controller.playlistJumpTo(-1), throwsA(isA<RangeError>()));
      });

      test('playlistJumpTo moves to specific track', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
            const VideoSource.network('https://example.com/video3.mp4'),
          ],
        );

        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 2);

        await controller.initializeWithPlaylist(playlist: playlist);

        await controller.playlistJumpTo(2);

        expect(controller.value.playlistIndex, equals(2));
      });

      test('setPlaylistRepeatMode updates state', () async {
        final playlist = Playlist(items: [const VideoSource.network('https://example.com/video1.mp4')]);

        await controller.initializeWithPlaylist(playlist: playlist);

        controller.setPlaylistRepeatMode(PlaylistRepeatMode.one);

        expect(controller.value.playlistRepeatMode, equals(PlaylistRepeatMode.one));
      });

      test('setPlaylistShuffle enables shuffle', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
            const VideoSource.network('https://example.com/video3.mp4'),
          ],
        );

        await controller.initializeWithPlaylist(playlist: playlist);

        controller.setPlaylistShuffle(enabled: true);

        expect(controller.value.isShuffled, isTrue);
      });

      test('setPlaylistShuffle disables shuffle', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
          ],
        );

        await controller.initializeWithPlaylist(playlist: playlist);
        controller.setPlaylistShuffle(enabled: true);
        expect(controller.value.isShuffled, isTrue);

        controller.setPlaylistShuffle(enabled: false);

        expect(controller.value.isShuffled, isFalse);
      });

      test('updates value on PlaylistTrackChangedEvent', () async {
        final playlist = Playlist(
          items: [
            const VideoSource.network('https://example.com/video1.mp4'),
            const VideoSource.network('https://example.com/video2.mp4'),
          ],
        );

        await controller.initializeWithPlaylist(playlist: playlist);

        eventController.add(const PlaylistTrackChangedEvent(1));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.playlistIndex, equals(1));
      });
    });

    group('network resilience', () {
      setUp(() async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('BufferingStartedEvent updates value with buffering state', () async {
        eventController.add(const BufferingStartedEvent(reason: BufferingReason.networkUnstable));

        // Allow event to be processed
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.isNetworkBuffering, isTrue);
        expect(controller.value.bufferingReason, BufferingReason.networkUnstable);
      });

      test('BufferingEndedEvent clears buffering state', () async {
        // First set buffering state
        eventController.add(const BufferingStartedEvent(reason: BufferingReason.initial));
        await Future<void>.delayed(Duration.zero);
        expect(controller.value.isNetworkBuffering, isTrue);

        // Then end buffering
        eventController.add(const BufferingEndedEvent());
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.isNetworkBuffering, isFalse);
        expect(controller.value.bufferingReason, isNull);
      });

      test('NetworkErrorEvent triggers retry when autoRetry is enabled', () async {
        eventController.add(const NetworkErrorEvent(message: 'Connection lost'));
        await Future<void>.delayed(Duration.zero);

        // Should be in recovery mode with incremented retry count
        expect(controller.value.isRecoveringFromError, isTrue);
        expect(controller.value.networkRetryCount, equals(1));
        expect(controller, isBuffering);
      });

      test('NetworkErrorEvent does not retry when autoRetry is disabled', () async {
        // Dispose and create controller with auto-retry disabled
        when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
        await controller.dispose();

        controller = ProVideoPlayerController(errorRecoveryOptions: ErrorRecoveryOptions.noAutoRecovery);

        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 2);
        when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController.add(const NetworkErrorEvent(message: 'Connection lost'));
        await Future<void>.delayed(Duration.zero);

        // Should go to error state without retrying
        expect(controller.value.isRecoveringFromError, isFalse);
        expect(controller.value.networkRetryCount, equals(0));
        expect(controller, hasError);
        expect(controller.value.errorMessage, equals('Connection lost'));
      });

      test('NetworkErrorEvent stops retrying after max retries', () async {
        // Dispose and create controller with max 2 retries
        when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
        await controller.dispose();

        controller = ProVideoPlayerController(errorRecoveryOptions: const ErrorRecoveryOptions(maxAutoRetries: 2));

        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 2);
        when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // First error - retry 1
        eventController.add(const NetworkErrorEvent(message: 'Error 1'));
        await Future<void>.delayed(Duration.zero);
        expect(controller.value.networkRetryCount, equals(1));
        expect(controller.value.isRecoveringFromError, isTrue);

        // Second error - retry 2
        eventController.add(const NetworkErrorEvent(message: 'Error 2'));
        await Future<void>.delayed(Duration.zero);
        expect(controller.value.networkRetryCount, equals(2));
        expect(controller.value.isRecoveringFromError, isTrue);

        // Third error - max reached, should stop retrying
        eventController.add(const NetworkErrorEvent(message: 'Error 3'));
        await Future<void>.delayed(Duration.zero);
        expect(controller.value.isRecoveringFromError, isFalse);
        expect(controller, hasError);
      });

      test('PlaybackRecoveredEvent resets retry state', () async {
        // Set up error state first
        eventController.add(const NetworkErrorEvent(message: 'Connection lost'));
        await Future<void>.delayed(Duration.zero);
        expect(controller.value.networkRetryCount, equals(1));
        expect(controller.value.isRecoveringFromError, isTrue);

        // Recovery event
        eventController.add(const PlaybackRecoveredEvent(retriesUsed: 1));
        await Future<void>.delayed(Duration.zero);

        expect(controller.value.networkRetryCount, equals(0));
        expect(controller.value.isRecoveringFromError, isFalse);
        expect(controller.value.isNetworkBuffering, isFalse);
      });

      test('NetworkStateChangedEvent triggers immediate retry when recovering', () async {
        // Mock seekTo for retry
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        // Set up error/recovery state first
        eventController.add(const NetworkErrorEvent(message: 'Connection lost'));
        await Future<void>.delayed(Duration.zero);
        expect(controller.value.isRecoveringFromError, isTrue);

        // Network restored - should trigger immediate retry
        eventController.add(const NetworkStateChangedEvent(isConnected: true));
        await Future<void>.delayed(Duration.zero);

        // Retry calls seekTo then play
        verify(() => mockPlatform.seekTo(1, any())).called(greaterThanOrEqualTo(1));
        verify(() => mockPlatform.play(1)).called(greaterThanOrEqualTo(1));
      });

      test('NetworkStateChangedEvent does not retry when not recovering', () async {
        // No error state - just normal playback
        expect(controller.value.isRecoveringFromError, isFalse);

        // Reset mock call count
        clearInteractions(mockPlatform);

        // Network state change when not recovering
        eventController.add(const NetworkStateChangedEvent(isConnected: true));
        await Future<void>.delayed(Duration.zero);

        // play() should NOT be called
        verifyNever(() => mockPlatform.play(any()));
      });
    });

    group('options getter', () {
      test('returns options passed during initialization', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        const customOptions = VideoPlayerOptions(autoPlay: true, looping: true, volume: 0.5);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl), options: customOptions);

        expect(controller.options.autoPlay, isTrue);
        expect(controller.options.looping, isTrue);
        expect(controller.options.volume, equals(0.5));
      });
    });

    group('initialization errors', () {
      test('throws StateError when already initialized', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        expect(
          () => controller.initialize(source: const VideoSource.network('https://example.com/other.mp4')),
          throwsA(isA<StateError>().having((e) => e.message, 'message', 'Controller is already initialized')),
        );
      });
    });

    group('external subtitles', () {
      test('addExternalSubtitle returns null when subtitles disabled', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer(
          (_) async => const ExternalSubtitleTrack(
            id: 'ext-1',
            label: 'English',
            path: 'https://example.com/subs.vtt',
            sourceType: 'network',
            format: SubtitleFormat.vtt,
            language: 'en',
          ),
        );

        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(subtitlesEnabled: false),
        );

        final result = await controller.addExternalSubtitle(
          const SubtitleSource.network('https://example.com/subs.vtt', label: 'English', language: 'en'),
        );

        expect(result, isNull);
        verifyNever(() => mockPlatform.addExternalSubtitle(any(), any()));
      });

      test('addExternalSubtitle calls platform when subtitles enabled', () async {
        const expectedTrack = ExternalSubtitleTrack(
          id: 'ext-1',
          label: 'English',
          path: 'https://example.com/subs.vtt',
          sourceType: 'network',
          format: SubtitleFormat.vtt,
          language: 'en',
        );

        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer((_) async => expectedTrack);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        final result = await controller.addExternalSubtitle(
          const SubtitleSource.network('https://example.com/subs.vtt', label: 'English', language: 'en'),
        );

        expect(result, equals(expectedTrack));
        verify(() => mockPlatform.addExternalSubtitle(1, any())).called(1);
      });

      test('removeExternalSubtitle calls platform', () async {
        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        when(() => mockPlatform.removeExternalSubtitle(any(), any())).thenAnswer((_) async => true);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        final result = await controller.removeExternalSubtitle('ext-1');

        expect(result, isTrue);
        verify(() => mockPlatform.removeExternalSubtitle(1, 'ext-1')).called(1);
      });

      test('getExternalSubtitles calls platform', () async {
        const expectedTracks = [
          ExternalSubtitleTrack(
            id: 'ext-1',
            label: 'English',
            path: 'https://example.com/en.vtt',
            sourceType: 'network',
            format: SubtitleFormat.vtt,
            language: 'en',
          ),
        ];

        when(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => 1);

        when(() => mockPlatform.getExternalSubtitles(any())).thenAnswer((_) async => expectedTracks);

        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        final result = await controller.getExternalSubtitles();

        expect(result, equals(expectedTracks));
        verify(() => mockPlatform.getExternalSubtitles(1)).called(1);
      });
    });
  });
}
