/// Abstract interface for HLS.js player implementations.
///
/// This interface allows both real HLS.js players and mock implementations
/// to be used interchangeably, enabling proper type safety while maintaining
/// testability.
abstract class HlsPlayerInterface {
  /// Attaches the player to a video element.
  ///
  /// Accepts any video element type (HTMLVideoElement for real implementation,
  /// mock video element for testing).
  void attachMedia(Object video);

  /// Detaches the player from the video element.
  void detachMedia();

  /// Loads an HLS source URL.
  void loadSource(String url);

  /// Starts loading the stream.
  void startLoad([int startPosition = -1]);

  /// Stops loading the stream.
  void stopLoad();

  /// Gets the current quality level index (-1 for auto).
  int get currentLevel;

  /// Sets the current quality level index (-1 for auto).
  set currentLevel(int level);

  /// Gets the next level to be loaded (-1 for auto).
  int get nextLevel;

  /// Sets the next level to be loaded (-1 for auto).
  set nextLevel(int level);

  /// Gets the auto level capping (-1 for no cap).
  int get autoLevelCapping;

  /// Sets the auto level capping (-1 for no cap).
  set autoLevelCapping(int level);

  /// Gets whether auto level selection is enabled.
  bool get autoLevelEnabled;

  /// Gets the list of available quality levels.
  List<HlsLevelInterface> get levels;

  /// Gets the current audio track index.
  int get audioTrack;

  /// Sets the current audio track index.
  set audioTrack(int index);

  /// Gets the list of available audio tracks.
  List<HlsAudioTrackInterface> get audioTracks;

  /// Gets the current subtitle track index (-1 for disabled).
  int get subtitleTrack;

  /// Sets the current subtitle track index (-1 to disable).
  set subtitleTrack(int index);

  /// Gets the list of available subtitle tracks.
  List<HlsSubtitleTrackInterface> get subtitleTracks;

  /// Gets the estimated bandwidth in bits per second.
  double get bandwidthEstimate;

  /// Adds an event listener.
  void on(String event, void Function(String event, Object? data) callback);

  /// Removes all event listeners.
  void offAll();

  /// Destroys the HLS.js instance and releases resources.
  void destroy();

  /// Recovers from a media error.
  void recoverMediaError();

  /// Swaps the audio codec for error recovery.
  void swapAudioCodec();
}

/// Abstract interface for HLS quality level.
abstract class HlsLevelInterface {
  /// The level index in the HLS manifest.
  int get index;

  /// The bitrate in bits per second.
  int get bitrate;

  /// The video width in pixels.
  int get width;

  /// The video height in pixels.
  int get height;

  /// Optional name from the manifest.
  String? get name;

  /// The codec string.
  String? get codecs;

  /// Returns a human-readable label for this quality level.
  String get label;
}

/// Abstract interface for HLS audio track.
abstract class HlsAudioTrackInterface {
  /// The track index in the list.
  int get index;

  /// The track ID from the manifest.
  int? get id;

  /// The track name.
  String? get name;

  /// The language code.
  String? get lang;

  /// Whether this is the default track.
  bool get isDefault;

  /// Returns a human-readable label for this audio track.
  String get label;
}

/// Abstract interface for HLS subtitle track.
abstract class HlsSubtitleTrackInterface {
  /// The track index in the list.
  int get index;

  /// The track ID from the manifest.
  int? get id;

  /// The track name.
  String? get name;

  /// The language code.
  String? get lang;

  /// Whether this is the default track.
  bool get isDefault;

  /// Whether this is a forced track (for foreign language parts).
  bool get forced;

  /// Returns a human-readable label for this subtitle track.
  String get label;
}
