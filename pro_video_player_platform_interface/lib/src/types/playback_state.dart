/// The current playback state of the video player.
enum PlaybackState {
  /// The player has not been initialized yet.
  uninitialized,

  /// The player is initializing (loading the video source).
  initializing,

  /// The player is ready to play.
  ready,

  /// The video is currently playing.
  playing,

  /// The video is paused.
  paused,

  /// The video playback has completed.
  completed,

  /// The player is buffering.
  buffering,

  /// An error occurred.
  error,

  /// The player has been disposed.
  disposed,
}
