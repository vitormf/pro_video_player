/// Configuration options for Picture-in-Picture mode.
///
/// These options are passed to `enterPip()` to customize the PiP behavior.
///
/// ## Platform Setup Required
///
/// PiP requires platform-specific setup:
///
/// **Android:** Add `android:supportsPictureInPicture="true"` to your
/// `MainActivity` in `AndroidManifest.xml`. When PiP is active, the entire
/// app is shown in the small PiP window. Your app should respond to
/// `value.isPipActive` to show only the video player.
///
/// **iOS:** Add "Audio, AirPlay, and Picture in Picture" to your app's
/// Background Modes capability (or add `UIBackgroundModes` with `audio` to
/// `Info.plist`). iOS uses true video-only PiP where the video floats in a
/// system-controlled window independently from the app.
///
/// See the package README for detailed setup instructions.
class PipOptions {
  /// Creates Picture-in-Picture options.
  const PipOptions({this.aspectRatio, this.autoEnterOnBackground = false});

  /// The aspect ratio for the PiP window (width / height).
  ///
  /// If `null`, uses the video's natural aspect ratio.
  final double? aspectRatio;

  /// Whether to automatically enter PiP when the app goes to background.
  ///
  /// When `true`, the player will attempt to enter PiP mode when the app
  /// goes to the background. This requires the same platform setup as
  /// regular PiP (see class documentation).
  final bool autoEnterOnBackground;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PipOptions) return false;
    return aspectRatio == other.aspectRatio && autoEnterOnBackground == other.autoEnterOnBackground;
  }

  @override
  int get hashCode => Object.hash(aspectRatio, autoEnterOnBackground);

  @override
  String toString() =>
      'PipOptions('
      'aspectRatio: $aspectRatio, '
      'autoEnterOnBackground: $autoEnterOnBackground'
      ')';
}
