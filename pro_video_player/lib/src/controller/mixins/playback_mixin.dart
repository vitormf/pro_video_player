import '../controller_base.dart';

/// Mixin providing core playback controls.
mixin PlaybackMixin on ProVideoPlayerControllerBase {
  /// Starts or resumes video playback.
  Future<void> play() async {
    ensureInitializedInternal();
    return services.playbackManager.play();
  }

  /// Pauses video playback.
  Future<void> pause() async {
    ensureInitializedInternal();
    return services.playbackManager.pause();
  }

  /// Stops playback and resets position to the beginning.
  Future<void> stop() async {
    ensureInitializedInternal();
    return services.playbackManager.stop();
  }

  /// Seeks to the specified [position].
  Future<void> seekTo(Duration position) async {
    ensureInitializedInternal();
    return services.playbackManager.seekTo(position);
  }

  /// Seeks forward by [duration].
  Future<void> seekForward(Duration duration) async {
    ensureInitializedInternal();
    return services.playbackManager.seekForward(duration);
  }

  /// Seeks backward by [duration].
  Future<void> seekBackward(Duration duration) async {
    ensureInitializedInternal();
    return services.playbackManager.seekBackward(duration);
  }

  /// Sets the playback speed.
  ///
  /// [speed] must be greater than 0.
  Future<void> setPlaybackSpeed(double speed) async {
    ensureInitializedInternal();
    return services.playbackManager.setPlaybackSpeed(speed);
  }

  /// Sets the player volume.
  ///
  /// [volume] must be between 0.0 (muted) and 1.0 (full volume).
  /// This controls the player's internal volume, not the device volume.
  /// Use `setDeviceVolume` to control the device's media volume.
  Future<void> setVolume(double volume) async {
    ensureInitializedInternal();
    return services.playbackManager.setVolume(volume);
  }

  /// Toggles between play and pause.
  Future<void> togglePlayPause() async {
    ensureInitializedInternal();
    return services.playbackManager.togglePlayPause();
  }
}
