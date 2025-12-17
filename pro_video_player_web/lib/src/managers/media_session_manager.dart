import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/media_session_interface.dart';
import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';

/// Manages browser Media Session API integration.
///
/// This manager integrates with the browser's Media Session API to provide
/// platform-native media controls (lock screen controls, notification area,
/// media keys, etc.). It handles:
/// - Setting media metadata (title, artist, album, artwork)
/// - Registering action handlers (play, pause, stop, seek)
/// - Cleanup on disposal
///
/// The Media Session API is supported in:
/// - Chrome 73+ (desktop and mobile)
/// - Firefox 82+ (desktop and mobile)
/// - Safari 15+ (macOS and iOS)
/// - Edge 79+
class MediaSessionManager with WebManagerCallbacks {
  /// Creates a media session manager.
  MediaSessionManager({
    required this.emitEvent,
    required this.videoElement,
    required MediaSessionInterface mediaSession,
  }) : _mediaSession = mediaSession;

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// The Media Session API wrapper.
  final MediaSessionInterface _mediaSession;

  /// Whether the Media Session API is available.
  bool get isAvailable => _mediaSession.isAvailable;

  /// Sets up action handlers for media session controls.
  ///
  /// These handlers are called when the user interacts with platform media
  /// controls (e.g., pressing play/pause on a keyboard, tapping controls in
  /// the lock screen, using media keys).
  ///
  /// Seek handlers automatically seek forward/backward by 15 seconds.
  ///
  /// Note: The async callbacks are wrapped in synchronous functions that
  /// fire-and-forget (don't await), as required by the browser's Media Session API.
  void setupActionHandlers({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function() onStop,
  }) {
    if (!_mediaSession.isAvailable) {
      verboseLog('Media Session API not available', tag: 'MediaSessionManager');
      return;
    }

    try {
      // Register action handlers (wrapped for fire-and-forget)
      _mediaSession.setActionHandler('play', () => onPlay());
      _mediaSession.setActionHandler('pause', () => onPause());
      _mediaSession.setActionHandler('stop', () => onStop());

      // Seek handlers
      _mediaSession.setActionHandler('seekforward', _handleSeekForward);
      _mediaSession.setActionHandler('seekbackward', _handleSeekBackward);

      verboseLog('Media session action handlers set up', tag: 'MediaSessionManager');
    } catch (e) {
      verboseLog('Failed to set up media session action handlers: $e', tag: 'MediaSessionManager');
    }
  }

  /// Sets media metadata for browser media controls.
  ///
  /// This updates the displayed information in platform media controls
  /// (e.g., macOS Control Center, Windows media overlay, mobile notifications).
  ///
  /// All parameters can be null, in which case they default to empty strings
  /// (except artworkUrl which remains null).
  void setMetadata(MediaMetadata metadata) {
    if (!_mediaSession.isAvailable) {
      verboseLog('Media Session API not available', tag: 'MediaSessionManager');
      return;
    }

    try {
      _mediaSession.setMetadata(
        title: metadata.title ?? '',
        artist: metadata.artist ?? '',
        album: metadata.album ?? '',
        artworkUrl: metadata.artworkUrl,
      );

      verboseLog('Media metadata set: ${metadata.title}', tag: 'MediaSessionManager');
    } catch (e) {
      verboseLog('Failed to set media metadata: $e', tag: 'MediaSessionManager');
    }
  }

  /// Handles seek forward action (15 seconds).
  void _handleSeekForward() {
    try {
      final currentPos = videoElement.currentTime;
      final newPos = currentPos + 15;
      videoElement.currentTime = newPos;
      verboseLog('Seeked forward to $newPos seconds', tag: 'MediaSessionManager');
    } catch (e) {
      verboseLog('Failed to seek forward: $e', tag: 'MediaSessionManager');
    }
  }

  /// Handles seek backward action (15 seconds).
  void _handleSeekBackward() {
    try {
      final currentPos = videoElement.currentTime;
      final newPos = (currentPos - 15).clamp(0.0, double.infinity);
      videoElement.currentTime = newPos;
      verboseLog('Seeked backward to $newPos seconds', tag: 'MediaSessionManager');
    } catch (e) {
      verboseLog('Failed to seek backward: $e', tag: 'MediaSessionManager');
    }
  }

  /// Disposes the manager and cleans up resources.
  ///
  /// Clears action handlers and metadata.
  void dispose() {
    try {
      _mediaSession.clearActionHandlers();
      _mediaSession.clearMetadata();
      verboseLog('Media session manager disposed', tag: 'MediaSessionManager');
    } catch (e) {
      verboseLog('Error during media session disposal: $e', tag: 'MediaSessionManager');
    }
  }
}
