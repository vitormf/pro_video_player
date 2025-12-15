import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that opens the video scaling mode picker.
///
/// This button displays an aspect ratio icon and opens a picker to select
/// between different video scaling modes (fit, fill, stretch) when tapped.
///
/// Example:
/// ```dart
/// ScalingModeButton(
///   theme: VideoPlayerTheme.light(),
///   onPressed: () => showScalingModePicker(...),
/// )
/// ```
class ScalingModeButton extends StatelessWidget {
  /// Creates a scaling mode button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [onPressed] callback is called when the button is tapped.
  const ScalingModeButton({required this.theme, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(Icons.aspect_ratio, color: theme.primaryColor),
    iconSize: 20,
    tooltip: 'Scaling mode',
    onPressed: onPressed,
  );
}
