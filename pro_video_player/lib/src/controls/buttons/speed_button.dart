import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that opens the playback speed picker.
///
/// This button displays the current playback speed (e.g., "1.0x") as a text
/// button that opens a picker when tapped.
///
/// Example:
/// ```dart
/// SpeedButton(
///   theme: VideoPlayerTheme.light(),
///   speed: controller.value.playbackSpeed,
///   onPressed: () => showSpeedPicker(...),
/// )
/// ```
class SpeedButton extends StatelessWidget {
  /// Creates a playback speed button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [speed] is the current playback speed to display.
  /// The [onPressed] callback is called when the button is tapped.
  const SpeedButton({required this.theme, required this.speed, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// The current playback speed (e.g., 1.0, 1.5, 2.0).
  final double speed;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Format speed to max 2 decimal places, removing trailing zeros
    // 1.0 → "1x", 1.5 → "1.5x", 1.25 → "1.25x", 1.333 → "1.33x"
    final formattedSpeed = speed.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    final speedText = '${formattedSpeed}x';
    return Tooltip(
      message: 'Playback speed',
      child: TextButton(
        key: const Key('toolbar_speed_button'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(speedText, style: TextStyle(color: theme.primaryColor, fontSize: 14)),
      ),
    );
  }
}
