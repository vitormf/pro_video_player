import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';
import 'base_picker_dialog.dart';

/// A dialog that allows users to select subtitle track.
///
/// On desktop/web with context menu open, shows as a popup menu continuation.
/// On mobile or without context menu, shows as a bottom sheet.
///
/// Includes an "Off" option to disable subtitles.
///
/// Example:
/// ```dart
/// SubtitlePickerDialog.show(
///   context: context,
///   controller: controller,
///   theme: theme,
///   lastContextMenuPosition: Offset(100, 200),
///   onDismiss: () => resetHideTimer(),
/// );
/// ```
class SubtitlePickerDialog {
  SubtitlePickerDialog._();

  /// Shows the subtitle track picker dialog.
  ///
  /// The dialog adapts to the platform:
  /// - Desktop/web with [lastContextMenuPosition]: popup menu at that position
  /// - Mobile or no context menu position: bottom sheet
  ///
  /// The [onDismiss] callback is called when the dialog is closed,
  /// allowing the parent to reset auto-hide timers.
  static void show({
    required BuildContext context,
    required ProVideoPlayerController controller,
    required VideoPlayerTheme theme,
    required VoidCallback onDismiss,
    Offset? lastContextMenuPosition,
  }) {
    final tracks = controller.value.subtitleTracks;
    final selectedTrack = controller.value.selectedSubtitleTrack;

    // Create items list with null representing "Off" option
    final items = <SubtitleTrack?>[null, ...tracks];

    BasePickerDialog.show<SubtitleTrack?>(
      context: context,
      theme: theme,
      title: 'Subtitles',
      items: items,
      itemLabelBuilder: (track) => track == null ? 'Off' : track.label,
      isItemSelected: (track) => track == null ? selectedTrack == null : selectedTrack?.id == track.id,
      onItemSelected: (track) => unawaited(controller.setSubtitleTrack(track)),
      onDismiss: onDismiss,
      lastContextMenuPosition: lastContextMenuPosition,
    );
  }
}
