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

  group('ProVideoPlayerController video quality', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
    });

    test('setVideoQuality calls platform and updates value on success', () async {
      const track = VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000);
      when(() => fixture.mockPlatform.setVideoQuality(any(), any())).thenAnswer((_) async => true);

      final result = await fixture.controller.setVideoQuality(track);

      expect(result, isTrue);
      verify(() => fixture.mockPlatform.setVideoQuality(1, track)).called(1);
      expect(fixture.controller.value.selectedQualityTrack, equals(track));
    });

    test('setVideoQuality does not update value on failure', () async {
      const track = VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000);
      when(() => fixture.mockPlatform.setVideoQuality(any(), any())).thenAnswer((_) async => false);

      final result = await fixture.controller.setVideoQuality(track);

      expect(result, isFalse);
      expect(fixture.controller.value.selectedQualityTrack, isNull);
    });

    test('setVideoQuality with auto clears selection', () async {
      when(() => fixture.mockPlatform.setVideoQuality(any(), any())).thenAnswer((_) async => true);

      await fixture.controller.setVideoQuality(VideoQualityTrack.auto);

      expect(fixture.controller.value.selectedQualityTrack, isNull);
    });

    test('getVideoQualities calls platform', () async {
      const tracks = [
        VideoQualityTrack.auto,
        VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
      ];
      when(() => fixture.mockPlatform.getVideoQualities(any())).thenAnswer((_) async => tracks);

      final result = await fixture.controller.getVideoQualities();

      expect(result, equals(tracks));
      verify(() => fixture.mockPlatform.getVideoQualities(1)).called(1);
    });

    test('getCurrentVideoQuality calls platform', () async {
      const track = VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000);
      when(() => fixture.mockPlatform.getCurrentVideoQuality(any())).thenAnswer((_) async => track);

      final result = await fixture.controller.getCurrentVideoQuality();

      expect(result, equals(track));
      verify(() => fixture.mockPlatform.getCurrentVideoQuality(1)).called(1);
    });

    test('isQualitySelectionSupported calls platform', () async {
      when(() => fixture.mockPlatform.isQualitySelectionSupported(any())).thenAnswer((_) async => true);

      final result = await fixture.controller.isQualitySelectionSupported();

      expect(result, isTrue);
      verify(() => fixture.mockPlatform.isQualitySelectionSupported(1)).called(1);
    });

    test('updates value on VideoQualityTracksChangedEvent', () async {
      const tracks = [
        VideoQualityTrack.auto,
        VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
      ];
      fixture.emitEvent(const VideoQualityTracksChangedEvent(tracks));
      await fixture.waitForEvents();

      expect(fixture.controller.value.qualityTracks, equals(tracks));
    });

    test('updates value on SelectedQualityChangedEvent', () async {
      const track = VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000);
      fixture.emitEvent(const SelectedQualityChangedEvent(track));
      await fixture.waitForEvents();

      expect(fixture.controller.value.selectedQualityTrack, equals(track));
    });
  });
}
