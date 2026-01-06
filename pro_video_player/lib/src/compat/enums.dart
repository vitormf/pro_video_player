/// Enums for video_player API compatibility.
///
/// These enums match the exact signatures from Flutter's video_player library.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'compat_annotation.dart';

/// The way in which the video was originally loaded.
///
/// This has nothing to do with the video's file type. It's just the place
/// from which the video is fetched from.
///
/// [video_player compatibility] This enum matches the video_player API exactly.
@videoPlayerCompat
enum DataSourceType {
  /// The video was included in the app's asset files.
  asset,

  /// The video was downloaded from the internet.
  network,

  /// The video was loaded off of the local filesystem.
  file,

  /// The video is available via contentUri. Android only.
  contentUri,
}

/// The file format of the given video.
///
/// [video_player compatibility] This enum matches the video_player API exactly.
@videoPlayerCompat
enum VideoFormat {
  /// Dynamic Adaptive Streaming over HTTP, also known as MPEG-DASH.
  dash,

  /// HTTP Live Streaming.
  hls,

  /// Smooth Streaming.
  ss,

  /// Any format other than the other ones defined in this enum.
  other,
}

/// The rendering method for displaying video content.
///
/// [video_player compatibility] This enum matches the video_player API exactly.
@videoPlayerCompat
enum VideoViewType {
  /// Texture will be used to render video.
  textureView,

  /// Platform view will be used to render video.
  platformView,
}
