import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'error_recovery_manager.dart';
import 'event_coordinator.dart';
import 'playback_manager.dart';
import 'playlist_manager.dart';

/// Coordinates the disposal of all manager instances.
///
/// This class encapsulates the cleanup logic for all specialized managers,
/// ensuring they're disposed in the correct order to prevent resource leaks.
class DisposalCoordinator {
  /// Creates a disposal coordinator.
  const DisposalCoordinator({
    required this.getPlayerId,
    required this.platform,
    required this.eventCoordinator,
    required this.errorRecovery,
    required this.playlistManager,
    required this.playbackManager,
  });

  /// Callback to get current player ID.
  final int? Function() getPlayerId;

  /// Platform instance for making platform calls.
  final ProVideoPlayerPlatform platform;

  /// Event coordinator to dispose.
  final EventCoordinator eventCoordinator;

  /// Error recovery manager to dispose.
  final ErrorRecoveryManager errorRecovery;

  /// Playlist manager to dispose.
  final PlaylistManager playlistManager;

  /// Playback manager to dispose.
  final PlaybackManager playbackManager;

  /// Disposes all managers and platform resources.
  ///
  /// Managers are disposed in reverse dependency order (dependent managers
  /// are disposed first, then their dependencies).
  Future<void> disposeAll() async {
    final playerId = getPlayerId();

    // Dispose managers (only if initialized)
    if (playerId != null) {
      // Dispose event coordinator first (stops listening to events)
      await eventCoordinator.dispose();

      // Dispose other managers
      errorRecovery.dispose();
      playlistManager.dispose();
      playbackManager.dispose();
    }

    // Dispose platform player
    if (playerId != null) {
      await platform.dispose(playerId);
    }
  }
}
