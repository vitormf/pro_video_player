import Foundation

/// Controls mode for the video player view.
///
/// Determines what type of controls are displayed with the video player.
public enum ControlsMode: String {
    /// No controls - video only, programmatic control.
    case none

    /// Native platform controls (AVPlayerViewController on iOS, AVPlayerView on macOS).
    case native

    /// Custom Flutter controls (rendered in Dart/Flutter layer).
    case custom
}
