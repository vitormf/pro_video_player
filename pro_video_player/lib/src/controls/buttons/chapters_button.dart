import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that opens the chapters picker.
///
/// This button displays a list icon and optionally shows the current chapter
/// title next to it. When tapped, it opens a picker to navigate to different
/// chapters in the video.
///
/// Example:
/// ```dart
/// ChaptersButton(
///   theme: VideoPlayerTheme.light(),
///   currentChapterTitle: controller.value.currentChapter?.title,
///   onPressed: () => showChaptersPicker(...),
/// )
/// ```
class ChaptersButton extends StatelessWidget {
  /// Creates a chapters button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [currentChapterTitle] is the title of the current chapter to display,
  /// or null if no chapter is active or should be hidden.
  /// The [onPressed] callback is called when the button is tapped.
  const ChaptersButton({required this.theme, required this.currentChapterTitle, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// The title of the current chapter, or null.
  final String? currentChapterTitle;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Chapters',
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
          Icon(Icons.list, color: theme.primaryColor, size: 18),
          if (currentChapterTitle != null) ...[
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                currentChapterTitle!,
                style: TextStyle(color: theme.primaryColor, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
