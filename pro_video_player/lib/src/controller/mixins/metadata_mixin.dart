import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

/// Mixin providing metadata and chapter functionality.
mixin MetadataMixin on ProVideoPlayerControllerBase {
  /// Returns video metadata (codec, resolution, bitrate, etc.).
  ///
  /// This returns the cached metadata from [VideoPlayerValue.videoMetadata]
  /// if available. To fetch fresh metadata from the platform, use
  /// [fetchVideoMetadata].
  ///
  /// Returns `null` if metadata is not available yet (player not ready or
  /// metadata not extracted).
  VideoMetadata? get videoMetadata => value.videoMetadata;

  /// Fetches video metadata from the platform.
  ///
  /// This calls the platform to get metadata directly, which is useful if
  /// you need metadata before the automatic extraction event is received.
  ///
  /// Returns `null` if the player is not ready or metadata cannot be extracted.
  Future<VideoMetadata?> fetchVideoMetadata() async {
    final metadata = await services.metadataManager.fetchVideoMetadata();
    if (metadata != null) {
      value = value.copyWith(videoMetadata: metadata);
    }
    return metadata;
  }

  /// Sets the media metadata for platform media controls.
  ///
  /// This metadata is displayed in:
  /// - iOS/macOS: Control Center and Lock Screen (via MPNowPlayingInfoCenter)
  /// - Android: Media notification and Lock Screen (via MediaSession)
  /// - Web: Browser media controls (via Media Session API)
  ///
  /// The metadata is only shown when background playback is enabled.
  ///
  /// Pass [MediaMetadata.empty] to clear any previously set metadata.
  Future<void> setMediaMetadata(MediaMetadata metadata) async {
    ensureInitializedInternal();
    await services.metadataManager.setMediaMetadata(metadata);
  }

  /// Available chapters in the video.
  ///
  /// Returns an empty list if no chapters are available.
  /// Chapters are sorted by [Chapter.startTime] in ascending order.
  List<Chapter> get chapters => value.chapters;

  /// The chapter at the current playback position.
  ///
  /// Returns `null` if no chapters are available or if the current position
  /// is before the first chapter.
  Chapter? get currentChapter => value.currentChapter;

  /// Whether the video has chapter information available.
  bool get hasChapters => value.hasChapters;

  /// Seeks to the start of the specified chapter.
  ///
  /// This is a convenience method equivalent to calling
  /// `seekTo(chapter.startTime)`.
  Future<void> seekToChapter(Chapter chapter) async {
    ensureInitializedInternal();
    await services.metadataManager.seekToChapter(chapter);
  }

  /// Seeks to the next chapter, if available.
  ///
  /// If already in the last chapter or no chapters are available, does nothing.
  /// Returns `true` if a seek was performed, `false` otherwise.
  Future<bool> seekToNextChapter() async {
    ensureInitializedInternal();
    return services.metadataManager.seekToNextChapter();
  }

  /// Seeks to the previous chapter, if available.
  ///
  /// If at the beginning of a chapter (within first 3 seconds), seeks to the
  /// previous chapter. Otherwise, seeks to the start of the current chapter.
  /// Returns `true` if a seek was performed, `false` otherwise.
  Future<bool> seekToPreviousChapter() async {
    ensureInitializedInternal();
    return services.metadataManager.seekToPreviousChapter();
  }

  /// Gets the current battery information.
  ///
  /// Returns battery level (0-100) and charging state, or `null` if battery
  /// information is not available on this platform/device.
  Future<BatteryInfo?> getBatteryInfo() => platform.getBatteryInfo();

  /// Stream of battery state changes.
  ///
  /// Emits [BatteryInfo] whenever the battery level or charging state changes.
  Stream<BatteryInfo> get batteryUpdates => platform.batteryUpdates;
}
