import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that triggers Picture-in-Picture mode.
///
/// This button displays a PiP icon and calls the provided [onPressed] callback
/// when tapped.
///
/// Example:
/// ```dart
/// PipButton(
///   theme: VideoPlayerTheme.light(),
///   onPressed: () => controller.enterPip(),
/// )
/// ```
class PipButton extends StatelessWidget {
  /// Creates a PiP button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [onPressed] callback is called when the button is tapped.
  const PipButton({required this.theme, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('toolbar_pip_button'),
    icon: Icon(Icons.picture_in_picture_alt, color: theme.primaryColor),
    iconSize: 20,
    tooltip: 'Picture-in-Picture',
    onPressed: onPressed,
  );
}
