import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';
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

  group('ProVideoPlayerController error recovery', () {
    setUp(() async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 1);
      when(() => fixture.mockPlatform.play(any())).thenAnswer((_) async {});
      when(() => fixture.mockPlatform.dispose(any())).thenAnswer((_) async {});

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
    });

    test('clearError resets error state', () async {
      // Set error state
      fixture.emitEvent(ErrorEvent('Test error'));
      await fixture.waitForEvents();
      expect(fixture.controller.value.hasError, isTrue);

      fixture.controller.clearError();

      expect(fixture.controller.value.hasError, isFalse);
      expect(fixture.controller, isReady);
    });

    test('clearError does nothing if no error', () async {
      expect(fixture.controller, isReady);

      fixture.controller.clearError();

      expect(fixture.controller, isReady);
    });

    test('retry throws when no error', () async {
      expect(fixture.controller.retry, throwsA(isA<StateError>()));
    });

    test('retry throws when disposed', () async {
      await fixture.controller.dispose();

      expect(fixture.controller.retry, throwsA(isA<StateError>()));
    });

    test('retry calls play and returns true on success', () async {
      // Set error state
      fixture.emitEvent(ErrorEvent('Test error'));
      await fixture.waitForEvents();

      final result = await fixture.controller.retry();

      expect(result, isTrue);
      verify(() => fixture.mockPlatform.play(1)).called(1);
    });

    test('retry returns false when max retries exceeded', () async {
      // Create error that cannot retry
      const error = VideoPlayerError(
        message: 'Test error',
        category: VideoPlayerErrorCategory.network,
        severity: VideoPlayerErrorSeverity.recoverable,
        maxRetries: 0,
      );
      fixture.emitEvent(ErrorEvent.withError(error));
      await fixture.waitForEvents();

      final result = await fixture.controller.retry();

      expect(result, isFalse);
      verifyNever(() => fixture.mockPlatform.play(any()));
    });

    test('reinitialize throws when disposed', () async {
      await fixture.controller.dispose();

      expect(fixture.controller.reinitialize, throwsA(isA<StateError>()));
    });

    test('reinitialize throws when no source', () async {
      final newController = ProVideoPlayerController();

      expect(newController.reinitialize, throwsA(isA<StateError>()));
    });

    test('reinitialize disposes and recreates player', () async {
      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 2);

      await fixture.controller.reinitialize();

      verify(() => fixture.mockPlatform.dispose(1)).called(1);
      verify(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).called(2); // Original + reinitialize
      expect(fixture.controller.playerId, equals(2));
    });

    test('cancelAutoRetry cancels pending retry', () async {
      fixture.controller.cancelAutoRetry();

      expect(fixture.controller.isRetrying, isFalse);
    });

    test('errorRecoveryOptions returns configured options', () async {
      expect(fixture.controller.errorRecoveryOptions, equals(ErrorRecoveryOptions.defaultOptions));
    });
  });
}
