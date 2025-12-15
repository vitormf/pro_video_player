import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  group('ProVideoPlayerController playback control', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));
    });

    test('play calls platform play', () async {
      when(() => fixture.mockPlatform.play(any())).thenAnswer((_) async {});

      await fixture.controller.play();

      verify(() => fixture.mockPlatform.play(1)).called(1);
    });

    test('pause calls platform pause', () async {
      when(() => fixture.mockPlatform.pause(any())).thenAnswer((_) async {});

      await fixture.controller.pause();

      verify(() => fixture.mockPlatform.pause(1)).called(1);
    });

    test('stop calls platform stop', () async {
      when(() => fixture.mockPlatform.stop(any())).thenAnswer((_) async {});

      await fixture.controller.stop();

      verify(() => fixture.mockPlatform.stop(1)).called(1);
    });

    test('seekTo calls platform seekTo', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      await fixture.controller.seekTo(const Duration(seconds: 30));

      verify(() => fixture.mockPlatform.seekTo(1, const Duration(seconds: 30))).called(1);
    });

    test('seekForward seeks forward by duration', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set initial position and duration via events
      fixture.eventController
        ..add(const PositionChangedEvent(Duration(seconds: 30)))
        ..add(const DurationChangedEvent(Duration(minutes: 5)));
      await Future<void>.delayed(Duration.zero);

      await fixture.controller.seekForward(const Duration(seconds: 10));

      verify(() => fixture.mockPlatform.seekTo(1, const Duration(seconds: 40))).called(1);
    });

    test('seekForward clamps to duration', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set position near end
      fixture.eventController
        ..add(const PositionChangedEvent(Duration(seconds: 55)))
        ..add(const DurationChangedEvent(Duration(minutes: 1)));
      await Future<void>.delayed(Duration.zero);

      await fixture.controller.seekForward(const Duration(seconds: 10));

      verify(() => fixture.mockPlatform.seekTo(1, const Duration(minutes: 1))).called(1);
    });

    test('seekBackward seeks backward by duration', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set initial position
      fixture.eventController.add(const PositionChangedEvent(Duration(seconds: 30)));
      await Future<void>.delayed(Duration.zero);

      await fixture.controller.seekBackward(const Duration(seconds: 10));

      verify(() => fixture.mockPlatform.seekTo(1, const Duration(seconds: 20))).called(1);
    });

    test('seekBackward clamps to zero', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set position near start
      fixture.eventController.add(const PositionChangedEvent(Duration(seconds: 5)));
      await Future<void>.delayed(Duration.zero);

      await fixture.controller.seekBackward(const Duration(seconds: 10));

      verify(() => fixture.mockPlatform.seekTo(1, Duration.zero)).called(1);
    });

    test('togglePlayPause pauses when playing', () async {
      when(() => fixture.mockPlatform.pause(any())).thenAnswer((_) async {});

      fixture.eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
      await Future<void>.delayed(Duration.zero);

      await fixture.controller.togglePlayPause();

      verify(() => fixture.mockPlatform.pause(1)).called(1);
    });

    test('togglePlayPause plays when paused', () async {
      when(() => fixture.mockPlatform.play(any())).thenAnswer((_) async {});

      fixture.eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
      await Future<void>.delayed(Duration.zero);

      await fixture.controller.togglePlayPause();

      verify(() => fixture.mockPlatform.play(1)).called(1);
    });
  });
}
