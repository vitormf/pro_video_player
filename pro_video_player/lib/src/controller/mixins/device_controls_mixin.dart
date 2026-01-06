import '../controller_base.dart';

/// Mixin providing device-level controls (volume, brightness).
mixin DeviceControlsMixin on ProVideoPlayerControllerBase {
  /// Gets the current device media volume.
  ///
  /// Returns a value between 0.0 (muted) and 1.0 (max volume).
  /// This is the device's media/music stream volume, not the player's internal volume.
  Future<double> getDeviceVolume() {
    ensureInitializedInternal();
    return services.deviceControlsManager.getDeviceVolume();
  }

  /// Sets the device media volume.
  ///
  /// [volume] must be between 0.0 (muted) and 1.0 (max volume).
  /// This controls the device's media/music stream volume directly, which affects
  /// all media playback on the device.
  ///
  /// On iOS, this uses AVAudioSession to control the output volume.
  /// On Android, this uses AudioManager to control the STREAM_MUSIC volume.
  ///
  /// Note: The system volume UI may be shown briefly when changing volume.
  Future<void> setDeviceVolume(double volume) async {
    ensureInitializedInternal();
    await services.deviceControlsManager.setDeviceVolume(volume);
  }

  /// Gets the current screen brightness.
  ///
  /// Returns a value between 0.0 (dimmest) and 1.0 (brightest).
  /// On iOS/Android, this returns the current screen brightness setting.
  /// On other platforms, returns 1.0 as a default.
  Future<double> getScreenBrightness() {
    ensureInitializedInternal();
    return services.deviceControlsManager.getScreenBrightness();
  }

  /// Sets the screen brightness.
  ///
  /// [brightness] must be between 0.0 (dimmest) and 1.0 (brightest).
  /// On iOS, this sets UIScreen.main.brightness.
  /// On Android, this sets WindowManager.LayoutParams.screenBrightness.
  ///
  /// The change is temporary and will be reset when the app is closed or
  /// when fullscreen mode is exited.
  Future<void> setScreenBrightness(double brightness) async {
    ensureInitializedInternal();
    await services.deviceControlsManager.setScreenBrightness(brightness);
  }
}
