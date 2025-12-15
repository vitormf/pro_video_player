import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Manages device-level controls for the video player.
///
/// This manager handles:
/// - Device volume control (separate from player volume)
/// - Screen brightness control
class DeviceControlsManager {
  /// Creates a device controls manager with dependency injection via callbacks.
  DeviceControlsManager({required this.platform, required this.ensureInitialized});

  /// Platform implementation for device control operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

  /// Gets the current device media volume (0.0 to 1.0).
  ///
  /// This is the device's media/music volume, independent of the player's volume.
  ///
  /// **Platform support:**
  /// - **Android**: Returns media stream volume
  /// - **iOS/macOS**: Returns system volume
  /// - **Web/Desktop**: May not be supported, returns 1.0
  Future<double> getDeviceVolume() => platform.getDeviceVolume();

  /// Sets the device media volume (0.0 to 1.0).
  ///
  /// This controls the device's media/music volume, independent of the player's volume.
  /// The player's volume is a multiplier on top of this device volume.
  ///
  /// **Platform support:**
  /// - **Android**: Sets media stream volume
  /// - **iOS/macOS**: Sets system volume
  /// - **Web/Desktop**: May not be supported, no effect
  Future<void> setDeviceVolume(double volume) async {
    ensureInitialized();
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError.value(volume, 'volume', 'Must be between 0.0 and 1.0');
    }
    await platform.setDeviceVolume(volume);
  }

  /// Gets the current screen brightness (0.0 to 1.0).
  ///
  /// **Platform support:**
  /// - **Android/iOS**: Returns app-level brightness override or system brightness
  /// - **Web/Desktop**: May not be supported, returns 1.0
  Future<double> getScreenBrightness() => platform.getScreenBrightness();

  /// Sets the screen brightness (0.0 to 1.0).
  ///
  /// This sets an app-level brightness override. When the app is closed or the
  /// override is removed, the system brightness is restored.
  ///
  /// **Platform support:**
  /// - **Android/iOS**: Sets app-level brightness override
  /// - **Web/Desktop**: May not be supported, no effect
  Future<void> setScreenBrightness(double brightness) async {
    ensureInitialized();
    if (brightness < 0.0 || brightness > 1.0) {
      throw ArgumentError.value(brightness, 'brightness', 'Must be between 0.0 and 1.0');
    }
    await platform.setScreenBrightness(brightness);
  }
}
