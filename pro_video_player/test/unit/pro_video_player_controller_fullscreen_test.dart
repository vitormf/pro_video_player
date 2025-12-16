import 'package:flutter/services.dart';
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

  group('ProVideoPlayerController fullscreen', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);

      // Mock SystemChrome calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (methodCall) async => null,
      );

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
    });

    test('enterFullscreen calls platform and updates value', () async {
      when(() => fixture.mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

      final result = await fixture.controller.enterFullscreen();

      expect(result, isTrue);
      expect(fixture.controller, isInFullscreen);
      verify(() => fixture.mockPlatform.enterFullscreen(1)).called(1);
    });

    test('enterFullscreen with custom orientation calls platform', () async {
      when(() => fixture.mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

      await fixture.controller.enterFullscreen(orientation: FullscreenOrientation.portraitBoth);

      expect(fixture.controller, isInFullscreen);
      verify(() => fixture.mockPlatform.enterFullscreen(1)).called(1);
    });

    test('enterFullscreen with all orientation options', () async {
      when(() => fixture.mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
      when(() => fixture.mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

      // Test all orientation options work without error
      for (final orientation in FullscreenOrientation.values) {
        await fixture.controller.enterFullscreen(orientation: orientation);
        await fixture.controller.exitFullscreen();
      }
    });

    test('exitFullscreen calls platform and updates value', () async {
      when(() => fixture.mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
      when(() => fixture.mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

      // Enter fullscreen first
      await fixture.controller.enterFullscreen();
      expect(fixture.controller, isInFullscreen);

      // Exit fullscreen
      await fixture.controller.exitFullscreen();

      expect(fixture.controller, isNotInFullscreen);
      verify(() => fixture.mockPlatform.exitFullscreen(1)).called(1);
    });

    test('toggleFullscreen enters fullscreen when not in fullscreen', () async {
      when(() => fixture.mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

      await fixture.controller.toggleFullscreen();

      expect(fixture.controller, isInFullscreen);
      verify(() => fixture.mockPlatform.enterFullscreen(1)).called(1);
    });

    test('toggleFullscreen exits fullscreen when in fullscreen', () async {
      when(() => fixture.mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
      when(() => fixture.mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

      // Enter fullscreen first
      await fixture.controller.enterFullscreen();

      // Toggle should exit
      await fixture.controller.toggleFullscreen();

      expect(fixture.controller, isNotInFullscreen);
      verify(() => fixture.mockPlatform.exitFullscreen(1)).called(1);
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
      fixture.emitEvent(const FullscreenStateChangedEvent(isFullscreen: true));
      await fixture.waitForEvents();

      expect(fixture.controller, isInFullscreen);

      fixture.emitEvent(const FullscreenStateChangedEvent(isFullscreen: false));
      await fixture.waitForEvents();

      expect(fixture.controller, isNotInFullscreen);
    });
  });
}
