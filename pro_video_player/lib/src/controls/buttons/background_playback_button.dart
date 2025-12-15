import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that toggles background playback mode.
///
/// This button displays different icons and colors based on whether background
/// playback is enabled:
/// - Enabled: Filled headphones icon with active color
/// - Disabled: Outlined headphones icon with primary color
///
/// Example:
/// ```dart
/// BackgroundPlaybackButton(
///   theme: VideoPlayerTheme.light(),
///   isEnabled: controller.value.isBackgroundPlaybackEnabled,
///   onPressed: () => controller.setBackgroundPlayback(
///     enabled: !controller.value.isBackgroundPlaybackEnabled,
///   ),
/// )
/// ```
class BackgroundPlaybackButton extends StatelessWidget {
  /// Creates a background playback toggle button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [isEnabled] determines the icon and color used.
  /// The [onPressed] callback is called when the button is tapped.
  const BackgroundPlaybackButton({required this.theme, required this.isEnabled, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// Whether background playback is currently enabled.
  final bool isEnabled;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(
      isEnabled ? Icons.headphones : Icons.headphones_outlined,
      color: isEnabled ? theme.progressBarActiveColor : theme.primaryColor,
    ),
    iconSize: 20,
    tooltip: isEnabled ? 'Disable background playback' : 'Enable background playback',
    onPressed: onPressed,
  );
}
