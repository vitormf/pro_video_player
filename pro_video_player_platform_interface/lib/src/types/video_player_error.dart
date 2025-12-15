/// Categories of video player errors.
///
/// Error categories help determine the appropriate recovery strategy
/// and provide more context about what went wrong.
enum VideoPlayerErrorCategory {
  /// Network-related errors (connection timeout, no internet, etc.).
  ///
  /// These errors are typically recoverable with retry logic.
  network,

  /// Video source errors (invalid URL, file not found, access denied).
  ///
  /// May be recoverable if the source can be corrected or an alternative exists.
  source,

  /// Codec or format errors (unsupported format, corrupted file).
  ///
  /// Usually not recoverable without providing a different source.
  codec,

  /// Permission errors (storage access, DRM, geo-restrictions).
  ///
  /// May require user action to resolve.
  permission,

  /// Platform or system errors (audio session, hardware issues).
  ///
  /// Recovery depends on the specific issue.
  platform,

  /// Playback errors that occur during video playback.
  ///
  /// May be recoverable by seeking or restarting playback.
  playback,

  /// Timeout errors (initialization timeout, seek timeout).
  ///
  /// Usually recoverable with retry logic.
  timeout,

  /// Unknown or unclassified errors.
  unknown,
}

/// Severity levels for video player errors.
///
/// Severity helps determine whether automatic recovery should be attempted
/// and how the error should be presented to the user.
enum VideoPlayerErrorSeverity {
  /// Recoverable errors that may resolve with retry or time.
  ///
  /// Examples: temporary network issues, buffering timeouts.
  /// The player may attempt automatic recovery.
  recoverable,

  /// Warning-level errors that don't prevent playback.
  ///
  /// Examples: subtitle loading failed, quality switch failed.
  /// Playback continues but with degraded functionality.
  warning,

  /// Fatal errors that require user intervention or source change.
  ///
  /// Examples: invalid source, unsupported format, permanent access denied.
  /// The player cannot recover automatically.
  fatal,
}

/// Suggested strategies for recovering from errors.
///
/// These strategies can be used by the application to implement
/// appropriate recovery behavior.
enum RecoveryStrategy {
  /// Retry the failed operation after a delay.
  ///
  /// Suitable for transient network issues.
  retry,

  /// Reinitialize the player with the same source.
  ///
  /// Suitable for playback errors that occurred mid-stream.
  reinitialize,

  /// Try an alternative source if available.
  ///
  /// Suitable when the primary source is unavailable.
  tryAlternativeSource,

  /// Reduce quality or switch to a lower bitrate.
  ///
  /// Suitable for bandwidth-related issues.
  reduceQuality,

  /// Wait for network connectivity to be restored.
  ///
  /// Suitable for offline scenarios.
  waitForNetwork,

  /// Request user intervention (e.g., grant permissions).
  ///
  /// Suitable for permission-related errors.
  requestUserAction,

  /// No recovery is possible; display error to user.
  ///
  /// Suitable for fatal errors like invalid source format.
  none,
}

/// Comprehensive video player error with classification and recovery context.
///
/// This class provides detailed information about playback errors to enable
/// intelligent error handling and recovery.
///
/// ## Example
///
/// ```dart
/// controller.addListener(() {
///   final error = controller.value.error;
///   if (error != null) {
///     if (error.severity == VideoPlayerErrorSeverity.recoverable) {
///       // Attempt automatic recovery
///       if (error.suggestedRecovery == RecoveryStrategy.retry) {
///         controller.retry();
///       }
///     } else if (error.severity == VideoPlayerErrorSeverity.fatal) {
///       // Show error to user
///       showErrorDialog(error.userMessage);
///     }
///   }
/// });
/// ```
class VideoPlayerError {
  /// Creates a video player error.
  const VideoPlayerError({
    required this.message,
    required this.category,
    required this.severity,
    this.code,
    this.suggestedRecovery = RecoveryStrategy.none,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.nativeErrorCode,
    this.originalError,
    this.stackTrace,
  });

