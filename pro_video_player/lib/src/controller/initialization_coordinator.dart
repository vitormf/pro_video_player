import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'casting_manager.dart';
import 'configuration_manager.dart';
import 'device_controls_manager.dart';
import 'error_recovery_manager.dart';
import 'event_coordinator.dart';
import 'fullscreen_manager.dart';
import 'metadata_manager.dart';
import 'pip_manager.dart';
import 'playback_manager.dart';
import 'playlist_manager.dart';
import 'subtitle_manager.dart';
import 'track_manager.dart';

// Alias for cleaner code
typedef _Logger = ProVideoPlayerLogger;

/// Coordinates the initialization of all manager instances.
///
/// This class encapsulates the creation and wiring of all specialized managers,
/// ensuring they're initialized with the correct dependencies and in the right order.
class InitializationCoordinator {
  /// Creates an initialization coordinator.
  InitializationCoordinator({
    required this.getValue,
    required this.setValue,
    required this.getPlayerId,
    required this.getOptions,
    required this.isDisposed,
    required this.isRetrying,
    required this.setRetrying,
    required this.platform,
    required this.errorRecoveryOptions,
    required this.ensureInitialized,
    required this.onRetry,
    required this.onPlay,
    required this.onSeekTo,
  });

  /// Callback to get current player value.
  final VideoPlayerValue Function() getValue;

  /// Callback to update player value.
  final void Function(VideoPlayerValue) setValue;

  /// Callback to get current player ID.
  final int? Function() getPlayerId;

  /// Callback to get current player options.
  final VideoPlayerOptions Function() getOptions;

  /// Callback to check if controller is disposed.
  final bool Function() isDisposed;

  /// Callback to check if controller is retrying.
  final bool Function() isRetrying;

  /// Callback to set retrying state.
  final void Function({required bool isRetrying}) setRetrying;

  /// Platform instance for making platform calls.
  final ProVideoPlayerPlatform platform;

  /// Error recovery options.
  final ErrorRecoveryOptions errorRecoveryOptions;

  /// Callback to ensure controller is initialized.
  final void Function() ensureInitialized;

  /// Callback to retry playback.
  final Future<void> Function() onRetry;

  /// Callback to start playback.
  final Future<void> Function() onPlay;

  /// Callback to seek to a position.
  final Future<void> Function(Duration) onSeekTo;

  /// Handles the complete initialization flow including source handling.
  ///
  /// This method orchestrates the entire initialization process:
  /// - Handles playlist sources (loading and converting)
  /// - Creates the platform player
  /// - Initializes all managers
  /// - Subscribes to events
  /// - Handles auto-play and auto-subtitle discovery
  Future<InitializationResult> initializeWithSource({
    required VideoSource source,
    required VideoPlayerOptions options,
    required void Function(VideoSource) setSource,
    required void Function(VideoPlayerOptions) setOptions,
    required void Function(int?) setPlayerId,
  }) async {
    // Handle playlist video sources
    if (source is PlaylistVideoSource) {
      _Logger.log('Loading playlist from URL: ${source.url}', tag: 'InitCoordinator');

      try {
        final loader = PlaylistLoader();
        final result = await loader.loadAndConvert(source);

        if (result is Playlist) {
          // It's a multi-video playlist - return for playlist initialization
          _Logger.log('Playlist loaded with ${result.length} items', tag: 'InitCoordinator');
          return InitializationResult.playlist(result, options);
        } else if (result is VideoSource) {
          // It's an HLS adaptive stream, treat as single video
          _Logger.log('Detected HLS adaptive stream, treating as single video', tag: 'InitCoordinator');
          source = result;
        } else {
          throw Exception('Invalid playlist result type');
        }
      } catch (e) {
        _Logger.error('Failed to load playlist', tag: 'InitCoordinator', error: e);
        rethrow;
      }
    }

    // Store source and options
    setSource(source);
    setOptions(options);

    // Update state to initializing
    setValue(getValue().copyWith(playbackState: PlaybackState.initializing, clearError: true));

    try {
      // Create platform player
      final playerId = await platform.create(source: source, options: options);
      _Logger.log('Player created with ID: $playerId', tag: 'InitCoordinator');
      setPlayerId(playerId);

      // Notify that player is created (allows UI to show player view)
      setValue(getValue().copyWith(playbackState: PlaybackState.buffering));

      // Initialize all managers
      final managers = initializeManagers();
      final circularManagers = initializeCircularDependencyManagers(
        playbackManager: managers.playbackManager,
        trackManager: managers.trackManager,
        errorRecoveryManager: managers.errorRecovery,
        setPlayerId: setPlayerId,
        setSource: setSource,
      );

      // Don't subscribe to events here - subscription happens lazily when needed
      // This prevents test hanging issues with ValueListenableBuilder widgets

      // Update state to ready
      setValue(
        getValue().copyWith(
          playbackState: PlaybackState.ready,
          playbackSpeed: options.playbackSpeed,
          volume: options.volume,
          isLooping: options.looping,
          currentSubtitleRenderMode: options.subtitleRenderMode,
        ),
      );

      _Logger.log('Player initialized successfully', tag: 'InitCoordinator');

      // Auto-discover subtitles for local file sources
      if (options.autoDiscoverSubtitles && options.subtitlesEnabled && source is FileVideoSource) {
        await managers.subtitleManager.discoverAndAddSubtitles(source.path, options.subtitleDiscoveryMode);
      }

      return InitializationResult.complete(managers, circularManagers, autoPlay: options.autoPlay);
    } catch (e) {
      _Logger.error('Failed to initialize player', tag: 'InitCoordinator', error: e);
      setValue(getValue().copyWith(playbackState: PlaybackState.error, errorMessage: e.toString()));
      rethrow;
    }
  }

