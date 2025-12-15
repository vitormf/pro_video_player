import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../pro_video_player_controller.dart';
import '../video_player_theme.dart';

/// A compact video player layout optimized for small player sizes or PiP mode.
///
/// This layout provides:
/// - Large center play/pause button
/// - Interactive progress bar at bottom
/// - Minimal UI footprint
///
/// Best suited for:
/// - Picture-in-Picture mode
/// - Small embedded players
/// - Mobile layouts with limited space
///
/// Example:
/// ```dart
/// CompactLayout(
///   controller: videoController,
///   theme: VideoPlayerTheme.light(),
/// )
/// ```
class CompactLayout extends StatefulWidget {
  /// Creates a compact video player layout.
  ///
  /// The [controller] must be initialized before the widget is built.
  /// The [theme] defines the visual appearance of the controls.
  const CompactLayout({required this.controller, required this.theme, super.key});

  /// The video player controller that manages playback.
  final ProVideoPlayerController controller;

  /// The theme that defines colors and styles for the controls.
  final VideoPlayerTheme theme;

  @override
  State<CompactLayout> createState() => _CompactLayoutState();
}

class _CompactLayoutState extends State<CompactLayout> {
  // Progress bar drag state
  bool _isDragging = false;
  double? _dragProgress;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // Center play/pause button
      Expanded(
        child: Center(
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: widget.controller,
            builder: (context, value, child) {
              if (value.playbackState == PlaybackState.buffering) {
                return CircularProgressIndicator(color: widget.theme.primaryColor);
              }
              return IconButton(
                icon: Icon(
                  value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: widget.theme.primaryColor,
                ),
                iconSize: 64,
                onPressed: value.isPlaying ? widget.controller.pause : widget.controller.play,
              );
            },
          ),
        ),
      ),
      // Interactive progress bar at bottom
      ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: widget.controller,
        builder: (context, value, child) {
          final duration = value.duration;
          final position = value.position;
          final progress = duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;
          final bufferedProgress = duration.inMilliseconds > 0
              ? value.bufferedPosition.inMilliseconds / duration.inMilliseconds
              : 0.0;
          final displayProgress = _isDragging && _dragProgress != null ? _dragProgress! : progress;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SizedBox(
              height: 16, // Taller hit area for easier interaction
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  return GestureDetector(
                    onTapDown: (details) {
                      if (duration.inMilliseconds <= 0) return;
                      final localX = details.localPosition.dx;
                      final newProgress = (localX / barWidth).clamp(0.0, 1.0);
                      final newPosition = Duration(milliseconds: (newProgress * duration.inMilliseconds).round());
                      unawaited(widget.controller.seekTo(newPosition));
                    },
                    onHorizontalDragStart: (details) {
                      if (duration.inMilliseconds <= 0) return;
                      setState(() {
                        _isDragging = true;
                        final localX = details.localPosition.dx;
                        _dragProgress = (localX / barWidth).clamp(0.0, 1.0);
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      if (duration.inMilliseconds <= 0 || !_isDragging) return;
                      setState(() {
                        final localX = details.localPosition.dx;
                        _dragProgress = (localX / barWidth).clamp(0.0, 1.0);
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_dragProgress != null && duration.inMilliseconds > 0) {
                        final newPosition = Duration(milliseconds: (_dragProgress! * duration.inMilliseconds).round());
                        unawaited(widget.controller.seekTo(newPosition));
                      }
                      setState(() {
                        _isDragging = false;
                        _dragProgress = null;
                      });
                    },
                    onHorizontalDragCancel: () {
                      setState(() {
                        _isDragging = false;
                        _dragProgress = null;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress bar (4px tall, centered in 16px hit area)
                        SizedBox(
                          height: 4,
                          child: Stack(
                            children: [
                              // Background
                              Container(
                                decoration: BoxDecoration(
                                  color: widget.theme.progressBarInactiveColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Buffered
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: bufferedProgress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: widget.theme.progressBarBufferedColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Played
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: displayProgress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: widget.theme.progressBarActiveColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    ],
  );
}
