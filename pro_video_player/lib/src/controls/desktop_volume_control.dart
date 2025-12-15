import 'dart:async';

import 'package:flutter/material.dart';

import '../pro_video_player_controller.dart';
import '../video_player_theme.dart';

/// Desktop volume control widget with mute/unmute button and horizontal slider.
///
/// This widget is optimized for desktop platforms, providing a compact inline
/// volume control that fits well in the bottom control bar.
///
/// Example:
/// ```dart
/// DesktopVolumeControl(
///   controller: controller,
///   theme: theme,
/// )
/// ```
class DesktopVolumeControl extends StatelessWidget {
  /// Creates a desktop volume control.
  const DesktopVolumeControl({required this.controller, required this.theme, super.key});

  /// The video player controller.
  final ProVideoPlayerController controller;

  /// The theme for styling the control.
  final VideoPlayerTheme theme;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: controller,
    builder: (context, value, child) {
      final volume = value.volume;
      final isMuted = volume == 0;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mute/unmute button
          IconButton(
            icon: Icon(
              isMuted ? Icons.volume_off : (volume > 0.5 ? Icons.volume_up : Icons.volume_down),
              color: theme.primaryColor,
            ),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: isMuted ? 'Unmute' : 'Mute',
            onPressed: () {
              unawaited(controller.setVolume(isMuted ? 1.0 : 0.0));
            },
          ),
          // Horizontal volume slider
          SizedBox(
            width: 60,
            height: 20,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: theme.primaryColor,
                inactiveTrackColor: theme.progressBarInactiveColor,
                thumbColor: theme.primaryColor,
                overlayColor: theme.primaryColor.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: volume,
                onChanged: (newVolume) {
                  unawaited(controller.setVolume(newVolume));
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}
