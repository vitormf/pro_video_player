import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

/// Mixin providing Picture-in-Picture functionality.
mixin PipMixin on ProVideoPlayerControllerBase {
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
  /// to `value.isPipActive` to show only the video player.
  ///
  /// **iOS:** Requires "Audio, AirPlay, and Picture in Picture" in your app's
  /// Background Modes capability (or `UIBackgroundModes` with `audio` in
  /// `Info.plist`). iOS uses true video-only PiP where the video floats in a
  /// system-controlled window independently from the app.
  Future<bool> enterPip({PipOptions options = const PipOptions()}) async {
    ensureInitializedInternal();
    return services.pipManager.enterPip(options: options);
  }

  /// Exits Picture-in-Picture mode.
  Future<void> exitPip() async {
    ensureInitializedInternal();
    await services.pipManager.exitPip();
  }

  /// Sets the PiP remote action buttons.
  ///
  /// These actions appear as buttons in the PiP window, allowing users to
  /// control playback without leaving the PiP view.
  ///
  /// **Platform support:**
  /// - **Android**: Full support via `RemoteAction` in `PictureInPictureParams`.
  /// - **iOS**: Limited support. iOS 15+ supports skip forward/backward buttons.
  /// - **macOS/Web/Windows/Linux**: Not supported.
  ///
  /// Pass `null` or an empty list to clear all custom actions.
  Future<void> setPipActions(List<PipAction>? actions) async {
    ensureInitializedInternal();
    await services.pipManager.setPipActions(actions);
  }

  /// Returns whether Picture-in-Picture is supported on this device.
  ///
  /// This only checks device/platform support, not whether PiP is allowed
  /// for this player (see [VideoPlayerOptions.allowPip]).
  ///
  /// **Note:** This method does NOT require the player to be initialized since
  /// it only checks platform capabilities, not player state.
  Future<bool> isPipSupported() {
    // Note: Does NOT call ensureInitializedInternal() because this is a platform
    // capability check, not a player operation.
    return services.pipManager.isPipSupported();
  }

  /// Returns whether Picture-in-Picture is available for this player.
  ///
  /// Returns `true` if both the device supports PiP (see [isPipSupported]) and
  /// [VideoPlayerOptions.allowPip] is `true`.
  Future<bool> isPipAvailable() {
    ensureInitializedInternal();
    return services.pipManager.isPipAvailable();
  }
}
