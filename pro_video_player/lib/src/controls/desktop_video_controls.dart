import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../pro_video_player_controller.dart';
import '../video_player_theme.dart';
import 'buttons/fullscreen_button.dart';
import 'controls_enums.dart';
import 'desktop_volume_control.dart';
import 'progress_bar.dart';
import 'seek_preview.dart';

/// Desktop video controls layout.
///
/// This widget implements the desktop-optimized control layout with:
/// - Gradient overlay only at the bottom (video remains visible)
/// - Inline playback controls (play/pause, prev/next)
/// - Progress bar with time labels
/// - Volume control and fullscreen button
/// - Mouse hover interactions
///
/// Example:
/// ```dart
/// DesktopVideoControls(
///   controller: controller,
///   theme: theme,
///   controlsState: controlsState,
///   // ... configuration parameters
/// )
/// ```
class DesktopVideoControls extends StatelessWidget {
  /// Creates desktop video controls.
  const DesktopVideoControls({
    required this.controller,
    required this.theme,
    required this.controlsState,
    required this.gestureSeekPosition,
    required this.dragStartPosition,
    required this.minimalToolbarOnDesktop,
    required this.shouldShowVolumeButton,
    required this.liveScrubbingMode,
    required this.enableSeekBarHoverPreview,
    required this.showFullscreenButton,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onToggleTimeDisplay,
    required this.onMouseEnter,
    required this.onMouseExit,
    required this.onResetHideTimer,
    required this.onFullscreenEnter,
    required this.onFullscreenExit,
    super.key,
  });

  /// The video player controller.
  final ProVideoPlayerController controller;

  /// The theme for styling.
  final VideoPlayerTheme theme;

  /// The controls state.
  final dynamic controlsState; // VideoControlsState

  /// The current seek position during gesture seeking.
  final Duration? gestureSeekPosition;

  /// The starting position when a drag began.
  final Duration? dragStartPosition;

  /// Whether to use minimal toolbar on desktop.
  final bool minimalToolbarOnDesktop;

  /// Whether to show volume button.
  final bool shouldShowVolumeButton;

  /// Live scrubbing mode.
  final LiveScrubbingMode liveScrubbingMode;

  /// Whether to enable seek bar hover preview.
  final bool enableSeekBarHoverPreview;

  /// Whether to show fullscreen button.
  final bool showFullscreenButton;

  /// Callback when dragging starts.
  final VoidCallback onDragStart;

  /// Callback when dragging ends.
  final VoidCallback onDragEnd;

  /// Callback to toggle time display.
  final VoidCallback onToggleTimeDisplay;

  /// Callback when mouse enters controls area.
  final VoidCallback onMouseEnter;

  /// Callback when mouse exits controls area.
  final VoidCallback onMouseExit;

  /// Callback to reset hide timer.
  final VoidCallback onResetHideTimer;

  /// Callback to enter fullscreen.
  final VoidCallback onFullscreenEnter;

  /// Callback to exit fullscreen.
  final VoidCallback onFullscreenExit;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, value, child) {
      final position = gestureSeekPosition ?? value.position;
      final duration = value.duration;
      final isDragging = (controlsState as dynamic).isDragging as bool;
      final dragProgress = (controlsState as dynamic).dragProgress as double?;
      final showRemainingTime = (controlsState as dynamic).showRemainingTime as bool;

      return Column(
        children: [
          // Empty expanded space - no overlay here, video is visible
          const Expanded(child: SizedBox.expand()),
          // Seek preview in center when dragging (shown above the controls)
          if (isDragging && dragProgress != null && dragStartPosition != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SeekPreview(
                duration: duration,
                dragProgress: dragProgress,
                dragStartPosition: dragStartPosition!,
                theme: theme,
              ),
            ),
          // Buffering indicator (shown above the controls)
          if (value.playbackState == PlaybackState.buffering && !isDragging)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CircularProgressIndicator(color: theme.primaryColor),
            ),
          // Bottom controls with gradient background
          MouseRegion(
            onEnter: (_) => onMouseEnter(),
            onExit: (_) {
              onMouseExit();
              onResetHideTimer();
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              // Single row: [Play] [Prev/Next?] [Seekbar] [Time] [Volume] [Fullscreen]
              child: Row(
                children: [
                  // Playlist previous (if applicable and not minimal mode)
                  if (!minimalToolbarOnDesktop && value.playlist != null)
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: theme.primaryColor),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Previous',
                      onPressed: controller.playlistPrevious,
                    ),
                  // Play/pause button
                  IconButton(
                    icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow, color: theme.primaryColor),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: value.isPlaying ? 'Pause' : 'Play',
                    onPressed: () => value.isPlaying ? controller.pause() : controller.play(),
                  ),
                  // Playlist next (if applicable and not minimal mode)
                  if (!minimalToolbarOnDesktop && value.playlist != null)
                    IconButton(
                      icon: Icon(Icons.skip_next, color: theme.primaryColor),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Next',
                      onPressed: controller.playlistNext,
                    ),
                  const SizedBox(width: 8),
                  // Progress bar (expanded)
                  Expanded(
                    child: ProgressBar(
                      controller: controller,
                      theme: theme,
                      liveScrubbingMode: liveScrubbingMode,
                      enableSeekBarHoverPreview: enableSeekBarHoverPreview,
                      onDragStart: onDragStart,
                      onDragEnd: onDragEnd,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time display: current / total (tap to toggle remaining)
                  GestureDetector(
                    onTap: onToggleTimeDisplay,
                    child: Text(
                      showRemainingTime
                          ? '${formatVideoDuration(position)} / -${formatVideoDuration(duration - position)}'
                          : '${formatVideoDuration(position)} / ${formatVideoDuration(duration)}',
                      style: TextStyle(color: theme.secondaryColor, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Volume control
                  if (shouldShowVolumeButton) DesktopVolumeControl(controller: controller, theme: theme),
                  // Fullscreen button
                  if (showFullscreenButton && !minimalToolbarOnDesktop)
                    FullscreenButton(
                      theme: theme,
                      isFullscreen: value.isFullscreen,
                      onEnter: onFullscreenEnter,
                      onExit: onFullscreenExit,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
