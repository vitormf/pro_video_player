import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';
import 'base_picker_dialog.dart';

/// A dialog that allows users to select audio track.
///
/// On desktop/web with context menu open, shows as a popup menu continuation.
/// On mobile or without context menu, shows as a bottom sheet.
///
/// Example:
/// ```dart
/// AudioPickerDialog.show(
///   context: context,
///   controller: controller,
///   theme: theme,
///   lastContextMenuPosition: Offset(100, 200),
///   onDismiss: () => resetHideTimer(),
/// );
/// ```
class AudioPickerDialog {
  AudioPickerDialog._();

  /// Shows the audio track picker dialog.
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
    final tracks = controller.value.audioTracks;
    final selectedTrack = controller.value.selectedAudioTrack;

    BasePickerDialog.show<AudioTrack>(
      context: context,
      theme: theme,
      title: 'Audio Tracks',
      items: tracks,
      itemLabelBuilder: (track) => track.label,
      isItemSelected: (track) => selectedTrack?.id == track.id,
      onItemSelected: (track) => unawaited(controller.setAudioTrack(track)),
      onDismiss: onDismiss,
      lastContextMenuPosition: lastContextMenuPosition,
    );
  }
}
