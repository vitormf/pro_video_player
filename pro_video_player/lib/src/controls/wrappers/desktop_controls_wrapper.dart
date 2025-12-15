import 'dart:async';

import 'package:flutter/gestures.dart' show PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent, LogicalKeyboardKey;

import '../../pro_video_player_controller.dart';
import '../../video_controls_controller.dart';
import '../../video_controls_state.dart';
import '../../video_player_theme.dart';
import '../keyboard_overlay.dart';

/// Desktop controls wrapper with keyboard shortcuts, context menu, and mouse interactions.
///
/// This wrapper provides desktop-specific interactions:
/// - Single tap: Play/pause
/// - Double tap: Fullscreen toggle
/// - Mouse hover: Show controls
/// - Keyboard shortcuts: Space, arrows, F, Escape, etc.
/// - Right-click: Context menu
class DesktopControlsWrapper extends StatelessWidget {
  /// Creates a desktop controls wrapper.
  const DesktopControlsWrapper({
    required this.child,
    required this.controller,
    required this.controlsController,
    required this.theme,
    required this.showFullscreenButton,
    required this.onEnterFullscreen,
    required this.onExitFullscreen,
    super.key,
  });

  /// The controls content to wrap.
  final Widget child;

  /// The video player controller.
  final ProVideoPlayerController controller;

  /// The controls controller.
  final VideoControlsController controlsController;

  /// The theme for styling.
  final VideoPlayerTheme theme;

  /// Whether to show the fullscreen button.
  final bool showFullscreenButton;

  /// Callback to enter fullscreen.
  final VoidCallback onEnterFullscreen;

  /// Callback to exit fullscreen.
  final VoidCallback onExitFullscreen;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // First, let controller handle non-fullscreen keys
    final result = controlsController.handleKeyEvent(node, event);
    if (result == KeyEventResult.handled) {
      return result;
    }

    // Handle fullscreen-specific keys (F and Escape)
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // F: Toggle fullscreen
      if (key == LogicalKeyboardKey.keyF && showFullscreenButton) {
        final isFullscreen = controller.value.isFullscreen;
        if (isFullscreen) {
          onExitFullscreen();
        } else {
          onEnterFullscreen();
        }
        controlsController.resetHideTimer();
        return KeyEventResult.handled;
      }

      // Escape: Exit fullscreen (when in fullscreen mode)
      if (key == LogicalKeyboardKey.escape && showFullscreenButton) {
        final isFullscreen = controller.value.isFullscreen;
        if (isFullscreen) {
          onExitFullscreen();
          controlsController.resetHideTimer();
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Vertical scroll: Adjust volume
      // Positive scrollDelta.dy = scroll down (decrease volume)
      // Negative scrollDelta.dy = scroll up (increase volume)
      final scrollDelta = event.scrollDelta.dy;

      if (scrollDelta.abs() > 0) {
        final currentVolume = controller.value.volume;
        // Each scroll tick changes volume by 0.05 (matching keyboard shortcuts)
        final volumeChange = scrollDelta > 0 ? -0.05 : 0.05;
        final newVolume = (currentVolume + volumeChange).clamp(0.0, 1.0);

        if (newVolume != currentVolume) {
          unawaited(controller.setVolume(newVolume));
          controlsController
            ..showKeyboardOverlay(KeyboardOverlayType.volume, newVolume)
            ..resetHideTimer();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _handleScroll,
    child: GestureDetector(
      behavior: HitTestBehavior.deferToChild, // Let child widgets handle taps first
      onTap: () {
        if (controller.value.isPlaying) {
          unawaited(controller.pause());
        } else {
          unawaited(controller.play());
        }
      },
      onDoubleTap: showFullscreenButton
          ? () {
              if (controller.value.isFullscreen) {
                onExitFullscreen();
              } else {
                onEnterFullscreen();
              }
            }
          : null,
      onSecondaryTapUp: (details) => controlsController.showContextMenu(
        context: context,
        position: details.globalPosition,
        theme: theme,
        onEnterFullscreenCallback: onEnterFullscreen,
        onExitFullscreenCallback: onExitFullscreen,
      ),
      child: Focus(
        focusNode: controlsController.focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onEnter: (_) => controlsController.onMouseHover(),
          onHover: (_) => controlsController.onMouseHover(),
          child: Stack(
            children: [
              child,
              // Keyboard overlay
              if (controlsController.controlsState.keyboardOverlayType != null)
                KeyboardOverlay(
                  type: controlsController.controlsState.keyboardOverlayType,
                  value: controlsController.controlsState.keyboardOverlayValue,
                  theme: theme,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
