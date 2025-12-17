import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'abstractions/video_element_interface.dart';

/// Callback function for emitting video player events.
typedef EventEmitter = void Function(VideoPlayerEvent event);

/// Mixin that provides standard callbacks for web video player managers.
///
/// All manager classes share these common dependencies for accessing and
/// interacting with the HTML video element and emitting events to Flutter.
///
/// Unlike the main package's ManagerCallbacks which uses platform method calls,
/// WebManagerCallbacks provides direct access to the video element interface
/// since WebVideoPlayer IS the platform implementation.
mixin WebManagerCallbacks {
  /// Emits a video player event to the Flutter event stream.
  EventEmitter get emitEvent;

  /// Gets the video element interface for direct manipulation.
  ///
  /// Managers can read/write video element properties (currentTime, volume,
  /// playbackRate, etc.) and call methods (play, pause, load, etc.) through
  /// this interface.
  ///
  /// In production, this will wrap web.HTMLVideoElement. In tests, it will be
  /// a mock implementation.
  VideoElementInterface get videoElement;
}
