import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Manages casting functionality for the video player.
///
/// This manager handles:
/// - Casting support detection
/// - Starting/stopping casting
/// - Cast device management
class CastingManager {
  /// Creates a casting manager with dependency injection via callbacks.
  CastingManager({
    required this.getPlayerId,
    required this.getOptions,
    required this.platform,
    required this.ensureInitialized,
  });

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Gets the video player options.
  final VideoPlayerOptions Function() getOptions;

  /// Platform implementation for casting operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

  /// Returns whether casting is supported on the current platform and allowed by options.
  ///
  /// This checks both platform capabilities and [VideoPlayerOptions.allowCasting].
  /// Returns `false` if casting is disabled via options, even if the platform supports it.
  Future<bool> isCastingSupported() async {
    if (!getOptions().allowCasting) {
      return false;
    }
    return platform.isCastingSupported();
  }

  /// Starts casting to the specified device.
  ///
  /// If [device] is `null`, the platform will show a device picker dialog
  /// allowing the user to select a device. This is the recommended approach
  /// for most use cases.
  ///
  /// Returns `true` if casting started successfully, `false` if casting
  /// is not supported, not allowed, or failed to connect.
  ///
  /// Returns `false` immediately if casting is disabled via [VideoPlayerOptions.allowCasting].
  Future<bool> startCasting({CastDevice? device}) async {
    ensureInitialized();

    // Gracefully handle disabled casting
    if (!getOptions().allowCasting) {
      return false;
    }

    return platform.startCasting(getPlayerId()!, device: device);
  }

  /// Stops casting and returns playback to the local device.
  ///
  /// This disconnects from the current cast device (if any) and resumes
  /// local playback. The current playback position is preserved.
  ///
  /// Returns `true` if casting was stopped successfully, `false` if not
  /// currently casting or if the operation failed.
  Future<bool> stopCasting() async {
    ensureInitialized();
    return platform.stopCasting(getPlayerId()!);
  }
}
