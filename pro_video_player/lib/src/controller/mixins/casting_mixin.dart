import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

/// Mixin providing casting functionality (AirPlay, Chromecast).
mixin CastingMixin on ProVideoPlayerControllerBase {
  /// Returns whether casting is supported on this platform.
  ///
  /// ## Platform Support
  ///
  /// - **iOS/macOS**: Returns `true` (AirPlay is built-in)
  /// - **Android**: Returns `true` if Google Cast SDK is properly configured
  /// - **Web**: Returns `true` if the browser supports the Remote Playback API
  /// - **Windows/Linux**: Returns `false`
  Future<bool> isCastingSupported() async {
    ensureInitializedInternal();
    return services.castingManager.isCastingSupported();
  }

  /// Returns the list of available cast devices.
  ///
  /// This returns the cached list from [VideoPlayerValue.availableCastDevices].
  /// The list is updated automatically via device discovery events.
  List<CastDevice> get availableCastDevices => value.availableCastDevices;

  /// Starts casting to the specified device.
  ///
  /// If [device] is `null`, the platform will show a device picker dialog
  /// allowing the user to select a device. This is the recommended approach
  /// for most use cases.
  ///
  /// Returns `true` if casting started successfully, `false` if casting
  /// is not supported, not allowed, or failed to connect.
  ///
  /// ## Platform Behavior
  ///
  /// - **iOS/macOS**: Shows the AirPlay route picker (device parameter is ignored)
  /// - **Android**: If device is `null`, shows the Cast dialog
  /// - **Web**: Uses the Remote Playback API prompt
  Future<bool> startCasting({CastDevice? device}) async {
    ensureInitializedInternal();
    return services.castingManager.startCasting(device: device);
  }

  /// Stops casting and returns playback to the local device.
  ///
  /// This disconnects from the current cast device (if any) and resumes
  /// local playback. The current playback position is preserved.
  ///
  /// Returns `true` if casting was stopped successfully, `false` if not
  /// currently casting or if the operation failed.
  Future<bool> stopCasting() async {
    ensureInitializedInternal();
    return services.castingManager.stopCasting();
  }

  /// Returns the current casting state.
  CastState get castState => value.castState;

  /// Returns the currently connected cast device, if any.
  CastDevice? get currentCastDevice => value.currentCastDevice;

  /// Returns whether the player is currently casting.
  bool get isCasting => value.isCasting;
}