  /// Creates an error from a simple message and code.
  ///
  /// Attempts to classify the error based on the code string.
  factory VideoPlayerError.fromCode({
    required String message,
    String? code,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    final (category, severity, recovery) = _classifyError(code, message);
    return VideoPlayerError(
      message: message,
      code: code,
      category: category,
      severity: severity,
      suggestedRecovery: recovery,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Creates a network error.
  factory VideoPlayerError.network({
    required String message,
    String? code,
    int retryCount = 0,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) => VideoPlayerError(
    message: message,
    code: code,
    category: VideoPlayerErrorCategory.network,
    severity: VideoPlayerErrorSeverity.recoverable,
    suggestedRecovery: RecoveryStrategy.retry,
    retryCount: retryCount,
    maxRetries: maxRetries,
    retryDelay: retryDelay,
  );

  /// Creates a source error.
  factory VideoPlayerError.source({required String message, String? code}) => VideoPlayerError(
    message: message,
    code: code,
    category: VideoPlayerErrorCategory.source,
    severity: VideoPlayerErrorSeverity.fatal,
    suggestedRecovery: RecoveryStrategy.tryAlternativeSource,
  );

  /// Creates a codec/format error.
  factory VideoPlayerError.codec({required String message, String? code}) => VideoPlayerError(
    message: message,
    code: code,
    category: VideoPlayerErrorCategory.codec,
    severity: VideoPlayerErrorSeverity.fatal,
  );

  /// Creates a timeout error.
  factory VideoPlayerError.timeout({required String message, String? code, int retryCount = 0, int maxRetries = 3}) =>
      VideoPlayerError(
        message: message,
        code: code,
        category: VideoPlayerErrorCategory.timeout,
        severity: VideoPlayerErrorSeverity.recoverable,
        suggestedRecovery: RecoveryStrategy.retry,
        retryCount: retryCount,
        maxRetries: maxRetries,
      );

  /// The error message (technical description).
  final String message;

  /// The error code for programmatic handling.
  final String? code;

  /// The category of error.
  final VideoPlayerErrorCategory category;

  /// The severity level of the error.
  final VideoPlayerErrorSeverity severity;

  /// Suggested recovery strategy.
  final RecoveryStrategy suggestedRecovery;

  /// Number of retry attempts already made.
  final int retryCount;

  /// Maximum number of retry attempts allowed.
  final int maxRetries;

  /// Delay before next retry attempt.
  final Duration retryDelay;

  /// Native platform error code (e.g., ExoPlayer error code, AVError code).
  final int? nativeErrorCode;

  /// The original exception or error object.
  final Object? originalError;

  /// Stack trace from the original error.
  final StackTrace? stackTrace;

  /// Whether more retry attempts are available.
  bool get canRetry => retryCount < maxRetries && severity == VideoPlayerErrorSeverity.recoverable;

  /// Calculates the delay for the next retry using exponential backoff.
  Duration get nextRetryDelay =>
      Duration(milliseconds: (retryDelay.inMilliseconds * (1 << retryCount)).clamp(0, 30000));

  /// User-friendly error message suitable for display.
  String get userMessage {
    switch (category) {
      case VideoPlayerErrorCategory.network:
        return 'Network error. Please check your internet connection.';
      case VideoPlayerErrorCategory.source:
        return 'Unable to load video. The source may be unavailable.';
      case VideoPlayerErrorCategory.codec:
        return 'This video format is not supported.';
      case VideoPlayerErrorCategory.permission:
        return 'Permission required to play this video.';
      case VideoPlayerErrorCategory.platform:
        return 'A system error occurred. Please try again.';
      case VideoPlayerErrorCategory.playback:
        return 'Playback error occurred. Please try again.';
      case VideoPlayerErrorCategory.timeout:
        return 'Loading timed out. Please try again.';
      case VideoPlayerErrorCategory.unknown:
        return 'An error occurred. Please try again.';
    }
  }

  /// Creates a copy with an incremented retry count.
  VideoPlayerError incrementRetry() => VideoPlayerError(
    message: message,
    code: code,
    category: category,
    severity: severity,
    suggestedRecovery: suggestedRecovery,
    retryCount: retryCount + 1,
    maxRetries: maxRetries,
    retryDelay: retryDelay,
    nativeErrorCode: nativeErrorCode,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  /// Creates a copy with updated fields.
  VideoPlayerError copyWith({
    String? message,
    String? code,
    VideoPlayerErrorCategory? category,
    VideoPlayerErrorSeverity? severity,
    RecoveryStrategy? suggestedRecovery,
    int? retryCount,
    int? maxRetries,
    Duration? retryDelay,
    int? nativeErrorCode,
    Object? originalError,
    StackTrace? stackTrace,
  }) => VideoPlayerError(
    message: message ?? this.message,
    code: code ?? this.code,
    category: category ?? this.category,
    severity: severity ?? this.severity,
    suggestedRecovery: suggestedRecovery ?? this.suggestedRecovery,
    retryCount: retryCount ?? this.retryCount,
    maxRetries: maxRetries ?? this.maxRetries,
    retryDelay: retryDelay ?? this.retryDelay,
    nativeErrorCode: nativeErrorCode ?? this.nativeErrorCode,
    originalError: originalError ?? this.originalError,
    stackTrace: stackTrace ?? this.stackTrace,
  );

  /// Classifies an error based on code and message.
  static (VideoPlayerErrorCategory, VideoPlayerErrorSeverity, RecoveryStrategy) _classifyError(
    String? code,
    String message,
  ) {
    final lowerCode = code?.toLowerCase() ?? '';
    final lowerMessage = message.toLowerCase();

    // Timeout errors (check before network since 'timeout' could be in both)
    if (lowerCode.contains('timeout') || lowerMessage.contains('timeout') || lowerMessage.contains('timed out')) {
      return (VideoPlayerErrorCategory.timeout, VideoPlayerErrorSeverity.recoverable, RecoveryStrategy.retry);
    }

    // Network errors
    if (lowerCode.contains('network') ||
        lowerCode.contains('connection') ||
        lowerMessage.contains('network') ||
        lowerMessage.contains('connection') ||
        lowerMessage.contains('unreachable')) {
      return (VideoPlayerErrorCategory.network, VideoPlayerErrorSeverity.recoverable, RecoveryStrategy.retry);
    }

    // Source errors
    if (lowerCode.contains('source') ||
        lowerCode.contains('invalid') ||
        lowerCode.contains('not_found') ||
        lowerMessage.contains('not found') ||
        lowerMessage.contains('invalid source') ||
        lowerMessage.contains('404')) {
      return (VideoPlayerErrorCategory.source, VideoPlayerErrorSeverity.fatal, RecoveryStrategy.tryAlternativeSource);
    }

    // Codec errors
    if (lowerCode.contains('codec') ||
        lowerCode.contains('format') ||
        lowerCode.contains('decoder') ||
        lowerMessage.contains('unsupported') ||
        lowerMessage.contains('codec') ||
        lowerMessage.contains('format')) {
      return (VideoPlayerErrorCategory.codec, VideoPlayerErrorSeverity.fatal, RecoveryStrategy.none);
    }

    // Permission errors
    if (lowerCode.contains('permission') ||
        lowerCode.contains('drm') ||
        lowerCode.contains('license') ||
        lowerMessage.contains('permission') ||
        lowerMessage.contains('denied') ||
        lowerMessage.contains('restricted')) {
      return (VideoPlayerErrorCategory.permission, VideoPlayerErrorSeverity.fatal, RecoveryStrategy.requestUserAction);
    }

    // Platform errors
    if (lowerCode.contains('audio_session') ||
        lowerCode.contains('platform') ||
        lowerCode.contains('system') ||
        lowerMessage.contains('audio session') ||
        lowerMessage.contains('hardware')) {
      return (VideoPlayerErrorCategory.platform, VideoPlayerErrorSeverity.recoverable, RecoveryStrategy.reinitialize);
    }

    // Playback errors (default for unknown codes)
    if (lowerCode.contains('playback') || lowerCode.contains('error')) {
      return (VideoPlayerErrorCategory.playback, VideoPlayerErrorSeverity.recoverable, RecoveryStrategy.reinitialize);
    }

    // Unknown
    return (VideoPlayerErrorCategory.unknown, VideoPlayerErrorSeverity.recoverable, RecoveryStrategy.retry);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoPlayerError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code &&
          category == other.category &&
          severity == other.severity &&
          retryCount == other.retryCount;

  @override
  int get hashCode => Object.hash(message, code, category, severity, retryCount);

  @override
  String toString() =>
      'VideoPlayerError(message: $message, code: $code, category: $category, severity: $severity, retryCount: $retryCount/$maxRetries)';
}

/// Options for error recovery behavior.
///
/// Configure how the player handles errors and recovery attempts.
class ErrorRecoveryOptions {
  /// Creates error recovery options.
  const ErrorRecoveryOptions({
    this.enableAutoRetry = true,
    this.maxAutoRetries = 3,
    this.baseRetryDelay = const Duration(seconds: 2),
    this.maxRetryDelay = const Duration(seconds: 30),
    this.useExponentialBackoff = true,
    this.retryOnNetworkError = true,
    this.retryOnTimeoutError = true,
    this.retryOnPlaybackError = false,
    this.onRetryAttempt,
    this.onRecoveryFailed,
  });

  /// Default options with automatic retry enabled.
  static const defaultOptions = ErrorRecoveryOptions();

  /// Options with no automatic recovery.
  static const noAutoRecovery = ErrorRecoveryOptions(enableAutoRetry: false);

  /// Whether to automatically attempt recovery for recoverable errors.
  final bool enableAutoRetry;

  /// Maximum number of automatic retry attempts.
  final int maxAutoRetries;

  /// Base delay between retry attempts.
  final Duration baseRetryDelay;

  /// Maximum delay between retry attempts (when using exponential backoff).
  final Duration maxRetryDelay;

  /// Whether to use exponential backoff for retry delays.
  final bool useExponentialBackoff;

  /// Whether to retry on network errors.
  final bool retryOnNetworkError;

  /// Whether to retry on timeout errors.
  final bool retryOnTimeoutError;

  /// Whether to retry on playback errors.
  final bool retryOnPlaybackError;

  /// Callback invoked before each retry attempt.
  ///
  /// Return `false` to cancel the retry.
  final bool Function(VideoPlayerError error, int attemptNumber)? onRetryAttempt;

  /// Callback invoked when all recovery attempts have failed.
  final void Function(VideoPlayerError error)? onRecoveryFailed;

  /// Whether to retry for the given error category.
  bool shouldRetry(VideoPlayerErrorCategory category) {
    if (!enableAutoRetry) return false;
    switch (category) {
      case VideoPlayerErrorCategory.network:
        return retryOnNetworkError;
      case VideoPlayerErrorCategory.timeout:
        return retryOnTimeoutError;
      case VideoPlayerErrorCategory.playback:
        return retryOnPlaybackError;
      case VideoPlayerErrorCategory.source:
      case VideoPlayerErrorCategory.codec:
      case VideoPlayerErrorCategory.permission:
      case VideoPlayerErrorCategory.platform:
      case VideoPlayerErrorCategory.unknown:
        return false;
    }
  }

  /// Calculates the delay for a given retry attempt.
  Duration getRetryDelay(int attemptNumber) {
    if (!useExponentialBackoff) return baseRetryDelay;
    final delay = Duration(milliseconds: baseRetryDelay.inMilliseconds * (1 << attemptNumber));
    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }

  /// Creates a copy with updated fields.
  ErrorRecoveryOptions copyWith({
    bool? enableAutoRetry,
    int? maxAutoRetries,
    Duration? baseRetryDelay,
    Duration? maxRetryDelay,
    bool? useExponentialBackoff,
    bool? retryOnNetworkError,
    bool? retryOnTimeoutError,
    bool? retryOnPlaybackError,
    bool Function(VideoPlayerError error, int attemptNumber)? onRetryAttempt,
    void Function(VideoPlayerError error)? onRecoveryFailed,
  }) => ErrorRecoveryOptions(
    enableAutoRetry: enableAutoRetry ?? this.enableAutoRetry,
    maxAutoRetries: maxAutoRetries ?? this.maxAutoRetries,
    baseRetryDelay: baseRetryDelay ?? this.baseRetryDelay,
    maxRetryDelay: maxRetryDelay ?? this.maxRetryDelay,
    useExponentialBackoff: useExponentialBackoff ?? this.useExponentialBackoff,
    retryOnNetworkError: retryOnNetworkError ?? this.retryOnNetworkError,
    retryOnTimeoutError: retryOnTimeoutError ?? this.retryOnTimeoutError,
    retryOnPlaybackError: retryOnPlaybackError ?? this.retryOnPlaybackError,
    onRetryAttempt: onRetryAttempt ?? this.onRetryAttempt,
    onRecoveryFailed: onRecoveryFailed ?? this.onRecoveryFailed,
  );
}
