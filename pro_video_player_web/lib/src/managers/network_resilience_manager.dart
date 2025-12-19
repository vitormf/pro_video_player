import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:web/web.dart' as web;

import '../abstractions/navigator_interface.dart';
import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';

/// Manages network connectivity monitoring and error recovery.
///
/// This manager monitors the browser's network state using the Navigator.onLine
/// API and automatically attempts to recover playback when the network connection
/// is restored after a network error.
///
/// Recovery strategies differ based on the playback technology:
/// - **Native HTML5**: Reloads the video element and restores position
/// - **HLS.js**: Calls startLoad() to resume adaptive streaming
/// - **DASH.js**: Re-attaches the source and restores position
///
/// The manager enforces a maximum retry limit to prevent infinite retry loops.
class NetworkResilienceManager with WebManagerCallbacks {
  /// Creates a network resilience manager.
  NetworkResilienceManager({required this.emitEvent, required this.videoElement, required NavigatorInterface navigator})
    : _navigator = navigator,
      _isNetworkAvailable = navigator.onLine;

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// The Navigator object for checking network state (injected for testing).
  final NavigatorInterface _navigator;

  /// Maximum number of network recovery retries.
  static const int maxRetries = 3;

  // State fields
  bool _isNetworkAvailable = true;
  bool _hadNetworkError = false;
  bool _wasPlayingBeforeError = false;
  int _networkRetryCount = 0;

  // Event listener functions (stored for removal on dispose)
  JSFunction? _onlineListener;
  JSFunction? _offlineListener;

  // Dart callbacks (stored for testing - can be called from Dart)
  void Function(Object?)? _onlineCallback;
  void Function(Object?)? _offlineCallback;

  /// Whether network is currently available.
  bool get isNetworkAvailable => _isNetworkAvailable;

  /// Whether a network error has occurred.
  bool get hadNetworkError => _hadNetworkError;

  /// Whether playback was active when error occurred.
  bool get wasPlayingBeforeError => _wasPlayingBeforeError;

  /// Current retry count.
  int get retryCount => _networkRetryCount;

  /// Sets up network connectivity monitoring.
  ///
  /// Listens for online/offline events from the browser and emits
  /// [NetworkStateChangedEvent] when connectivity changes.
  void setupNetworkMonitoring() {
    // Store Dart callbacks for testing
    _onlineCallback = (_) {
      final wasAvailable = _isNetworkAvailable;
      _isNetworkAvailable = true;
      emitEvent(const NetworkStateChangedEvent(isConnected: true));
      verboseLog('Network online', tag: 'NetworkResilienceManager');

      // Attempt recovery if we had a network error
      if (!wasAvailable && _hadNetworkError) {
        verboseLog('Attempting network recovery', tag: 'NetworkResilienceManager');
        // Note: Recovery is triggered externally via attemptRecovery()
      }
    };

    _offlineCallback = (_) {
      _isNetworkAvailable = false;
      emitEvent(const NetworkStateChangedEvent(isConnected: false));
      verboseLog('Network offline', tag: 'NetworkResilienceManager');
    };

    // Convert to JS functions for real browser usage
    _onlineListener = ((web.Event e) {
      _onlineCallback!(e);
    }).toJS;
    _offlineListener = ((web.Event e) {
      _offlineCallback!(e);
    }).toJS;

    _navigator.addEventListener('online', _onlineListener!);
    _navigator.addEventListener('offline', _offlineListener!);

    verboseLog('Network monitoring setup complete', tag: 'NetworkResilienceManager');
  }

  /// Records a network error event.
  ///
  /// Tracks error state and emits buffering event to indicate recovery attempt.
  /// [wasPlaying] indicates whether video was playing when error occurred.
  void onNetworkError({required bool wasPlaying}) {
    _hadNetworkError = true;
    _wasPlayingBeforeError = wasPlaying;

    if (_networkRetryCount < maxRetries) {
      _networkRetryCount++;
      emitEvent(const BufferingStartedEvent(reason: BufferingReason.networkUnstable));
      verboseLog('Network error detected (retry $_networkRetryCount/$maxRetries)', tag: 'NetworkResilienceManager');
    } else {
      verboseLog('Network error detected (max retries reached)', tag: 'NetworkResilienceManager');
    }
  }

  /// Attempts to recover from a network error.
  ///
  /// Calls the appropriate recovery callback based on the active playback
  /// technology:
  /// - [onHlsRecovery]: Called for HLS.js playback
  /// - [onDashRecovery]: Called for DASH.js playback
  /// - [onNativeRecovery]: Called for native HTML5 playback (returns position)
  ///
  /// Emits [PlaybackRecoveredEvent] on successful recovery.
  ///
  /// Returns early if max retries have been reached.
  Future<void> attemptRecovery({
    Future<void> Function()? onHlsRecovery,
    Future<void> Function()? onDashRecovery,
    Future<double> Function()? onNativeRecovery,
  }) async {
    if (_networkRetryCount > maxRetries) {
      verboseLog('Max retries reached, not attempting recovery', tag: 'NetworkResilienceManager');
      return;
    }

    try {
      if (onHlsRecovery != null) {
        // HLS.js recovery
        verboseLog('Attempting HLS.js recovery', tag: 'NetworkResilienceManager');
        await onHlsRecovery();

        if (_wasPlayingBeforeError) {
          await videoElement.play();
        }
      } else if (onDashRecovery != null) {
        // DASH.js recovery
        verboseLog('Attempting DASH.js recovery', tag: 'NetworkResilienceManager');
        await onDashRecovery();

        if (_wasPlayingBeforeError) {
          await videoElement.play();
        }
      } else if (onNativeRecovery != null) {
        // Native recovery
        verboseLog('Attempting native recovery', tag: 'NetworkResilienceManager');
        final position = await onNativeRecovery();

        // Restore position
        videoElement.currentTime = position;

        if (_wasPlayingBeforeError) {
          await videoElement.play();
        }
      }

      // Success - reset error state
      _hadNetworkError = false;
      final retriesUsed = _networkRetryCount;
      _networkRetryCount = 0;

      emitEvent(PlaybackRecoveredEvent(retriesUsed: retriesUsed));
      verboseLog('Network recovery successful (used $retriesUsed retries)', tag: 'NetworkResilienceManager');
    } catch (e) {
      verboseLog('Network recovery failed: $e', tag: 'NetworkResilienceManager');
      // Error state remains, will retry on next online event
    }
  }

  /// Disposes the manager and cleans up resources.
  ///
  /// Removes event listeners and resets state.
  void dispose() {
    if (_onlineListener != null) {
      _navigator.removeEventListener('online', _onlineListener!);
    }
    if (_offlineListener != null) {
      _navigator.removeEventListener('offline', _offlineListener!);
    }

    _hadNetworkError = false;
    _networkRetryCount = 0;

    verboseLog('Network resilience manager disposed', tag: 'NetworkResilienceManager');
  }

  /// Test-only: Gets the online callback for testing.
  ///
  /// This allows tests to trigger online/offline events without going through
  /// JS interop.
  @visibleForTesting
  void Function(Object?)? get onlineCallbackForTesting => _onlineCallback;

  /// Test-only: Gets the offline callback for testing.
  ///
  /// This allows tests to trigger online/offline events without going through
  /// JS interop.
  @visibleForTesting
  void Function(Object?)? get offlineCallbackForTesting => _offlineCallback;
}
