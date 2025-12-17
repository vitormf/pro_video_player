import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../pro_video_player.dart' show SubtitleOverlay;
import 'controller/casting_manager.dart';
import 'controller/configuration_manager.dart';
import 'controller/device_controls_manager.dart';
import 'controller/disposal_coordinator.dart';
import 'controller/error_recovery_manager.dart';
import 'controller/event_coordinator.dart';
import 'controller/fullscreen_manager.dart';
import 'controller/initialization_coordinator.dart';
import 'controller/metadata_manager.dart';
import 'controller/pip_manager.dart';
import 'controller/playback_manager.dart';
import 'controller/playlist_manager.dart';
import 'controller/subtitle_manager.dart';
import 'controller/track_manager.dart';
import 'subtitle_overlay.dart' show SubtitleOverlay;

// Alias for cleaner code
typedef _Logger = ProVideoPlayerLogger;

/// Controller for a video player instance.
///
/// Create a controller using named constructors (`network`, `file`, `asset`),
/// then call [initialize] to load the video. Use [play], [pause], [seekTo],
/// etc. to control playback.
///
/// Remember to call [dispose] when done to release resources.
///
/// Example (video_player compatible style):
/// ```dart
/// final controller = ProVideoPlayerController.network(
///   'https://example.com/video.mp4',
/// );
/// await controller.initialize();
/// await controller.play();
/// // ...
/// await controller.dispose();
/// ```
///
/// Advanced example (custom source):
/// ```dart
/// final controller = ProVideoPlayerController();
/// await controller.initialize(
///   source: VideoSource.network('https://example.com/video.mp4'),
///   options: VideoPlayerOptions(autoPlay: true),
/// );
/// ```
class ProVideoPlayerController extends ValueNotifier<VideoPlayerValue> {
  /// Creates a new video player controller.
  ///
  /// For compatibility with the video_player library, prefer using named
  /// constructors: `network`, `file`, or `asset`.
  ///
  /// Optionally pass [errorRecoveryOptions] to configure automatic error
  /// recovery behavior. By default, automatic retry is enabled for network
  /// and timeout errors.
  ProVideoPlayerController({ErrorRecoveryOptions errorRecoveryOptions = ErrorRecoveryOptions.defaultOptions})
    : _errorRecoveryOptions = errorRecoveryOptions,
      _initialSource = null,
      _initialOptions = null,
      super(const VideoPlayerValue());

  /// Creates a video player controller for a network video.
  ///
  /// This constructor is compatible with Flutter's video_player library.
  ///
  /// The [dataSource] is the URL of the video. Optional [httpHeaders] can be
  /// provided for authenticated content. Optional [videoPlayerOptions] can be
  /// provided to configure player behavior.
  ///
  /// Call [initialize] after construction to load the video.
  ///
  /// Example:
  /// ```dart
  /// final controller = ProVideoPlayerController.network(
  ///   'https://example.com/video.mp4',
  ///   httpHeaders: {'Authorization': 'Bearer token'},
  ///   videoPlayerOptions: VideoPlayerOptions(autoPlay: true),
  /// );
  /// await controller.initialize();
  /// ```
  ProVideoPlayerController.network(
    String dataSource, {
    Map<String, String>? httpHeaders,
    VideoPlayerOptions? videoPlayerOptions,
    ErrorRecoveryOptions errorRecoveryOptions = ErrorRecoveryOptions.defaultOptions,
  }) : _errorRecoveryOptions = errorRecoveryOptions,
       _initialSource = VideoSource.network(dataSource, headers: httpHeaders),
       _initialOptions = videoPlayerOptions,
       super(const VideoPlayerValue());

  /// Creates a video player controller for a local file.
  ///
  /// This constructor is compatible with Flutter's video_player library.
  ///
  /// The [file] is the local video file. Optional [videoPlayerOptions] can be
  /// provided to configure player behavior.
  ///
  /// Call [initialize] after construction to load the video.
  ///
  /// Example:
  /// ```dart
  /// final controller = ProVideoPlayerController.file(
  ///   File('/path/to/video.mp4'),
  /// );
  /// await controller.initialize();
  /// ```
  ProVideoPlayerController.file(
    File file, {
    VideoPlayerOptions? videoPlayerOptions,
    ErrorRecoveryOptions errorRecoveryOptions = ErrorRecoveryOptions.defaultOptions,
  }) : _errorRecoveryOptions = errorRecoveryOptions,
       _initialSource = VideoSource.file(file.path),
       _initialOptions = videoPlayerOptions,
       super(const VideoPlayerValue());

  /// Creates a video player controller for an asset video.
  ///
  /// This constructor is compatible with Flutter's video_player library.
  ///
  /// The [dataSource] is the asset path (e.g., 'assets/video.mp4'). Optional
  /// [package] can be specified for assets from packages. Optional
  /// [videoPlayerOptions] can be provided to configure player behavior.
  ///
  /// Call [initialize] after construction to load the video.
  ///
  /// Example:
  /// ```dart
  /// final controller = ProVideoPlayerController.asset(
  ///   'assets/video.mp4',
  /// );
  /// await controller.initialize();
  /// ```
  ProVideoPlayerController.asset(
    String dataSource, {
    String? package,
    VideoPlayerOptions? videoPlayerOptions,
    ErrorRecoveryOptions errorRecoveryOptions = ErrorRecoveryOptions.defaultOptions,
  }) : _errorRecoveryOptions = errorRecoveryOptions,
       _initialSource = VideoSource.asset(package != null ? 'packages/$package/$dataSource' : dataSource),
       _initialOptions = videoPlayerOptions,
       super(const VideoPlayerValue());

  int? _playerId;
  VideoSource? _source;
  VideoPlayerOptions _options = const VideoPlayerOptions();
  final ErrorRecoveryOptions _errorRecoveryOptions;
  final VideoSource? _initialSource;
  final VideoPlayerOptions? _initialOptions;
  late ErrorRecoveryManager _errorRecovery;
  late TrackManager _trackManager;
  late PlaylistManager _playlistManager;
  late PipManager _pipManager;
  late FullscreenManager _fullscreenManager;
  late CastingManager _castingManager;
  late DeviceControlsManager _deviceControlsManager;
  late MetadataManager _metadataManager;
  late PlaybackManager _playbackManager;
  late EventCoordinator _eventCoordinator;
  late SubtitleManager _subtitleManager;
  late ConfigurationManager _configurationManager;
  bool _isDisposed = false;
  bool _isRetrying = false;

  /// The current video source, or null if not initialized.
  VideoSource? get source => _source;

