/// VideoPlayerOptions for video_player API compatibility.
///
/// This class provides the exact video_player API signature for compatibility.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'package:flutter/foundation.dart';

import 'compat_annotation.dart';
import 'video_player_web_options.dart';

/// Configuration options for the video player.
///
/// This class provides the exact video_player API signature for compatibility.
/// It wraps pro_video_player's more extensive VideoPlayerOptions internally.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@immutable
@videoPlayerCompat
class VideoPlayerOptions {
  /// Creates video player options with the exact video_player signature.
  const VideoPlayerOptions({this.mixWithOthers = false, this.allowBackgroundPlayback = false, this.webOptions});

  /// Set this to true to mix the video player's audio with other audio sources.
  ///
  /// When set to false (the default), the video player will pause other audio
  /// sources when starting playback.
  final bool mixWithOthers;

  /// Set this to true to keep playing video in background when app goes in
  /// background.
  ///
  /// Defaults to false.
  final bool allowBackgroundPlayback;

  /// Additional web controls.
  final VideoPlayerWebOptions? webOptions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoPlayerOptions &&
          runtimeType == other.runtimeType &&
          mixWithOthers == other.mixWithOthers &&
          allowBackgroundPlayback == other.allowBackgroundPlayback &&
          webOptions == other.webOptions;

  @override
  int get hashCode => Object.hash(mixWithOthers, allowBackgroundPlayback, webOptions);
}
