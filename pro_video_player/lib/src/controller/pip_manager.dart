import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Manages Picture-in-Picture (PiP) functionality for the video player.
///
/// This manager handles:
/// - Entering and exiting PiP mode
/// - PiP availability checks
/// - PiP action configuration
class PipManager {
  /// Creates a PiP manager with dependency injection via callbacks.
  PipManager({
    required this.getPlayerId,
    required this.getOptions,
    required this.platform,
    required this.ensureInitialized,
  });

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Gets the video player options.
  final VideoPlayerOptions Function() getOptions;

  /// Platform implementation for PiP operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

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
    ensureInitialized();

    // Gracefully handle disabled PiP
    if (!getOptions().allowPip) {
      return false;
    }

    // Check if PiP is supported before attempting to enter
    final supported = await platform.isPipSupported();
    if (!supported) {
      return false;
    }

    return platform.enterPip(getPlayerId()!, options: options);
  }

  /// Exits Picture-in-Picture mode.
  Future<void> exitPip() async {
    ensureInitialized();
    await platform.exitPip(getPlayerId()!);
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
    ensureInitialized();
    await platform.setPipActions(getPlayerId()!, actions);
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
  Future<bool> isPipSupported() => platform.isPipSupported();

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
  Future<bool> isPipAvailable() async {
    if (!getOptions().allowPip) {
      return false;
    }
    return platform.isPipSupported();
  }
}
