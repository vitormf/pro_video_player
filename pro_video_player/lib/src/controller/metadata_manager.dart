import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Manages video metadata and chapter navigation for the video player.
///
/// This manager handles:
/// - Fetching video metadata (codec, resolution, bitrate, etc.)
/// - Setting media metadata for system controls
/// - Chapter navigation (next, previous, jump to chapter)
class MetadataManager {
  /// Creates a metadata manager with dependency injection via callbacks.
  MetadataManager({
    required this.getValue,
    required this.getPlayerId,
    required this.platform,
    required this.ensureInitialized,
    required this.onSeekTo,
  });

  /// Gets the current video player value.
  final VideoPlayerValue Function() getValue;

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Platform implementation for metadata operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

  /// Callback to seek to a specific position.
  final Future<void> Function(Duration position) onSeekTo;

  /// Fetches video metadata from the platform.
  ///
  /// This calls the platform to get metadata directly, which is useful if
  /// you need metadata before the automatic extraction event is received.
  ///
  /// Returns `null` if metadata is not available or extraction failed.
  Future<VideoMetadata?> fetchVideoMetadata() async {
    ensureInitialized();
    return platform.getVideoMetadata(getPlayerId()!);
  }

  /// Sets media metadata for system controls and notifications.
  ///
  /// This updates the metadata shown in:
  /// - Lock screen controls (iOS/Android)
  /// - System media controls (macOS/Windows)
  /// - Background playback notifications (Android)
  /// - Casting receiver displays (Chromecast, AirPlay)
  ///
  /// The metadata is optional and purely presentational - it doesn't affect
  /// playback behavior.
  Future<void> setMediaMetadata(MediaMetadata metadata) async {
    ensureInitialized();
    await platform.setMediaMetadata(getPlayerId()!, metadata);
  }

  /// Seeks to the start of the specified chapter.
  ///
  /// This is a convenience method equivalent to calling `seekTo(chapter.startTime)`.
  Future<void> seekToChapter(Chapter chapter) async {
    ensureInitialized();
    await onSeekTo(chapter.startTime);
  }

  /// Seeks to the next chapter, if available.
  ///
  /// If already in the last chapter or no chapters are available, does nothing.
  /// Returns `true` if a seek was performed, `false` otherwise.
  Future<bool> seekToNextChapter() async {
    final value = getValue();
    if (!value.hasChapters) return false;

    final current = value.currentChapter;
    if (current == null) {
      // No current chapter, seek to first
      await seekToChapter(value.chapters.first);
      return true;
    }

    final currentIndex = value.chapters.indexOf(current);
    if (currentIndex < 0 || currentIndex >= value.chapters.length - 1) {
      return false; // Already at last chapter
    }

    await seekToChapter(value.chapters[currentIndex + 1]);
    return true;
  }

  /// Seeks to the previous chapter, if available.
  ///
  /// If at the beginning of a chapter (within first 3 seconds), seeks to the
  /// previous chapter. Otherwise, seeks to the start of the current chapter.
  /// Returns `true` if a seek was performed, `false` otherwise.
  Future<bool> seekToPreviousChapter() async {
    final value = getValue();
    if (!value.hasChapters) return false;

    final current = value.currentChapter;
    if (current == null) return false;

    final currentIndex = value.chapters.indexOf(current);
    if (currentIndex < 0) return false;

    // If we're more than 3 seconds into the chapter, restart it
    final elapsedInChapter = value.position - current.startTime;
    if (elapsedInChapter > const Duration(seconds: 3)) {
      await seekToChapter(current);
      return true;
    }

    // Otherwise go to previous chapter (if exists)
    if (currentIndex > 0) {
      await seekToChapter(value.chapters[currentIndex - 1]);
      return true;
    }

    // At first chapter, just restart it
    await seekToChapter(current);
    return true;
  }
}
