import 'dart:async';

import 'package:flutter/material.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';
import 'base_picker_dialog.dart';

/// A dialog that allows users to select playback speed.
///
/// On desktop/web with context menu open, shows as a popup menu continuation.
/// On mobile or without context menu, shows as a bottom sheet.
///
/// Example:
/// ```dart
/// SpeedPickerDialog.show(
///   context: context,
///   controller: controller,
///   theme: theme,
///   speedOptions: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
///   lastContextMenuPosition: Offset(100, 200),
///   onDismiss: () => resetHideTimer(),
/// );
/// ```
class SpeedPickerDialog {
  SpeedPickerDialog._();

  /// Shows the speed picker dialog.
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
    required List<double> speedOptions,
    required VoidCallback onDismiss,
    Offset? lastContextMenuPosition,
  }) {
    final currentSpeed = controller.value.playbackSpeed;

    BasePickerDialog.show<double>(
      context: context,
      theme: theme,
      title: 'Playback Speed',
      items: speedOptions,
      itemLabelBuilder: (speed) => '${speed}x',
      isItemSelected: (speed) => currentSpeed == speed,
      onItemSelected: (speed) => unawaited(controller.setPlaybackSpeed(speed)),
      onDismiss: onDismiss,
      lastContextMenuPosition: lastContextMenuPosition,
    );
  }
}
