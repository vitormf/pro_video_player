import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../video_player_theme.dart';

/// A mini progress bar shown during seek gestures.
///
/// Displays:
/// - Total duration as background bar
/// - Buffered region (lighter color)
/// - Current position marker
/// - Seek target position marker
/// - Chapter markers (if available)
///
/// Styled as a YouTube-like horizontal mini bar.
class SeekPreviewProgressBar extends StatelessWidget {
  /// Creates a seek preview progress bar.
  const SeekPreviewProgressBar({
    required this.currentPosition,
    required this.seekTargetPosition,
    required this.duration,
    required this.bufferedPosition,
    required this.theme,
    super.key,
    this.chapters = const [],
    this.width = 280.0,
    this.height = 4.0,
  });

  /// The current playback position (before seeking).
  final Duration currentPosition;

  /// The target position being previewed.
  final Duration seekTargetPosition;

  /// The total video duration.
  final Duration duration;

  /// The buffered position.
  final Duration bufferedPosition;

  /// The theme for styling.
  final VideoPlayerTheme theme;

  /// Optional chapter markers to display.
  final List<Chapter> chapters;

  /// Width of the progress bar.
  final double width;

  /// Height of the progress bar track.
  final double height;

  @override
  Widget build(BuildContext context) {
    // Avoid division by zero
    if (duration.inMilliseconds <= 0) {
      return const SizedBox.shrink();
    }

    final currentFraction = currentPosition.inMilliseconds / duration.inMilliseconds;
    final seekTargetFraction = seekTargetPosition.inMilliseconds / duration.inMilliseconds;
    final bufferedFraction = bufferedPosition.inMilliseconds / duration.inMilliseconds;

    return Container(
      width: width,
      height: height + 16, // Extra height for markers
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background track (total duration)
          Positioned(
            left: 0,
            right: 0,
            top: 6,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),

          // Buffered region
          Positioned(
            left: 0,
            top: 6,
            child: Container(
              width: width * bufferedFraction.clamp(0.0, 1.0),
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),

          // Chapter markers
          ...chapters.map((chapter) {
            final chapterFraction = chapter.startTime.inMilliseconds / duration.inMilliseconds;
            return Positioned(
              left: (width * chapterFraction.clamp(0.0, 1.0)) - 1,
              top: 6,
              child: Container(width: 2, height: height, color: Colors.white.withValues(alpha: 0.7)),
            );
          }),

          // Current position marker
          Positioned(
            left: (width * currentFraction.clamp(0.0, 1.0)) - 4,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.secondaryColor.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4)],
              ),
            ),
          ),

          // Seek target position marker (larger, different color)
          Positioned(
            left: (width * seekTargetFraction.clamp(0.0, 1.0)) - 6,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
