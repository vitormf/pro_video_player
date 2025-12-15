import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';
import '../video_controls_utils.dart';

/// A dialog that allows users to select video scaling mode.
///
/// Shows a bottom sheet with available scaling mode options (fit, fill, stretch).
/// Each option includes a label and description explaining the behavior.
///
/// Example:
/// ```dart
/// ScalingModePickerDialog.show(
///   context: context,
///   controller: controller,
///   theme: theme,
///   scalingModeOptions: [VideoScalingMode.fit, VideoScalingMode.fill, VideoScalingMode.stretch],
///   onDismiss: () => resetHideTimer(),
/// );
/// ```
class ScalingModePickerDialog {
  ScalingModePickerDialog._();

  /// Shows the scaling mode picker dialog.
  ///
  /// Displays a bottom sheet with scaling mode options.
  /// The [onDismiss] callback is called when the dialog is closed,
  /// allowing the parent to reset auto-hide timers.
  static void show({
    required BuildContext context,
    required ProVideoPlayerController controller,
    required VideoPlayerTheme theme,
    required List<VideoScalingMode> scalingModeOptions,
    required VoidCallback onDismiss,
  }) {
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
                    'Video Scaling Mode',
                    style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...scalingModeOptions.map(
                  (mode) => ListTile(
                    title: Text(
                      VideoControlsUtils.getScalingModeLabel(mode),
                      style: TextStyle(color: theme.primaryColor),
                    ),
                    subtitle: Text(
                      VideoControlsUtils.getScalingModeDescription(mode),
                      style: TextStyle(color: theme.primaryColor.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await controller.setScalingMode(mode);
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
