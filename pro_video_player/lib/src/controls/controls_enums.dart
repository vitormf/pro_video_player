/// Represents actions that can be displayed in the player toolbar.
///
/// Use this enum with `VideoPlayerControls.playerToolbarActions` to configure
/// which actions appear in the player toolbar and in what order. Actions that
/// exceed `VideoPlayerControls.maxPlayerToolbarActions` will be shown in an
/// overflow menu.
///
/// Example:
/// ```dart
/// VideoPlayerControls(
///   controller: controller,
///   playerToolbarActions: [
///     PlayerToolbarAction.subtitles,
///     PlayerToolbarAction.speed,
///     PlayerToolbarAction.pip,
///     PlayerToolbarAction.fullscreen,
///   ],
///   maxPlayerToolbarActions: 3, // First 3 visible, rest in overflow menu
/// )
/// ```
enum PlayerToolbarAction {
  /// Shuffle button for playlist playback.
  ///
  /// Only visible when a playlist is active.
  shuffle,

  /// Repeat mode button for playlist playback.
  ///
  /// Cycles through: none → all → one → none.
  /// Only visible when a playlist is active.
  repeatMode,

  /// Subtitle track selection button.
  ///
  /// Only visible when subtitle tracks are available.
  subtitles,

  /// Audio track selection button.
  ///
  /// Only visible when multiple audio tracks are available.
  audio,

  /// Chapter navigation button.
  ///
  /// Only visible when chapters are available in the video.
  /// Opens a bottom sheet to select and navigate to chapters.
  chapters,

  /// Video quality selection button.
  ///
  /// Only visible when multiple quality tracks are available (adaptive streams).
  quality,

  /// Playback speed selection button.
  speed,

  /// Video scaling mode button (fit, fill, stretch).
  scalingMode,

  /// Background playback toggle button.
  ///
  /// Only visible when background playback is supported on the platform (iOS, Android).
  ///
  /// **Note:** This button is always hidden on:
  /// - **macOS**: Background playback is enabled by default and cannot be toggled.
  /// - **Web**: Background playback is not supported.
  backgroundPlayback,

  /// Picture-in-Picture button.
  ///
  /// Only visible when PiP is available on the device.
  pip,

  /// Casting button (AirPlay, Chromecast, Remote Playback).
  ///
  /// Only visible when casting is supported on the platform.
  casting,

  /// Orientation lock button for fullscreen mode.
  ///
  /// Opens a bottom sheet to select orientation lock options:
  /// Auto-rotate, Landscape, Landscape Left, or Landscape Right.
  ///
  /// Only visible in fullscreen mode when `VideoPlayerControls.showOrientationLockButton`
  /// is `true`.
  orientationLock,

  /// Fullscreen toggle button.
  fullscreen,
}

/// Defines the compact mode behavior for the video player controls.
///
/// Compact mode provides a simplified UI optimized for small player sizes,
/// such as Picture-in-Picture mode or small embedded players.
enum CompactMode {
  /// Compact mode is disabled. Full controls are always shown.
  never,

  /// Compact mode is enabled based on player size.
  ///
  /// When the player dimensions fall below `VideoPlayerControls.compactThreshold`,
  /// compact controls are shown automatically.
  auto,

  /// Compact mode is always enabled, regardless of player size.
  ///
  /// Useful for Picture-in-Picture mode or when you want minimal UI.
  always,
}

/// Defines when live scrubbing should be enabled for the seek bar.
///
/// Live scrubbing updates the video position immediately as the user drags
/// the progress bar, providing real-time feedback. Different modes optimize
/// performance based on the video source type and buffering state.
enum LiveScrubbingMode {
  /// Live scrubbing is disabled. Video position only updates when the user
  /// releases their finger/mouse.
  ///
  /// Best for: Low-end devices or when seeking performance is critical.
  disabled,

  /// Live scrubbing is always enabled for all video sources, regardless of
  /// source type or buffering state.
  ///
  /// Provides the best user experience but may cause network requests
  /// when scrubbing to unbuffered portions of network videos.
  ///
  /// Best for: High-quality network connections and modern devices.
  always,

  /// Live scrubbing is enabled only for local files (file:// and asset sources).
  ///
  /// Network videos will only update position on drag end to avoid
  /// excessive network requests.
  ///
  /// Best for: Apps that primarily use network videos with limited bandwidth.
  localOnly,

  /// Live scrubbing intelligently adapts based on source type and buffering state.
  ///
  /// Enabled for:
  /// - Local files (file:// and asset sources) - always
  /// - Network videos - only within buffered range
  ///
  /// When scrubbing beyond the buffered range on network videos, position updates
  /// only on drag end to avoid loading unbuffered segments. Provides an optimal
  /// balance between responsiveness and performance.
  ///
  /// Best for: Most applications (recommended default).
  adaptive,
}
