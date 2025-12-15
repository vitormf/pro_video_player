import 'dart:async';

import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

// Alias for cleaner code
typedef _Logger = ProVideoPlayerLogger;

/// Manages error recovery and auto-retry logic for the video player.
///
/// This manager handles:
/// - Automatic retry on recoverable errors
/// - Exponential backoff for network errors
/// - Network state change detection
/// - Retry scheduling and cancellation
class ErrorRecoveryManager {
  /// Creates an error recovery manager.
  ErrorRecoveryManager({
    required ErrorRecoveryOptions options,
    required this.getValue,
    required this.setValue,
    required this.isDisposed,
    required this.getPlayerId,
    required this.platform,
    required this.onRetry,
  }) : _options = options;

  final ErrorRecoveryOptions _options;

  /// Callback to get current player value.
  final VideoPlayerValue Function() getValue;

  /// Callback to update player value.
  final void Function(VideoPlayerValue) setValue;

  /// Callback to check if controller is disposed.
  final bool Function() isDisposed;

  /// Callback to get current player ID.
  final int? Function() getPlayerId;

  /// Platform instance for making platform calls.
  final ProVideoPlayerPlatform platform;

  /// Callback when retry is needed (calls controller.retry()).
  final Future<void> Function() onRetry;

  Timer? _retryTimer;
  bool _isRetrying = false;

  /// Whether a retry is currently in progress.
  bool get isRetrying => _isRetrying;

  /// The error recovery options.
  ErrorRecoveryOptions get options => _options;

  /// Schedules an automatic retry for the given error.
  ///
  /// This is called when the player encounters an error that might be
  /// recoverable. It checks if auto-retry is enabled, if the error category
  /// should be retried, and schedules a retry with exponential backoff.
  void scheduleAutoRetry(VideoPlayerError error) {
    if (!_options.enableAutoRetry) return;
    if (!_options.shouldRetry(error.category)) return;
    if (!error.canRetry) {
      _options.onRecoveryFailed?.call(error);
      return;
    }

    final attemptNumber = error.retryCount + 1;
    if (_options.onRetryAttempt?.call(error, attemptNumber) == false) {
      _Logger.log('Auto-retry cancelled by callback', tag: 'ErrorRecovery');
      return;
    }

    final delay = _options.getRetryDelay(error.retryCount);
    _Logger.log('Scheduling auto-retry in ${delay.inSeconds}s (attempt $attemptNumber)', tag: 'ErrorRecovery');

    _isRetrying = true;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () async {
      if (isDisposed()) return;
      _isRetrying = false;
      try {
        await onRetry();
      } catch (e) {
        _Logger.error('Auto-retry failed', tag: 'ErrorRecovery', error: e);
      }
    });
  }

  /// Handles a network error by scheduling retries with exponential backoff.
  ///
  /// If auto-retry is disabled or max retries exceeded, the error is set
  /// on the player value. Otherwise, schedules a retry attempt.
  void handleNetworkError(String message) {
    if (!_options.enableAutoRetry) {
      // No auto-retry configured, just update error state
      final value = getValue();
      setValue(value.copyWith(playbackState: PlaybackState.error, errorMessage: message));
      return;
    }

    final value = getValue();
    final currentRetry = value.networkRetryCount;
    final maxRetries = _options.maxAutoRetries;

    if (currentRetry >= maxRetries) {
      // Max retries exceeded
      _Logger.log('Max retries ($maxRetries) exceeded, stopping retry', tag: 'ErrorRecovery');
      cancelRetryTimer();
      _isRetrying = false;
      setValue(value.copyWith(playbackState: PlaybackState.error, errorMessage: message, isRecoveringFromError: false));
      return;
    }

    // Schedule retry with exponential backoff
    final delay = _calculateRetryDelay(currentRetry);
    _Logger.log('Scheduling retry ${currentRetry + 1}/$maxRetries in ${delay.inSeconds}s', tag: 'ErrorRecovery');

    setValue(
      value.copyWith(
        networkRetryCount: currentRetry + 1,
        isRecoveringFromError: true,
        playbackState: PlaybackState.buffering,
      ),
    );

    _scheduleRetry(delay);
  }

  /// Handles network state change from native layer.
  ///
  /// If network is restored while recovering from error, attempts
  /// immediate recovery without waiting for the scheduled retry.
  void handleNetworkStateChange({required bool isConnected}) {
    final value = getValue();
    if (isConnected && value.isRecoveringFromError) {
      // Network restored while we had an error - try immediate recovery
      _Logger.log('Network restored, attempting immediate recovery', tag: 'ErrorRecovery');
      cancelRetryTimer();
      unawaited(attemptRetry());
    }
  }

  /// Schedules a retry attempt after the specified delay.
  void _scheduleRetry(Duration delay) {
    cancelRetryTimer();
    _retryTimer = Timer(delay, attemptRetry);
  }

  /// Cancels any pending retry timer.
  void cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Attempts to recover from a network error.
  ///
  /// Seeks to current position to trigger a reload, then resumes playback.
  /// This is called automatically by the retry timer or when network is restored.
  Future<void> attemptRetry() async {
    final playerId = getPlayerId();
    if (isDisposed() || playerId == null) return;
    if (_isRetrying) return; // Prevent concurrent retries

    _isRetrying = true;
    final value = getValue();
    _Logger.log('Attempting network recovery (retry ${value.networkRetryCount})', tag: 'ErrorRecovery');

    try {
      // Seek to current position to trigger a reload
      final currentPosition = value.position;
      await platform.seekTo(playerId, currentPosition);

      // Try to resume playback
      await platform.play(playerId);
    } catch (e) {
      _Logger.log('Retry attempt failed: $e', tag: 'ErrorRecovery');
      // The native layer will send another NetworkErrorEvent if it fails
    } finally {
      _isRetrying = false;
    }
  }

  /// Calculates retry delay with exponential backoff.
  ///
  /// Returns 2^n seconds, capped at 30 seconds.
  Duration _calculateRetryDelay(int retryCount) {
    // Exponential backoff: 2^n seconds, capped at 30 seconds
    final seconds = (1 << retryCount).clamp(1, 30);
    return Duration(seconds: seconds);
  }

  /// Disposes the manager and cancels any pending timers.
  void dispose() {
    cancelRetryTimer();
    _isRetrying = false;
  }
}
