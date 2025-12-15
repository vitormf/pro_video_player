import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';

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
    final isDesktop =
        !kIsWeb &&
            (Theme.of(context).platform == TargetPlatform.macOS ||
                Theme.of(context).platform == TargetPlatform.windows ||
                Theme.of(context).platform == TargetPlatform.linux) ||
        kIsWeb;

    // Desktop/web: show as popup menu continuation
    if (isDesktop && lastContextMenuPosition != null) {
      final position = lastContextMenuPosition;
      unawaited(
        showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
          items: tracks
              .map(
                (track) => PopupMenuItem<String>(
                  value: track.id,
                  child: Row(
                    children: [
                      Icon(selectedTrack?.id == track.id ? Icons.check : null, size: 20),
                      const SizedBox(width: 12),
                      Text(track.label),
                    ],
                  ),
                ),
              )
              .toList(),
        ).then((value) {
          if (value != null) {
            final track = tracks.firstWhere((t) => t.id == value);
            unawaited(controller.setAudioTrack(track));
          }
          onDismiss();
        }),
      );
      return;
    }

    // Mobile: show as bottom sheet
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: theme.backgroundColor,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Audio Tracks',
                    style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // Audio tracks
                ...tracks.map(
                  (track) => ListTile(
                    title: Text(
                      track.label,
                      style: TextStyle(
                        color: selectedTrack?.id == track.id ? theme.progressBarActiveColor : theme.primaryColor,
                        fontWeight: selectedTrack?.id == track.id ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: selectedTrack?.id == track.id
                        ? Icon(Icons.check, color: theme.progressBarActiveColor)
                        : null,
                    onTap: () {
                      unawaited(controller.setAudioTrack(track));
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ).then((_) => onDismiss()),
    );
  }
}
