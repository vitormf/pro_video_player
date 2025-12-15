import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that opens the video quality picker.
///
/// This button displays a quality icon and label (e.g., "Auto", "1080p", "720p")
/// that opens a picker to select video quality when tapped.
///
/// Example:
/// ```dart
/// QualityButton(
///   theme: VideoPlayerTheme.light(),
///   qualityLabel: '1080p',
///   onPressed: () => showQualityPicker(...),
/// )
/// ```
class QualityButton extends StatelessWidget {
  /// Creates a video quality button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [qualityLabel] is the current quality to display (e.g., "Auto", "1080p").
  /// The [onPressed] callback is called when the button is tapped.
  const QualityButton({required this.theme, required this.qualityLabel, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// The quality label to display (e.g., "Auto", "1080p", "720p").
  final String qualityLabel;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Video quality',
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.high_quality, color: theme.primaryColor, size: 18),
          const SizedBox(width: 4),
          Text(qualityLabel, style: TextStyle(color: theme.primaryColor, fontSize: 14)),
        ],
      ),
    ),
  );
}
