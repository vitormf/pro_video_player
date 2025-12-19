import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/hls_player_interface.dart';
import '../verbose_logging.dart';
import 'streaming_manager.dart';

/// Manages HLS.js integration for adaptive streaming.
///
/// This manager handles the HLS.js player lifecycle and event handling for
/// HLS (HTTP Live Streaming) adaptive bitrate streaming. It provides:
/// - HLS.js player initialization and attachment
/// - Quality level tracking and selection
/// - Audio and subtitle track management
/// - Error handling and recovery
/// - Event emission for quality/track changes
class HlsManager extends StreamingManager<HlsPlayerInterface> {
  /// Creates an HLS manager.
  HlsManager({required super.emitEvent, required super.videoElement});

  @override
  String get logTag => 'HlsManager';

  /// Gets the HLS player instance (for coordination with other managers).
  HlsPlayerInterface? get hlsPlayer => player;

  /// Initializes the HLS player and sets up event handlers.
  ///
  /// [sourceUrl] is the HLS playlist URL (.m3u8).
  /// [hlsPlayer] is the HLS.js player instance to use.
  /// [maxBitrate] is the optional maximum bitrate in bits per second.
  Future<void> initialize({required String sourceUrl, required HlsPlayerInterface hlsPlayer, int? maxBitrate}) async {
    player = hlsPlayer;
    markInitialized();

    // Apply max bitrate if specified
    if (maxBitrate != null && maxBitrate > 0) {
      hlsPlayer.autoLevelCapping = _findLevelForBitrate(maxBitrate, hlsPlayer.levels);
      verboseLog('Set HLS max bitrate: $maxBitrate bps', tag: logTag);
    }

    // Set up event handlers
    setupEventHandlers();

    // Attach to video element and load source
    hlsPlayer.attachMedia(videoElement);
    hlsPlayer.loadSource(sourceUrl);

    verboseLog('HLS.js player initialized: $sourceUrl', tag: logTag);
  }

  /// Finds the level index that matches the given bitrate.
  int _findLevelForBitrate(int maxBitrate, List<HlsLevelInterface> levels) {
    for (var i = levels.length - 1; i >= 0; i--) {
      if (levels[i].bitrate <= maxBitrate) {
        return i;
      }
    }
    return -1; // No cap
  }

  /// Sets up HLS.js event handlers.
  @override
  void setupEventHandlers() {
    final hls = player;
    if (hls == null) return;

    // Manifest parsed - quality levels available
    hls.on('manifestParsed', _onManifestParsed);

    // Level switched - quality changed
    hls.on('levelSwitched', _onLevelSwitched);

    // Audio tracks updated
    hls.on('audioTracksUpdated', _onAudioTracksUpdated);

    // Subtitle tracks updated
    hls.on('subtitleTracksUpdated', _onSubtitleTracksUpdated);

    // Error handling
    hls.on('error', _onError);

    verboseLog('HLS.js event handlers set up', tag: logTag);
  }

  /// Event handler for manifest parsed.
  void _onManifestParsed(String event, Object? data) => _handleManifestParsed();

  /// Event handler for level switched.
  void _onLevelSwitched(String event, Object? data) => _handleLevelSwitched();

  /// Event handler for audio tracks updated.
  void _onAudioTracksUpdated(String event, Object? data) => _handleAudioTracksUpdated();

  /// Event handler for subtitle tracks updated.
  void _onSubtitleTracksUpdated(String event, Object? data) => _handleSubtitleTracksUpdated();

  /// Event handler for errors.
  void _onError(String event, Object? data) => _handleError(data);

  /// Handles manifest parsed event.
  void _handleManifestParsed() {
    verboseLog('HLS manifest parsed', tag: 'HlsManager');
    _updateAvailableQualities();
    emitEvent(const SelectedQualityChangedEvent(VideoQualityTrack.auto));
  }

