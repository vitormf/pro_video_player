import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that toggles playlist shuffle mode.
///
/// This button displays different icons and colors based on shuffle state:
/// - Shuffled: shuffle_on icon with active color
/// - Not shuffled: shuffle icon with primary color
///
/// Example:
/// ```dart
/// ShuffleButton(
///   theme: VideoPlayerTheme.light(),
///   isShuffled: controller.value.isShuffled,
///   onPressed: () => controller.setPlaylistShuffle(
///     enabled: !controller.value.isShuffled,
///   ),
/// )
/// ```
class ShuffleButton extends StatelessWidget {
  /// Creates a shuffle toggle button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [isShuffled] determines the icon and color used.
  /// The [onPressed] callback is called when the button is tapped.
  const ShuffleButton({required this.theme, required this.isShuffled, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// Whether shuffle mode is currently enabled.
  final bool isShuffled;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(
      isShuffled ? Icons.shuffle_on : Icons.shuffle,
      color: isShuffled ? theme.progressBarActiveColor : theme.primaryColor,
    ),
    iconSize: 20,
    tooltip: isShuffled ? 'Shuffle on' : 'Shuffle off',
    onPressed: onPressed,
  );
}
