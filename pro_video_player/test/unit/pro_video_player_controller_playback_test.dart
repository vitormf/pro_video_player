import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../shared/test_constants.dart';
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

  group('ProVideoPlayerController playback control', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
    });

    test('play calls platform play', () async {
      when(() => fixture.mockPlatform.play(any())).thenAnswer((_) async {});

      await fixture.controller.play();

      fixture.verifyPlay();
    });

    test('pause calls platform pause', () async {
      when(() => fixture.mockPlatform.pause(any())).thenAnswer((_) async {});

      await fixture.controller.pause();

      fixture.verifyPause();
    });

    test('stop calls platform stop', () async {
      when(() => fixture.mockPlatform.stop(any())).thenAnswer((_) async {});

      await fixture.controller.stop();

      verify(() => fixture.mockPlatform.stop(1)).called(1);
    });

    test('seekTo calls platform seekTo', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      await fixture.controller.seekTo(const Duration(seconds: 30));

      fixture.verifySeekTo(const Duration(seconds: 30));
    });

    test('seekForward seeks forward by duration', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set initial position and duration via events
      fixture.eventController
        ..add(const PositionChangedEvent(Duration(seconds: 30)))
        ..add(const DurationChangedEvent(TestMetadata.duration));
      await fixture.waitForEvents();

      await fixture.controller.seekForward(const Duration(seconds: 10));

      fixture.verifySeekTo(const Duration(seconds: 40));
    });

    test('seekForward clamps to duration', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set position near end
      fixture.eventController
        ..add(const PositionChangedEvent(Duration(seconds: 55)))
        ..add(const DurationChangedEvent(Duration(minutes: 1)));
      await fixture.waitForEvents();

      await fixture.controller.seekForward(const Duration(seconds: 10));

      fixture.verifySeekTo(const Duration(minutes: 1));
    });

    test('seekBackward seeks backward by duration', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set initial position
      fixture.emitEvent(const PositionChangedEvent(Duration(seconds: 30)));
      await fixture.waitForEvents();

      await fixture.controller.seekBackward(const Duration(seconds: 10));

      fixture.verifySeekTo(const Duration(seconds: 20));
    });

    test('seekBackward clamps to zero', () async {
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set position near start
      fixture.emitEvent(const PositionChangedEvent(Duration(seconds: 5)));
      await fixture.waitForEvents();

      await fixture.controller.seekBackward(const Duration(seconds: 10));

      fixture.verifySeekTo(Duration.zero);
    });

    test('togglePlayPause pauses when playing', () async {
      when(() => fixture.mockPlatform.pause(any())).thenAnswer((_) async {});

      fixture.emitEvent(const PlaybackStateChangedEvent(PlaybackState.playing));
      await fixture.waitForEvents();

      await fixture.controller.togglePlayPause();

      fixture.verifyPause();
    });

    test('togglePlayPause plays when paused', () async {
      when(() => fixture.mockPlatform.play(any())).thenAnswer((_) async {});

      fixture.emitEvent(const PlaybackStateChangedEvent(PlaybackState.paused));
      await fixture.waitForEvents();

      await fixture.controller.togglePlayPause();

      fixture.verifyPlay();
    });
  });
}
