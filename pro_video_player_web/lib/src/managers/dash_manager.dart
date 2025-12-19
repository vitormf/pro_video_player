import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/dash_player_interface.dart';
import '../verbose_logging.dart';
import 'streaming_manager.dart';

/// Manages DASH.js integration for adaptive streaming.
///
/// This manager handles the DASH.js player lifecycle and event handling for
/// DASH (Dynamic Adaptive Streaming over HTTP) adaptive bitrate streaming. It provides:
/// - DASH.js player initialization and attachment
/// - Quality level tracking and selection
/// - Audio and text track management
/// - Error handling and recovery
/// - Event emission for quality/track changes
/// - Throughput/bandwidth tracking
class DashManager extends StreamingManager<DashPlayerInterface> {
  /// Creates a DASH manager.
  DashManager({required super.emitEvent, required super.videoElement});

  @override
  String get logTag => 'DashManager';

  /// Current source URL.
  String? _sourceUrl;

  /// Gets the DASH player instance (for coordination with other managers).
  DashPlayerInterface? get dashPlayer => player;

  /// Initializes the DASH player and sets up event handlers.
  ///
  /// [sourceUrl] is the DASH manifest URL (.mpd).
  /// [dashPlayer] is the DASH.js player instance to use.
  /// [autoPlay] whether to auto-play after initialization.
  /// [abrMode] the adaptive bitrate mode (auto or manual).
  /// [minBitrate] the minimum bitrate in bits per second.
  /// [maxBitrate] the maximum bitrate in bits per second.
  Future<void> initialize({
    required String sourceUrl,
    required DashPlayerInterface dashPlayer,
    bool autoPlay = false,
    AbrMode abrMode = AbrMode.auto,
    int? minBitrate,
    int? maxBitrate,
  }) async {
    player = dashPlayer;
    _sourceUrl = sourceUrl;
    markInitialized();

    // Apply bitrate limits via settings
    if (minBitrate != null || maxBitrate != null) {
      final abrSettings = <String, Object>{};
      if (minBitrate != null && minBitrate > 0) {
        abrSettings['minBitrate'] = {'video': minBitrate};
        verboseLog('Set DASH min bitrate: $minBitrate bps', tag: logTag);
      }
      if (maxBitrate != null && maxBitrate > 0) {
        abrSettings['maxBitrate'] = {'video': maxBitrate};
        verboseLog('Set DASH max bitrate: $maxBitrate bps', tag: logTag);
      }
      dashPlayer.updateSettings({
        'streaming': {'abr': abrSettings},
      });
    }

    // Configure ABR mode
    if (abrMode == AbrMode.manual) {
      dashPlayer.setAutoSwitchQualityFor('video', enabled: false);
      verboseLog('Set DASH to manual quality mode', tag: logTag);
    } else {
      dashPlayer.setAutoSwitchQualityFor('video', enabled: true);
      verboseLog('Set DASH to auto quality mode', tag: logTag);
    }

    // Set up event handlers
    setupEventHandlers();

    // Initialize DASH player with video element and source
    dashPlayer.initialize(view: videoElement, url: sourceUrl, autoPlay: autoPlay);

    verboseLog('DASH.js player initialized: $sourceUrl', tag: logTag);
  }

  /// Sets up DASH.js event handlers.
  @override
  void setupEventHandlers() {
    final dash = player;
    if (dash == null) return;

    // Stream initialized - quality levels available
    dash.on('streamInitialized', _onStreamInitialized);

    // Quality change rendered - quality changed
    dash.on('qualityChangeRendered', _onQualityChangeRendered);

    // Text tracks added
    dash.on('textTracksAdded', _onTextTracksAdded);

    // Audio tracks added
    dash.on('audioTracksAdded', _onAudioTracksAdded);

    // Error handling
    dash.on('error', _onError);

    verboseLog('DASH.js event handlers set up', tag: logTag);
  }

  /// Event handler for stream initialized.
  void _onStreamInitialized(Object? event) => _handleStreamInitialized();

  /// Event handler for quality change rendered.
  void _onQualityChangeRendered(Object? event) => _handleQualityChangeRendered();

  /// Event handler for text tracks added.
  void _onTextTracksAdded(Object? event) => _handleTextTracksAdded();

  /// Event handler for audio tracks added.
  void _onAudioTracksAdded(Object? event) => _handleAudioTracksAdded();

  /// Event handler for errors.
  void _onError(Object? event) => _handleError(event);

  /// Handles stream initialized event.
  void _handleStreamInitialized() {
    verboseLog('DASH stream initialized', tag: 'DashManager');
    _updateAvailableQualities();
  }

  /// Handles quality change rendered event.
  void _handleQualityChangeRendered() {
    verboseLog('DASH quality change rendered', tag: 'DashManager');

    final quality = getCurrentQuality();
    emitEvent(SelectedQualityChangedEvent(quality, isAutoSwitch: true));
  }

