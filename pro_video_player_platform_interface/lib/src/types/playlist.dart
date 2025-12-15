import 'video_source.dart';

/// A collection of video sources for sequential playback.
///
/// Use a playlist to play multiple videos in sequence with support for:
/// - Navigation (next, previous, jump to index)
/// - Repeat modes (none, all, one)
/// - Shuffle mode
///
/// ## Example
///
/// ```dart
/// // Create a playlist
/// final playlist = Playlist(
///   items: [
///     VideoSource.network('https://example.com/video1.mp4'),
///     VideoSource.network('https://example.com/video2.mp4'),
///     VideoSource.network('https://example.com/video3.mp4'),
///   ],
///   initialIndex: 0, // Start from the first video
/// );
///
/// // Initialize the player with the playlist
/// await controller.initializeWithPlaylist(
///   playlist: playlist,
///   options: const VideoPlayerOptions(autoPlay: true),
/// );
///
/// // Navigate the playlist
/// await controller.playlistNext();     // Go to next video
/// await controller.playlistPrevious(); // Go to previous video
/// await controller.playlistJumpTo(2);  // Jump to specific index
///
/// // Control repeat and shuffle
/// controller.setPlaylistRepeatMode(PlaylistRepeatMode.all);
/// controller.setPlaylistShuffle(enabled: true);
/// ```
///
/// ## Loading from Playlist Files
///
/// To load a playlist from a file (M3U, M3U8, PLS), use [VideoSource.playlist]:
///
/// ```dart
/// await controller.initialize(
///   source: VideoSource.playlist('https://example.com/playlist.m3u'),
/// );
/// ```
class Playlist {
  /// Creates a playlist with the given video sources.
  ///
  /// The [items] list must contain at least one video source.
  /// The [initialIndex] specifies which video to start playing (defaults to 0).
  const Playlist({required this.items, this.initialIndex = 0})
    : assert(items.length > 0, 'Playlist must contain at least one item');

  /// The list of video sources in the playlist.
  final List<VideoSource> items;

  /// The initial index to start playback from.
  ///
  /// Defaults to 0 (first item). Must be a valid index within [items].
  final int initialIndex;

  /// Returns the number of items in the playlist.
  int get length => items.length;

  /// Returns the video source at the specified [index].
  ///
  /// Throws [RangeError] if [index] is out of bounds.
  VideoSource operator [](int index) => items[index];

  /// Creates a copy of this playlist with the given fields replaced.
  ///
  /// Use this to modify a playlist without mutating the original:
  /// ```dart
  /// final newPlaylist = playlist.copyWith(initialIndex: 2);
  /// ```
  Playlist copyWith({List<VideoSource>? items, int? initialIndex}) =>
      Playlist(items: items ?? this.items, initialIndex: initialIndex ?? this.initialIndex);
}
