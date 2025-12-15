import '../../pro_video_player_platform_interface.dart' show VideoPlayerOptions;
import 'types.dart' show VideoPlayerOptions;
import 'video_player_options.dart' show VideoPlayerOptions;

/// Mode for auto-discovering subtitle files when playing local video files.
///
/// When [VideoPlayerOptions.autoDiscoverSubtitles] is enabled and a video
/// is loaded from a local file, the player will search for matching subtitle
/// files in the same directory and common subdirectories.
enum SubtitleDiscoveryMode {
  /// Strict matching - subtitle must have exact same base name as video.
  ///
  /// Example:
  /// - Video: `my_movie.mp4`
  /// - Matches: `my_movie.srt`, `my_movie.en.srt`
  /// - No match: `my-movie.srt`, `mymovie.srt`
  strict,

  /// Prefix matching - subtitle base name must start with video's base name.
  ///
  /// This is the recommended mode as it handles common naming variations
  /// while avoiding false positives.
  ///
  /// Example:
  /// - Video: `my_movie.mp4`
  /// - Matches: `my_movie.srt`, `my_movie.en.srt`, `my_movie.2024.srt`
  /// - No match: `movie.srt`, `my-movie.srt`
  prefix,

  /// Fuzzy matching - first 2-3 tokens of the filename must match.
  ///
  /// Tokens are split by common separators (`.`, `-`, `_`, ` `).
  /// This handles cases where video files have extra metadata like
  /// resolution, codec, or release info that subtitles don't include.
  ///
  /// Example:
  /// - Video: `My.Movie.2024.1080p.BluRay.mp4`
  /// - Matches: `My.Movie.srt`, `My.Movie.2024.srt`
  /// - No match: `Movie.srt`, `Another.Movie.srt`
  fuzzy,
}
