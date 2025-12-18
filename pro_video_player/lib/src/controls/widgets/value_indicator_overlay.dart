import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A reusable overlay widget for displaying volume, brightness, or other value indicators.
///
/// This widget shows a slim vertical bar with an icon and the current level (0-100%).
///
/// Used by VideoPlayerGestureDetector for volume and brightness feedback.
class ValueIndicatorOverlay extends StatelessWidget {
  /// Creates a value indicator overlay.
  const ValueIndicatorOverlay({
    required this.value,
    required this.icon,
    required this.theme,
    this.containerWidth = 4.0,
    this.barHeight = 160.0,
    this.borderRadius = 2.0,
    super.key,
  });

  /// Current level value (0.0-1.0).
  final double value;

  /// Icon to display above the bar.
  final IconData icon;

  /// The video player theme containing color definitions.
  final VideoPlayerTheme theme;

  /// Width of the indicator bar container. Defaults to 4.0 (slim).
  final double containerWidth;

  /// Height of the indicator bar. Defaults to 160.0.
  final double barHeight;

  /// Border radius for the bar corners. Defaults to 2.0.
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 28,
        color: Colors.white,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
      ),
      const SizedBox(height: 12),
      Container(
        width: containerWidth,
        height: barHeight,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: containerWidth,
              height: barHeight * value,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
