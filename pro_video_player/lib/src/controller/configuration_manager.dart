import 'package:flutter/foundation.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Manages video player configuration settings.
///
/// This manager handles:
/// - Looping mode
/// - Video scaling mode
/// - Background playback settings
class ConfigurationManager {
  /// Creates a configuration manager with dependency injection via callbacks.
  ConfigurationManager({
    required this.getValue,
    required this.setValue,
    required this.getPlayerId,
    required this.platform,
    required this.ensureInitialized,
  });

  /// Gets the current video player value.
  final VideoPlayerValue Function() getValue;

  /// Updates the video player value.
  final void Function(VideoPlayerValue) setValue;

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Platform implementation for configuration operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

  /// Sets whether the video should loop.
  Future<void> setLooping({required bool looping}) async {
    ensureInitialized();
    await platform.setLooping(getPlayerId()!, looping: looping);
    setValue(getValue().copyWith(isLooping: looping));
  }

  /// Sets the video scaling mode.
  ///
  /// Determines how the video fills the player viewport:
  /// - [VideoScalingMode.fit]: Letterbox mode, shows entire video with black bars
  /// - [VideoScalingMode.fill]: Crop mode, fills viewport while maintaining aspect ratio
  /// - [VideoScalingMode.stretch]: Stretch mode, ignores aspect ratio
  Future<void> setScalingMode(VideoScalingMode mode) async {
    ensureInitialized();
    await platform.setScalingMode(getPlayerId()!, mode);
  }

  /// Enables or disables background playback.
  ///
  /// When enabled, audio will continue playing when the app is in the background.
  /// This requires proper platform configuration:
  /// - **iOS**: Add UIBackgroundModes audio capability in Info.plist
  /// - **Android**: Uses a foreground service with notification
  /// - **macOS**: Always enabled
  ///
  /// Returns `true` if the operation succeeded, `false` if:
  /// - The platform doesn't support background playback
  /// - The feature couldn't be enabled (e.g., missing permissions)
  ///
  /// Example:
  /// ```dart
  /// final success = await controller.setBackgroundPlayback(enabled: true);
  /// if (!success) {
  ///   print('Background playback not available');
  /// }
  /// ```
  Future<bool> setBackgroundPlayback({required bool enabled}) async {
    ensureInitialized();

    // On macOS, background playback is always enabled - no-op
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      setValue(getValue().copyWith(isBackgroundPlaybackEnabled: true));
      return true;
    }

    final success = await platform.setBackgroundPlayback(getPlayerId()!, enabled: enabled);
    if (success) {
      setValue(getValue().copyWith(isBackgroundPlaybackEnabled: enabled));
    }
    return success;
  }

  /// Returns whether background playback is supported on this platform.
  ///
  /// **Platform support:**
  /// - **iOS**: `true` (requires proper Info.plist configuration)
  /// - **Android**: `true` (uses foreground service)
  /// - **macOS**: `true` (always enabled)
  /// - **Web/Windows/Linux**: `false`
  Future<bool> isBackgroundPlaybackSupported() => platform.isBackgroundPlaybackSupported();
}
