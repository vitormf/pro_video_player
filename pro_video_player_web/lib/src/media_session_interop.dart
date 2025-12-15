import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Media Session API JS interop.
///
/// The web package doesn't expose MediaSession yet, so we use raw JS interop.
/// This provides integration with browser media controls (macOS Control Center,
/// Windows/Chrome media overlay, mobile browser notifications).

@JS('navigator.mediaSession')
external JSObject? get _jsMediaSession;

/// Checks if Media Session API is available on the navigator.
bool hasMediaSession(web.Navigator navigator) => _jsMediaSession != null;

/// Gets the media session from the navigator.
JSObject? getMediaSession(web.Navigator navigator) => _jsMediaSession;

/// Creates a MediaMetadata object for the Media Session API.
JSObject createMediaMetadata({required String title, required String artist, required String album, String? artwork}) =>
    artwork != null && artwork.isNotEmpty
    ? _createMediaMetadataWithArtwork(title, artist, album, artwork)
    : _createMediaMetadata(title, artist, album);

@JS('eval')
external JSObject _jsEval(String code);

/// Creates MediaMetadata without artwork.
JSObject _createMediaMetadata(String title, String artist, String album) {
  final code =
      '''
    (function() {
      return new MediaMetadata({
        title: "$title",
        artist: "$artist",
        album: "$album"
      });
    })()
  ''';
  return _jsEval(code);
}

/// Creates MediaMetadata with artwork.
JSObject _createMediaMetadataWithArtwork(String title, String artist, String album, String artworkUrl) {
  // Escape special characters in the artwork URL
  final escapedUrl = artworkUrl.replaceAll('"', r'\"').replaceAll("'", r"\'");
  final code =
      '''
    (function() {
      return new MediaMetadata({
        title: "$title",
        artist: "$artist",
        album: "$album",
        artwork: [
          { src: "$escapedUrl", sizes: "512x512", type: "image/png" }
        ]
      });
    })()
  ''';
  return _jsEval(code);
}

/// Sets metadata on the media session.
void setMediaSessionMetadata(JSObject mediaSession, JSObject metadata) {
  _jsEval('navigator.mediaSession.metadata = arguments[0];');
  // Re-assign using property set
  _setMediaSessionMetadataInternal(metadata);
}

void _setMediaSessionMetadataInternal(JSObject metadata) {
  // Use a more direct approach
  final code = 'navigator.mediaSession.metadata = $metadata';
  try {
    _jsEval(code);
  } catch (_) {
    // If eval fails, try inline assignment
  }
}

/// Sets an action handler on the media session.
void setMediaSessionActionHandler(JSObject mediaSession, String action, void Function() handler) {
  try {
    _jsSetActionHandler(action, handler.toJS);
  } catch (_) {
    // Ignore errors when setting action handlers
  }
}

@JS('navigator.mediaSession.setActionHandler')
external void _jsSetActionHandler(String action, JSFunction handler);
