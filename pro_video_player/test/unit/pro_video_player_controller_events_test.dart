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

  group('ProVideoPlayerController event handling', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));
    });

    test('updates value on PlaybackStateChangedEvent', () async {
      fixture.eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.playbackState, PlaybackState.playing);
    });

    test('updates value on PositionChangedEvent', () async {
      fixture.eventController.add(const PositionChangedEvent(Duration(seconds: 30)));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.position, const Duration(seconds: 30));
    });

    test('updates value on DurationChangedEvent', () async {
      fixture.eventController.add(const DurationChangedEvent(Duration(minutes: 5)));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.duration, const Duration(minutes: 5));
    });

    test('updates value on VideoSizeChangedEvent', () async {
      fixture.eventController.add(const VideoSizeChangedEvent(width: 1920, height: 1080));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.size, equals((width: 1920, height: 1080)));
    });

    test('updates value on ErrorEvent', () async {
      fixture.eventController.add(ErrorEvent('Playback error'));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.playbackState, PlaybackState.error);
      expect(fixture.controller.value.errorMessage, 'Playback error');
    });

    test('updates value on PipStateChangedEvent', () async {
      fixture.eventController.add(const PipStateChangedEvent(isActive: true));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.isPipActive, isTrue);
    });

    test('updates value on BufferedPositionChangedEvent', () async {
      fixture.eventController.add(const BufferedPositionChangedEvent(Duration(seconds: 60)));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.bufferedPosition, const Duration(seconds: 60));
    });

    test('updates value on PlaybackCompletedEvent', () async {
      fixture.eventController.add(const PlaybackCompletedEvent());
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.playbackState, PlaybackState.completed);
    });

    test('updates value on SubtitleTracksChangedEvent', () async {
      const tracks = [
        SubtitleTrack(id: 'en', label: 'English', language: 'en'),
        SubtitleTrack(id: 'es', label: 'Spanish', language: 'es'),
      ];
      fixture.eventController.add(const SubtitleTracksChangedEvent(tracks));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.subtitleTracks, equals(tracks));
    });

    test('updates value on SelectedSubtitleChangedEvent', () async {
      const track = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      fixture.eventController.add(const SelectedSubtitleChangedEvent(track));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.selectedSubtitleTrack, equals(track));
    });

    test('updates value on SelectedSubtitleChangedEvent with null', () async {
      fixture.eventController.add(const SelectedSubtitleChangedEvent(null));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.selectedSubtitleTrack, isNull);
    });

    test('updates value on PlaybackSpeedChangedEvent', () async {
      fixture.eventController.add(const PlaybackSpeedChangedEvent(2));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.playbackSpeed, 2.0);
    });

    test('updates value on VolumeChangedEvent', () async {
      fixture.eventController.add(const VolumeChangedEvent(0.5));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.volume, 0.5);
    });

    test('updates value on AudioTracksChangedEvent', () async {
      const tracks = [
        AudioTrack(id: 'en', label: 'English (5.1)', language: 'en'),
        AudioTrack(id: 'es', label: 'Spanish', language: 'es'),
      ];
      fixture.eventController.add(const AudioTracksChangedEvent(tracks));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.audioTracks, equals(tracks));
    });

    test('updates value on SelectedAudioChangedEvent', () async {
      const track = AudioTrack(id: 'en', label: 'English (5.1)', language: 'en');
      fixture.eventController.add(const SelectedAudioChangedEvent(track));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.selectedAudioTrack, equals(track));
    });

    test('updates value on SelectedAudioChangedEvent with null', () async {
      fixture.eventController.add(const SelectedAudioChangedEvent(null));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.selectedAudioTrack, isNull);
    });
  });
}
