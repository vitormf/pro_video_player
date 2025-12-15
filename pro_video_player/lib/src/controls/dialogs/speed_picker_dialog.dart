import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';

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
        showMenu<double>(
          context: context,
          position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
          items: speedOptions
              .map(
                (speed) => PopupMenuItem<double>(
                  value: speed,
                  child: Row(
                    children: [
                      Icon(currentSpeed == speed ? Icons.check : null, size: 20),
                      const SizedBox(width: 12),
                      Text('${speed}x'),
                    ],
                  ),
                ),
              )
              .toList(),
        ).then((speed) {
          if (speed != null) {
            unawaited(controller.setPlaybackSpeed(speed));
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
                    'Playback Speed',
                    style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...speedOptions.map(
                  (speed) => ListTile(
                    title: Text(
                      '${speed}x',
                      style: TextStyle(
                        color: currentSpeed == speed ? theme.progressBarActiveColor : theme.primaryColor,
                        fontWeight: currentSpeed == speed ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: currentSpeed == speed ? Icon(Icons.check, color: theme.progressBarActiveColor) : null,
                    onTap: () {
                      unawaited(controller.setPlaybackSpeed(speed));
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
