import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../pro_video_player_controller.dart';
import '../../video_player_theme.dart';

/// A dialog that allows users to lock screen orientation in fullscreen mode.
///
/// Shows a bottom sheet with orientation options:
/// - Auto-rotate (no lock)
/// - Landscape (both directions)
/// - Landscape Left
/// - Landscape Right
///
/// Example:
/// ```dart
/// OrientationLockPickerDialog.show(
///   context: context,
///   controller: controller,
///   theme: theme,
/// );
/// ```
class OrientationLockPickerDialog {
  OrientationLockPickerDialog._();

  /// Shows the orientation lock picker dialog.
  ///
  /// Displays a bottom sheet with orientation lock options.
  /// The currently locked orientation (if any) is highlighted.
  static void show({
    required BuildContext context,
    required ProVideoPlayerController controller,
    required VideoPlayerTheme theme,
  }) {
    final currentLock = controller.value.lockedOrientation;

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
                    'Screen Orientation',
                    style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildOrientationOption(
                  theme: theme,
                  title: 'Auto-rotate',
                  subtitle: 'Follow device orientation',
                  icon: Icons.screen_rotation,
                  isSelected: currentLock == null,
                  onTap: () {
                    unawaited(controller.unlockOrientation());
                    Navigator.pop(context);
                  },
                ),
                _buildOrientationOption(
                  theme: theme,
                  title: 'Landscape',
                  subtitle: 'Lock to landscape (both directions)',
                  icon: Icons.screen_lock_landscape,
                  isSelected: currentLock == FullscreenOrientation.landscapeBoth,
                  onTap: () {
                    unawaited(controller.lockOrientation(FullscreenOrientation.landscapeBoth));
                    Navigator.pop(context);
                  },
                ),
                _buildOrientationOption(
                  theme: theme,
                  title: 'Landscape Left',
                  subtitle: 'Lock to landscape left only',
                  icon: Icons.screen_lock_landscape,
                  isSelected: currentLock == FullscreenOrientation.landscapeLeft,
                  onTap: () {
                    unawaited(controller.lockOrientation(FullscreenOrientation.landscapeLeft));
                    Navigator.pop(context);
                  },
                ),
                _buildOrientationOption(
                  theme: theme,
                  title: 'Landscape Right',
                  subtitle: 'Lock to landscape right only',
                  icon: Icons.screen_lock_landscape,
                  isSelected: currentLock == FullscreenOrientation.landscapeRight,
                  onTap: () {
                    unawaited(controller.lockOrientation(FullscreenOrientation.landscapeRight));
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildOrientationOption({
    required VideoPlayerTheme theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Icon(icon, color: isSelected ? theme.progressBarActiveColor : theme.primaryColor),
    title: Text(
      title,
      style: TextStyle(
        color: isSelected ? theme.progressBarActiveColor : theme.primaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    subtitle: Text(subtitle, style: TextStyle(color: theme.primaryColor.withValues(alpha: 0.7), fontSize: 12)),
    trailing: isSelected ? Icon(Icons.check, color: theme.progressBarActiveColor) : null,
    onTap: onTap,
  );
}