  /// The unique ID of this player instance.
  ///
  /// Returns `null` if the player has not been initialized.
  int? get playerId => _playerId;

  /// Whether the player has been initialized.
  bool get isInitialized => _playerId != null && value.isInitialized;

  /// Whether the player has been disposed.
  bool get isDisposed => _isDisposed;

  /// The configuration options for this player.
  ///
  /// These are the options passed during [initialize].
  VideoPlayerOptions get options => _options;

  // ==================== video_player Compatibility Properties ====================

  /// The data source URL or path.
  ///
  /// This property is provided for compatibility with Flutter's video_player
  /// library. Returns the string representation of the current [source].
  ///
  /// For more detailed source information, use the [source] property instead.
  String? get dataSource {
    final src = source;
    if (src == null) return null;
    if (src is NetworkVideoSource) return src.url;
    if (src is FileVideoSource) return src.path;
    if (src is AssetVideoSource) return src.assetPath;
    if (src is PlaylistVideoSource) return src.url;
    return null;
  }

  /// The type of data source.
  ///
  /// This property is provided for compatibility with Flutter's video_player
  /// library. Returns the type based on the current [source].
  DataSourceType? get dataSourceType {
    final src = source;
    if (src == null) return null;
    if (src is NetworkVideoSource) return DataSourceType.network;
    if (src is FileVideoSource) {
      // Check if it's a content URI (Android)
      if (src.path.startsWith('content://')) {
        return DataSourceType.contentUri;
      }
      return DataSourceType.file;
    }
    if (src is AssetVideoSource) return DataSourceType.asset;
    if (src is PlaylistVideoSource) return DataSourceType.network;
    return null;
  }

  /// HTTP headers for network requests.
  ///
  /// This property is provided for compatibility with Flutter's video_player
  /// library. Returns headers if the current source is a network source.
  Map<String, String>? get httpHeaders {
    final src = source;
    if (src is NetworkVideoSource) return src.headers;
    return null;
  }

  /// The current playback position.
  ///
  /// This property is provided for compatibility with Flutter's video_player
  /// library, which returns position as a Future. However, the position is
  /// also available synchronously via `value.position`.
  ///
  /// For UI code, prefer using `value.position` directly for synchronous
  /// access. This getter is provided for code migrating from video_player.
  Future<Duration> get position async {
    _ensureInitialized();
    // Could optionally fetch fresh from platform here, but value.position
    // is kept up-to-date via events, so returning it is sufficient
    return value.position;
  }

  ProVideoPlayerPlatform get _platform => ProVideoPlayerPlatform.instance;

  /// Initializes the video player with the given [source].
  ///
  /// For controllers created with named constructors (`network`, `file`,
  /// `asset`), the source is optional and will use the source provided in
  /// the constructor.
  ///
  /// Must be called before any other methods.
  /// Throws [StateError] if already initialized, disposed, or if no source
  /// is provided and none was set in the constructor.
  Future<void> initialize({VideoSource? source, VideoPlayerOptions? options}) async {
    if (_isDisposed) {
      throw StateError('Cannot initialize a disposed controller');
    }
    if (_playerId != null) {
      throw StateError('Controller is already initialized');
    }

    // Use constructor source/options if not explicitly provided
    final effectiveSource = source ?? _initialSource;
    final effectiveOptions = options ?? _initialOptions ?? const VideoPlayerOptions();

    if (effectiveSource == null) {
      throw StateError(
        'No source provided. Either pass a source to initialize() or use a '
        'named constructor (network, file, asset).',
      );
    }

    _Logger.log(
      'Initializing player with source: ${effectiveSource.runtimeType}, autoPlay: ${effectiveOptions.autoPlay}',
      tag: 'Controller',
    );

    // Create initialization coordinator
    final coordinator = InitializationCoordinator(
      getValue: () => value,
      setValue: (v) => value = v,
      getPlayerId: () => _playerId,
      getOptions: () => _options,
      isDisposed: () => _isDisposed,
      isRetrying: () => _isRetrying,
      setRetrying: ({required isRetrying}) => _isRetrying = isRetrying,
      platform: _platform,
      errorRecoveryOptions: _errorRecoveryOptions,
      ensureInitialized: _ensureInitialized,
      onRetry: _performRetryPlayback,
      onPlay: play,
      onSeekTo: seekTo,
    );

    // Delegate to coordinator for full initialization
    final result = await coordinator.initializeWithSource(
      source: effectiveSource,
      options: effectiveOptions,
      setSource: (s) => _source = s,
      setOptions: (o) => _options = o,
      setPlayerId: (id) => _playerId = id,
    );

    // Handle result
    if (result.isPlaylist) {
      // Loaded a playlist - delegate to playlist initialization
      return initializeWithPlaylist(playlist: result.playlist!, options: result.options!);
    }

    // Complete initialization - store managers
    _errorRecovery = result.managers!.errorRecovery;
    _trackManager = result.managers!.trackManager;
    _playbackManager = result.managers!.playbackManager;
    _metadataManager = result.managers!.metadataManager;
    _pipManager = result.managers!.pipManager;
    _fullscreenManager = result.managers!.fullscreenManager;
    _castingManager = result.managers!.castingManager;
    _deviceControlsManager = result.managers!.deviceControlsManager;
    _subtitleManager = result.managers!.subtitleManager;
    _configurationManager = result.managers!.configurationManager;
    _playlistManager = result.circularManagers!.playlistManager;
    _eventCoordinator = result.circularManagers!.eventCoordinator;

    // Subscribe to platform events
    _eventCoordinator.subscribeToEvents();

    // Auto-play if requested (after managers are stored)
    if (result.autoPlay) {
      _Logger.log('Auto-playing video', tag: 'Controller');
      value = value.copyWith(playbackState: PlaybackState.playing);
      await play();
    }
  }

  /// Starts or resumes video playback.
  Future<void> play() async {
    _ensureInitialized();
    return _playbackManager.play();
  }

  /// Pauses video playback.
  Future<void> pause() async {
    _ensureInitialized();
    return _playbackManager.pause();
  }

  /// Stops playback and resets position to the beginning.
  Future<void> stop() async {
    _ensureInitialized();
    return _playbackManager.stop();
  }

  /// Seeks to the specified [position].
  Future<void> seekTo(Duration position) async {
    _ensureInitialized();
    return _playbackManager.seekTo(position);
  }

  /// Seeks forward by [duration].
  Future<void> seekForward(Duration duration) async {
    _ensureInitialized();
    return _playbackManager.seekForward(duration);
  }

