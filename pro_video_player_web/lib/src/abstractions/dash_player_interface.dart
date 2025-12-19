/// Abstract interface for dash.js player implementations.
///
/// This interface allows both real dash.js players and mock implementations
/// to be used interchangeably, enabling proper type safety while maintaining
/// testability.
abstract class DashPlayerInterface {
  /// Initializes the player with a video element and source URL.
  ///
  /// [view] is the video element (HTMLVideoElement for real, mock for testing).
  /// [url] is the DASH manifest URL.
  /// [autoPlay] whether to auto-play after initialization.
  void initialize({required Object view, required String url, bool autoPlay = false});

  /// Attaches the player to a video element.
  void attachView(Object view);

  /// Attaches a source URL.
  void attachSource(String url);

  /// Gets the list of available video bitrates/qualities.
  List<DashBitrateInfoInterface> getVideoBitrateInfoList();

  /// Gets the list of available audio bitrates.
  List<DashBitrateInfoInterface> getAudioBitrateInfoList();

  /// Gets the current quality index for a media type.
  int getQualityFor(String type);

  /// Sets the quality index for a media type.
  void setQualityFor(String type, int quality);

  /// Enables/disables automatic bitrate adaptation for a media type.
  void setAutoSwitchQualityFor(String type, {required bool enabled});

  /// Gets whether automatic bitrate adaptation is enabled for a media type.
  bool getAutoSwitchQualityFor(String type);

  /// Updates player settings.
  void updateSettings(Map<String, dynamic> settings);

  /// Gets the list of available text tracks (subtitles).
  List<DashTextTrackInterface> getTextTracks();

  /// Sets the current text track by index.
  void setTextTrack(int index);

  /// Enables or disables text track display.
  void setTextTrackVisibility({required bool visible});

  /// Gets the list of available audio tracks.
  List<DashAudioTrackInterface> getAudioTracks();

  /// Sets the current audio track by index.
  void setAudioTrack(int index);

  /// Gets the average throughput in kbps.
  double getAverageThroughput();

  /// Adds an event listener.
  void on(String event, void Function(Object? data) callback);

  /// Removes all event listeners.
  void offAll();

  /// Resets the player.
  void reset();

  /// Destroys the player and releases resources.
  void destroy();
}

/// Abstract interface for DASH bitrate/quality info.
abstract class DashBitrateInfoInterface {
  /// The quality index.
  int get index;

  /// The bitrate in bits per second.
  int get bitrate;

  /// The video width in pixels.
  int get width;

  /// The video height in pixels.
  int get height;

  /// The media type (video/audio).
  String? get mediaType;

  /// Returns a human-readable label for this quality level.
  String get label;
}

/// Abstract interface for DASH text/subtitle track.
abstract class DashTextTrackInterface {
  /// The track index.
  int get index;

  /// The track ID from the manifest.
  String? get id;

  /// The language code.
  String? get lang;

  /// The roles (e.g., subtitle, caption).
  List<String>? get roles;

  /// Whether this is the default track.
  bool get isDefault;

  /// Returns a human-readable label for this subtitle track.
  String get label;
}

/// Abstract interface for DASH audio track.
abstract class DashAudioTrackInterface {
  /// The track index.
  int get index;

  /// The track ID from the manifest.
  String? get id;

  /// The language code.
  String? get lang;

  /// The roles.
  List<String>? get roles;

  /// Whether this is the default track.
  bool get isDefault;

  /// Returns a human-readable label for this audio track.
  String get label;
}
