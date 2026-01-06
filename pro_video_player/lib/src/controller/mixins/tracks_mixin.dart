import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

/// Mixin providing track selection (subtitles, audio, quality).
mixin TracksMixin on ProVideoPlayerControllerBase {
  /// Selects a subtitle track.
  ///
  /// Pass `null` to disable subtitles.
  ///
  /// Returns immediately without effect if [VideoPlayerOptions.subtitlesEnabled]
  /// was set to `false` during initialization.
  Future<void> setSubtitleTrack(SubtitleTrack? track) async {
    ensureInitializedInternal();
    await services.trackManager.setSubtitleTrack(track);
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
  /// When switching to [SubtitleRenderMode.flutter], embedded subtitle cues
  /// will start being streamed to Flutter for rendering. When switching to
  /// [SubtitleRenderMode.native], the native player will handle rendering.
  ///
  /// External subtitles are always rendered in Flutter regardless of this setting.
  ///
  /// Returns immediately without effect if [VideoPlayerOptions.subtitlesEnabled]
  /// is `false`.
  Future<void> setSubtitleRenderMode(SubtitleRenderMode mode) async {
    ensureInitializedInternal();
    await services.trackManager.setSubtitleRenderMode(mode);
  }

  /// Adds an external subtitle track from a [SubtitleSource].
  ///
  /// This method loads and validates the subtitle file from the given source
  /// and adds it as a selectable subtitle track. The subtitle can then be
  /// selected using [setSubtitleTrack].
  ///
  /// Supports multiple source types:
  /// - [SubtitleSource.network] — Load from HTTP/HTTPS URL
  /// - [SubtitleSource.file] — Load from local file path
  /// - [SubtitleSource.asset] — Load from Flutter asset
  /// - [SubtitleSource.from] — Auto-detect source type from string
  ///
  /// Returns the created [ExternalSubtitleTrack] on success, or `null` if
  /// loading failed (e.g., invalid path, network error, file not found).
  Future<ExternalSubtitleTrack?> addExternalSubtitle(SubtitleSource source) async {
    ensureInitializedInternal();
    return services.subtitleManager.addExternalSubtitle(source);
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
    ensureInitializedInternal();
    return services.subtitleManager.removeExternalSubtitle(trackId);
  }

  /// Gets all external subtitle tracks that have been added.
  ///
  /// Returns a list of [ExternalSubtitleTrack] objects representing all
  /// external subtitles that have been loaded via [addExternalSubtitle].
  /// This does not include embedded subtitle tracks from the video file.
  Future<List<ExternalSubtitleTrack>> getExternalSubtitles() async {
    ensureInitializedInternal();
    return services.subtitleManager.getExternalSubtitles();
  }

  /// Selects an audio track.
  ///
  /// Pass `null` to reset to the default audio track.
  Future<void> setAudioTrack(AudioTrack? track) async {
    ensureInitializedInternal();
    await services.trackManager.setAudioTrack(track);
  }

  /// Sets the video quality for adaptive streams.
  ///
  /// Pass [VideoQualityTrack.auto] to enable automatic quality selection (ABR).
  /// Pass a specific track from [VideoPlayerValue.qualityTracks] to lock to
  /// that quality level.
  ///
  /// This only has effect for adaptive streaming content (HLS, DASH).
  /// For non-adaptive content, this method has no effect.
  ///
  /// Returns `true` if the quality was successfully set.
  Future<bool> setVideoQuality(VideoQualityTrack track) async {
    ensureInitializedInternal();
    return services.trackManager.setVideoQuality(track);
  }

  /// Returns the available video quality tracks.
  ///
  /// For adaptive streaming content (HLS, DASH), this returns a list of
  /// available quality options. The list always includes [VideoQualityTrack.auto]
  /// as the first option.
  ///
  /// For non-adaptive content, returns a list with only [VideoQualityTrack.auto].
  Future<List<VideoQualityTrack>> getVideoQualities() async {
    ensureInitializedInternal();
    return services.trackManager.getVideoQualities();
  }

  /// Returns the currently selected video quality track.
  ///
  /// Returns [VideoQualityTrack.auto] if automatic quality selection is active.
  Future<VideoQualityTrack> getCurrentVideoQuality() async {
    ensureInitializedInternal();
    return services.trackManager.getCurrentVideoQuality();
  }

  /// Returns whether manual quality selection is supported for the current content.
  ///
  /// This returns `true` for adaptive streaming content (HLS, DASH) where
  /// multiple quality levels are available.
  Future<bool> isQualitySelectionSupported() async {
    ensureInitializedInternal();
    return services.trackManager.isQualitySelectionSupported();
  }

  /// Sets the subtitle timing offset for synchronization.
  ///
  /// A positive [offset] delays subtitles (shows them later), while a negative
  /// [offset] shows subtitles earlier. This is useful for fixing subtitle sync
  /// issues where subtitles appear too early or too late.
  void setSubtitleOffset(Duration offset) {
    value = value.copyWith(subtitleOffset: offset);
  }

  /// Returns the current subtitle timing offset.
  Duration get subtitleOffset => value.subtitleOffset;

  /// Returns whether subtitles are enabled for this player.
  ///
  /// This reflects the [VideoPlayerOptions.subtitlesEnabled] setting.
  bool get subtitlesEnabled => options.subtitlesEnabled;
}