  /// Seeks backward by [duration].
  Future<void> seekBackward(Duration duration) async {
    _ensureInitialized();
    return _playbackManager.seekBackward(duration);
  }

  /// Sets the playback speed.
  ///
  /// [speed] must be greater than 0.
  Future<void> setPlaybackSpeed(double speed) async {
    _ensureInitialized();
    return _playbackManager.setPlaybackSpeed(speed);
  }

  /// Sets the player volume.
  ///
  /// [volume] must be between 0.0 (muted) and 1.0 (full volume).
  /// This controls the player's internal volume, not the device volume.
  /// Use [setDeviceVolume] to control the device's media volume.
  Future<void> setVolume(double volume) async {
    _ensureInitialized();
    return _playbackManager.setVolume(volume);
  }

  /// Gets the current device media volume.
  ///
  /// Returns a value between 0.0 (muted) and 1.0 (max volume).
  /// This is the device's media/music stream volume, not the player's internal volume.
  Future<double> getDeviceVolume() {
    _ensureInitialized();
    return _deviceControlsManager.getDeviceVolume();
  }

  /// Sets the device media volume.
  ///
  /// [volume] must be between 0.0 (muted) and 1.0 (max volume).
  /// This controls the device's media/music stream volume directly, which affects
  /// all media playback on the device.
  ///
  /// On iOS, this uses AVAudioSession to control the output volume.
  /// On Android, this uses AudioManager to control the STREAM_MUSIC volume.
  ///
  /// Note: The system volume UI may be shown briefly when changing volume.
  Future<void> setDeviceVolume(double volume) async {
    _ensureInitialized();
    await _deviceControlsManager.setDeviceVolume(volume);
  }

  /// Gets the current screen brightness.
  ///
  /// Returns a value between 0.0 (dimmest) and 1.0 (brightest).
  /// On iOS/Android, this returns the current screen brightness setting.
  /// On other platforms, returns 1.0 as a default.
  Future<double> getScreenBrightness() {
    _ensureInitialized();
    return _deviceControlsManager.getScreenBrightness();
  }

  /// Sets the screen brightness.
  ///
  /// [brightness] must be between 0.0 (dimmest) and 1.0 (brightest).
  /// On iOS, this sets UIScreen.main.brightness.
  /// On Android, this sets WindowManager.LayoutParams.screenBrightness.
  ///
  /// The change is temporary and will be reset when the app is closed or
  /// when fullscreen mode is exited.
  Future<void> setScreenBrightness(double brightness) async {
    _ensureInitialized();
    await _deviceControlsManager.setScreenBrightness(brightness);
  }

  /// Sets whether the video should loop.
  Future<void> setLooping(bool looping) async {
    _ensureInitialized();
    return _configurationManager.setLooping(looping);
  }

  /// Sets the video scaling mode.
  ///
  /// Determines how the video fills the player viewport:
  /// - [VideoScalingMode.fit]: Letterbox mode, shows entire video with black bars
  /// - [VideoScalingMode.fill]: Crop mode, fills viewport while maintaining aspect ratio
  /// - [VideoScalingMode.stretch]: Stretch mode, ignores aspect ratio
  Future<void> setScalingMode(VideoScalingMode mode) async {
    _ensureInitialized();
    return _configurationManager.setScalingMode(mode);
  }

