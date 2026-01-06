import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

// Alias for cleaner code
typedef _Logger = ProVideoPlayerLogger;

/// Mixin providing error recovery functionality.
mixin ErrorRecoveryMixin on ProVideoPlayerControllerBase {
  /// The error recovery options for this controller.
  ///
  /// Override in main class to provide actual options.
  ErrorRecoveryOptions get errorRecoveryOptions;

  /// Whether an automatic retry is currently in progress.
  bool get isRetrying => isRetryingInternal;

  /// Clears the current error state and resets to ready state.
  ///
  /// This does not retry the failed operation. Use [retry] or [reinitialize]
  /// to attempt recovery.
  void clearError() {
    if (!value.hasError) return;
    value = value.copyWith(playbackState: PlaybackState.ready, clearError: true);
  }

  /// Retries the last failed operation.
  ///
  /// If the player failed during initialization, this will reinitialize.
  /// If the player failed during playback, this will attempt to resume.
  ///
  /// Returns `true` if the retry was successful, `false` otherwise.
  ///
  /// Throws [StateError] if there is no error to retry, or if the controller
  /// is disposed.
  Future<bool> retry() async {
    if (isDisposed) {
      throw StateError('Cannot retry on a disposed controller');
    }
    if (!value.hasError) {
      throw StateError('No error to retry');
    }

    final error = value.error;
    if (error != null && !error.canRetry) {
      _Logger.log('Cannot retry: max retries exceeded', tag: 'Controller');
      return false;
    }

    _Logger.log(
      'Retrying after error (attempt ${(error?.retryCount ?? 0) + 1}/${error?.maxRetries ?? errorRecoveryOptions.maxAutoRetries})',
      tag: 'Controller',
    );

    // Increment retry count
    final updatedError = error?.incrementRetry();

    try {
      // If player was never created, reinitialize
      if (playerId == null && sourceInternal != null) {
        await reinitialize();
        return true;
      }

      // Otherwise, try to resume playback
      clearError();
      await _play();
      return true;
    } catch (e) {
      _Logger.error('Retry failed', tag: 'Controller', error: e);
      final newError =
          updatedError?.copyWith(message: e.toString(), originalError: e) ??
          VideoPlayerError.fromCode(message: e.toString());
      value = value.copyWith(playbackState: PlaybackState.error, errorMessage: e.toString(), error: newError);
      return false;
    }
  }

  /// Cancels any pending automatic retry.
  ///
  /// This stops any scheduled retry attempts and resets the retrying state.
  void cancelAutoRetry() {
    services.errorRecovery.cancelRetryTimer();
    isRetryingInternal = false;
  }

  /// Reinitializes the player with the original source.
  ///
  /// This disposes the current player and creates a new one with the same
  /// source and options that were used in the initial initialize call.
  ///
  /// Use this for complete recovery from fatal errors or when the player
  /// is in an unrecoverable state.
  ///
  /// Throws [StateError] if the controller was never initialized or is disposed.
  Future<void> reinitialize();

  /// Internal play method - implemented by main class.
  Future<void> _play() => services.playbackManager.play();
}
