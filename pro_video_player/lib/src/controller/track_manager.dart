import 'dart:async';

import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Manages track selection (subtitle, audio, video quality) for the video player.
///
/// This manager handles:
/// - Subtitle track selection and auto-selection based on preferences
/// - Audio track selection
/// - Video quality track selection for adaptive streams
/// - Subtitle render mode configuration
class TrackManager {
  /// Creates a track manager with dependency injection via callbacks.
  TrackManager({
    required this.getValue,
    required this.setValue,
    required this.getPlayerId,
    required this.getOptions,
    required this.platform,
    required this.ensureInitialized,
  });

  /// Gets the current video player value.
  final VideoPlayerValue Function() getValue;

  /// Updates the video player value.
  final void Function(VideoPlayerValue) setValue;

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Gets the video player options.
  final VideoPlayerOptions Function() getOptions;

  /// Platform implementation for track operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

  /// Sets the active subtitle track.
  ///
  /// Pass `null` to disable subtitles. Returns immediately without effect
  /// if subtitles are disabled via [VideoPlayerOptions.subtitlesEnabled].
  Future<void> setSubtitleTrack(SubtitleTrack? track) async {
    ensureInitialized();

    // Gracefully handle disabled subtitles
    if (!getOptions().subtitlesEnabled) {
      return;
    }

    await platform.setSubtitleTrack(getPlayerId()!, track);
    final value = getValue();
    setValue(value.copyWith(selectedSubtitleTrack: track, clearSelectedSubtitle: track == null));
  }

  /// Sets the subtitle rendering mode at runtime.
  ///
  /// This allows switching between native and Flutter subtitle rendering
  /// during playback without restarting the video.
  ///
  /// - [SubtitleRenderMode.native]: Native platform renders subtitles
  /// - [SubtitleRenderMode.flutter]: Flutter renders subtitles via overlay
  /// - [SubtitleRenderMode.auto]: Automatically select based on controls mode
  ///
  /// Returns immediately without effect if subtitles are disabled.
  Future<void> setSubtitleRenderMode(SubtitleRenderMode mode) async {
    ensureInitialized();

    // Gracefully handle disabled subtitles
    if (!getOptions().subtitlesEnabled) {
      return;
    }

    await platform.setSubtitleRenderMode(getPlayerId()!, mode);
    final value = getValue();
    setValue(value.copyWith(currentSubtitleRenderMode: mode));
  }

  /// Sets the active audio track.
  ///
  /// Pass `null` to use the default audio track.
  Future<void> setAudioTrack(AudioTrack? track) async {
    ensureInitialized();
    await platform.setAudioTrack(getPlayerId()!, track);
    final value = getValue();
    setValue(value.copyWith(selectedAudioTrack: track, clearSelectedAudio: track == null));
  }

  /// Sets the video quality for adaptive streams.
  ///
  /// Pass [VideoQualityTrack.auto] to enable automatic quality selection (ABR).
  /// Pass a specific track to lock to that quality level.
  ///
  /// This only has effect for adaptive streaming content (HLS, DASH).
  /// For non-adaptive content, this method has no effect.
  ///
  /// Returns `true` if the quality was successfully set.
  Future<bool> setVideoQuality(VideoQualityTrack track) async {
    ensureInitialized();
    final success = await platform.setVideoQuality(getPlayerId()!, track);
    if (success) {
      final value = getValue();
      setValue(value.copyWith(selectedQualityTrack: track, clearSelectedQuality: track.isAuto));
    }
    return success;
  }

  /// Returns the available video quality tracks.
  ///
  /// For adaptive streaming content (HLS, DASH), this returns a list of
  /// available quality options. The list always includes [VideoQualityTrack.auto]
  /// as the first option.
  ///
  /// For non-adaptive content, returns a list with only [VideoQualityTrack.auto].
  Future<List<VideoQualityTrack>> getVideoQualities() async {
    ensureInitialized();
    return platform.getVideoQualities(getPlayerId()!);
  }

  /// Returns the currently selected video quality track.
  ///
  /// Returns [VideoQualityTrack.auto] if automatic quality selection is active.
  Future<VideoQualityTrack> getCurrentVideoQuality() async {
    ensureInitialized();
    return platform.getCurrentVideoQuality(getPlayerId()!);
  }

  /// Returns whether manual quality selection is supported for the current content.
  ///
  /// This returns `true` for adaptive streaming content (HLS, DASH) where
  /// multiple quality levels are available.
  Future<bool> isQualitySelectionSupported() async {
    ensureInitialized();
    return platform.isQualitySelectionSupported(getPlayerId()!);
  }

  /// Auto-selects a subtitle track based on configuration preferences.
  ///
  /// Selection priority:
  /// 1. Track matching [VideoPlayerOptions.preferredSubtitleLanguage]
  /// 2. Track marked as default
  /// 3. First available track
  ///
  /// Called automatically when subtitle tracks become available and
  /// [VideoPlayerOptions.showSubtitlesByDefault] is true.
  void autoSelectSubtitle(List<SubtitleTrack> tracks) {
    SubtitleTrack? trackToSelect;

    final options = getOptions();

    // Try to find track matching preferred language
    if (options.preferredSubtitleLanguage != null) {
      trackToSelect = tracks.where((t) => t.language == options.preferredSubtitleLanguage).firstOrNull;
    }

    // Fall back to default track
    trackToSelect ??= tracks.where((t) => t.isDefault).firstOrNull;

    // Fall back to first track
    trackToSelect ??= tracks.firstOrNull;

    if (trackToSelect != null) {
      // Fire and forget for auto-selection - explicitly discard the future
      unawaited(setSubtitleTrack(trackToSelect));
    }
  }
}