  /// Selects a subtitle track.
  ///
  /// Pass `null` to disable subtitles.
  ///
  /// Returns immediately without effect if [VideoPlayerOptions.subtitlesEnabled]
  /// was set to `false` during initialization.
  Future<void> setSubtitleTrack(SubtitleTrack? track) async {
    _ensureInitialized();
    await _trackManager.setSubtitleTrack(track);
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
  ///
  /// Example:
  /// ```dart
  /// // Switch to Flutter rendering for custom styling
  /// await controller.setSubtitleRenderMode(SubtitleRenderMode.flutter);
  ///
  /// // Switch back to native rendering
  /// await controller.setSubtitleRenderMode(SubtitleRenderMode.native);
  ///
  /// // Use auto mode (resolves based on controls mode)
  /// await controller.setSubtitleRenderMode(SubtitleRenderMode.auto);
  /// ```
  Future<void> setSubtitleRenderMode(SubtitleRenderMode mode) async {
    _ensureInitialized();
    await _trackManager.setSubtitleRenderMode(mode);
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
  /// The subtitle format is auto-detected from the file extension if not
  /// provided. Supported formats: VTT, SRT, ASS, SSA, TTML.
  ///
  /// Returns the created [ExternalSubtitleTrack] on success, or `null` if
  /// loading failed (e.g., invalid path, network error, file not found).
  ///
  /// Example:
  /// ```dart
  /// // From URL
  /// final track = await controller.addExternalSubtitle(
  ///   SubtitleSource.network(
  ///     'https://example.com/subtitles/english.vtt',
  ///     label: 'English',
  ///     language: 'en',
  ///   ),
  /// );
  ///
  /// // From local file
  /// final track = await controller.addExternalSubtitle(
  ///   SubtitleSource.file('/path/to/subtitles.srt', label: 'Spanish'),
  /// );
  ///
  /// // Auto-detect source type
  /// final track = await controller.addExternalSubtitle(
  ///   SubtitleSource.from('https://example.com/subs.vtt'),
  /// );
  ///
  /// if (track != null) {
  ///   await controller.setSubtitleTrack(track);
  /// }
  /// ```
  Future<ExternalSubtitleTrack?> addExternalSubtitle(SubtitleSource source) async {
    _ensureInitialized();
    return _subtitleManager.addExternalSubtitle(source);
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
    _ensureInitialized();
    return _subtitleManager.removeExternalSubtitle(trackId);
  }

  /// Gets all external subtitle tracks that have been added.
  ///
  /// Returns a list of [ExternalSubtitleTrack] objects representing all
  /// external subtitles that have been loaded via [addExternalSubtitle].
  /// This does not include embedded subtitle tracks from the video file.
  Future<List<ExternalSubtitleTrack>> getExternalSubtitles() async {
    _ensureInitialized();
    return _subtitleManager.getExternalSubtitles();
  }

  /// Selects an audio track.
  ///
  /// Pass `null` to reset to the default audio track.
  Future<void> setAudioTrack(AudioTrack? track) async {
    _ensureInitialized();
    await _trackManager.setAudioTrack(track);
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
    _ensureInitialized();
    return _trackManager.setVideoQuality(track);
  }

  /// Returns the available video quality tracks.
  ///
  /// For adaptive streaming content (HLS, DASH), this returns a list of
  /// available quality options. The list always includes [VideoQualityTrack.auto]
  /// as the first option.
  ///
  /// For non-adaptive content, returns a list with only [VideoQualityTrack.auto].
  Future<List<VideoQualityTrack>> getVideoQualities() async {
    _ensureInitialized();
    return _trackManager.getVideoQualities();
  }

  /// Returns the currently selected video quality track.
  ///
  /// Returns [VideoQualityTrack.auto] if automatic quality selection is active.
  Future<VideoQualityTrack> getCurrentVideoQuality() async {
    _ensureInitialized();
    return _trackManager.getCurrentVideoQuality();
  }

  /// Returns whether manual quality selection is supported for the current content.
  ///
  /// This returns `true` for adaptive streaming content (HLS, DASH) where
  /// multiple quality levels are available.
  Future<bool> isQualitySelectionSupported() async {
    _ensureInitialized();
    return _trackManager.isQualitySelectionSupported();
  }

  /// Sets whether background playback is enabled.
  ///
  /// Enables or disables background playback for the current player.
  ///
  /// When enabled, audio continues playing when the app is backgrounded.
  /// The video will pause but audio will continue.
  ///
  /// **Platform behavior:**
  /// - **iOS**: Requires `UIBackgroundModes` with `audio` in Info.plist
  /// - **Android**: Requires foreground service permission (Android 14+)
  /// - **macOS**: Background playback is **always enabled** by default.
  ///   Calling this method on macOS is a no-op and always returns `true`.
  ///   The background playback toggle button is hidden on macOS.
  /// - **Web/Windows/Linux**: Not supported
  ///
  /// Returns `true` if background playback was successfully enabled/disabled,
  /// `false` if the platform doesn't support it or isn't configured correctly.
  ///
  /// Example:
  /// ```dart
  /// // Enable background playback
  /// final success = await controller.setBackgroundPlayback(enabled: true);
  /// if (!success) {
  ///   print('Background playback not available');
  /// }
  /// ```
  Future<bool> setBackgroundPlayback({required bool enabled}) async {
    _ensureInitialized();
    return _configurationManager.setBackgroundPlayback(enabled: enabled);
  }

  /// Returns whether background playback is supported on this platform.
  ///
  /// **Platform support:**
  /// - **iOS**: `true` (requires proper Info.plist configuration)
  /// - **Android**: `true` (requires proper manifest configuration)
  /// - **macOS**: Always `true`. Background playback is always enabled on macOS
  ///   by default and cannot be disabled. The toggle button is hidden in the UI.
  /// - **Web/Windows/Linux**: `false`
  Future<bool> isBackgroundPlaybackSupported() async {
    _ensureInitialized();
    return _configurationManager.isBackgroundPlaybackSupported();
  }

  /// Returns whether background playback is available for this player.
  ///
  /// Returns `true` if the platform supports background playback and it's
  /// currently enabled.
  bool get isBackgroundPlaybackEnabled => value.isBackgroundPlaybackEnabled;

  // ==================== Platform Capabilities API ====================

  /// Gets the platform-specific feature capabilities.
  ///
  /// This method queries the native platform to determine which features are
  /// supported and available. The returned [PlatformCapabilities] object contains
  /// boolean flags for each feature, allowing the app to adapt UI and functionality.
  ///
  /// Features may be unavailable due to:
  /// - Platform limitations (e.g., Web doesn't support background playback)
  /// - Missing native dependencies (e.g., Chromecast SDK not integrated)
  /// - Runtime conditions (e.g., PiP disabled in system settings)
  /// - OS version requirements (e.g., PiP requires Android 8.0+)
  ///
  /// This method should be called once during initialization and the result
  /// can be cached. The capabilities typically don't change during app runtime.
  ///
  /// Example:
  /// ```dart
  /// final capabilities = await controller.getPlatformCapabilities();
  ///
  /// // Only show cast button if casting is supported
  /// if (capabilities.supportsCasting) {
  ///   showCastButton();
  /// }
  ///
  /// // Adapt UI based on available features
  /// if (!capabilities.supportsBackgroundPlayback) {
  ///   showWarning('Background playback not available on this platform');
  /// }
  ///
  /// // Check streaming format support
  /// if (capabilities.supportsDASH) {
  ///   loadDashStream();
  /// } else if (capabilities.supportsHLS) {
  ///   loadHlsStream();
  /// }
  ///
  /// // Log platform info for debugging
  /// print('Platform: ${capabilities.platformName}');
  /// print('Player: ${capabilities.nativePlayerType}');
  /// print('AirPlay: ${capabilities.supportsAirPlay}');
  /// print('Chromecast: ${capabilities.supportsChromecast}');
  /// ```
  Future<PlatformCapabilities> getPlatformCapabilities() => _platform.getPlatformCapabilities();

  // ==================== Battery API ====================

  /// Gets the current battery information.
  ///
  /// Returns battery level (0-100) and charging state, or `null` if battery
  /// information is not available on this platform/device.
  ///
  /// ## Platform Support
  ///
  /// - **iOS**: Full support via UIDevice battery APIs
  /// - **Android**: Full support via BatteryManager
  /// - **macOS**: Supported on MacBooks with battery (null on desktops)
  /// - **Web**: Supported in browsers with Battery Status API (Chrome, Edge)
  /// - **Windows/Linux**: Not currently implemented, returns null
  ///
  /// Example:
  /// ```dart
  /// final batteryInfo = await controller.getBatteryInfo();
  /// if (batteryInfo != null) {
  ///   print('Battery: ${batteryInfo.percentage}%');
  ///   print('Charging: ${batteryInfo.isCharging}');
  /// }
  /// ```
  Future<BatteryInfo?> getBatteryInfo() => _platform.getBatteryInfo();

  /// Stream of battery state changes.
  ///
  /// Emits [BatteryInfo] whenever the battery level or charging state changes.
  /// The stream gracefully completes if battery monitoring is not supported.
  ///
  /// Platform support is the same as [getBatteryInfo].
  ///
  /// Example:
  /// ```dart
  /// controller.batteryUpdates.listen((batteryInfo) {
  ///   print('Battery: ${batteryInfo.percentage}%');
  /// });
  /// ```
  Stream<BatteryInfo> get batteryUpdates => _platform.batteryUpdates;

  // ==================== Casting API ====================

  /// Returns whether casting is supported on this platform.
  ///
  /// ## Platform Support
  ///
  /// - **iOS/macOS**: Returns `true` (AirPlay is built-in)
  /// - **Android**: Returns `true` if Google Cast SDK is properly configured
  /// - **Web**: Returns `true` if the browser supports the Remote Playback API
  /// - **Windows/Linux**: Returns `false`
  Future<bool> isCastingSupported() async {
    _ensureInitialized();
    return _castingManager.isCastingSupported();
  }

  /// Returns the list of available cast devices.
  ///
  /// This returns the cached list from [VideoPlayerValue.availableCastDevices].
  /// The list is updated automatically via device discovery events.
  ///
  /// For real-time discovery, listen to [CastDevicesChangedEvent] via the
  /// platform event stream.
  ///
  /// Note: On some platforms (e.g., web), this list may be empty even when
  /// casting is supported, as device discovery happens during the casting
  /// prompt rather than continuously.
  List<CastDevice> get availableCastDevices => value.availableCastDevices;

  /// Starts casting to the specified device.
  ///
  /// If [device] is `null`, the platform will show a device picker dialog
  /// allowing the user to select a device. This is the recommended approach
  /// for most use cases.
  ///
  /// Returns `true` if casting started successfully, `false` if casting
  /// is not supported, not allowed (via [VideoPlayerOptions.allowCasting]),
  /// or failed to connect.
  ///
  /// ## Platform Behavior
  ///
  /// - **iOS/macOS**: Shows the AirPlay route picker (device parameter is ignored)
  /// - **Android**: If device is `null`, shows the Cast dialog; otherwise connects to the specified device
  /// - **Web**: Uses the Remote Playback API prompt
  ///
  /// Example:
  /// ```dart
  /// // Show device picker
  /// final success = await controller.startCasting();
  ///
  /// // Or connect to a specific device
  /// final devices = controller.availableCastDevices;
  /// if (devices.isNotEmpty) {
  ///   await controller.startCasting(device: devices.first);
  /// }
  /// ```
  Future<bool> startCasting({CastDevice? device}) async {
    _ensureInitialized();
    return _castingManager.startCasting(device: device);
  }

  /// Stops casting and returns playback to the local device.
  ///
  /// This disconnects from the current cast device (if any) and resumes
  /// local playback. The current playback position is preserved.
  ///
  /// Returns `true` if casting was stopped successfully, `false` if not
  /// currently casting or if the operation failed.
  Future<bool> stopCasting() async {
    _ensureInitialized();
    return _castingManager.stopCasting();
  }

  /// Returns the current casting state.
  ///
  /// This returns the cached state from [VideoPlayerValue.castState].
  /// Listen to [CastStateChangedEvent] via the platform event stream
  /// for state changes.
  CastState get castState => value.castState;

  /// Returns the currently connected cast device, if any.
  ///
  /// Returns `null` if not currently casting.
  CastDevice? get currentCastDevice => value.currentCastDevice;

  /// Returns whether the player is currently casting.
  bool get isCasting => value.isCasting;

  /// Returns video metadata (codec, resolution, bitrate, etc.).
  ///
  /// This returns the cached metadata from [VideoPlayerValue.videoMetadata]
  /// if available. To fetch fresh metadata from the platform, use
  /// [fetchVideoMetadata].
  ///
  /// Returns `null` if metadata is not available yet (player not ready or
  /// metadata not extracted).
  VideoMetadata? get videoMetadata => value.videoMetadata;

  /// Fetches video metadata from the platform.
  ///
  /// This calls the platform to get metadata directly, which is useful if
  /// you need metadata before the automatic extraction event is received.
  ///
  /// Returns `null` if the player is not ready or metadata cannot be extracted.
  Future<VideoMetadata?> fetchVideoMetadata() async {
    final metadata = await _metadataManager.fetchVideoMetadata();
    if (metadata != null) {
      value = value.copyWith(videoMetadata: metadata);
    }
    return metadata;
  }

  /// Enters Picture-in-Picture mode.
  ///
  /// Returns `true` if PiP was entered successfully, `false` if PiP is not
  /// supported, not allowed (via [VideoPlayerOptions.allowPip]), or failed.
  ///
  /// ## Platform Setup Required
  ///
  /// **Android:** Requires `android:supportsPictureInPicture="true"` in your
  /// `AndroidManifest.xml` activity declaration. When PiP is active on Android,
  /// the entire app is shown in the small PiP window. Your app should respond
  /// to `value.isPipActive` to show only the video player. Without the manifest
  /// attribute, PiP will not work and this method returns `false`.
  ///
  /// **iOS:** Requires "Audio, AirPlay, and Picture in Picture" in your app's
  /// Background Modes capability (or `UIBackgroundModes` with `audio` in
  /// `Info.plist`). iOS uses true video-only PiP where the video floats in a
  /// system-controlled window independently from the app. Without this
  /// capability, PiP will not work and this method returns `false`.
  ///
  /// See the package README for detailed setup instructions.
  Future<bool> enterPip({PipOptions options = const PipOptions()}) async {
    _ensureInitialized();
    return _pipManager.enterPip(options: options);
  }

  /// Exits Picture-in-Picture mode.
  Future<void> exitPip() async {
    _ensureInitialized();
    await _pipManager.exitPip();
  }

  /// Sets the PiP remote action buttons.
  ///
  /// These actions appear as buttons in the PiP window, allowing users to
  /// control playback without leaving the PiP view.
  ///
  /// **Platform support:**
  /// - **Android**: Full support via `RemoteAction` in `PictureInPictureParams`.
  ///   Actions appear as icon buttons in the PiP window overlay.
  /// - **iOS**: Limited support. iOS 15+ supports skip forward/backward buttons
  ///   via `AVPictureInPictureController`. Play/pause is handled automatically.
  /// - **macOS/Web/Windows/Linux**: Not supported.
  ///
  /// Pass `null` or an empty list to clear all custom actions.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Standard video controls
  /// await controller.setPipActions(PipActions.standard);
  ///
  /// // Or configure manually
  /// await controller.setPipActions([
  ///   PipAction(type: PipActionType.skipBackward, skipInterval: Duration(seconds: 10)),
  ///   PipAction(type: PipActionType.playPause),
  ///   PipAction(type: PipActionType.skipForward, skipInterval: Duration(seconds: 10)),
  /// ]);
  /// ```
  ///
  /// When an action button is tapped, a [PipActionTriggeredEvent] is emitted
  /// via the platform event stream. The controller logs these events and you
  /// can handle them in your app as needed.
  Future<void> setPipActions(List<PipAction>? actions) async {
    _ensureInitialized();
    await _pipManager.setPipActions(actions);
  }

  /// Returns whether Picture-in-Picture is supported on this device.
  ///
  /// This only checks device/platform support, not whether PiP is allowed
  /// for this player (see [VideoPlayerOptions.allowPip]). To check both,
  /// use [isPipAvailable].
  ///
  /// ## Platform Behavior
  ///
  /// **Android:** Returns `false` if the app's `AndroidManifest.xml` is missing
  /// `android:supportsPictureInPicture="true"` on the activity, or if the device
  /// is running Android 7.1 (API 25) or lower.
  ///
  /// **iOS:** Returns `false` if the device doesn't support PiP, or if the app
  /// is missing the "Audio, AirPlay, and Picture in Picture" Background Mode
  /// capability (or `UIBackgroundModes` with `audio` in `Info.plist`).
  ///
  /// See the package README for detailed setup instructions.
  Future<bool> isPipSupported() {
    _ensureInitialized();
    return _pipManager.isPipSupported();
  }

  /// Returns whether Picture-in-Picture is available for this player.
  ///
  /// Returns `true` if both the device supports PiP (see [isPipSupported]) and
  /// [VideoPlayerOptions.allowPip] is `true`.
  ///
  /// This is a convenience method that combines both checks. Use this to determine
  /// whether to show PiP controls in your UI.
  ///
  /// ## Platform Setup Required
  ///
  /// PiP requires platform-specific setup. See [enterPip] documentation for
  /// details on configuring each platform, or check the package README.
  Future<bool> isPipAvailable() {
    _ensureInitialized();
    return _pipManager.isPipAvailable();
  }

  /// Returns whether subtitles are enabled for this player.
  ///
  /// This reflects the [VideoPlayerOptions.subtitlesEnabled] setting.
  bool get subtitlesEnabled => _options.subtitlesEnabled;

  /// Sets the subtitle timing offset for synchronization.
  ///
  /// A positive [offset] delays subtitles (shows them later), while a negative
  /// [offset] shows subtitles earlier. This is useful for fixing subtitle sync
  /// issues where subtitles appear too early or too late.
  ///
  /// This adjustment is applied immediately without reloading the video.
  /// Only affects external subtitle tracks rendered by [SubtitleOverlay].
  /// Embedded subtitles rendered by native players are not affected.
  ///
  /// Example:
  /// ```dart
  /// // Subtitles appear 2 seconds too early - delay them
  /// controller.setSubtitleOffset(const Duration(seconds: 2));
  ///
  /// // Subtitles appear 1 second too late - show them earlier
  /// controller.setSubtitleOffset(const Duration(seconds: -1));
  ///
  /// // Reset to no offset
  /// controller.setSubtitleOffset(Duration.zero);
  /// ```
  void setSubtitleOffset(Duration offset) {
    value = value.copyWith(subtitleOffset: offset);
  }

  /// Returns the current subtitle timing offset.
  ///
  /// See [setSubtitleOffset] for details on how the offset affects subtitle display.
  Duration get subtitleOffset => value.subtitleOffset;

  /// Enters fullscreen mode.
  ///
  /// This hides the system UI (status bar, navigation bar) and sets
  /// the orientation based on [orientation] parameter or the
  /// `fullscreenOrientation` option if not specified.
  ///
  /// The app should respond to `value.isFullscreen` to expand the video
  /// widget to fill the screen.
  ///
  /// Returns `true` if fullscreen was entered successfully.
  Future<bool> enterFullscreen({FullscreenOrientation? orientation}) async {
    _ensureInitialized();
    return _fullscreenManager.enterFullscreen(orientation: orientation);
  }

  /// Exits fullscreen mode.
  ///
  /// This restores the system UI and orientation to normal.
  Future<void> exitFullscreen() async {
    _ensureInitialized();
    await _fullscreenManager.exitFullscreen();
  }

  /// Toggles fullscreen mode.
  Future<void> toggleFullscreen() async {
    _ensureInitialized();
    await _fullscreenManager.toggleFullscreen();
  }

  /// Sets the fullscreen state for Flutter-managed fullscreen (no native call).
  ///
  /// Use this on desktop platforms where Flutter controls handle fullscreen
  /// via route navigation rather than native fullscreen windows.
  ///
  /// This updates the [VideoPlayerValue.isFullscreen] state without triggering
  /// native fullscreen behavior (like creating a separate window on macOS).
  void setFlutterFullscreenState({required bool isFullscreen}) {
    _fullscreenManager.setFlutterFullscreenState(isFullscreen: isFullscreen);
  }

  // ==================== Orientation Lock API ====================

  /// Locks the screen orientation to the specified [orientation].
  ///
  /// This is typically used in fullscreen mode to allow users to lock the
  /// screen to a specific orientation (e.g., landscape only).
  ///
  /// The orientation lock persists until [unlockOrientation] is called or
  /// fullscreen mode is exited.
  ///
  /// Example:
  /// ```dart
  /// // Lock to landscape only
  /// await controller.lockOrientation(FullscreenOrientation.landscapeBoth);
  ///
  /// // Lock to portrait only
  /// await controller.lockOrientation(FullscreenOrientation.portraitBoth);
  /// ```
  Future<void> lockOrientation(FullscreenOrientation orientation) async {
    _ensureInitialized();
    await _fullscreenManager.lockOrientation(orientation);
  }

  /// Unlocks the screen orientation.
  ///
  /// When unlocked in fullscreen mode, the orientation follows the
  /// [VideoPlayerOptions.fullscreenOrientation] setting.
  /// When unlocked outside fullscreen, all orientations are allowed.
  Future<void> unlockOrientation() async {
    _ensureInitialized();
    await _fullscreenManager.unlockOrientation();
  }

  /// Toggles the orientation lock.
  ///
  /// If currently unlocked, locks to [FullscreenOrientation.landscapeBoth].
  /// If currently locked, unlocks the orientation.
  Future<void> toggleOrientationLock() async {
    _ensureInitialized();
    await _fullscreenManager.toggleOrientationLock();
  }

  /// Cycles through orientation lock options.
  ///
  /// Cycles through: Unlocked → Landscape Both → Landscape Left → Landscape Right → Unlocked
  ///
  /// This is useful for a toolbar button that cycles through lock states.
  Future<void> cycleOrientationLock() async {
    _ensureInitialized();
    await _fullscreenManager.cycleOrientationLock();
  }

  /// Whether the screen orientation is currently locked.
  bool get isOrientationLocked => value.isOrientationLocked;

  /// The currently locked orientation, or `null` if not locked.
  FullscreenOrientation? get lockedOrientation => value.lockedOrientation;

  /// Toggles between play and pause.
  Future<void> togglePlayPause() async {
    _ensureInitialized();
    return _playbackManager.togglePlayPause();
  }

  // ==================== Error Recovery API ====================

  /// The error recovery options for this controller.
  ErrorRecoveryOptions get errorRecoveryOptions => _errorRecoveryOptions;

  /// Whether an automatic retry is currently in progress.
  bool get isRetrying => _isRetrying;

  /// Clears the current error state and resets to ready state.
  ///
  /// This does not retry the failed operation. Use [retry] or [reinitialize]
  /// to attempt recovery.
  void clearError() {
    if (!value.hasError) return;
    value = value.copyWith(playbackState: PlaybackState.ready, clearError: true);
  }

  /// Retries the last failed operation.
  ///
  /// If the player failed during initialization, this will reinitialize.
  /// If the player failed during playback, this will attempt to resume.
  ///
  /// Returns `true` if the retry was successful, `false` otherwise.
  ///
  /// Throws [StateError] if there is no error to retry, or if the controller
  /// is disposed.
  Future<bool> retry() async {
    if (_isDisposed) {
      throw StateError('Cannot retry on a disposed controller');
    }
    if (!value.hasError) {
      throw StateError('No error to retry');
    }

    final error = value.error;
    if (error != null && !error.canRetry) {
      _Logger.log('Cannot retry: max retries exceeded', tag: 'Controller');
      return false;
    }

    _Logger.log(
      'Retrying after error (attempt ${(error?.retryCount ?? 0) + 1}/${error?.maxRetries ?? _errorRecoveryOptions.maxAutoRetries})',
      tag: 'Controller',
    );

    // Increment retry count
    final updatedError = error?.incrementRetry();

    try {
      // If player was never created, reinitialize
      if (_playerId == null && _source != null) {
        await reinitialize();
        return true;
      }

      // Otherwise, try to resume playback
      clearError();
      await play();
      return true;
    } catch (e) {
      _Logger.error('Retry failed', tag: 'Controller', error: e);
      final newError =
          updatedError?.copyWith(message: e.toString(), originalError: e) ??
          VideoPlayerError.fromCode(message: e.toString());
      value = value.copyWith(playbackState: PlaybackState.error, errorMessage: e.toString(), error: newError);
      return false;
    }
  }

  /// Cancels any pending automatic retry.
  ///
  /// This stops any scheduled retry attempts and resets the retrying state.
  void cancelAutoRetry() {
    _errorRecovery.cancelRetryTimer();
    _isRetrying = false;
  }

  /// Reinitializes the player with the original source.
  ///
  /// This disposes the current player and creates a new one with the same
  /// source and options that were used in the initial [initialize] call.
  ///
  /// Use this for complete recovery from fatal errors or when the player
  /// is in an unrecoverable state.
  ///
  /// Throws [StateError] if the controller was never initialized or is disposed.
  Future<void> reinitialize() async {
    if (_isDisposed) {
      throw StateError('Cannot reinitialize a disposed controller');
    }
    if (_source == null) {
      throw StateError('Cannot reinitialize: no source available');
    }

    _Logger.log('Reinitializing player', tag: 'Controller');

    // Clean up existing player
    _errorRecovery.cancelRetryTimer();
    if (_playerId != null) {
      await _eventCoordinator.dispose();
    }

    if (_playerId != null) {
      try {
        await _platform.dispose(_playerId!);
      } catch (e) {
        _Logger.error('Error disposing player during reinitialize', tag: 'Controller', error: e);
      }
      _playerId = null;
    }

    // Reset state
    value = const VideoPlayerValue();

    // Reinitialize with original source and options
    await initialize(source: _source, options: _options);
  }

  void _ensureInitialized() {
    if (_isDisposed) {
      throw StateError('Controller has been disposed');
    }
    if (_playerId == null) {
      throw StateError('Controller has not been initialized');
    }
  }

  /// Performs the actual playback retry - called by ErrorRecoveryManager.
  Future<void> _performRetryPlayback() async {
    if (_isDisposed || _playerId == null) return;
    if (_isRetrying) return; // Prevent concurrent retries

    _isRetrying = true;
    _Logger.log('Attempting network recovery (retry ${value.networkRetryCount})', tag: 'Controller');

    try {
      // Seek to current position to trigger a reload
      final currentPosition = value.position;
      await _platform.seekTo(_playerId!, currentPosition);

      // Try to resume playback
      await _platform.play(_playerId!);
    } catch (e) {
      _Logger.log('Retry attempt failed: $e', tag: 'Controller');
      // The native layer will send another NetworkErrorEvent if it fails
    } finally {
      _isRetrying = false;
    }
  }

  // Playlist management

  /// Initializes the player with a playlist.
  ///
  /// The playlist will start playing from [Playlist.initialIndex].
  Future<void> initializeWithPlaylist({
    required Playlist playlist,
    VideoPlayerOptions options = const VideoPlayerOptions(),
  }) async {
    if (_isDisposed) throw StateError('Cannot perform operation on disposed controller');
    _Logger.log('Initializing with playlist (${playlist.length} items)', tag: 'Controller');

    _options = options;

    // Create initialization coordinator
    final coordinator = InitializationCoordinator(
      getValue: () => value,
      setValue: (v) => value = v,
      getPlayerId: () => _playerId,
      getOptions: () => _options,
      isDisposed: () => _isDisposed,
      isRetrying: () => _isRetrying,
      setRetrying: ({required isRetrying}) => _isRetrying = isRetrying,
      platform: _platform,
      errorRecoveryOptions: _errorRecoveryOptions,
      ensureInitialized: _ensureInitialized,
      onRetry: _performRetryPlayback,
      onPlay: play,
      onSeekTo: seekTo,
    );

    // Initialize all managers
    final managers = coordinator.initializeManagers();
    final circularManagers = coordinator.initializeCircularDependencyManagers(
      playbackManager: managers.playbackManager,
      trackManager: managers.trackManager,
      errorRecoveryManager: managers.errorRecovery,
      setPlayerId: (id) => _playerId = id,
      setSource: (s) => _source = s,
    );

    // Store managers
    _errorRecovery = managers.errorRecovery;
    _trackManager = managers.trackManager;
    _playbackManager = managers.playbackManager;
    _metadataManager = managers.metadataManager;
    _pipManager = managers.pipManager;
    _fullscreenManager = managers.fullscreenManager;
    _castingManager = managers.castingManager;
    _deviceControlsManager = managers.deviceControlsManager;
    _subtitleManager = managers.subtitleManager;
    _configurationManager = managers.configurationManager;
    _playlistManager = circularManagers.playlistManager;
    _eventCoordinator = circularManagers.eventCoordinator;

    // Subscribe to events and initialize playlist
    _eventCoordinator.subscribeToEvents();
    await _playlistManager.initializeWithPlaylist(playlist: playlist, options: options);
  }

  /// Moves to the next track in the playlist.
  ///
  /// Returns `true` if moved to next track, `false` if at end of playlist
  /// (and repeat mode is [PlaylistRepeatMode.none]).
  Future<bool> playlistNext() async {
    _ensureInitialized();
    return _playlistManager.playlistNext();
  }

  /// Moves to the previous track in the playlist.
  ///
  /// Returns `true` if moved to previous track, `false` if already at
  /// beginning of playlist.
  Future<bool> playlistPrevious() async {
    _ensureInitialized();
    return _playlistManager.playlistPrevious();
  }

  /// Jumps to a specific track in the playlist by index.
  Future<void> playlistJumpTo(int index) async {
    _ensureInitialized();
    return _playlistManager.playlistJumpTo(index);
  }

  /// Sets the playlist repeat mode.
  void setPlaylistRepeatMode(PlaylistRepeatMode mode) {
    _ensureInitialized();
    _playlistManager.setPlaylistRepeatMode(mode);
  }

  /// Toggles playlist shuffle mode.
  ///
  /// When shuffle is enabled, tracks play in random order.
  /// When disabled, tracks play in original order.
  void setPlaylistShuffle({required bool enabled}) {
    _ensureInitialized();
    _playlistManager.setPlaylistShuffle(enabled: enabled);
  }

  /// Sets the media metadata for platform media controls.
  ///
  /// This metadata is displayed in:
  /// - iOS/macOS: Control Center and Lock Screen (via MPNowPlayingInfoCenter)
  /// - Android: Media notification and Lock Screen (via MediaSession)
  /// - Web: Browser media controls (via Media Session API)
  ///
  /// The metadata is only shown when background playback is enabled
  /// ([VideoPlayerOptions.allowBackgroundPlayback] is `true`).
  ///
  /// Pass [MediaMetadata.empty] to clear any previously set metadata.
  ///
  /// Example:
  /// ```dart
  /// await controller.setMediaMetadata(const MediaMetadata(
  ///   title: 'My Video',
  ///   artist: 'Channel Name',
  ///   artworkUrl: 'https://example.com/thumbnail.jpg',
  /// ));
  /// ```
  Future<void> setMediaMetadata(MediaMetadata metadata) async {
    _ensureInitialized();
    await _metadataManager.setMediaMetadata(metadata);
  }

  // ==================== Chapter Navigation ====================

  /// Available chapters in the video.
  ///
  /// Returns an empty list if no chapters are available.
  /// Chapters are sorted by [Chapter.startTime] in ascending order.
  List<Chapter> get chapters => value.chapters;

  /// The chapter at the current playback position.
  ///
  /// Returns `null` if no chapters are available or if the current position
  /// is before the first chapter.
  Chapter? get currentChapter => value.currentChapter;

  /// Whether the video has chapter information available.
  bool get hasChapters => value.hasChapters;

  /// Seeks to the start of the specified chapter.
  ///
  /// This is a convenience method equivalent to calling
  /// `seekTo(chapter.startTime)`.
  ///
  /// Example:
  /// ```dart
  /// if (controller.hasChapters) {
  ///   // Seek to the first chapter
  ///   await controller.seekToChapter(controller.chapters.first);
  /// }
  /// ```
  Future<void> seekToChapter(Chapter chapter) async {
    _ensureInitialized();
    await _metadataManager.seekToChapter(chapter);
  }

  /// Seeks to the next chapter, if available.
  ///
  /// If already in the last chapter or no chapters are available, does nothing.
  /// Returns `true` if a seek was performed, `false` otherwise.
  Future<bool> seekToNextChapter() async {
    _ensureInitialized();
    return _metadataManager.seekToNextChapter();
  }

  /// Seeks to the previous chapter, if available.
  ///
  /// If at the beginning of a chapter (within first 3 seconds), seeks to the
  /// previous chapter. Otherwise, seeks to the start of the current chapter.
  /// Returns `true` if a seek was performed, `false` otherwise.
  Future<bool> seekToPreviousChapter() async {
    _ensureInitialized();
    return _metadataManager.seekToPreviousChapter();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    // Only dispose if initialized (managers exist)
    if (_playerId != null) {
      final coordinator = DisposalCoordinator(
        getPlayerId: () => _playerId,
        platform: _platform,
        eventCoordinator: _eventCoordinator,
        errorRecovery: _errorRecovery,
        playlistManager: _playlistManager,
        playbackManager: _playbackManager,
      );

      await coordinator.disposeAll();
    }

    _playerId = null;
    value = value.copyWith(playbackState: PlaybackState.disposed);
    super.dispose();
  }

  // ============================================================================
  // Caption Compatibility Layer (video_player compatibility)
  // ============================================================================

  /// Sets closed captions for the video.
  ///
  /// This method is provided for compatibility with Flutter's video_player library.
  /// Pass `null` to disable captions, or a [Future<ClosedCaptionFile>] to enable them.
  ///
  /// **Note**: This is a compatibility stub. Full implementation requires converting
  /// the caption data to a subtitle format and loading it. For production use,
  /// prefer using [addExternalSubtitle] with a proper [SubtitleSource] which
  /// provides more features and format support.
  ///
  /// Throws [StateError] if the controller is not initialized.
  Future<void> setClosedCaptionFile(Future<ClosedCaptionFile>? closedCaptionFile) async {
    _ensureInitialized();

    if (closedCaptionFile == null) {
      await setSubtitleTrack(null);
      return;
    }

    // Wait for captions to load (for API compatibility)
    await closedCaptionFile;

    // TODO(pro_video_player): Implement full caption loading.
    // This would require either:
    // 1. Adding SubtitleSource.memory() constructor for in-memory content
    // 2. Writing captions to a temporary file and using SubtitleSource.file()
    // 3. Adding a new platform method for loading caption data directly
    //
    // For now, this is a compatibility stub that succeeds without actually
    // loading the captions. Users migrating from video_player should use
    // addExternalSubtitle() with a proper SubtitleSource instead.
  }

  /// Sets the caption offset.
  ///
  /// This adjusts the timing of captions by the given [offset].
  /// Positive values delay captions, negative values advance them.
  ///
  /// This method is provided for compatibility with Flutter's video_player library.
  /// For new code, the method name is the same so you can use it directly.
  ///
  /// Throws [StateError] if the controller is not initialized.
  Future<void> setCaptionOffset(Duration offset) async {
    _ensureInitialized();
    await _platform.setSubtitleOffset(_playerId!, offset);
  }
}
