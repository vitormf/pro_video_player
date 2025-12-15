import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

// Alias for cleaner code
typedef _Logger = ProVideoPlayerLogger;

/// Manages external subtitle loading and discovery for the video player.
///
/// This manager handles:
/// - Adding external subtitle files (network, local, asset)
/// - Removing external subtitles
/// - Discovering subtitle files alongside video files
/// - Getting all loaded external subtitles
class SubtitleManager {
  /// Creates a subtitle manager with dependency injection via callbacks.
  SubtitleManager({
    required this.getPlayerId,
    required this.getOptions,
    required this.platform,
    required this.ensureInitialized,
  });

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Gets the video player options.
  final VideoPlayerOptions Function() getOptions;

  /// Platform implementation for subtitle operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

  /// Adds an external subtitle track from the specified [source].
  ///
  /// The subtitle can be loaded from:
  /// - Network URL (HTTP/HTTPS)
  /// - Local file path
  /// - Flutter asset
  ///
  /// Returns the added [ExternalSubtitleTrack] if successful, or `null` if:
  /// - Subtitles are disabled via [VideoPlayerOptions.subtitlesEnabled]
  /// - The subtitle file couldn't be loaded
  /// - The format is not supported
  ///
  /// Example:
  /// ```dart
  /// // From network
  /// final track = await controller.addExternalSubtitle(
  ///   SubtitleSource.network(
  ///     'https://example.com/subtitles/english.vtt',
  ///     label: 'English',
  ///     language: 'en',
  ///   ),
  /// );
  ///
  /// // From local file
  /// final track = await controller.addExternalSubtitle(
  ///   SubtitleSource.file('/path/to/subtitles.srt', label: 'Spanish'),
  /// );
  ///
  /// // Auto-detect source type
  /// final track = await controller.addExternalSubtitle(
  ///   SubtitleSource.from('https://example.com/subs.vtt'),
  /// );
  ///
  /// if (track != null) {
  ///   await controller.setSubtitleTrack(track);
  /// }
  /// ```
  Future<ExternalSubtitleTrack?> addExternalSubtitle(SubtitleSource source) async {
    ensureInitialized();

    // Gracefully handle disabled subtitles
    if (!getOptions().subtitlesEnabled) {
      return null;
    }

    return platform.addExternalSubtitle(getPlayerId()!, source);
  }

  /// Removes an external subtitle track.
  ///
  /// The [trackId] should be the ID of a track previously added via
  /// [addExternalSubtitle]. If this track is currently selected, subtitles
  /// will be disabled.
  ///
  /// Returns `true` if the track was removed successfully, `false` if the
  /// track was not found.
  Future<bool> removeExternalSubtitle(String trackId) async {
    ensureInitialized();
    return platform.removeExternalSubtitle(getPlayerId()!, trackId);
  }

  /// Gets all external subtitle tracks that have been added.
  ///
  /// Returns a list of [ExternalSubtitleTrack] objects representing all
  /// external subtitles that have been loaded via [addExternalSubtitle].
  /// This does not include embedded subtitle tracks from the video file.
  Future<List<ExternalSubtitleTrack>> getExternalSubtitles() async {
    ensureInitialized();
    return platform.getExternalSubtitles(getPlayerId()!);
  }

  /// Discovers and adds subtitle files matching the video file.
  ///
  /// This is called automatically during initialization when
  /// [VideoPlayerOptions.autoDiscoverSubtitles] is enabled.
  Future<void> discoverAndAddSubtitles(String videoPath, SubtitleDiscoveryMode mode) async {
    _Logger.log('Discovering subtitles for: $videoPath (mode: ${mode.name})', tag: 'Controller');

    try {
      final discovered = await SubtitleDiscovery.discoverSubtitles(videoPath, mode: mode);

      if (discovered.isEmpty) {
        _Logger.log('No subtitles discovered', tag: 'Controller');
        return;
      }

      _Logger.log('Discovered ${discovered.length} subtitle(s)', tag: 'Controller');

      for (final source in discovered) {
        final track = await addExternalSubtitle(source);
        if (track != null) {
          _Logger.log('Added discovered subtitle: ${track.label} (${track.language ?? "unknown"})', tag: 'Controller');
        }
      }
    } catch (e) {
      _Logger.error('Failed to discover subtitles', tag: 'Controller', error: e);
      // Don't rethrow - subtitle discovery failure shouldn't prevent playback
    }
  }
}
