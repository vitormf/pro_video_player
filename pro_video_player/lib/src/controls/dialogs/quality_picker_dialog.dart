import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';
import '../video_controls_utils.dart';

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
          items: [
            // "Auto" option
            PopupMenuItem<String>(
              value: 'auto',
              child: Row(
                children: [
                  Icon(isAutoSelected ? Icons.check : null, size: 20),
                  const SizedBox(width: 12),
                  const Text('Auto'),
                ],
              ),
            ),
            // Quality tracks (sorted by height descending)
            ...VideoControlsUtils.sortedQualityTracks(tracks).map(
              (track) => PopupMenuItem<String>(
                value: track.id,
                child: Row(
                  children: [
                    Icon(selectedTrack?.id == track.id ? Icons.check : null, size: 20),
                    const SizedBox(width: 12),
                    Text(track.displayLabel),
                  ],
                ),
              ),
            ),
          ],
        ).then((value) {
          if (value == 'auto') {
            unawaited(controller.setVideoQuality(VideoQualityTrack.auto));
          } else if (value != null) {
            final track = tracks.firstWhere((t) => t.id == value);
            unawaited(controller.setVideoQuality(track));
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
                    'Video Quality',
                    style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // "Auto" option
                ListTile(
                  title: Text(
                    'Auto',
                    style: TextStyle(
                      color: isAutoSelected ? theme.progressBarActiveColor : theme.primaryColor,
                      fontWeight: isAutoSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    'Adjust automatically based on network',
                    style: TextStyle(color: theme.primaryColor.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  trailing: isAutoSelected ? Icon(Icons.check, color: theme.progressBarActiveColor) : null,
                  onTap: () {
                    unawaited(controller.setVideoQuality(VideoQualityTrack.auto));
                    Navigator.pop(context);
                  },
                ),
                // Quality tracks (sorted by height descending)
                ...VideoControlsUtils.sortedQualityTracks(tracks).map(
                  (track) => ListTile(
                    title: Text(
                      track.displayLabel,
                      style: TextStyle(
                        color: selectedTrack?.id == track.id ? theme.progressBarActiveColor : theme.primaryColor,
                        fontWeight: selectedTrack?.id == track.id ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: selectedTrack?.id == track.id
                        ? Icon(Icons.check, color: theme.progressBarActiveColor)
                        : null,
                    onTap: () {
                      unawaited(controller.setVideoQuality(track));
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
