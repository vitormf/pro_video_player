import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Mixin that provides standard callbacks for controller managers.
///
/// All manager classes (FullscreenManager, TrackManager, ConfigurationManager,
/// PlaybackManager) share these common dependencies for accessing and modifying
/// the video player state.
///
/// Note: [getOptions] is optional as not all managers require video player options.
mixin ManagerCallbacks {
  /// Gets the current video player value.
  VideoPlayerValue Function() get getValue;

  /// Updates the video player value.
  void Function(VideoPlayerValue) get setValue;

  /// Gets the player ID (null if not initialized).
  int? Function() get getPlayerId;

  /// Gets the video player options (optional - not all managers need this).
  VideoPlayerOptions Function()? get getOptions => null;

  /// Platform implementation for operations.
  ProVideoPlayerPlatform get platform;

  /// Ensures the controller is initialized before operations.
  void Function() get ensureInitialized;
}
