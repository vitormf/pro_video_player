import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';

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

  group('ProVideoPlayerController media metadata', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));
    });

    test('setMediaMetadata calls platform', () async {
      when(() => fixture.mockPlatform.setMediaMetadata(any(), any())).thenAnswer((_) async {});

      const metadata = MediaMetadata(title: 'Test Video', artist: 'Test Artist');
      await fixture.controller.setMediaMetadata(metadata);

      verify(() => fixture.mockPlatform.setMediaMetadata(1, metadata)).called(1);
    });

    test('setMediaMetadata throws when not initialized', () async {
      final uninitializedController = ProVideoPlayerController();

      expect(() => uninitializedController.setMediaMetadata(MediaMetadata.empty), throwsA(isA<StateError>()));
    });

    test('updates value on MetadataChangedEvent', () async {
      fixture.eventController.add(const MetadataChangedEvent(title: 'New Title'));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.title, equals('New Title'));
    });

    test('updates value on EmbeddedSubtitleCueEvent with cue', () async {
      const cue = SubtitleCue(text: 'Hello world', start: Duration(seconds: 1), end: Duration(seconds: 3));
      fixture.eventController.add(const EmbeddedSubtitleCueEvent(cue: cue, trackId: 'track-1'));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.currentEmbeddedCue, equals(cue));
    });

    test('updates value on EmbeddedSubtitleCueEvent with null cue (hides subtitle)', () async {
      // First set a cue
      const cue = SubtitleCue(text: 'Hello world', start: Duration(seconds: 1), end: Duration(seconds: 3));
      fixture.eventController.add(const EmbeddedSubtitleCueEvent(cue: cue));
      await Future<void>.delayed(Duration.zero);
      expect(fixture.controller.value.currentEmbeddedCue, equals(cue));

      // Then clear it with null
      fixture.eventController.add(const EmbeddedSubtitleCueEvent(cue: null));
      await Future<void>.delayed(Duration.zero);

      expect(fixture.controller.value.currentEmbeddedCue, isNull);
    });
  });
}