  /// Handles text tracks added event.
  void _handleTextTracksAdded() {
    verboseLog('DASH text tracks added', tag: logTag);

    final tracks = <SubtitleTrack>[];
    final dashTracks = player?.getTextTracks() ?? [];

    for (final t in dashTracks) {
      tracks.add(SubtitleTrack(id: t.index.toString(), label: t.label, language: t.lang));
    }

    emitEvent(SubtitleTracksChangedEvent(tracks));
  }

  /// Handles audio tracks added event.
  void _handleAudioTracksAdded() {
    verboseLog('DASH audio tracks added', tag: logTag);

    final tracks = <AudioTrack>[];
    final dashTracks = player?.getAudioTracks() ?? [];

    for (final t in dashTracks) {
      tracks.add(AudioTrack(id: t.index.toString(), label: t.label, language: t.lang));
    }

    emitEvent(AudioTracksChangedEvent(tracks));
  }

  /// Handles DASH error event.
  void _handleError(Object? data) {
    verboseLog('DASH error: $data', tag: logTag);

    // Extract error details if available
    final errorData = (data as Map?)?['error'] as Map?;
    final errorCode = errorData?['code'] as String? ?? 'unknown';
    final errorMessage = errorData?['message'] as String?;

    emitEvent(
      ErrorEvent('DASH.js error: $errorCode${errorMessage != null ? ' - $errorMessage' : ''}', code: 'DASH_ERROR'),
    );
  }

  /// Updates available quality tracks from DASH.js bitrate info.
  void _updateAvailableQualities() {
    final bitrateList = player?.getVideoBitrateInfoList() ?? [];
    final qualities = <VideoQualityTrack>[];

    // Add auto quality option
    qualities.add(VideoQualityTrack.auto);

    // Add each quality level
    for (final info in bitrateList) {
      final height = info.height;
      final width = info.width;
      final bitrate = info.bitrate;
      final qualityIndex = info.index;

      qualities.add(
        VideoQualityTrack(
          id: qualityIndex.toString(),
          label: '${height}p',
          width: width,
          height: height,
          bitrate: bitrate,
        ),
      );
    }

    updateAvailableQualities(qualities);

    // Emit quality tracks changed event
    emitEvent(VideoQualityTracksChangedEvent(qualities));
  }

  /// Sets the video quality.
  ///
  /// Returns true if the quality was set successfully.
  @override
  bool setQuality(VideoQualityTrack track) {
    final p = player;
    if (p == null) return false;

    if (track.isAuto) {
      p.setAutoSwitchQualityFor('video', enabled: true);
      verboseLog('Set DASH quality to auto', tag: logTag);
      return true;
    }

    final index = int.tryParse(track.id);
    if (index == null) return false;

    final bitrateList = p.getVideoBitrateInfoList();
    if (index < 0 || index >= bitrateList.length) {
      return false;
    }

    p.setAutoSwitchQualityFor('video', enabled: false);
    p.setQualityFor('video', index);
    verboseLog('Set DASH quality to index $index', tag: logTag);
    return true;
  }

  /// Gets the current quality track.
  @override
  VideoQualityTrack getCurrentQuality() {
    final p = player;
    if (p == null) return VideoQualityTrack.auto;

    // Check if ABR is enabled
    final abrEnabled = p.getAutoSwitchQualityFor('video');
    if (abrEnabled) {
      return VideoQualityTrack.auto;
    }

    final currentQuality = p.getQualityFor('video');
    final availableQualities = getAvailableQualities();

    // Find matching quality in available list (skip auto at index 0)
    if (currentQuality < 0 || currentQuality >= availableQualities.length - 1) {
      return VideoQualityTrack.auto;
    }

    // currentQuality is 0-indexed, but availableQualities has auto at index 0
    return availableQualities[currentQuality + 1];
  }

  /// Gets average throughput in bits per second.
  ///
  /// DASH.js returns throughput in kbps, this converts to bps.
  int getAverageThroughput() {
    final p = player;
    if (p == null) return 0;

    try {
      final throughputKbps = p.getAverageThroughput();
      // Convert kbps to bps
      return (throughputKbps * 1000).round();
    } catch (e) {
      verboseLog('Error getting throughput: $e', tag: logTag);
      return 0;
    }
  }

  /// Recovers from an error by resetting and reattaching source.
  @override
  Future<void> recover() async {
    final p = player;
    if (p == null || _sourceUrl == null) return;

    try {
      p.reset();
      p.attachSource(_sourceUrl!);
      verboseLog('DASH recovery: reset and reattached source', tag: logTag);
    } catch (e) {
      verboseLog('DASH recovery failed: $e', tag: logTag);
    }
  }

  /// Cleans up the DASH player.
  ///
  /// Resets the DASH player and removes all event handlers.
  @override
  void cleanupPlayer() {
    player?.reset();
    verboseLog('DASH.js player reset', tag: logTag);
  }

  @override
  void dispose() {
    super.dispose();
    _sourceUrl = null;
  }
}
