/// VideoProgressColors for video_player API compatibility.
///
/// This class provides the exact video_player API signature for compatibility.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'package:flutter/material.dart';

import '../compat_annotation.dart';

/// Colors for the video progress indicator.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@videoPlayerCompat
class VideoProgressColors {
  /// Creates video progress colors with the specified values.
  ///
  /// [video_player compatibility] This constructor matches video_player exactly.
  const VideoProgressColors({
    this.playedColor = const Color.fromRGBO(255, 0, 0, 0.7),
    this.bufferedColor = const Color.fromRGBO(50, 50, 200, 0.2),
    this.backgroundColor = const Color.fromRGBO(200, 200, 200, 0.5),
  });

  /// The color of the played portion of the progress bar.
  final Color playedColor;

  /// The color of the buffered portion of the progress bar.
  final Color bufferedColor;

  /// The color of the background of the progress bar.
  final Color backgroundColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoProgressColors &&
          runtimeType == other.runtimeType &&
          playedColor == other.playedColor &&
          bufferedColor == other.bufferedColor &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(playedColor, bufferedColor, backgroundColor);
}