  /// Initializes all managers and returns them.
  ///
  /// Managers are created in dependency order (managers that other managers
  /// depend on are created first).
  ManagerSet initializeManagers() {
    // Initialize error recovery manager
    final errorRecovery = ErrorRecoveryManager(
      options: errorRecoveryOptions,
      getValue: getValue,
      setValue: setValue,
      isDisposed: isDisposed,
      getPlayerId: getPlayerId,
      platform: platform,
      onRetry: onRetry,
    );

    // Initialize track manager
    final trackManager = TrackManager(
      getValue: getValue,
      setValue: setValue,
      getPlayerId: getPlayerId,
      getOptions: getOptions,
      platform: platform,
      ensureInitialized: ensureInitialized,
    );

    // Initialize playback manager (must be before metadata manager for seekTo callback)
    final playbackManager = PlaybackManager(
      getValue: getValue,
      setValue: setValue,
      getPlayerId: getPlayerId,
      platform: platform,
      ensureInitialized: ensureInitialized,
    );

    // Initialize metadata manager
    final metadataManager = MetadataManager(
      getValue: getValue,
      getPlayerId: getPlayerId,
      platform: platform,
      ensureInitialized: ensureInitialized,
      onSeekTo: playbackManager.seekTo,
    );

    // Initialize PiP manager
    final pipManager = PipManager(
      getPlayerId: getPlayerId,
      getOptions: getOptions,
      platform: platform,
      ensureInitialized: ensureInitialized,
    );

    // Initialize fullscreen manager
    final fullscreenManager = FullscreenManager(
      getValue: getValue,
      setValue: setValue,
      getPlayerId: getPlayerId,
      getOptions: getOptions,
      platform: platform,
      ensureInitialized: ensureInitialized,
    );

    // Initialize casting manager
    final castingManager = CastingManager(
      getPlayerId: getPlayerId,
      getOptions: getOptions,
      platform: platform,
      ensureInitialized: ensureInitialized,
    );

    // Initialize device controls manager
    final deviceControlsManager = DeviceControlsManager(platform: platform, ensureInitialized: ensureInitialized);

    // Initialize subtitle manager
    final subtitleManager = SubtitleManager(
      getPlayerId: getPlayerId,
      getOptions: getOptions,
      platform: platform,
      ensureInitialized: ensureInitialized,
    );

    // Initialize configuration manager
    final configurationManager = ConfigurationManager(
      getValue: getValue,
      setValue: setValue,
      getPlayerId: getPlayerId,
      platform: platform,
      ensureInitialized: ensureInitialized,
    );

    // Playlist manager and event coordinator are created separately and passed in
    // because they have circular dependencies with the controller's methods

    return ManagerSet(
      errorRecovery: errorRecovery,
      trackManager: trackManager,
      playbackManager: playbackManager,
      metadataManager: metadataManager,
      pipManager: pipManager,
      fullscreenManager: fullscreenManager,
      castingManager: castingManager,
      deviceControlsManager: deviceControlsManager,
      subtitleManager: subtitleManager,
      configurationManager: configurationManager,
    );
  }

