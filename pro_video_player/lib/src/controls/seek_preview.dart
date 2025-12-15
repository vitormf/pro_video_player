import 'package:flutter/material.dart';

import '../video_player_theme.dart';

/// A preview widget shown while seeking through video playback.
///
/// Displays the target position and the time difference from the starting
/// position with appropriate icons and styling.
class SeekPreview extends StatelessWidget {
  /// Creates a seek preview widget.
  const SeekPreview({
    required this.dragProgress,
    required this.dragStartPosition,
    required this.duration,
    required this.theme,
    super.key,
  });

  /// The current drag progress (0.0 to 1.0).
  final double dragProgress;

  /// The position where dragging started.
  final Duration dragStartPosition;

  /// The total duration of the video.
  final Duration duration;

  /// The theme for styling the preview.
  final VideoPlayerTheme theme;

  @override
  Widget build(BuildContext context) {
    final targetPosition = Duration(milliseconds: (dragProgress * duration.inMilliseconds).round());
    final difference = targetPosition - dragStartPosition;
    final isForward = difference.inMilliseconds >= 0;
    final absDifference = Duration(milliseconds: difference.inMilliseconds.abs());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // FittedBox ensures the content scales down if there's not enough vertical space
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatVideoDuration(targetPosition),
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isForward ? Icons.fast_forward : Icons.fast_rewind,
                  color: theme.secondaryColor,
                  size: 18,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
                ),
                const SizedBox(width: 6),
                Text(
                  '${isForward ? '+' : '-'}${formatVideoDuration(absDifference)}',
                  style: TextStyle(
                    color: theme.secondaryColor,
                    fontSize: 16,
                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
