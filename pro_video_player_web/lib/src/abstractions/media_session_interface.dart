import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../media_session_interop.dart' as media_session;

/// Interface for Media Session API.
///
/// Abstracts the browser Media Session API to allow for testing without actual
/// browser APIs. The Media Session API enables web apps to integrate with
/// platform media controls (lock screen, notification area, media keys).
abstract interface class MediaSessionInterface {
  /// Whether the Media Session API is available.
  bool get isAvailable;

  /// Sets the metadata for the media session.
  ///
  /// This updates the displayed information in platform media controls
  /// (e.g., macOS Control Center, Windows media overlay, mobile notifications).
  void setMetadata({required String title, required String artist, required String album, String? artworkUrl});

  /// Sets an action handler for the media session.
  ///
  /// Common actions: 'play', 'pause', 'stop', 'seekforward', 'seekbackward',
  /// 'seekto', 'previoustrack', 'nexttrack'.
  ///
  /// Note: The handler must be synchronous. For async operations, use
  /// fire-and-forget (don't await).
  void setActionHandler(String action, void Function() handler);

  /// Clears all action handlers.
  void clearActionHandlers();

  /// Clears the metadata.
  void clearMetadata();
}

/// Browser implementation of [MediaSessionInterface].
///
/// Wraps the real Media Session API via JS interop.
class BrowserMediaSession implements MediaSessionInterface {
  /// Creates a browser media session wrapper.
  BrowserMediaSession({required web.Navigator navigator}) : _navigator = navigator;

  final web.Navigator _navigator;
  JSObject? _mediaSession;
  final Set<String> _registeredActions = {};

  @override
  bool get isAvailable {
    if (!media_session.hasMediaSession(_navigator)) {
      return false;
    }
    _mediaSession ??= media_session.getMediaSession(_navigator);
    return _mediaSession != null;
  }

  @override
  void setMetadata({required String title, required String artist, required String album, String? artworkUrl}) {
    if (!isAvailable) return;

    try {
      final jsMetadata = media_session.createMediaMetadata(
        title: title,
        artist: artist,
        album: album,
        artwork: artworkUrl,
      );
      media_session.setMediaSessionMetadata(_mediaSession!, jsMetadata);
    } catch (_) {
      // Ignore errors when setting metadata
    }
  }

  @override
  void setActionHandler(String action, void Function() handler) {
    if (!isAvailable) return;

    try {
      media_session.setMediaSessionActionHandler(_mediaSession!, action, handler);
      _registeredActions.add(action);
    } catch (_) {
      // Ignore errors when setting action handlers
    }
  }

  @override
  void clearActionHandlers() {
    if (!isAvailable) return;

    for (final action in _registeredActions) {
      try {
        // Setting handler to null removes it
        _jsSetActionHandler(action, null);
      } catch (_) {
        // Ignore errors
      }
    }
    _registeredActions.clear();
  }

  @override
  void clearMetadata() {
    if (!isAvailable) return;

    try {
      _jsSetMetadataNull();
    } catch (_) {
      // Ignore errors
    }
  }
}

@JS('navigator.mediaSession.setActionHandler')
external void _jsSetActionHandler(String action, JSFunction? handler);

@JS('eval')
external void _jsEval(String code);

void _jsSetMetadataNull() {
  try {
    _jsEval('navigator.mediaSession.metadata = null;');
  } catch (_) {
    // Ignore errors
  }
}
