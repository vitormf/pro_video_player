/// Annotation to mark classes and methods that exist solely for
/// compatibility with Flutter's video_player library.
///
/// ## Purpose
///
/// This annotation clearly identifies code that exists to provide API
/// compatibility with Flutter's official `video_player` package. It helps
/// developers understand:
///
/// - **What**: Which classes/methods are compatibility shims
/// - **Why**: To enable drop-in replacement of video_player
/// - **When**: To use this vs. native pro_video_player API
///
/// ## Usage
///
/// Apply to classes that mirror video_player types:
/// ```dart
/// @videoPlayerCompat
/// class VideoPlayerController { ... }
/// ```
///
/// Apply to methods that match video_player signatures:
/// ```dart
/// @videoPlayerCompat
/// double startFraction(Duration duration) { ... }
/// ```
///
/// ## Behavior
///
/// Classes and methods marked with this annotation:
/// - Match the exact API signature from video_player
/// - Are wrappers/delegates to pro_video_player functionality
/// - Should be used when drop-in replacement is needed
/// - May have reduced functionality compared to native pro_video_player API
///
/// ## When to Use
///
/// **Use compatibility layer** (`video_player_compat.dart`) when:
/// - Migrating from video_player with minimal code changes
/// - Need exact video_player API compatibility
/// - Working with code that depends on video_player types
///
/// **Use native pro_video_player API** when:
/// - Starting a new project
/// - Want access to advanced features (PiP, casting, chapters, etc.)
/// - Don't need backward compatibility with video_player
///
/// ## Import
///
/// ```dart
/// // For video_player compatibility (drop-in replacement)
/// import 'package:pro_video_player/video_player_compat.dart';
///
/// // For native pro_video_player API (recommended for new projects)
/// import 'package:pro_video_player/pro_video_player.dart';
/// ```
class VideoPlayerCompat {
  /// Creates a video_player compatibility annotation.
  ///
  /// The [since] parameter indicates when this compatibility was added.
  /// The [notes] parameter can provide additional context about the
  /// compatibility, such as known limitations or differences.
  const VideoPlayerCompat({this.since, this.notes});

  /// The version when this compatibility feature was added.
  ///
  /// Example: `'1.0.0'`
  final String? since;

  /// Additional notes about this compatibility feature.
  ///
  /// Use this to document any differences from the original video_player
  /// API or known limitations.
  final String? notes;
}

/// Shorthand constant for marking video_player compatibility.
///
/// Use this annotation on classes, methods, and properties that exist
/// to provide API compatibility with Flutter's video_player library.
///
/// Example:
/// ```dart
/// @videoPlayerCompat
/// class VideoPlayerValue { ... }
///
/// @videoPlayerCompat
/// double startFraction(Duration duration) => ...;
/// ```
const videoPlayerCompat = VideoPlayerCompat();
