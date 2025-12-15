import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that opens the audio track picker.
///
/// This button displays an audio icon and opens a picker to select between
/// available audio tracks when tapped.
///
/// Example:
/// ```dart
/// AudioButton(
///   theme: VideoPlayerTheme.light(),
///   onPressed: () => showAudioPicker(...),
/// )
/// ```
class AudioButton extends StatelessWidget {
  /// Creates an audio track button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [onPressed] callback is called when the button is tapped.
  const AudioButton({required this.theme, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(Icons.audiotrack, color: theme.primaryColor),
    iconSize: 20,
    tooltip: 'Audio track',
    onPressed: onPressed,
  );
}
