import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoPlayerErrorCategory', () {
    test('has all expected values', () {
      expect(VideoPlayerErrorCategory.values, hasLength(8));
      expect(VideoPlayerErrorCategory.values, contains(VideoPlayerErrorCategory.network));
      expect(VideoPlayerErrorCategory.values, contains(VideoPlayerErrorCategory.source));
      expect(VideoPlayerErrorCategory.values, contains(VideoPlayerErrorCategory.codec));
      expect(VideoPlayerErrorCategory.values, contains(VideoPlayerErrorCategory.permission));
      expect(VideoPlayerErrorCategory.values, contains(VideoPlayerErrorCategory.platform));
      expect(VideoPlayerErrorCategory.values, contains(VideoPlayerErrorCategory.playback));
      expect(VideoPlayerErrorCategory.values, contains(VideoPlayerErrorCategory.timeout));
      expect(VideoPlayerErrorCategory.values, contains(VideoPlayerErrorCategory.unknown));
    });
  });

  group('VideoPlayerErrorSeverity', () {
    test('has all expected values', () {
      expect(VideoPlayerErrorSeverity.values, hasLength(3));
      expect(VideoPlayerErrorSeverity.values, contains(VideoPlayerErrorSeverity.recoverable));
      expect(VideoPlayerErrorSeverity.values, contains(VideoPlayerErrorSeverity.warning));
      expect(VideoPlayerErrorSeverity.values, contains(VideoPlayerErrorSeverity.fatal));
    });
  });

  group('RecoveryStrategy', () {
    test('has all expected values', () {
      expect(RecoveryStrategy.values, hasLength(7));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.retry));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.reinitialize));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.tryAlternativeSource));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.reduceQuality));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.waitForNetwork));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.requestUserAction));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.none));
    });
  });

  group('VideoPlayerError', () {
    group('constructor', () {
      test('creates with required parameters', () {
        const error = VideoPlayerError(
          message: 'Test error',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error.message, equals('Test error'));
        expect(error.category, equals(VideoPlayerErrorCategory.network));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
        expect(error.code, isNull);
        expect(error.suggestedRecovery, equals(RecoveryStrategy.none));
        expect(error.retryCount, equals(0));
        expect(error.maxRetries, equals(3));
        expect(error.retryDelay, equals(const Duration(seconds: 2)));
      });

      test('creates with all parameters', () {
        const error = VideoPlayerError(
          message: 'Test error',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          code: 'NETWORK_ERROR',
          suggestedRecovery: RecoveryStrategy.retry,
          retryCount: 2,
          maxRetries: 5,
          retryDelay: Duration(seconds: 5),
          nativeErrorCode: 123,
        );

        expect(error.message, equals('Test error'));
        expect(error.code, equals('NETWORK_ERROR'));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.retry));
        expect(error.retryCount, equals(2));
        expect(error.maxRetries, equals(5));
        expect(error.retryDelay, equals(const Duration(seconds: 5)));
        expect(error.nativeErrorCode, equals(123));
      });
    });

    group('fromCode factory', () {
      test('classifies network error from code', () {
        final error = VideoPlayerError.fromCode(message: 'Connection failed', code: 'NETWORK_ERROR');

        expect(error.category, equals(VideoPlayerErrorCategory.network));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.retry));
      });

      test('classifies network error from message', () {
        final error = VideoPlayerError.fromCode(message: 'Network connection unreachable');

        expect(error.category, equals(VideoPlayerErrorCategory.network));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
      });

      test('classifies source error from code', () {
        final error = VideoPlayerError.fromCode(message: 'Invalid URL', code: 'INVALID_SOURCE');

        expect(error.category, equals(VideoPlayerErrorCategory.source));
        expect(error.severity, equals(VideoPlayerErrorSeverity.fatal));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.tryAlternativeSource));
      });

      test('classifies source error from message', () {
        final error = VideoPlayerError.fromCode(message: 'Video not found (404)');

        expect(error.category, equals(VideoPlayerErrorCategory.source));
        expect(error.severity, equals(VideoPlayerErrorSeverity.fatal));
      });

      test('classifies codec error from code', () {
        final error = VideoPlayerError.fromCode(message: 'Cannot decode', code: 'CODEC_ERROR');

        expect(error.category, equals(VideoPlayerErrorCategory.codec));
        expect(error.severity, equals(VideoPlayerErrorSeverity.fatal));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.none));
      });

      test('classifies codec error from message', () {
        final error = VideoPlayerError.fromCode(message: 'Unsupported video format');

        expect(error.category, equals(VideoPlayerErrorCategory.codec));
        expect(error.severity, equals(VideoPlayerErrorSeverity.fatal));
      });

      test('classifies permission error from code', () {
        final error = VideoPlayerError.fromCode(message: 'Access denied', code: 'PERMISSION_ERROR');

        expect(error.category, equals(VideoPlayerErrorCategory.permission));
        expect(error.severity, equals(VideoPlayerErrorSeverity.fatal));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.requestUserAction));
      });

      test('classifies permission error from message', () {
        final error = VideoPlayerError.fromCode(message: 'Content restricted in your region');

        expect(error.category, equals(VideoPlayerErrorCategory.permission));
      });

      test('classifies timeout error from code', () {
        final error = VideoPlayerError.fromCode(message: 'Request timed out', code: 'TIMEOUT');

        expect(error.category, equals(VideoPlayerErrorCategory.timeout));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.retry));
      });

      test('classifies platform error from code', () {
        final error = VideoPlayerError.fromCode(message: 'Audio session failed', code: 'AUDIO_SESSION_ERROR');

        expect(error.category, equals(VideoPlayerErrorCategory.platform));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.reinitialize));
      });

      test('classifies playback error from code', () {
        final error = VideoPlayerError.fromCode(message: 'Failed to play', code: 'PLAYBACK_ERROR');

        expect(error.category, equals(VideoPlayerErrorCategory.playback));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.reinitialize));
      });

      test('returns unknown for unrecognized errors', () {
        final error = VideoPlayerError.fromCode(message: 'Something went wrong', code: 'UNKNOWN');

        expect(error.category, equals(VideoPlayerErrorCategory.unknown));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.retry));
      });
    });

    group('factory constructors', () {
      test('network creates network error', () {
        final error = VideoPlayerError.network(message: 'Connection failed', code: 'NET_001', retryCount: 1);

        expect(error.category, equals(VideoPlayerErrorCategory.network));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.retry));
        expect(error.retryCount, equals(1));
      });

      test('source creates source error', () {
        final error = VideoPlayerError.source(message: 'Invalid source', code: 'SRC_001');

        expect(error.category, equals(VideoPlayerErrorCategory.source));
        expect(error.severity, equals(VideoPlayerErrorSeverity.fatal));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.tryAlternativeSource));
      });

      test('codec creates codec error', () {
        final error = VideoPlayerError.codec(message: 'Unsupported format', code: 'CODEC_001');

        expect(error.category, equals(VideoPlayerErrorCategory.codec));
        expect(error.severity, equals(VideoPlayerErrorSeverity.fatal));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.none));
      });

      test('timeout creates timeout error', () {
        final error = VideoPlayerError.timeout(message: 'Request timed out', code: 'TIMEOUT_001', maxRetries: 5);

        expect(error.category, equals(VideoPlayerErrorCategory.timeout));
        expect(error.severity, equals(VideoPlayerErrorSeverity.recoverable));
        expect(error.suggestedRecovery, equals(RecoveryStrategy.retry));
        expect(error.maxRetries, equals(5));
      });
    });

    group('canRetry', () {
      test('returns true when retries remaining and recoverable', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error.canRetry, isTrue);
      });

      test('returns false when max retries reached', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          retryCount: 3,
        );

        expect(error.canRetry, isFalse);
      });

      test('returns false when severity is fatal', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.source,
          severity: VideoPlayerErrorSeverity.fatal,
        );

        expect(error.canRetry, isFalse);
      });

      test('returns false when severity is warning', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.codec,
          severity: VideoPlayerErrorSeverity.warning,
        );

        expect(error.canRetry, isFalse);
      });
    });

    group('nextRetryDelay', () {
      test('returns base delay for first retry', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error.nextRetryDelay, equals(const Duration(seconds: 2)));
      });

      test('doubles delay for each retry (exponential backoff)', () {
        const error1 = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          retryCount: 1,
        );
        expect(error1.nextRetryDelay, equals(const Duration(seconds: 4)));

        const error2 = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          retryCount: 2,
        );
        expect(error2.nextRetryDelay, equals(const Duration(seconds: 8)));
      });

      test('caps delay at 30 seconds', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          retryCount: 10,
        );

        expect(error.nextRetryDelay, equals(const Duration(seconds: 30)));
      });
    });

    group('userMessage', () {
      test('returns network message for network errors', () {
        const error = VideoPlayerError(
          message: 'Technical error',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error.userMessage, equals('Network error. Please check your internet connection.'));
      });

      test('returns source message for source errors', () {
        const error = VideoPlayerError(
          message: 'Technical error',
          category: VideoPlayerErrorCategory.source,
          severity: VideoPlayerErrorSeverity.fatal,
        );

        expect(error.userMessage, equals('Unable to load video. The source may be unavailable.'));
      });

      test('returns codec message for codec errors', () {
        const error = VideoPlayerError(
          message: 'Technical error',
          category: VideoPlayerErrorCategory.codec,
          severity: VideoPlayerErrorSeverity.fatal,
        );

        expect(error.userMessage, equals('This video format is not supported.'));
      });

      test('returns permission message for permission errors', () {
        const error = VideoPlayerError(
          message: 'Technical error',
          category: VideoPlayerErrorCategory.permission,
          severity: VideoPlayerErrorSeverity.fatal,
        );

        expect(error.userMessage, equals('Permission required to play this video.'));
      });

      test('returns platform message for platform errors', () {
        const error = VideoPlayerError(
          message: 'Technical error',
          category: VideoPlayerErrorCategory.platform,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error.userMessage, equals('A system error occurred. Please try again.'));
      });

      test('returns playback message for playback errors', () {
        const error = VideoPlayerError(
          message: 'Technical error',
          category: VideoPlayerErrorCategory.playback,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error.userMessage, equals('Playback error occurred. Please try again.'));
      });

      test('returns timeout message for timeout errors', () {
        const error = VideoPlayerError(
          message: 'Technical error',
          category: VideoPlayerErrorCategory.timeout,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error.userMessage, equals('Loading timed out. Please try again.'));
      });

      test('returns generic message for unknown errors', () {
        const error = VideoPlayerError(
          message: 'Technical error',
          category: VideoPlayerErrorCategory.unknown,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error.userMessage, equals('An error occurred. Please try again.'));
      });
    });

    group('incrementRetry', () {
      test('increments retry count by one', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        final incremented = error.incrementRetry();

        expect(incremented.retryCount, equals(1));
        expect(incremented.message, equals('Test'));
        expect(incremented.category, equals(VideoPlayerErrorCategory.network));
      });
    });

    group('copyWith', () {
      test('copies with new message', () {
        const error = VideoPlayerError(
          message: 'Original',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        final copied = error.copyWith(message: 'New message');

        expect(copied.message, equals('New message'));
        expect(copied.category, equals(VideoPlayerErrorCategory.network));
      });

      test('copies with new category', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        final copied = error.copyWith(category: VideoPlayerErrorCategory.codec);

        expect(copied.category, equals(VideoPlayerErrorCategory.codec));
        expect(copied.message, equals('Test'));
      });

      test('preserves unchanged values', () {
        const error = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          code: 'TEST',
          retryCount: 2,
          maxRetries: 5,
        );

        final copied = error.copyWith(message: 'New');

        expect(copied.code, equals('TEST'));
        expect(copied.retryCount, equals(2));
        expect(copied.maxRetries, equals(5));
      });
    });

    group('equality', () {
      test('equal errors are equal', () {
        const error1 = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          code: 'TEST',
          retryCount: 1,
        );

        const error2 = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          code: 'TEST',
          retryCount: 1,
        );

        expect(error1, equals(error2));
        expect(error1.hashCode, equals(error2.hashCode));
      });

      test('different messages are not equal', () {
        const error1 = VideoPlayerError(
          message: 'Test1',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        const error2 = VideoPlayerError(
          message: 'Test2',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error1, isNot(equals(error2)));
      });

      test('different categories are not equal', () {
        const error1 = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        const error2 = VideoPlayerError(
          message: 'Test',
          category: VideoPlayerErrorCategory.codec,
          severity: VideoPlayerErrorSeverity.recoverable,
        );

        expect(error1, isNot(equals(error2)));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        const error = VideoPlayerError(
          message: 'Test error',
          category: VideoPlayerErrorCategory.network,
          severity: VideoPlayerErrorSeverity.recoverable,
          code: 'NET_001',
          retryCount: 1,
        );

        final str = error.toString();
        expect(str, contains('VideoPlayerError'));
        expect(str, contains('Test error'));
        expect(str, contains('NET_001'));
        expect(str, contains('network'));
        expect(str, contains('recoverable'));
        expect(str, contains('1/3'));
      });
    });
  });

  group('ErrorRecoveryOptions', () {
    group('constructor', () {
      test('has correct default values', () {
        const options = ErrorRecoveryOptions.defaultOptions;

        expect(options.enableAutoRetry, isTrue);
        expect(options.maxAutoRetries, equals(3));
        expect(options.baseRetryDelay, equals(const Duration(seconds: 2)));
        expect(options.maxRetryDelay, equals(const Duration(seconds: 30)));
        expect(options.useExponentialBackoff, isTrue);
        expect(options.retryOnNetworkError, isTrue);
        expect(options.retryOnTimeoutError, isTrue);
        expect(options.retryOnPlaybackError, isFalse);
        expect(options.onRetryAttempt, isNull);
        expect(options.onRecoveryFailed, isNull);
      });

      test('creates with custom values', () {
        const options = ErrorRecoveryOptions(
          enableAutoRetry: false,
          maxAutoRetries: 5,
          baseRetryDelay: Duration(seconds: 5),
          maxRetryDelay: Duration(minutes: 1),
          useExponentialBackoff: false,
          retryOnNetworkError: false,
          retryOnTimeoutError: false,
          retryOnPlaybackError: true,
        );

        expect(options.enableAutoRetry, isFalse);
        expect(options.maxAutoRetries, equals(5));
        expect(options.baseRetryDelay, equals(const Duration(seconds: 5)));
        expect(options.maxRetryDelay, equals(const Duration(minutes: 1)));
        expect(options.useExponentialBackoff, isFalse);
        expect(options.retryOnNetworkError, isFalse);
        expect(options.retryOnTimeoutError, isFalse);
        expect(options.retryOnPlaybackError, isTrue);
      });
    });

    group('static instances', () {
      test('defaultOptions has auto retry enabled', () {
        expect(ErrorRecoveryOptions.defaultOptions.enableAutoRetry, isTrue);
      });

      test('noAutoRecovery has auto retry disabled', () {
        expect(ErrorRecoveryOptions.noAutoRecovery.enableAutoRetry, isFalse);
      });
    });

    group('shouldRetry', () {
      test('returns false when auto retry disabled', () {
        const options = ErrorRecoveryOptions.noAutoRecovery;

        expect(options.shouldRetry(VideoPlayerErrorCategory.network), isFalse);
        expect(options.shouldRetry(VideoPlayerErrorCategory.timeout), isFalse);
      });

      test('returns true for network errors by default', () {
        const options = ErrorRecoveryOptions.defaultOptions;

        expect(options.shouldRetry(VideoPlayerErrorCategory.network), isTrue);
      });

      test('returns false for network errors when disabled', () {
        const options = ErrorRecoveryOptions(retryOnNetworkError: false);

        expect(options.shouldRetry(VideoPlayerErrorCategory.network), isFalse);
      });

      test('returns true for timeout errors by default', () {
        const options = ErrorRecoveryOptions.defaultOptions;

        expect(options.shouldRetry(VideoPlayerErrorCategory.timeout), isTrue);
      });

      test('returns false for timeout errors when disabled', () {
        const options = ErrorRecoveryOptions(retryOnTimeoutError: false);

        expect(options.shouldRetry(VideoPlayerErrorCategory.timeout), isFalse);
      });

      test('returns true for playback errors when enabled', () {
        const options = ErrorRecoveryOptions(retryOnPlaybackError: true);

        expect(options.shouldRetry(VideoPlayerErrorCategory.playback), isTrue);
      });

      test('returns false for playback errors by default', () {
        const options = ErrorRecoveryOptions.defaultOptions;

        expect(options.shouldRetry(VideoPlayerErrorCategory.playback), isFalse);
      });

      test('returns false for non-retryable categories', () {
        const options = ErrorRecoveryOptions.defaultOptions;

        expect(options.shouldRetry(VideoPlayerErrorCategory.source), isFalse);
        expect(options.shouldRetry(VideoPlayerErrorCategory.codec), isFalse);
        expect(options.shouldRetry(VideoPlayerErrorCategory.permission), isFalse);
        expect(options.shouldRetry(VideoPlayerErrorCategory.platform), isFalse);
        expect(options.shouldRetry(VideoPlayerErrorCategory.unknown), isFalse);
      });
    });

    group('getRetryDelay', () {
      test('returns base delay when exponential backoff disabled', () {
        const options = ErrorRecoveryOptions(baseRetryDelay: Duration(seconds: 5), useExponentialBackoff: false);

        expect(options.getRetryDelay(0), equals(const Duration(seconds: 5)));
        expect(options.getRetryDelay(1), equals(const Duration(seconds: 5)));
        expect(options.getRetryDelay(2), equals(const Duration(seconds: 5)));
      });

      test('applies exponential backoff by default', () {
        const options = ErrorRecoveryOptions.defaultOptions;

        expect(options.getRetryDelay(0), equals(const Duration(seconds: 2)));
        expect(options.getRetryDelay(1), equals(const Duration(seconds: 4)));
        expect(options.getRetryDelay(2), equals(const Duration(seconds: 8)));
        expect(options.getRetryDelay(3), equals(const Duration(seconds: 16)));
      });

      test('caps delay at maxRetryDelay', () {
        const options = ErrorRecoveryOptions(maxRetryDelay: Duration(seconds: 10));

        expect(options.getRetryDelay(5), equals(const Duration(seconds: 10)));
        expect(options.getRetryDelay(10), equals(const Duration(seconds: 10)));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        const options = ErrorRecoveryOptions.defaultOptions;

        final copied = options.copyWith(enableAutoRetry: false, maxAutoRetries: 10);

        expect(copied.enableAutoRetry, isFalse);
        expect(copied.maxAutoRetries, equals(10));
        expect(copied.baseRetryDelay, equals(options.baseRetryDelay));
      });

      test('preserves unchanged values', () {
        const options = ErrorRecoveryOptions(maxAutoRetries: 5, baseRetryDelay: Duration(seconds: 5));

        final copied = options.copyWith(enableAutoRetry: false);

        expect(copied.maxAutoRetries, equals(5));
        expect(copied.baseRetryDelay, equals(const Duration(seconds: 5)));
      });
    });
  });
}
