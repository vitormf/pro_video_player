import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A reusable overlay widget for displaying volume, brightness, or other value indicators.
///
/// This widget shows:
/// - An icon representing the value type
/// - A vertical bar showing the current level (0-100%)
/// - A percentage label
///
/// Used by VideoPlayerGestureDetector for volume and brightness feedback.
class ValueIndicatorOverlay extends StatelessWidget {
  /// Creates a value indicator overlay.
  const ValueIndicatorOverlay({
    required this.value,
    required this.icon,
    required this.theme,
    this.containerWidth = 40.0,
    this.barHeight = 160.0,
    this.borderRadius = 20.0,
    super.key,
  });

  /// Current level value (0.0-1.0).
  final double value;

  /// Icon to display at the top.
  final IconData icon;

  /// The video player theme containing color definitions.
  final VideoPlayerTheme theme;

  /// Width of the indicator bar container. Defaults to 40.0.
  final double containerWidth;

  /// Height of the indicator bar. Defaults to 160.0.
  final double barHeight;

  /// Border radius for the bar corners. Defaults to 20.0.
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: theme.seekIconSize,
        color: theme.primaryColor,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
      ),
      const SizedBox(height: 12),
      Container(
        width: containerWidth,
        height: barHeight,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: barHeight * value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${(value * 100).round()}%',
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
        ),
      ),
    ],
  );
}
