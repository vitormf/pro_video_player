import 'package:flutter/material.dart';

import '../video_player_theme.dart';

/// Callbacks for toolbar actions and picker dialogs.
///
/// This interface bundles all callbacks used by toolbar buttons and action handlers,
/// reducing parameter coupling and creating a clean contract for toolbar widgets.
///
/// Example:
/// ```dart
/// final callbacks = ToolbarCallbacks(
///   onShowQualityPicker: (context, theme) => _showQualityPicker(context, theme),
///   onShowSubtitlePicker: (context, theme) => _showSubtitlePicker(context, theme),
///   onFullscreenEnter: () => _enterFullscreen(),
///   onFullscreenExit: () => _exitFullscreen(),
///   onPipPressed: () => controller.enterPip(),
/// );
/// ```
class ToolbarCallbacks {
  /// Creates a toolbar callbacks bundle.
  const ToolbarCallbacks({
    required this.onShowQualityPicker,
    required this.onShowSubtitlePicker,
    required this.onShowAudioPicker,
    required this.onShowChaptersPicker,
    required this.onShowSpeedPicker,
    required this.onShowScalingModePicker,
    required this.onShowOrientationLockPicker,
    required this.onShowContextMenu,
    required this.onFullscreenEnter,
    required this.onFullscreenExit,
    required this.onPipPressed,
    required this.onBackgroundPlaybackToggle,
  });

  /// Called to show the video quality picker dialog.
  ///
  /// The picker allows users to select from available quality tracks
  /// in adaptive streaming videos (HLS, DASH).
  final void Function(BuildContext context, VideoPlayerTheme theme) onShowQualityPicker;

  /// Called to show the subtitle track picker dialog.
  ///
  /// The picker allows users to select from available subtitle tracks
  /// or disable subtitles.
  final void Function(BuildContext context, VideoPlayerTheme theme) onShowSubtitlePicker;

  /// Called to show the audio track picker dialog.
  ///
  /// The picker allows users to select from available audio tracks
  /// (different languages, audio descriptions, etc.).
  final void Function(BuildContext context, VideoPlayerTheme theme) onShowAudioPicker;

  /// Called to show the chapters picker dialog.
  ///
  /// The picker allows users to jump to specific chapters in the video.
  final void Function(BuildContext context, VideoPlayerTheme theme) onShowChaptersPicker;

  /// Called to show the playback speed picker dialog.
  ///
  /// The picker allows users to select from available playback speed options
  /// (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x, etc.).
  final void Function(BuildContext context, VideoPlayerTheme theme) onShowSpeedPicker;

  /// Called to show the scaling mode picker bottom sheet.
  ///
  /// The picker allows users to select how video fills the viewport
  /// (fit, fill, stretch).
  final void Function(VideoPlayerTheme theme) onShowScalingModePicker;

  /// Called to show the orientation lock picker bottom sheet.
  ///
  /// The picker allows users to lock screen orientation in fullscreen mode
  /// (Auto-rotate, Landscape, Landscape Left, Landscape Right).
  final void Function(VideoPlayerTheme theme) onShowOrientationLockPicker;

  /// Called to show the context menu at a specific position.
  ///
  /// The context menu displays common actions like play/pause, seek,
  /// quality selection, etc.
  final void Function(BuildContext context, Offset position, VideoPlayerTheme theme) onShowContextMenu;

  /// Called when the fullscreen button is pressed to enter fullscreen.
  final VoidCallback onFullscreenEnter;

  /// Called when the fullscreen button is pressed to exit fullscreen.
  final VoidCallback onFullscreenExit;

  /// Called when the Picture-in-Picture button is pressed.
  final VoidCallback onPipPressed;

  /// Called when the background playback toggle button is pressed.
  ///
  /// This should toggle the background playback state.
  final VoidCallback onBackgroundPlaybackToggle;
}
