import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

/// Mixin providing video_player compatibility properties and methods.
mixin CompatibilityMixin on ProVideoPlayerControllerBase {
  /// The data source URL or path.
  ///
  /// This property is provided for compatibility with Flutter's video_player
  /// library. Returns the string representation of the current source.
  ///
  /// For more detailed source information, use the `source` property instead.
  String? get dataSource {
    final src = sourceInternal;
    if (src == null) return null;
    if (src is NetworkVideoSource) return src.url;
    if (src is FileVideoSource) return src.path;
    if (src is AssetVideoSource) return src.assetPath;
    if (src is PlaylistVideoSource) return src.url;
    return null;
  }

  /// The type of data source.
  ///
  /// This property is provided for compatibility with Flutter's video_player
  /// library. Returns the type based on the current source.
  DataSourceType? get dataSourceType {
    final src = sourceInternal;
    if (src == null) return null;
    if (src is NetworkVideoSource) return DataSourceType.network;
    if (src is FileVideoSource) {
      if (src.path.startsWith('content://')) return DataSourceType.contentUri;
      return DataSourceType.file;
    }
    if (src is AssetVideoSource) return DataSourceType.asset;
    if (src is PlaylistVideoSource) return DataSourceType.network;
    return null;
  }

  /// HTTP headers for network requests.
  ///
  /// This property is provided for compatibility with Flutter's video_player
  /// library. Returns headers if the current source is a network source.
  Map<String, String>? get httpHeaders {
    final src = sourceInternal;
    if (src is NetworkVideoSource) return src.headers;
    return null;
  }

  /// The current playback position.
  ///
  /// This property is provided for compatibility with Flutter's video_player
  /// library, which returns position as a Future. However, the position is
  /// also available synchronously via `value.position`.
  ///
  /// For UI code, prefer using `value.position` directly for synchronous
  /// access. This getter is provided for code migrating from video_player.
  Future<Duration> get position async {
    ensureInitializedInternal();
    return value.position;
  }

  /// Sets closed captions for the video.
  ///
  /// This method is provided for compatibility with Flutter's video_player library.
  /// Pass `null` to disable captions, or a [Future<ClosedCaptionFile>] to enable them.
  ///
  /// **Note**: This is a compatibility stub. For production use, prefer using
  /// `addExternalSubtitle` with a proper [SubtitleSource] which provides more
  /// features and format support.
  Future<void> setClosedCaptionFile(Future<ClosedCaptionFile>? closedCaptionFile) async {
    ensureInitializedInternal();

    if (closedCaptionFile == null) {
      await services.trackManager.setSubtitleTrack(null);
      return;
    }

    // Wait for captions to load (for API compatibility)
    await closedCaptionFile;

    // TODO(pro_video_player): Implement full caption loading.
    // This would require either:
    // 1. Adding SubtitleSource.memory() constructor for in-memory content
    // 2. Writing captions to a temporary file and using SubtitleSource.file()
    // 3. Adding a new platform method for loading caption data directly
  }

  /// Sets the caption offset.
  ///
  /// This adjusts the timing of captions by the given [offset].
  /// Positive values delay captions, negative values advance them.
  ///
  /// This method is provided for compatibility with Flutter's video_player library.
  Future<void> setCaptionOffset(Duration offset) async {
    ensureInitializedInternal();
    await platform.setSubtitleOffset(playerId!, offset);
  }
}
