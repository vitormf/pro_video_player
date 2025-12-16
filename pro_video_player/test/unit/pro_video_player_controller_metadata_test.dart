import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';

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

  group('ProVideoPlayerController media metadata', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
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
      fixture.emitEvent(const MetadataChangedEvent(title: 'New Title'));
      await fixture.waitForEvents();

      expect(fixture.controller.value.title, equals('New Title'));
    });

    test('updates value on EmbeddedSubtitleCueEvent with cue', () async {
      const cue = SubtitleCue(text: 'Hello world', start: Duration(seconds: 1), end: Duration(seconds: 3));
      fixture.emitEvent(const EmbeddedSubtitleCueEvent(cue: cue, trackId: 'track-1'));
      await fixture.waitForEvents();

      expect(fixture.controller.value.currentEmbeddedCue, equals(cue));
    });

    test('updates value on EmbeddedSubtitleCueEvent with null cue (hides subtitle)', () async {
      // First set a cue
      const cue = SubtitleCue(text: 'Hello world', start: Duration(seconds: 1), end: Duration(seconds: 3));
      fixture.emitEvent(const EmbeddedSubtitleCueEvent(cue: cue));
      await fixture.waitForEvents();
      expect(fixture.controller.value.currentEmbeddedCue, equals(cue));

      // Then clear it with null
      fixture.emitEvent(const EmbeddedSubtitleCueEvent(cue: null));
      await fixture.waitForEvents();

      expect(fixture.controller.value.currentEmbeddedCue, isNull);
    });
  });
}
