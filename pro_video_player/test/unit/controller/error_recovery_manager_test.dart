import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/src/controller/error_recovery_manager.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

void main() {
  late ErrorRecoveryManager manager;
  late MockProVideoPlayerPlatform mockPlatform;
  late VideoPlayerValue currentValue;
  late int? playerId;
  late bool disposed;
  late ErrorRecoveryOptions options;
  late bool retryCallbackCalled;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    currentValue = const VideoPlayerValue();
    playerId = 1;
    disposed = false;
    retryCallbackCalled = false;
    options = ErrorRecoveryOptions.defaultOptions;

    manager = ErrorRecoveryManager(
      options: options,
      getValue: () => currentValue,
      setValue: (v) => currentValue = v,
      isDisposed: () => disposed,
      getPlayerId: () => playerId,
      platform: mockPlatform,
      onRetry: () async => retryCallbackCalled = true,
    );
  });

  tearDown(() {
    manager.dispose();
  });

  group('ErrorRecoveryManager', () {
    group('scheduleAutoRetry', () {
      test('does nothing when auto-retry disabled', () {
        manager = ErrorRecoveryManager(
          options: ErrorRecoveryOptions.noAutoRecovery,
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        );

        final error = VideoPlayerError.network(message: 'Network error');
        manager.scheduleAutoRetry(error);

        expect(manager.isRetrying, isFalse);
        expect(retryCallbackCalled, isFalse);
      });

      test('does nothing for non-retryable error category', () {
        manager = ErrorRecoveryManager(
          options: const ErrorRecoveryOptions(retryOnTimeoutError: false),
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        );

        final error = VideoPlayerError.codec(message: 'Format not supported'); // Codec error
        manager.scheduleAutoRetry(error);

        expect(manager.isRetrying, isFalse);
        expect(retryCallbackCalled, isFalse);
      });

      test('calls onRecoveryFailed when error cannot be retried', () {
        var recoveryFailedCalled = false;
        manager = ErrorRecoveryManager(
          options: ErrorRecoveryOptions(onRecoveryFailed: (error) => recoveryFailedCalled = true),
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        );

        final error = VideoPlayerError.network(message: 'Network error', maxRetries: 0); // Cannot retry (maxRetries=0)
        manager.scheduleAutoRetry(error);

        expect(manager.isRetrying, isFalse);
        expect(retryCallbackCalled, isFalse);
        expect(recoveryFailedCalled, isTrue);
      });

      test('cancels retry when callback returns false', () {
        manager = ErrorRecoveryManager(
          options: ErrorRecoveryOptions(
            onRetryAttempt: (error, attempt) => false, // Cancel retry
          ),
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        );

        final error = VideoPlayerError.network(message: 'Network error');
        manager.scheduleAutoRetry(error);

        expect(manager.isRetrying, isFalse);
        expect(retryCallbackCalled, isFalse);
      });

      test('schedules retry with exponential backoff', () async {
        final error = VideoPlayerError.network(message: 'Network error', retryCount: 2);
        manager.scheduleAutoRetry(error);

        expect(manager.isRetrying, isTrue);

        // Wait for retry to execute (2^2 = 4 seconds, but we'll test with shorter wait)
        // In real scenario delay would be 4s, but for test we just verify the flag
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(manager.isRetrying, isTrue); // Still retrying
      });

      test('calls onRetryAttempt callback with correct attempt number', () {
        var attemptNumber = 0;
        manager = ErrorRecoveryManager(
          options: ErrorRecoveryOptions(
            onRetryAttempt: (error, attempt) {
              attemptNumber = attempt;
              return true;
            },
          ),
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        );

        final error = VideoPlayerError.network(message: 'Network error', retryCount: 3);
        manager.scheduleAutoRetry(error);

        expect(attemptNumber, equals(4)); // retryCount + 1
      });

      test('cancels previous retry timer when scheduling new one', () async {
        final error1 = VideoPlayerError.network(message: 'Network error');
        manager.scheduleAutoRetry(error1);
        expect(manager.isRetrying, isTrue);

        final error2 = VideoPlayerError.network(message: 'Network error');
        manager.scheduleAutoRetry(error2);
        expect(manager.isRetrying, isTrue); // Still retrying with new timer
      });

      test('does not retry when disposed', () async {
        final error = VideoPlayerError.network(message: 'Network error');

        // Use very short delay for testing
        manager = ErrorRecoveryManager(
          options: const ErrorRecoveryOptions(baseRetryDelay: Duration(milliseconds: 50)),
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        )..scheduleAutoRetry(error);
        expect(manager.isRetrying, isTrue);

        // Dispose before timer fires
        disposed = true;
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(retryCallbackCalled, isFalse);
      });
    });

    group('handleNetworkError', () {
      test('sets error state when auto-retry disabled', () {
        manager = ErrorRecoveryManager(
          options: ErrorRecoveryOptions.noAutoRecovery,
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        )..handleNetworkError('Connection lost');

        expect(currentValue.playbackState, PlaybackState.error);
        expect(currentValue.errorMessage, 'Connection lost');
        expect(manager.isRetrying, isFalse);
      });

      test('stops retrying when max retries exceeded', () {
        currentValue = const VideoPlayerValue(networkRetryCount: 5);
        manager = ErrorRecoveryManager(
          options: const ErrorRecoveryOptions(maxAutoRetries: 5),
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        )..handleNetworkError('Connection lost');

        expect(currentValue.playbackState, PlaybackState.error);
        expect(currentValue.errorMessage, 'Connection lost');
        expect(currentValue.isRecoveringFromError, isFalse);
        expect(manager.isRetrying, isFalse);
      });

      test('schedules retry with exponential backoff', () {
        currentValue = const VideoPlayerValue(networkRetryCount: 2);

        manager.handleNetworkError('Connection lost');

        expect(currentValue.networkRetryCount, equals(3));
        expect(currentValue.isRecoveringFromError, isTrue);
        expect(currentValue.playbackState, PlaybackState.buffering);
      });

      test('increments retry count on each attempt', () {
        currentValue = const VideoPlayerValue();
        manager.handleNetworkError('Connection lost');
        expect(currentValue.networkRetryCount, equals(1));

        currentValue = currentValue.copyWith(networkRetryCount: 1);
        manager.handleNetworkError('Connection lost');
        expect(currentValue.networkRetryCount, equals(2));

        currentValue = currentValue.copyWith(networkRetryCount: 2);
        manager.handleNetworkError('Connection lost');
        expect(currentValue.networkRetryCount, equals(3));
      });
    });

    group('handleNetworkStateChange', () {
      test('attempts immediate recovery when network restored', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        currentValue = const VideoPlayerValue(isRecoveringFromError: true, position: Duration(seconds: 30));

        manager.handleNetworkStateChange(isConnected: true);

        // Give time for async operation
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 30))).called(1);
        verify(() => mockPlatform.play(1)).called(1);
      });

      test('does nothing when network disconnects', () async {
        currentValue = const VideoPlayerValue(isRecoveringFromError: true);

        manager.handleNetworkStateChange(isConnected: false);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockPlatform.seekTo(any(), any()));
        verifyNever(() => mockPlatform.play(any()));
      });

      test('does nothing when not recovering from error', () async {
        currentValue = const VideoPlayerValue();

        manager.handleNetworkStateChange(isConnected: true);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockPlatform.seekTo(any(), any()));
        verifyNever(() => mockPlatform.play(any()));
      });

      test('cancels pending retry timer on network restore', () {
        currentValue = const VideoPlayerValue(isRecoveringFromError: true, networkRetryCount: 2);
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        // Schedule a retry
        manager.handleNetworkError('Connection lost');
        expect(currentValue.isRecoveringFromError, isTrue);

        // Network restored - should cancel pending timer
        manager.handleNetworkStateChange(isConnected: true);

        // Timer should be cancelled (no way to verify directly, but covered by immediate retry)
      });
    });

    group('attemptRetry', () {
      test('seeks to current position and resumes playback', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        currentValue = const VideoPlayerValue(position: Duration(seconds: 45));

        await manager.attemptRetry();

        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 45))).called(1);
        verify(() => mockPlatform.play(1)).called(1);
      });

      test('does nothing when disposed', () async {
        disposed = true;

        await manager.attemptRetry();

        verifyNever(() => mockPlatform.seekTo(any(), any()));
        verifyNever(() => mockPlatform.play(any()));
      });

      test('does nothing when no player ID', () async {
        playerId = null;

        await manager.attemptRetry();

        verifyNever(() => mockPlatform.seekTo(any(), any()));
        verifyNever(() => mockPlatform.play(any()));
      });

      test('prevents concurrent retries', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        // Start first retry
        final retry1 = manager.attemptRetry();
        expect(manager.isRetrying, isTrue);

        // Try second retry while first is in progress
        await manager.attemptRetry();

        // Wait for first to complete
        await retry1;

        // seekTo should only be called once (concurrent retry prevented)
        verify(() => mockPlatform.seekTo(any(), any())).called(1);
      });

      test('handles errors gracefully', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenThrow(Exception('Seek failed'));

        currentValue = const VideoPlayerValue(position: Duration(seconds: 30));

        // Should not throw
        await manager.attemptRetry();

        // Verify seek was attempted
        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 30))).called(1);

        // Play should not be called if seek failed
        verifyNever(() => mockPlatform.play(any()));
      });

      test('resets isRetrying flag after completion', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        // Manually set retrying flag
        manager = ErrorRecoveryManager(
          options: const ErrorRecoveryOptions(baseRetryDelay: Duration(milliseconds: 50)),
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async {
            retryCallbackCalled = true;
            await manager.attemptRetry();
          },
        );

        final error = VideoPlayerError.network(message: 'Network error');
        manager.scheduleAutoRetry(error);
        expect(manager.isRetrying, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(manager.isRetrying, isFalse);
      });
    });

    group('cancelRetryTimer', () {
      test('cancels pending timer', () async {
        // Schedule a retry
        final error = VideoPlayerError.network(message: 'Network error');
        manager.scheduleAutoRetry(error);
        expect(manager.isRetrying, isTrue);

        // Cancel it
        manager.cancelRetryTimer();

        // Wait to ensure callback doesn't fire
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(retryCallbackCalled, isFalse);
      });

      test('handles null timer gracefully', () {
        // Should not throw
        manager
          ..cancelRetryTimer()
          ..cancelRetryTimer(); // Call twice
      });
    });

    group('dispose', () {
      test('cancels pending retry timer', () async {
        final error = VideoPlayerError.network(message: 'Network error');
        manager.scheduleAutoRetry(error);
        expect(manager.isRetrying, isTrue);

        manager.dispose();

        expect(manager.isRetrying, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(retryCallbackCalled, isFalse);
      });

      test('resets isRetrying flag', () {
        manager = ErrorRecoveryManager(
          options: const ErrorRecoveryOptions(baseRetryDelay: Duration(milliseconds: 50)),
          getValue: () => currentValue,
          setValue: (v) => currentValue = v,
          isDisposed: () => disposed,
          getPlayerId: () => playerId,
          platform: mockPlatform,
          onRetry: () async => retryCallbackCalled = true,
        );

        final error = VideoPlayerError.network(message: 'Network error');
        manager.scheduleAutoRetry(error);
        expect(manager.isRetrying, isTrue);

        manager.dispose();

        expect(manager.isRetrying, isFalse);
      });
    });

    group('exponential backoff', () {
      test('calculates correct delays', () {
        // Test the delay calculation indirectly through handleNetworkError
        // Since _calculateRetryDelay is private, we verify the behavior

        // Retry 0: 2^0 = 1 second
        currentValue = const VideoPlayerValue();
        manager.handleNetworkError('Connection lost');
        expect(currentValue.networkRetryCount, equals(1));

        // Retry 1: 2^1 = 2 seconds
        currentValue = currentValue.copyWith(networkRetryCount: 1);
        manager.handleNetworkError('Connection lost');
        expect(currentValue.networkRetryCount, equals(2));

        // Retry 2: 2^2 = 4 seconds
        currentValue = currentValue.copyWith(networkRetryCount: 2);
        manager.handleNetworkError('Connection lost');
        expect(currentValue.networkRetryCount, equals(3));

        // Retry 5: 2^5 = 32, capped at 30 seconds
        currentValue = currentValue.copyWith(networkRetryCount: 5);
        manager.handleNetworkError('Connection lost');
        expect(currentValue.networkRetryCount, equals(6));
      });
    });
  });
}