  /// Creates playlist manager and event coordinator with circular dependencies.
  ///
  /// These managers depend on controller methods (onPlay, onSeekTo) and other
  /// managers, so they're created separately after the initial manager set.
  CircularDependencyManagers initializeCircularDependencyManagers({
    required PlaybackManager playbackManager,
    required TrackManager trackManager,
    required ErrorRecoveryManager errorRecoveryManager,
    required void Function(int?) setPlayerId,
    required void Function(VideoSource) setSource,
  }) {
    // Initialize playlist manager
    final playlistManager = PlaylistManager(
      getValue: getValue,
      setValue: setValue,
      getOptions: getOptions,
      getPlayerId: getPlayerId,
      setPlayerId: setPlayerId,
      setSource: setSource,
      platform: platform,
      onPlay: onPlay,
    );

    // Initialize event coordinator
    final eventCoordinator = EventCoordinator(
      getValue: getValue,
      setValue: setValue,
      getPlayerId: getPlayerId,
      getOptions: getOptions,
      isDisposed: isDisposed,
      isRetrying: isRetrying,
      setRetrying: setRetrying,
      platform: platform,
      playbackManager: playbackManager,
      trackManager: trackManager,
      errorRecoveryManager: errorRecoveryManager,
      playlistManager: playlistManager,
      onSeekTo: onSeekTo,
      onPlay: onPlay,
    );

    // Wire up circular dependency: playlist manager needs to subscribe to events
    playlistManager.eventSubscriptionCallback = eventCoordinator.subscribeToEvents;

    return CircularDependencyManagers(playlistManager: playlistManager, eventCoordinator: eventCoordinator);
  }
}

/// Container for all manager instances (except circular dependency managers).
class ManagerSet {
  /// Creates a manager set.
  const ManagerSet({
    required this.errorRecovery,
    required this.trackManager,
    required this.playbackManager,
    required this.metadataManager,
    required this.pipManager,
    required this.fullscreenManager,
    required this.castingManager,
    required this.deviceControlsManager,
    required this.subtitleManager,
    required this.configurationManager,
  });

  /// Error recovery manager instance.
  final ErrorRecoveryManager errorRecovery;

  /// Track manager instance.
  final TrackManager trackManager;

  /// Playback manager instance.
  final PlaybackManager playbackManager;

  /// Metadata manager instance.
  final MetadataManager metadataManager;

  /// PiP manager instance.
  final PipManager pipManager;

  /// Fullscreen manager instance.
  final FullscreenManager fullscreenManager;

  /// Casting manager instance.
  final CastingManager castingManager;

  /// Device controls manager instance.
  final DeviceControlsManager deviceControlsManager;

  /// Subtitle manager instance.
  final SubtitleManager subtitleManager;

  /// Configuration manager instance.
  final ConfigurationManager configurationManager;
}

/// Container for managers with circular dependencies.
class CircularDependencyManagers {
  /// Creates a circular dependency managers container.
  const CircularDependencyManagers({required this.playlistManager, required this.eventCoordinator});

  /// Playlist manager instance.
  final PlaylistManager playlistManager;

  /// Event coordinator instance.
  final EventCoordinator eventCoordinator;
}

/// Result of initialization, indicating whether it completed or needs playlist handling.
class InitializationResult {
  const InitializationResult._({
    this.managers,
    this.circularManagers,
    this.playlist,
    this.options,
    this.autoPlay = false,
  });

  /// Initialization completed successfully.
  factory InitializationResult.complete(
    ManagerSet managers,
    CircularDependencyManagers circularManagers, {
    bool autoPlay = false,
  }) => InitializationResult._(managers: managers, circularManagers: circularManagers, autoPlay: autoPlay);

  /// Loaded a playlist that needs playlist-specific initialization.
  factory InitializationResult.playlist(Playlist playlist, VideoPlayerOptions options) =>
      InitializationResult._(playlist: playlist, options: options);

  /// Manager instances (null if this is a playlist result).
  final ManagerSet? managers;

  /// Circular dependency managers (null if this is a playlist result).
  final CircularDependencyManagers? circularManagers;

  /// Playlist instance (null if this is a complete result).
  final Playlist? playlist;

  /// Video player options (null if this is a complete result).
  final VideoPlayerOptions? options;

  /// Whether auto-play is enabled.
  final bool autoPlay;

  /// Whether this result represents a playlist that needs handling.
  bool get isPlaylist => playlist != null;

  /// Whether this result represents completed initialization.
  bool get isComplete => managers != null;
}
