import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../video_player_theme.dart';

/// A button that opens the orientation lock picker.
///
/// Displays different icons based on locked orientation:
/// - Unlocked: screen_rotation icon with primary color
/// - Landscape locked: screen_lock_landscape icon with active color
/// - Portrait locked: screen_lock_portrait icon with active color
/// - All (unlocked): screen_rotation icon with primary color
class OrientationLockButton extends StatelessWidget {
  /// Creates an orientation lock button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [lockedOrientation] determines which icon to show.
  /// The [onPressed] callback is called when the button is tapped.
  const OrientationLockButton({
    required this.theme,
    required this.lockedOrientation,
    required this.onPressed,
    super.key,
  });

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// The currently locked orientation, or null if unlocked.
  final FullscreenOrientation? lockedOrientation;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLocked = lockedOrientation != null;

    // Choose icon based on lock state
    IconData icon;
    if (!isLocked) {
      icon = Icons.screen_rotation;
    } else {
      switch (lockedOrientation!) {
        case FullscreenOrientation.landscapeBoth:
        case FullscreenOrientation.landscapeLeft:
        case FullscreenOrientation.landscapeRight:
          icon = Icons.screen_lock_landscape;
        case FullscreenOrientation.portraitUp:
        case FullscreenOrientation.portraitDown:
        case FullscreenOrientation.portraitBoth:
          icon = Icons.screen_lock_portrait;
        case FullscreenOrientation.all:
          icon = Icons.screen_rotation;
      }
    }

    return IconButton(
      icon: Icon(icon, color: isLocked ? theme.progressBarActiveColor : theme.primaryColor),
      iconSize: 20,
      tooltip: isLocked ? 'Orientation locked' : 'Lock orientation',
      onPressed: onPressed,
    );
  }
}
