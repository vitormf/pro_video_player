import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';
import '../video_controls_utils.dart';
import 'base_picker_dialog.dart';

/// A dialog that allows users to select video quality.
///
/// On desktop/web with context menu open, shows as a popup menu continuation.
/// On mobile or without context menu, shows as a bottom sheet.
///
/// Includes an "Auto" option for adaptive quality selection.
///
/// Example:
/// ```dart
/// QualityPickerDialog.show(
///   context: context,
///   controller: controller,
///   theme: theme,
///   lastContextMenuPosition: Offset(100, 200),
///   onDismiss: () => resetHideTimer(),
/// );
/// ```
class QualityPickerDialog {
  QualityPickerDialog._();

  /// Shows the quality picker dialog.
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
    final tracks = controller.value.qualityTracks;
    final selectedTrack = controller.value.selectedQualityTrack;
    final isAutoSelected = selectedTrack == null || selectedTrack.isAuto;

    // Create items list with Auto option first, then sorted quality tracks
    final items = <VideoQualityTrack>[VideoQualityTrack.auto, ...VideoControlsUtils.sortedQualityTracks(tracks)];

    BasePickerDialog.show<VideoQualityTrack>(
      context: context,
      theme: theme,
      title: 'Video Quality',
      items: items,
      itemLabelBuilder: (track) => track.isAuto ? 'Auto' : track.displayLabel,
      isItemSelected: (track) => track.isAuto ? isAutoSelected : selectedTrack?.id == track.id,
      onItemSelected: (track) => unawaited(controller.setVideoQuality(track)),
      onDismiss: onDismiss,
      lastContextMenuPosition: lastContextMenuPosition,
    );
  }
}
