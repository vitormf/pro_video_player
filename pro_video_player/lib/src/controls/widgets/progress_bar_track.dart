import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A reusable progress bar track widget showing background, buffered, and played regions.
///
/// This widget renders a three-layer progress bar:
/// - Background layer (inactive color)
/// - Buffered layer (shows how much is buffered)
/// - Played layer (shows playback progress)
///
/// All layers use the same border radius for consistent styling.
class ProgressBarTrack extends StatelessWidget {
  /// Creates a progress bar track.
  const ProgressBarTrack({
    required this.theme,
    required this.bufferedProgress,
    required this.displayProgress,
    this.height = 4.0,
    this.borderRadius = 2.0,
    super.key,
  });

  /// The video player theme containing color definitions.
  final VideoPlayerTheme theme;

  /// Progress value for buffered content (0.0-1.0).
  final double bufferedProgress;

  /// Progress value for played content (0.0-1.0).
  final double displayProgress;

  /// Height of the progress bar track. Defaults to 4.0.
  final double height;

  /// Border radius for the progress bar corners. Defaults to 2.0.
  final double borderRadius;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Stack(
      children: [
        // Background (inactive)
        Container(
          decoration: BoxDecoration(
            color: theme.progressBarInactiveColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        // Buffered
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: bufferedProgress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.progressBarBufferedColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
        // Played
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: displayProgress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.progressBarActiveColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ],
    ),
  );
}
