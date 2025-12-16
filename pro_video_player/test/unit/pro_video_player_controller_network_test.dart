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

  group('ProVideoPlayerController network resilience', () {
    setUp(() async {
      when(() => fixture.mockPlatform.play(any())).thenAnswer((_) async {});
      await fixture.initializeWithDefaultSource();
    });

    test('BufferingStartedEvent updates value with buffering state', () async {
      fixture.emitEvent(const BufferingStartedEvent(reason: BufferingReason.networkUnstable));

      // Allow event to be processed
      await fixture.waitForEvents();

      expect(fixture.controller.value.isNetworkBuffering, isTrue);
      expect(fixture.controller.value.bufferingReason, BufferingReason.networkUnstable);
    });

    test('BufferingEndedEvent clears buffering state', () async {
      // First set buffering state
      fixture.emitEvent(const BufferingStartedEvent(reason: BufferingReason.initial));
      await fixture.waitForEvents();
      expect(fixture.controller.value.isNetworkBuffering, isTrue);

      // Then end buffering
      fixture.emitEvent(const BufferingEndedEvent());
      await fixture.waitForEvents();

      expect(fixture.controller.value.isNetworkBuffering, isFalse);
      expect(fixture.controller.value.bufferingReason, isNull);
    });

    test('NetworkErrorEvent triggers retry when autoRetry is enabled', () async {
      fixture.emitEvent(const NetworkErrorEvent(message: 'Connection lost'));
      await fixture.waitForEvents();

      // Should be in recovery mode with incremented retry count
      expect(fixture.controller.value.isRecoveringFromError, isTrue);
      expect(fixture.controller.value.networkRetryCount, equals(1));
      expect(fixture.controller, isBuffering);
    });

    test('NetworkErrorEvent does not retry when autoRetry is disabled', () async {
      // Dispose and create controller with auto-retry disabled
      when(() => fixture.mockPlatform.dispose(any())).thenAnswer((_) async {});
      await fixture.controller.dispose();

      fixture.controller = ProVideoPlayerController(errorRecoveryOptions: ErrorRecoveryOptions.noAutoRecovery);

      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 2);
      when(() => fixture.mockPlatform.events(any())).thenAnswer((_) => fixture.eventController.stream);

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      fixture.emitEvent(const NetworkErrorEvent(message: 'Connection lost'));
      await fixture.waitForEvents();

      // Should go to error state without retrying
      expect(fixture.controller.value.isRecoveringFromError, isFalse);
      expect(fixture.controller.value.networkRetryCount, equals(0));
      expect(fixture.controller.value.playbackState, PlaybackState.error);
      expect(fixture.controller.value.errorMessage, equals('Connection lost'));
    });

    test('NetworkErrorEvent stops retrying after max retries', () async {
      // Dispose and create controller with max 2 retries
      when(() => fixture.mockPlatform.dispose(any())).thenAnswer((_) async {});
      await fixture.controller.dispose();

      fixture.controller = ProVideoPlayerController(
        errorRecoveryOptions: const ErrorRecoveryOptions(maxAutoRetries: 2),
      );

      when(
        () => fixture.mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => 2);
      when(() => fixture.mockPlatform.events(any())).thenAnswer((_) => fixture.eventController.stream);

      await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      // First error - retry 1
      fixture.emitEvent(const NetworkErrorEvent(message: 'Error 1'));
      await fixture.waitForEvents();
      expect(fixture.controller.value.networkRetryCount, equals(1));
      expect(fixture.controller.value.isRecoveringFromError, isTrue);

      // Second error - retry 2
      fixture.emitEvent(const NetworkErrorEvent(message: 'Error 2'));
      await fixture.waitForEvents();
      expect(fixture.controller.value.networkRetryCount, equals(2));
      expect(fixture.controller.value.isRecoveringFromError, isTrue);

      // Third error - max reached, should stop retrying
      fixture.emitEvent(const NetworkErrorEvent(message: 'Error 3'));
      await fixture.waitForEvents();
      expect(fixture.controller.value.isRecoveringFromError, isFalse);
      expect(fixture.controller.value.playbackState, PlaybackState.error);
    });

    test('PlaybackRecoveredEvent resets retry state', () async {
      // Set up error state first
      fixture.emitEvent(const NetworkErrorEvent(message: 'Connection lost'));
      await fixture.waitForEvents();
      expect(fixture.controller.value.networkRetryCount, equals(1));
      expect(fixture.controller.value.isRecoveringFromError, isTrue);

      // Recovery event
      fixture.emitEvent(const PlaybackRecoveredEvent(retriesUsed: 1));
      await fixture.waitForEvents();

      expect(fixture.controller.value.networkRetryCount, equals(0));
      expect(fixture.controller.value.isRecoveringFromError, isFalse);
      expect(fixture.controller.value.isNetworkBuffering, isFalse);
    });

    test('NetworkStateChangedEvent triggers immediate retry when recovering', () async {
      // Mock seekTo for retry
      when(() => fixture.mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

      // Set up error/recovery state first
      fixture.emitEvent(const NetworkErrorEvent(message: 'Connection lost'));
      await fixture.waitForEvents();
      expect(fixture.controller.value.isRecoveringFromError, isTrue);

      // Network restored - should trigger immediate retry
      fixture.emitEvent(const NetworkStateChangedEvent(isConnected: true));
      await fixture.waitForEvents();

      // Retry calls seekTo then play
      verify(() => fixture.mockPlatform.seekTo(1, any())).called(greaterThanOrEqualTo(1));
      verify(() => fixture.mockPlatform.play(1)).called(greaterThanOrEqualTo(1));
    });

    test('NetworkStateChangedEvent does not retry when not recovering', () async {
      // No error state - just normal playback
      expect(fixture.controller.value.isRecoveringFromError, isFalse);

      // Reset mock call count
      clearInteractions(fixture.mockPlatform);

      // Network state change when not recovering
      fixture.emitEvent(const NetworkStateChangedEvent(isConnected: true));
      await fixture.waitForEvents();

      // play() should NOT be called
      verifyNever(() => fixture.mockPlatform.play(any()));
    });
  });
}
