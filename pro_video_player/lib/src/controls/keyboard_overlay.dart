import 'package:flutter/material.dart';

import '../video_controls_state.dart';
import '../video_player_theme.dart';

/// A visual overlay that provides feedback for keyboard-controlled actions.
///
/// Displays volume, seek, or speed adjustments in the center of the screen
/// with an icon and value. The overlay is non-interactive and automatically
/// dismisses after a short duration.
class KeyboardOverlay extends StatelessWidget {
  /// Creates a keyboard overlay.
  ///
  /// The [type] and [value] determine what is displayed. If either is null,
  /// an empty widget is returned.
  const KeyboardOverlay({required this.type, required this.value, required this.theme, super.key});

  /// The type of keyboard action being displayed.
  final KeyboardOverlayType? type;

  /// The current value for the action (volume 0-1, seek seconds, speed multiplier).
  final double? value;

  /// The theme for styling the overlay.
  final VideoPlayerTheme theme;

  @override
  Widget build(BuildContext context) {
    if (type == null || value == null) {
      return const SizedBox.shrink();
    }

    final shadow = [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)];

    return IgnorePointer(
      child: Center(
        child: switch (type!) {
          KeyboardOverlayType.volume => _buildVolumeContent(value!, theme, shadow),
          KeyboardOverlayType.seek => _buildSeekContent(value!, theme, shadow),
          KeyboardOverlayType.speed => _buildSpeedContent(value!, theme, shadow),
        },
      ),
    );
  }

  Widget _buildVolumeContent(double volume, VideoPlayerTheme theme, List<Shadow> shadow) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        volume > 0.5 ? Icons.volume_up : (volume > 0 ? Icons.volume_down : Icons.volume_off),
        size: 24,
        color: theme.primaryColor,
        shadows: shadow,
      ),
      const SizedBox(height: 4),
      Text(
        '${(volume * 100).round()}%',
        style: TextStyle(color: theme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold, shadows: shadow),
      ),
    ],
  );

  Widget _buildSeekContent(double seconds, VideoPlayerTheme theme, List<Shadow> shadow) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(seconds >= 0 ? Icons.fast_forward : Icons.fast_rewind, size: 24, color: theme.primaryColor, shadows: shadow),
      const SizedBox(height: 4),
      Text(
        '${seconds >= 0 ? '+' : ''}${seconds.toInt()}s',
        style: TextStyle(color: theme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold, shadows: shadow),
      ),
    ],
  );

  Widget _buildSpeedContent(double speed, VideoPlayerTheme theme, List<Shadow> shadow) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.speed, size: 24, color: theme.primaryColor, shadows: shadow),
      const SizedBox(height: 4),
      Text(
        '${speed}x',
        style: TextStyle(color: theme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold, shadows: shadow),
      ),
    ],
  );
}
