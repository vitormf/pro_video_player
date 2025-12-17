import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:web/web.dart' as web;

import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';
import 'dash_manager.dart';
import 'hls_manager.dart';

/// Manages audio track selection across HLS.js, DASH.js, and native HTML5.
///
/// This manager coordinates audio track selection by delegating to the
/// appropriate source (HLS.js, DASH.js, or native HTML5 AudioTrackList).
/// It follows a priority system: HLS > DASH > native.
///
/// Audio track change events are emitted by the individual managers
/// (HlsManager, DashManager) when they detect track changes.
///
/// For native HTML5 playback, this manager handles:
/// - Detecting and notifying available audio tracks
/// - Setting the active audio track via AudioTrackList API
///
/// Note: Native HTML5 AudioTrackList has limited browser support (Safari only).
/// Chrome, Firefox, and Edge do not expose the AudioTrackList API.
class AudioTrackManager with WebManagerCallbacks {
  /// Creates an audio track manager.
  AudioTrackManager({required this.emitEvent, required this.videoElement});

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// HLS manager for HLS.js audio track handling.
  HlsManager? hlsManager;

  /// DASH manager for DASH.js audio track handling.
  DashManager? dashManager;

  /// Whether an HLS manager is registered.
  bool get hasHlsManager => hlsManager != null && hlsManager!.isActive;

  /// Whether a DASH manager is registered.
  bool get hasDashManager => dashManager != null && dashManager!.isActive;

  /// Notifies about native HTML5 audio tracks.
  ///
  /// Extracts audio tracks from the video element's AudioTrackList and
  /// emits an [AudioTracksChangedEvent].
  ///
  /// Note: AudioTrackList is only supported in Safari. Other browsers
  /// return null for videoElement.audioTracks.
  Future<void> notifyNativeAudioTracks() async {
    try {
      final audioTracks = videoElement.mockAudioTracks;

      if (audioTracks == null || audioTracks.isEmpty) {
        verboseLog('No native audio tracks available', tag: 'AudioTrackManager');
        return;
      }

      final tracks = <AudioTrack>[];

      for (var i = 0; i < audioTracks.length; i++) {
        // Cast to web.AudioTrack - in production this is a browser AudioTrack object,
        // in tests this should be a compatible mock with id/label/language properties
        final audioTrack = audioTracks[i] as web.AudioTrack;
        tracks.add(
          AudioTrack(
            id: audioTrack.id.isNotEmpty ? audioTrack.id : i.toString(),
            label: audioTrack.label.isNotEmpty ? audioTrack.label : 'Audio ${i + 1}',
            language: audioTrack.language.isNotEmpty ? audioTrack.language : null,
          ),
        );
      }

      if (tracks.isNotEmpty) {
        emitEvent(AudioTracksChangedEvent(tracks));
        verboseLog('Notified ${tracks.length} native audio tracks', tag: 'AudioTrackManager');
      }
    } catch (e) {
      verboseLog('Error notifying native audio tracks: $e', tag: 'AudioTrackManager');
    }
  }

  /// Sets the active audio track.
  ///
  /// Delegates to the appropriate source in priority order:
  /// 1. HLS.js (if active)
  /// 2. DASH.js (if active)
  /// 3. Native HTML5 AudioTrackList
  ///
  /// Pass null to disable audio tracks (where supported).
  ///
  /// Returns true if the track was set successfully.
  bool setAudioTrack(AudioTrack? track) {
    // If track is null, we can't disable audio tracks on web
    if (track == null) {
      verboseLog('Cannot disable audio tracks on web', tag: 'AudioTrackManager');
      return false;
    }
    // Priority 1: HLS.js
    if (hasHlsManager) {
      return _setHlsAudioTrack(track);
    }

    // Priority 2: DASH.js
    if (hasDashManager) {
      return _setDashAudioTrack(track);
    }

    // Priority 3: Native HTML5
    return setNativeAudioTrack(track);
  }

  /// Sets audio track for HLS.js.
  bool _setHlsAudioTrack(AudioTrack track) {
    final index = int.tryParse(track.id);
    if (index == null) return false;

    try {
      final hlsPlayer = hlsManager!.hlsPlayer;
      if (hlsPlayer == null) return false;

      hlsPlayer.audioTrack = index;
      verboseLog('Set HLS audio track to $index', tag: 'AudioTrackManager');
      return true;
    } catch (e) {
      verboseLog('Error setting HLS audio track: $e', tag: 'AudioTrackManager');
      return false;
    }
  }

  /// Sets audio track for DASH.js.
  bool _setDashAudioTrack(AudioTrack track) {
    final index = int.tryParse(track.id);
    if (index == null) return false;

    try {
      final dashPlayer = dashManager!.dashPlayer;
      if (dashPlayer == null) return false;

      dashPlayer.setAudioTrack(index);
      verboseLog('Set DASH audio track to $index', tag: 'AudioTrackManager');
      return true;
    } catch (e) {
      verboseLog('Error setting DASH audio track: $e', tag: 'AudioTrackManager');
      return false;
    }
  }

  /// Sets audio track for native HTML5 AudioTrackList.
  ///
  /// Note: AudioTrackList is only supported in Safari. This method
  /// will return false on browsers that don't support AudioTrackList.
  bool setNativeAudioTrack(AudioTrack track) {
    try {
      final audioTracks = videoElement.mockAudioTracks;

      if (audioTracks == null || audioTracks.isEmpty) {
        verboseLog('Native audio tracks not available', tag: 'AudioTrackManager');
        return false;
      }

      // Disable all tracks and enable the selected one
      for (var i = 0; i < audioTracks.length; i++) {
        final audioTrack = audioTracks[i] as web.AudioTrack;
        final trackId = audioTrack.id.isNotEmpty ? audioTrack.id : i.toString();
        audioTrack.enabled = trackId == track.id;
      }

      verboseLog('Set native audio track to ${track.id}', tag: 'AudioTrackManager');
      return true;
    } catch (e) {
      verboseLog('Error setting native audio track: $e', tag: 'AudioTrackManager');
      return false;
    }
  }

  /// Gets native audio tracks from HTML5 AudioTrackList.
  ///
  /// Returns an empty list if AudioTrackList is not supported or available.
  List<AudioTrack> getNativeAudioTracks() {
    try {
      final audioTracks = videoElement.mockAudioTracks;

      if (audioTracks == null || audioTracks.isEmpty) {
        return [];
      }

      final tracks = <AudioTrack>[];
      for (var i = 0; i < audioTracks.length; i++) {
        final audioTrack = audioTracks[i] as web.AudioTrack;
        tracks.add(
          AudioTrack(
            id: audioTrack.id.isNotEmpty ? audioTrack.id : i.toString(),
            label: audioTrack.label.isNotEmpty ? audioTrack.label : 'Track ${i + 1}',
            language: audioTrack.language.isNotEmpty ? audioTrack.language : null,
          ),
        );
      }

      return tracks;
    } catch (e) {
      verboseLog('Error getting native audio tracks: $e', tag: 'AudioTrackManager');
      return [];
    }
  }

  /// Disposes the manager and cleans up resources.
  void dispose() {
    hlsManager = null;
    dashManager = null;

    verboseLog('Audio track manager disposed', tag: 'AudioTrackManager');
  }
}
