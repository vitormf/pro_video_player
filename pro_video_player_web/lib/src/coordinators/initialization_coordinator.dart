import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:web/web.dart' as web;

import '../abstractions/media_session_interface.dart';
import '../abstractions/navigator_interface.dart';
import '../abstractions/video_element_interface.dart';
import '../abstractions/wake_lock_interface.dart';
import '../manager_callbacks.dart';
import '../managers/audio_track_manager.dart';
import '../managers/casting_manager.dart';
import '../managers/dash_manager.dart';
import '../managers/event_listener_manager.dart';
import '../managers/hls_manager.dart';
import '../managers/media_session_manager.dart';
import '../managers/metadata_manager.dart';
import '../managers/network_resilience_manager.dart';
import '../managers/playback_control_manager.dart';
import '../managers/quality_manager.dart';
import '../managers/subtitle_manager.dart';
import '../managers/video_source_manager.dart';
import '../managers/wake_lock_manager.dart';

/// Coordinates the initialization of all web video player managers.
///
/// This coordinator encapsulates the creation and wiring of all specialized
/// managers, ensuring they're initialized with correct dependencies.
///
/// Uses static methods to provide a stateless initialization utility.
// ignore: avoid_classes_with_only_static_members - Necessary: provides namespace for initialization coordination logic
abstract final class WebInitializationCoordinator {
  /// Creates all manager instances.
  ///
  /// Initializes and wires all specialized managers with their dependencies,
  /// setting up the complete video player management infrastructure.
  ///
  /// Parameters:
  /// - [emitEvent]: Callback for emitting video player events
  /// - [videoElement]: HTML video element (VideoElementInterface or HTMLVideoElement)
  /// - [options]: Player configuration options
  /// - [source]: Initial video source to load
  ///
  /// Returns a map of manager type to instance for easy access by type.
  static Map<Type, dynamic> createManagers({
    required EventEmitter emitEvent,
    required Object videoElement,
    required VideoPlayerOptions options,
    required VideoSource source,
  }) {
    // Support both mock elements (VideoElementInterface) and real browser elements (HTMLVideoElement)
    // Mock elements are used directly, real elements are wrapped in BrowserVideoElement
    final VideoElementInterface element;
    if (videoElement is VideoElementInterface) {
      element = videoElement;
    } else if (videoElement is web.HTMLVideoElement) {
      element = BrowserVideoElement(videoElement);
    } else {
      throw ArgumentError('videoElement must be either VideoElementInterface or HTMLVideoElement');
    }

    // Create source and playback managers first (no dependencies)
    final sourceManager = VideoSourceManager(emitEvent: emitEvent, videoElement: element);

    final playbackManager = PlaybackControlManager(emitEvent: emitEvent, videoElement: element);

    // Create event listener manager
    final eventListenerManager = EventListenerManager(
      emitEvent: emitEvent,
      videoElement: element,
      onMetadataLoaded: () {
        // Callback will be wired after all managers created
      },
      getDuration: playbackManager.getDuration,
      getPosition: playbackManager.getPosition,
    );

    // Create streaming managers
    final hlsManager = HlsManager(emitEvent: emitEvent, videoElement: element);

    final dashManager = DashManager(emitEvent: emitEvent, videoElement: element);

    // Create coordination managers (depend on streaming managers)
    final qualityManager = QualityManager(emitEvent: emitEvent, videoElement: element);
    qualityManager
      ..hlsManager = hlsManager
      ..dashManager = dashManager;

    final audioTrackManager = AudioTrackManager(emitEvent: emitEvent, videoElement: element);
    audioTrackManager
      ..hlsManager = hlsManager
      ..dashManager = dashManager;

    final subtitleManager = SubtitleManager(emitEvent: emitEvent, videoElement: element);
    subtitleManager
      ..hlsManager = hlsManager
      ..dashManager = dashManager;

    // Create feature managers
    final castingManager = CastingManager(
      emitEvent: emitEvent,
      videoElement: element,
      allowCasting: options.allowCasting,
    );

    final wakeLockInterface = BrowserWakeLock(navigator: web.window.navigator);
    final wakeLockManager = WakeLockManager(
      emitEvent: emitEvent,
      videoElement: element,
      wakeLock: wakeLockInterface,
      preventScreenSleep: options.preventScreenSleep,
    );

    final mediaSessionInterface = BrowserMediaSession(navigator: web.window.navigator);
    final mediaSessionManager = MediaSessionManager(
      emitEvent: emitEvent,
      videoElement: element,
      mediaSession: mediaSessionInterface,
    );

    // Set up media session action handlers
    mediaSessionManager.setupActionHandlers(
      onPlay: playbackManager.play,
      onPause: () async => playbackManager.pause(),
      onStop: () async => playbackManager.stop(),
    );

    final metadataManager = MetadataManager(emitEvent: emitEvent, videoElement: element);

    final navigatorInterface = BrowserNavigator(navigator: web.window.navigator, window: web.window);
    final networkManager = NetworkResilienceManager(
      emitEvent: emitEvent,
      videoElement: element,
      navigator: navigatorInterface,
    );

    return {
      VideoSourceManager: sourceManager,
      PlaybackControlManager: playbackManager,
      EventListenerManager: eventListenerManager,
      HlsManager: hlsManager,
      DashManager: dashManager,
      QualityManager: qualityManager,
      AudioTrackManager: audioTrackManager,
      SubtitleManager: subtitleManager,
      CastingManager: castingManager,
      WakeLockManager: wakeLockManager,
      MediaSessionManager: mediaSessionManager,
      MetadataManager: metadataManager,
      NetworkResilienceManager: networkManager,
    };
  }
}
