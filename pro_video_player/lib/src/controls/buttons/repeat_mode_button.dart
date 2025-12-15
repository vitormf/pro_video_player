import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../video_player_theme.dart';

/// A button that cycles through playlist repeat modes.
///
/// This button displays different icons and colors based on the repeat mode:
/// - None: repeat icon with primary color, tooltip "Repeat off"
/// - All: repeat icon with active color, tooltip "Repeat all"
/// - One: repeat_one icon with active color, tooltip "Repeat one"
///
/// The button cycles through modes: none → all → one → none
///
/// Example:
/// ```dart
/// RepeatModeButton(
///   theme: VideoPlayerTheme.light(),
///   repeatMode: controller.value.playlistRepeatMode,
///   onPressed: () {
///     final nextMode = // calculate next mode
///     controller.setPlaylistRepeatMode(nextMode);
///   },
/// )
/// ```
class RepeatModeButton extends StatelessWidget {
  /// Creates a repeat mode toggle button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [repeatMode] determines the icon, color, and tooltip.
  /// The [onPressed] callback is called when the button is tapped.
  const RepeatModeButton({required this.theme, required this.repeatMode, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// The current repeat mode.
  final PlaylistRepeatMode repeatMode;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (repeatMode) {
      case PlaylistRepeatMode.none:
        icon = Icons.repeat;
        color = theme.primaryColor;
      case PlaylistRepeatMode.all:
        icon = Icons.repeat;
        color = theme.progressBarActiveColor;
      case PlaylistRepeatMode.one:
        icon = Icons.repeat_one;
        color = theme.progressBarActiveColor;
    }

    final tooltipText = switch (repeatMode) {
      PlaylistRepeatMode.none => 'Repeat off',
      PlaylistRepeatMode.all => 'Repeat all',
      PlaylistRepeatMode.one => 'Repeat one',
    };

    return IconButton(
      icon: Icon(icon, color: color),
      iconSize: 20,
      tooltip: tooltipText,
      onPressed: onPressed,
    );
  }
}
