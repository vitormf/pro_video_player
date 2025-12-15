/// The controls mode for the video player.
///
/// This determines how playback controls are displayed:
/// - [none]: No controls shown - video only. Use external widgets to control playback.
/// - [flutter]: Built-in Flutter controls (VideoPlayerControls widget).
/// - [native]: Platform-native controls (iOS: AVPlayerViewController, Android: ExoPlayer PlayerView).
enum ControlsMode {
  /// No controls shown - video only.
  ///
  /// Use external widgets or a custom controls builder to provide controls.
  none,

  /// Built-in Flutter controls.
  ///
  /// Shows the `VideoPlayerControls` widget with gesture support,
  /// progress bar, and control buttons. This provides a consistent
  /// cross-platform experience.
  ///
  /// This is the default mode.
  flutter,

  /// Native platform controls.
  ///
  /// - **iOS**: AVPlayerViewController transport controls
  /// - **Android**: ExoPlayer PlayerView default controls
  ///
  /// These controls are rendered by the native platform and may have
  /// different appearances on each platform.
  native,
}

/// Extension methods for [ControlsMode] serialization.
extension ControlsModeExtension on ControlsMode {
  /// Serializes this [ControlsMode] to a JSON string.
  String toJson() => name;

  /// Deserializes a [ControlsMode] from a JSON string.
  ///
  /// Returns [ControlsMode.none] if the value is null or unknown.
  static ControlsMode fromJson(String? value) {
    if (value == null) return ControlsMode.none;
    return ControlsMode.values.firstWhere((mode) => mode.name == value, orElse: () => ControlsMode.none);
  }
}
