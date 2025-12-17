import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

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
///
/// The manager uses dynamic typing for the HLS player to support both
/// production (real HLS.js) and test (mock) implementations.
class HlsManager extends StreamingManager {
  /// Creates an HLS manager.
  HlsManager({required super.emitEvent, required super.videoElement});

  @override
  String get logTag => 'HlsManager';

  /// Gets the HLS player instance (for coordination with other managers).
  dynamic get hlsPlayer => player;

  /// Initializes the HLS player and sets up event handlers.
  ///
  /// [sourceUrl] is the HLS playlist URL (.m3u8).
  /// [hlsPlayer] is the HLS.js player instance to use.
  /// [maxBitrate] is the optional maximum bitrate in bits per second.
  Future<void> initialize({required String sourceUrl, required dynamic hlsPlayer, int? maxBitrate}) async {
    player = hlsPlayer;
    markInitialized();

    // Apply max bitrate if specified
    if (maxBitrate != null && maxBitrate > 0) {
      hlsPlayer.maxBitrate = maxBitrate;
      verboseLog('Set HLS max bitrate: $maxBitrate bps', tag: logTag);
    }

    // Set up event handlers
    setupEventHandlers();

    // Attach to video element and load source
    hlsPlayer.attachMedia(videoElement);
    hlsPlayer.loadSource(sourceUrl);

    verboseLog('HLS.js player initialized: $sourceUrl', tag: logTag);
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
  void _onManifestParsed(dynamic event, [dynamic data]) => _handleManifestParsed();

  /// Event handler for level switched.
  void _onLevelSwitched(dynamic event, [dynamic data]) => _handleLevelSwitched();

  /// Event handler for audio tracks updated.
  void _onAudioTracksUpdated(dynamic event, [dynamic data]) => _handleAudioTracksUpdated();

  /// Event handler for subtitle tracks updated.
  void _onSubtitleTracksUpdated(dynamic event, [dynamic data]) => _handleSubtitleTracksUpdated();

  /// Event handler for errors.
  void _onError(dynamic event, [dynamic data]) => _handleError(data);

  /// Handles manifest parsed event.
  void _handleManifestParsed() {
    verboseLog('HLS manifest parsed', tag: 'HlsManager');
    _updateAvailableQualities();
    emitEvent(const SelectedQualityChangedEvent(VideoQualityTrack.auto));
  }

  /// Handles level switched event.
  void _handleLevelSwitched() {
    final currentLevel = player?.currentLevel as int? ?? -1;
    verboseLog('HLS level switched to $currentLevel', tag: logTag);

    final quality = getCurrentQuality();
    emitEvent(SelectedQualityChangedEvent(quality));
  }

  /// Handles audio tracks updated event.
  void _handleAudioTracksUpdated() {
    verboseLog('HLS audio tracks updated', tag: logTag);

    final tracks = <AudioTrack>[];
    final hlsAudioTracks = player?.audioTracks as List? ?? [];

    for (final t in hlsAudioTracks) {
      tracks.add(AudioTrack(id: t.id.toString(), label: t.name as String? ?? 'Unknown', language: t.lang as String?));
    }

    emitEvent(AudioTracksChangedEvent(tracks));
  }

  /// Handles subtitle tracks updated event.
  void _handleSubtitleTracksUpdated() {
    verboseLog('HLS subtitle tracks updated', tag: logTag);

    final tracks = <SubtitleTrack>[];
    final hlsSubtitleTracks = player?.subtitleTracks as List? ?? [];

    for (final t in hlsSubtitleTracks) {
      tracks.add(
        SubtitleTrack(id: t.id.toString(), label: t.name as String? ?? 'Unknown', language: t.lang as String?),
      );
    }

    emitEvent(SubtitleTracksChangedEvent(tracks));
  }

  /// Handles HLS error event.
  void _handleError(dynamic data) {
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
    final levels = player?.levels as List? ?? [];
    final qualities = <VideoQualityTrack>[];

    // Add auto quality option
    qualities.add(VideoQualityTrack.auto);

    // Add each quality level
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      final height = (level.height as int?) ?? 0;
      final bitrate = (level.bitrate as int?) ?? 0;
      final width = (level.width as int?) ?? 0;

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
    if (player == null) return false;

    if (track.isAuto) {
      player.currentLevel = -1;
      verboseLog('Set HLS quality to auto', tag: logTag);
      return true;
    }

    final index = int.tryParse(track.id);
    if (index == null) return false;

    final levels = player.levels as List? ?? [];
    if (index < 0 || index >= levels.length) {
      return false;
    }

    player.currentLevel = index;
    verboseLog('Set HLS quality to level $index', tag: logTag);
    return true;
  }

  /// Gets the current quality track.
  @override
  VideoQualityTrack getCurrentQuality() {
    if (player == null) return VideoQualityTrack.auto;

    final currentLevel = player.currentLevel as int? ?? -1;
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
    if (player == null) return;

    try {
      player.startLoad();
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
