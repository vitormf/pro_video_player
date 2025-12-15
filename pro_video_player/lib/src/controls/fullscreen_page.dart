import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../pro_video_player.dart';
import '../pro_video_player_controller.dart';
import '../video_player_controls.dart';
import '../video_player_theme.dart';
import 'fullscreen_status_bar.dart';

/// Internal fullscreen video page shown when entering fullscreen mode.
class FullscreenVideoPage extends StatelessWidget {
  /// Creates a fullscreen video page.
  const FullscreenVideoPage({
    required this.controller,
    required this.onExitFullscreen,
    super.key,
    this.theme,
    this.subtitleStyle,
    this.onDismiss,
  });

  /// The video player controller.
  final ProVideoPlayerController controller;

  /// Callback when exiting fullscreen.
  final VoidCallback onExitFullscreen;

  /// Optional theme override.
  final VideoPlayerTheme? theme;

  /// Optional subtitle style configuration.
  final SubtitleStyle? subtitleStyle;

  /// Callback when dismiss button is tapped (for fullscreen-only mode).
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? VideoPlayerThemeData.of(context);
    final isFullscreenOnly = controller.options.fullscreenOnly;

    return PopScope(
      // Block back navigation when fullscreenOnly is enabled (unless onDismiss handles it)
      canPop: !isFullscreenOnly,
      onPopInvokedWithResult: (didPop, result) {
        // If pop was blocked and we have an onDismiss callback, use it
        if (!didPop && isFullscreenOnly && onDismiss != null) {
          onDismiss!();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // Prevent resizing when system bars appear/disappear
        resizeToAvoidBottomInset: false,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Video player with controls filling the screen
            ProVideoPlayer(controller: controller, controlsMode: ControlsMode.none),

            // Fullscreen controls overlay
            VideoPlayerControls(
              controller: controller,
              theme: effectiveTheme,
              subtitleStyle: subtitleStyle,
              // Prevent recursive fullscreen - use custom handlers
              onEnterFullscreen: () {}, // Already in fullscreen
              onExitFullscreen: onExitFullscreen,
              onDismiss: onDismiss,
            ),

            // Fullscreen status bar (always visible, top of screen)
            if (controller.options.showFullscreenStatusBar)
              Positioned(top: 0, left: 0, right: 0, child: FullscreenStatusBar(controller: controller)),
          ],
        ),
      ),
    );
  }
}
