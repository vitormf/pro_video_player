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

/// Coordinates the disposal of all web video player managers.
///
/// This coordinator ensures managers are disposed in the correct order
/// to prevent resource leaks and ensure clean shutdown.
///
/// Uses static methods to provide a stateless coordination utility.
// ignore: avoid_classes_with_only_static_members - Necessary: provides namespace for disposal coordination logic
abstract final class WebDisposalCoordinator {
  /// Disposes all managers in the correct order.
  ///
  /// Order is important:
  /// 1. Event listeners (stop receiving events)
  /// 2. Wake lock (release system resources)
  /// 3. Media session (clean up browser integration)
  /// 4. Casting (disconnect if active)
  /// 5. Streaming managers (destroy JS instances)
  /// 6. Coordination managers (clean up references)
  /// 7. Core managers (playback, source, metadata, network)
  static void disposeAll(Map<Type, dynamic> managers) {
    // 1. Stop event listeners first
    final eventManager = managers[EventListenerManager] as EventListenerManager?;
    eventManager?.dispose();

    // 2. Release wake lock
    final wakeManager = managers[WakeLockManager] as WakeLockManager?;
    wakeManager?.dispose();

    // 3. Clean up media session
    final mediaManager = managers[MediaSessionManager] as MediaSessionManager?;
    mediaManager?.dispose();

    // 4. Clean up casting
    final castManager = managers[CastingManager] as CastingManager?;
    castManager?.dispose();

    // 5. Destroy streaming players (HLS.js, dash.js)
    final hlsManager = managers[HlsManager] as HlsManager?;
    hlsManager?.dispose();

    final dashManager = managers[DashManager] as DashManager?;
    dashManager?.dispose();

    // 6. Dispose coordination managers
    final qualityManager = managers[QualityManager] as QualityManager?;
    qualityManager?.dispose();

    final audioManager = managers[AudioTrackManager] as AudioTrackManager?;
    audioManager?.dispose();

    final subtitleManager = managers[SubtitleManager] as SubtitleManager?;
    subtitleManager?.dispose();

    // 7. Dispose core managers
    final playbackManager = managers[PlaybackControlManager] as PlaybackControlManager?;
    playbackManager?.dispose();

    final sourceManager = managers[VideoSourceManager] as VideoSourceManager?;
    sourceManager?.dispose();

    final metadataManager = managers[MetadataManager] as MetadataManager?;
    metadataManager?.dispose();

    final networkManager = managers[NetworkResilienceManager] as NetworkResilienceManager?;
    networkManager?.dispose();

    // Clear the map
    managers.clear();
  }
}
