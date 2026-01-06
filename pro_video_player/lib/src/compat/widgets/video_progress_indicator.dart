/// VideoProgressIndicator widget for video_player API compatibility.
///
/// This widget provides the exact video_player API signature for compatibility.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../compat_annotation.dart';
import '../video_player_controller.dart';
import 'video_progress_colors.dart';

/// A progress indicator for video playback.
///
/// [video_player compatibility] This widget matches the video_player API exactly.
@videoPlayerCompat
class VideoProgressIndicator extends StatefulWidget {
  /// Creates a video progress indicator.
  ///
  /// [video_player compatibility] This constructor matches video_player exactly.
  const VideoProgressIndicator(
    this.controller, {
    required this.allowScrubbing,
    super.key,
    this.colors = const VideoProgressColors(),
    this.padding = const EdgeInsets.only(top: 5),
  });

  /// The controller for the video being displayed.
  final VideoPlayerController controller;

  /// The colors to use for the progress indicator.
  final VideoProgressColors colors;

  /// Whether to allow scrubbing (seeking by dragging).
  final bool allowScrubbing;

  /// The padding around the progress indicator.
  final EdgeInsets padding;

  @override
  State<VideoProgressIndicator> createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<VideoProgressIndicator> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    widget.controller.removeListener(_listener);
    super.deactivate();
  }

  @override
  void didUpdateWidget(VideoProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_listener);
      widget.controller.addListener(_listener);
    }
  }

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;

    Widget progressIndicator;
    if (value.isInitialized) {
      final duration = value.duration.inMilliseconds;
      final position = value.position.inMilliseconds;

      var maxBuffering = 0;
      for (final range in value.buffered) {
        final end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      progressIndicator = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          LinearProgressIndicator(
            value: maxBuffering / duration,
            valueColor: AlwaysStoppedAnimation<Color>(widget.colors.bufferedColor),
            backgroundColor: widget.colors.backgroundColor,
          ),
          LinearProgressIndicator(
            value: position / duration,
            valueColor: AlwaysStoppedAnimation<Color>(widget.colors.playedColor),
            backgroundColor: Colors.transparent,
          ),
        ],
      );
    } else {
      progressIndicator = LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(widget.colors.playedColor),
        backgroundColor: widget.colors.backgroundColor,
      );
    }

    final Widget paddedProgressIndicator = Padding(padding: widget.padding, child: progressIndicator);

    if (widget.allowScrubbing) {
      return VideoScrubber(controller: widget.controller, child: paddedProgressIndicator);
    } else {
      return paddedProgressIndicator;
    }
  }
}

/// A widget that allows scrubbing (seeking) through a video.
///
/// [video_player compatibility] This widget matches the video_player API exactly.
@videoPlayerCompat
class VideoScrubber extends StatefulWidget {
  /// Creates a video scrubber.
  ///
  /// [video_player compatibility] This constructor matches video_player exactly.
  const VideoScrubber({required this.child, required this.controller, super.key});

  /// The widget to display (typically a progress indicator).
  final Widget child;

  /// The controller for the video being scrubbed.
  final VideoPlayerController controller;

  @override
  State<VideoScrubber> createState() => _VideoScrubberState();
}

class _VideoScrubberState extends State<VideoScrubber> {
  bool _controllerWasPlaying = false;

  VideoPlayerController get controller => widget.controller;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onHorizontalDragStart: (details) {
      if (!controller.value.isInitialized) {
        return;
      }
      _controllerWasPlaying = controller.value.isPlaying;
      if (_controllerWasPlaying) {
        unawaited(controller.pause());
      }
    },
    onHorizontalDragUpdate: (details) {
      if (!controller.value.isInitialized) {
        return;
      }
      _seekToRelativePosition(details.globalPosition);
    },
    onHorizontalDragEnd: (details) {
      if (_controllerWasPlaying && controller.value.isInitialized) {
        unawaited(controller.play());
      }
    },
    onTapDown: (details) {
      if (!controller.value.isInitialized) {
        return;
      }
      _seekToRelativePosition(details.globalPosition);
    },
    child: widget.child,
  );

  void _seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final tapPos = box.globalToLocal(globalPosition);
    final relative = tapPos.dx / box.size.width;
    final position = controller.value.duration * relative;
    unawaited(controller.seekTo(position));
  }
}