  /// Handles level switched event.
  void _handleLevelSwitched() {
    final currentLevel = player?.currentLevel ?? -1;
    verboseLog('HLS level switched to $currentLevel', tag: logTag);

    final quality = getCurrentQuality();
    emitEvent(SelectedQualityChangedEvent(quality));
  }

  /// Handles audio tracks updated event.
  void _handleAudioTracksUpdated() {
    verboseLog('HLS audio tracks updated', tag: logTag);

    final tracks = <AudioTrack>[];
    final hlsAudioTracks = player?.audioTracks ?? [];

    for (final t in hlsAudioTracks) {
      tracks.add(AudioTrack(id: t.id.toString(), label: t.name ?? 'Unknown', language: t.lang));
    }

    emitEvent(AudioTracksChangedEvent(tracks));
  }

  /// Handles subtitle tracks updated event.
  void _handleSubtitleTracksUpdated() {
    verboseLog('HLS subtitle tracks updated', tag: logTag);

    final tracks = <SubtitleTrack>[];
    final hlsSubtitleTracks = player?.subtitleTracks ?? [];

    for (final t in hlsSubtitleTracks) {
      tracks.add(SubtitleTrack(id: t.id.toString(), label: t.name ?? 'Unknown', language: t.lang));
    }

    emitEvent(SubtitleTracksChangedEvent(tracks));
  }

  /// Handles HLS error event.
  void _handleError(Object? data) {
    verboseLog('HLS error: $data', tag: logTag);

    // Extract error details if available
    final isFatal = (data as Map?)?['fatal'] as bool? ?? false;
    final errorType = data?['type'] as String? ?? 'unknown';

    if (isFatal) {
      emitEvent(ErrorEvent('HLS.js fatal error: $errorType', code: 'HLS_ERROR'));
    }
  }

  /// Updates available quality tracks from HLS.js levels.
  void _updateAvailableQualities() {
    final levels = player?.levels ?? [];
    final qualities = <VideoQualityTrack>[];

    // Add auto quality option
    qualities.add(VideoQualityTrack.auto);

    // Add each quality level
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      final height = level.height;
      final bitrate = level.bitrate;
      final width = level.width;

      qualities.add(
        VideoQualityTrack(id: i.toString(), label: '${height}p', width: width, height: height, bitrate: bitrate),
      );
    }

    updateAvailableQualities(qualities);
  }

  /// Sets the video quality.
  ///
  /// Returns true if the quality was set successfully.
  @override
  bool setQuality(VideoQualityTrack track) {
    final p = player;
    if (p == null) return false;

    if (track.isAuto) {
      p.currentLevel = -1;
      verboseLog('Set HLS quality to auto', tag: logTag);
      return true;
    }

    final index = int.tryParse(track.id);
    if (index == null) return false;

    final levels = p.levels;
    if (index < 0 || index >= levels.length) {
      return false;
    }

    p.currentLevel = index;
    verboseLog('Set HLS quality to level $index', tag: logTag);
    return true;
  }

  /// Gets the current quality track.
  @override
  VideoQualityTrack getCurrentQuality() {
    final p = player;
    if (p == null) return VideoQualityTrack.auto;

    final currentLevel = p.currentLevel;
    final availableQualities = getAvailableQualities();

    if (currentLevel < 0 || currentLevel >= availableQualities.length - 1) {
      return VideoQualityTrack.auto;
    }

    // currentLevel is 0-indexed, but availableQualities has auto at index 0
    return availableQualities[currentLevel + 1];
  }

  /// Recovers from an error by calling startLoad().
  @override
  Future<void> recover() async {
    final p = player;
    if (p == null) return;

    try {
      p.startLoad();
      verboseLog('HLS recovery: startLoad() called', tag: logTag);
    } catch (e) {
      verboseLog('HLS recovery failed: $e', tag: logTag);
    }
  }

  /// Cleans up the HLS player.
  ///
  /// Destroys the HLS player and removes all event handlers.
  @override
  void cleanupPlayer() {
    player?.destroy();
    verboseLog('HLS.js player destroyed', tag: logTag);
  }
}
