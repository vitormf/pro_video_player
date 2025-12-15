import 'dart:async';

import 'package:flutter/material.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';

/// A dialog that allows users to select and jump to video chapters.
///
/// Shows a scrollable bottom sheet with all available chapters.
/// Each chapter displays its index number, title, and start time.
///
/// Example:
/// ```dart
/// ChaptersPickerDialog.show(
///   context: context,
///   controller: controller,
///   theme: theme,
/// );
/// ```
class ChaptersPickerDialog {
  ChaptersPickerDialog._();

  /// Shows the chapters picker dialog.
  ///
  /// Displays a draggable scrollable bottom sheet with all video chapters.
  /// The currently playing chapter is highlighted.
  static void show({
    required BuildContext context,
    required ProVideoPlayerController controller,
    required VideoPlayerTheme theme,
  }) {
    final chapters = controller.chapters;
    final currentChapter = controller.currentChapter;

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: theme.backgroundColor,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Chapters',
                        style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text('${chapters.length} chapters', style: TextStyle(color: theme.secondaryColor, fontSize: 14)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      final isCurrentChapter = currentChapter?.id == chapter.id;

                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCurrentChapter
                                ? theme.progressBarActiveColor.withValues(alpha: 0.2)
                                : theme.secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrentChapter ? theme.progressBarActiveColor : theme.secondaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          chapter.title,
                          style: TextStyle(
                            color: isCurrentChapter ? theme.progressBarActiveColor : theme.primaryColor,
                            fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          chapter.formattedStartTime,
                          style: TextStyle(color: theme.secondaryColor, fontSize: 12),
                        ),
                        trailing: isCurrentChapter ? Icon(Icons.play_arrow, color: theme.progressBarActiveColor) : null,
                        onTap: () {
                          unawaited(controller.seekToChapter(chapter));
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
