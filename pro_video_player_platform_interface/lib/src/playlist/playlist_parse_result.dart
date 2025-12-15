import '../types/video_source.dart';
import 'playlist_type.dart';

/// Result of parsing a playlist file.
class PlaylistParseResult {
  /// Creates a playlist parse result.
  const PlaylistParseResult({required this.type, required this.items, this.title, this.metadata = const {}});

  /// The detected type of the playlist.
  final PlaylistType type;

  /// The parsed video sources from the playlist.
  /// Empty for HLS master/media playlists (they should be treated as single sources).
  final List<VideoSource> items;

  /// Optional playlist title.
  final String? title;

  /// Additional metadata extracted from the playlist.
  final Map<String, dynamic> metadata;

  /// Whether this playlist should be treated as a single adaptive video source.
  ///
  /// Returns `true` for HLS (master/media) and DASH playlists, which should
  /// be passed directly to the native player for adaptive bitrate handling.
  bool get isAdaptiveStream =>
      type == PlaylistType.hlsMaster || type == PlaylistType.hlsMedia || type == PlaylistType.dash;

  /// Whether this playlist contains multiple distinct videos.
  bool get isMultiVideo => items.length > 1 && !isAdaptiveStream;
}
