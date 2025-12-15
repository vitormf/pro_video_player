import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'controls_enums.dart';

/// Configuration bundle for video player controls.
///
/// This class bundles all configuration parameters (boolean flags, durations,
/// and option lists) into a single value object, reducing parameter coupling
/// in child widgets.
///
/// Example:
/// ```dart
/// final config = ControlsConfiguration(
///   showFullscreenButton: true,
///   showSkipButtons: true,
///   skipDuration: Duration(seconds: 10),
///   enableGestures: true,
/// );
/// ```
class ControlsConfiguration {
  /// Creates a controls configuration bundle.
  const ControlsConfiguration({
    required this.renderSubtitlesInternally,
    required this.showFullscreenButton,
    required this.showOrientationLockButton,
    required this.showSkipButtons,
    required this.skipDuration,
    required this.seekSecondsPerInch,
    required this.showSpeedButton,
    required this.speedOptions,
    required this.showSubtitleButton,
    required this.showAudioButton,
    required this.showPipButton,
    required this.showScalingModeButton,
    required this.scalingModeOptions,
    required this.showQualityButton,
    required this.showBackgroundPlaybackButton,
    required this.enableGestures,
    required this.enableDoubleTapSeek,
    required this.enableVolumeGesture,
    required this.enableBrightnessGesture,
    required this.enableSeekGesture,
    required this.enablePlaybackSpeedGesture,
    required this.autoHide,
    required this.autoHideDuration,
    required this.liveScrubbingMode,
    required this.compactMode,
    required this.compactThreshold,
    required this.playerToolbarActions,
    required this.maxPlayerToolbarActions,
    required this.autoOverflowActions,
    required this.fullscreenOrientation,
    required this.enableKeyboardShortcuts,
    required this.keyboardSeekDuration,
    required this.enableSeekBarHoverPreview,
    required this.enableContextMenu,
    required this.minimalToolbarOnDesktop,
  });

  /// Whether to render subtitles within controls widget.
  final bool renderSubtitlesInternally;

  /// Whether to show the fullscreen button.
  final bool showFullscreenButton;

  /// Whether to show the orientation lock button in fullscreen.
  final bool showOrientationLockButton;

  /// Whether to show skip forward/backward buttons.
  final bool showSkipButtons;

  /// Duration to skip when skip buttons are tapped.
  final Duration skipDuration;

  /// How many seconds to seek per inch of horizontal swipe gesture.
  final double seekSecondsPerInch;

  /// Whether to show the playback speed button.
  final bool showSpeedButton;

  /// Available playback speed options.
  final List<double> speedOptions;

  /// Whether to show the subtitle selection button.
  final bool showSubtitleButton;

  /// Whether to show the audio track selection button.
  final bool showAudioButton;

  /// Whether to show the Picture-in-Picture button.
  final bool showPipButton;

  /// Whether to show the scaling mode button.
  final bool showScalingModeButton;

  /// Available scaling mode options.
  final List<VideoScalingMode> scalingModeOptions;

  /// Whether to show the video quality selection button.
  final bool showQualityButton;

  /// Whether to show the background playback toggle button.
  final bool showBackgroundPlaybackButton;

  /// Whether to enable gesture controls.
  final bool enableGestures;

  /// Whether to enable double-tap to seek gestures.
  final bool enableDoubleTapSeek;

  /// Whether to enable volume control gestures (vertical swipe on right).
  final bool enableVolumeGesture;

  /// Whether to enable brightness control gestures (vertical swipe on left).
  final bool enableBrightnessGesture;

  /// Whether to enable seek gestures (horizontal swipe).
  final bool enableSeekGesture;

  /// Whether to enable playback speed gestures (two-finger vertical swipe).
  final bool enablePlaybackSpeedGesture;

  /// Whether to automatically hide controls when playing.
  final bool autoHide;

  /// Duration before controls are hidden when autoHide is enabled.
  final Duration autoHideDuration;

  /// Controls when live scrubbing is enabled for the seek bar.
  final LiveScrubbingMode liveScrubbingMode;

  /// Compact mode setting (auto, always, never).
  final CompactMode compactMode;

  /// Size threshold below which compact mode is activated.
  final Size compactThreshold;

  /// Custom toolbar actions configuration.
  final List<PlayerToolbarAction>? playerToolbarActions;

  /// Maximum number of actions to show before overflow.
  final int? maxPlayerToolbarActions;

  /// Whether to automatically overflow actions when space is limited.
  final bool autoOverflowActions;

  /// Preferred screen orientation when entering fullscreen.
  final FullscreenOrientation fullscreenOrientation;

  /// Whether to enable keyboard shortcuts on desktop and web platforms.
  final bool enableKeyboardShortcuts;

  /// Duration to seek when using keyboard arrow keys.
  final Duration keyboardSeekDuration;

  /// Whether to show time preview on seek bar hover (desktop/web only).
  final bool enableSeekBarHoverPreview;

  /// Whether to enable right-click context menu on desktop and web platforms.
  final bool enableContextMenu;

  /// Whether to use minimal toolbar on desktop and web platforms.
  final bool minimalToolbarOnDesktop;
}
