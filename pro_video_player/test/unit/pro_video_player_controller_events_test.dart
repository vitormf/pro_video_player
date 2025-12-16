import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

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

  group('ProVideoPlayerController event handling', () {
    setUp(() async {
      await fixture.initializeWithDefaultSource();
    });

    test('updates value on PlaybackStateChangedEvent', () async {
      fixture.emitEvent(const PlaybackStateChangedEvent(PlaybackState.playing));
      await fixture.waitForEvents();

      expect(fixture.controller, isPlaying);
    });

    test('updates value on PositionChangedEvent', () async {
      fixture.emitEvent(const PositionChangedEvent(Duration(seconds: 30)));
      await fixture.waitForEvents();

      expect(fixture.controller.value.position, const Duration(seconds: 30));
    });

    test('updates value on DurationChangedEvent', () async {
      fixture.emitEvent(const DurationChangedEvent(TestMetadata.duration));
      await fixture.waitForEvents();

      expect(fixture.controller.value.duration, TestMetadata.duration);
    });

    test('updates value on VideoSizeChangedEvent', () async {
      fixture.emitEvent(const VideoSizeChangedEvent(width: 1920, height: 1080));
      await fixture.waitForEvents();

      expect(fixture.controller.value.size, equals((width: 1920, height: 1080)));
    });

    test('updates value on ErrorEvent', () async {
      fixture.emitEvent(ErrorEvent('Playback error'));
      await fixture.waitForEvents();

      expect(fixture.controller.value.playbackState, PlaybackState.error);
      expect(fixture.controller.value.errorMessage, 'Playback error');
    });

    test('updates value on PipStateChangedEvent', () async {
      fixture.emitEvent(const PipStateChangedEvent(isActive: true));
      await fixture.waitForEvents();

      expect(fixture.controller, isInPip);
    });

    test('updates value on BufferedPositionChangedEvent', () async {
      fixture.emitEvent(const BufferedPositionChangedEvent(Duration(seconds: 60)));
      await fixture.waitForEvents();

      expect(fixture.controller.value.bufferedPosition, const Duration(seconds: 60));
    });

    test('updates value on PlaybackCompletedEvent', () async {
      fixture.emitEvent(const PlaybackCompletedEvent());
      await fixture.waitForEvents();

      expect(fixture.controller, isCompleted);
    });

    test('updates value on SubtitleTracksChangedEvent', () async {
      const tracks = [
        SubtitleTrack(id: 'en', label: 'English', language: 'en'),
        SubtitleTrack(id: 'es', label: 'Spanish', language: 'es'),
      ];
      fixture.emitEvent(const SubtitleTracksChangedEvent(tracks));
      await fixture.waitForEvents();

      expect(fixture.controller.value.subtitleTracks, equals(tracks));
    });

    test('updates value on SelectedSubtitleChangedEvent', () async {
      const track = SubtitleTrack(id: 'en', label: 'English', language: 'en');
      fixture.emitEvent(const SelectedSubtitleChangedEvent(track));
      await fixture.waitForEvents();

      expect(fixture.controller.value.selectedSubtitleTrack, equals(track));
    });

    test('updates value on SelectedSubtitleChangedEvent with null', () async {
      fixture.emitEvent(const SelectedSubtitleChangedEvent(null));
      await fixture.waitForEvents();

      expect(fixture.controller.value.selectedSubtitleTrack, isNull);
    });

    test('updates value on PlaybackSpeedChangedEvent', () async {
      fixture.emitEvent(const PlaybackSpeedChangedEvent(2));
      await fixture.waitForEvents();

      expect(fixture.controller, hasSpeed(2));
    });

    test('updates value on VolumeChangedEvent', () async {
      fixture.emitEvent(const VolumeChangedEvent(0.5));
      await fixture.waitForEvents();

      expect(fixture.controller, hasVolume(0.5));
    });

    test('updates value on AudioTracksChangedEvent', () async {
      const tracks = [
        AudioTrack(id: 'en', label: 'English (5.1)', language: 'en'),
        AudioTrack(id: 'es', label: 'Spanish', language: 'es'),
      ];
      fixture.emitEvent(const AudioTracksChangedEvent(tracks));
      await fixture.waitForEvents();

      expect(fixture.controller.value.audioTracks, equals(tracks));
    });

    test('updates value on SelectedAudioChangedEvent', () async {
      const track = AudioTrack(id: 'en', label: 'English (5.1)', language: 'en');
      fixture.emitEvent(const SelectedAudioChangedEvent(track));
      await fixture.waitForEvents();

      expect(fixture.controller.value.selectedAudioTrack, equals(track));
    });

    test('updates value on SelectedAudioChangedEvent with null', () async {
      fixture.emitEvent(const SelectedAudioChangedEvent(null));
      await fixture.waitForEvents();

      expect(fixture.controller.value.selectedAudioTrack, isNull);
    });
  });
}
