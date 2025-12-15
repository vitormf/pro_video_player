import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'controls/seek_preview_progress_bar.dart';
import 'pro_video_player_controller.dart';
import 'video_player_theme.dart';

/// The type of gesture currently being performed.
enum _GestureType {
  /// Horizontal swipe for seeking through video.
  seek,

  /// Vertical swipe on right side for volume control.
  volume,

  /// Vertical swipe on left side for brightness control.
  brightness,

  /// Two-finger vertical swipe for playback speed.
  playbackSpeed,
}

/// A widget that provides gesture-based controls for video playback.
///
/// This widget implements intuitive gesture controls:
/// - **Single tap**: Toggle controls visibility
/// - **Double tap left**: Seek backward
/// - **Double tap center**: Play/pause
/// - **Double tap right**: Seek forward
/// - **Vertical swipe left**: Adjust brightness
/// - **Vertical swipe right**: Adjust volume
/// - **Horizontal swipe**: Seek through video
///
/// ## Example
///
/// ```dart
/// VideoPlayerGestureDetector(
///   controller: controller,
///   seekDuration: Duration(seconds: 10),
///   onControlsVisibilityChanged: (visible) {
///     setState(() => _controlsVisible = visible);
///   },
///   child: ProVideoPlayer(controller: controller),
/// )
/// ```
class VideoPlayerGestureDetector extends StatefulWidget {
  /// Creates a video player gesture detector.
  const VideoPlayerGestureDetector({
    required this.controller,
    required this.child,
    super.key,
    this.seekDuration = const Duration(seconds: 10),
    this.seekSecondsPerInch = 20.0,
    this.enableDoubleTapSeek = true,
    this.enableVolumeGesture = true,
    this.enableBrightnessGesture = true,
    this.enableSeekGesture = true,
    this.enablePlaybackSpeedGesture = true,
    this.showFeedback = true,
    this.autoHideControls = true,
    this.autoHideDelay = const Duration(seconds: 2),
    this.verticalGestureThreshold = 30.0,
    this.sideGestureAreaFraction = 0.3,
    this.bottomExclusionHeight = 100.0,
    this.onControlsVisibilityChanged,
    this.onBrightnessChanged,
    this.onSeekGestureUpdate,
  });

  /// The video player controller.
  final ProVideoPlayerController controller;

  /// The child widget (typically the video player).
  final Widget child;

  /// Duration to seek forward/backward on double tap.
  ///
  /// Defaults to 10 seconds.
  final Duration seekDuration;

  /// How many seconds to seek per inch of horizontal swipe.
  ///
  /// This controls the sensitivity of the horizontal swipe seek gesture
  /// based on physical distance, ensuring consistent behavior across
  /// devices with different screen densities.
  ///
  /// For example, with the default of 20 seconds per inch, swiping
  /// 0.5 inches will seek 10 seconds, regardless of video duration.
  ///
  /// Defaults to 20 seconds per inch.
  final double seekSecondsPerInch;

  /// Whether to enable double tap to seek.
  ///
  /// Defaults to `true`.
  final bool enableDoubleTapSeek;

  /// Whether to enable volume gestures (vertical swipe on right side).
  ///
  /// Defaults to `true`.
  final bool enableVolumeGesture;

  /// Whether to enable brightness gestures (vertical swipe on left side).
  ///
  /// Defaults to `true`.
  final bool enableBrightnessGesture;

  /// Whether to enable seek gestures (horizontal swipe).
  ///
  /// Defaults to `true`.
  final bool enableSeekGesture;

  /// Whether to enable playback speed gestures (two-finger vertical swipe).
  ///
  /// Defaults to `true`.
  final bool enablePlaybackSpeedGesture;

  /// Whether to show visual feedback for gestures.
  ///
  /// Defaults to `true`.
  final bool showFeedback;

  /// Whether to automatically hide controls after [autoHideDelay] while playing.
  ///
  /// When enabled, controls will automatically hide after the specified delay
  /// when the video is playing. Controls reappear on any interaction.
  ///
  /// Defaults to `true`.
  final bool autoHideControls;

  /// Duration to wait before automatically hiding controls.
  ///
  /// Only applies when [autoHideControls] is `true` and video is playing.
  ///
  /// Defaults to 2 seconds.
  final Duration autoHideDelay;

  /// Minimum vertical drag distance (in logical pixels) before volume/brightness
  /// gestures are activated.
  ///
  /// This threshold helps prevent accidental volume/brightness changes when
  /// the user intends to tap or perform horizontal seek gestures.
  ///
  /// Defaults to 30 pixels.
  final double verticalGestureThreshold;

  /// The width fraction from each edge where volume/brightness gestures are active.
  ///
  /// Volume gestures work on the right edge (within this fraction of screen width),
  /// and brightness gestures work on the left edge.
  ///
  /// For example, 0.3 means gestures are active in the leftmost/rightmost 30%
  /// of the screen width.
  ///
  /// Defaults to 0.3 (30% from each edge).
  final double sideGestureAreaFraction;

  /// The height in logical pixels from the bottom to exclude from volume/brightness gestures.
  ///
  /// This prevents accidental gesture activation when interacting with the
  /// bottom toolbar or seek bar.
  ///
  /// Defaults to 100 pixels.
  final double bottomExclusionHeight;

  /// Called when controls visibility changes.
  final ValueChanged<bool>? onControlsVisibilityChanged;

  /// Called when brightness is changed via gesture.
  final ValueChanged<double>? onBrightnessChanged;

  /// Called when seek gesture is in progress with the target position.
  /// Null when gesture ends.
  final ValueChanged<Duration?>? onSeekGestureUpdate;

  @override
  State<VideoPlayerGestureDetector> createState() => _VideoPlayerGestureDetectorState();
}

class _VideoPlayerGestureDetectorState extends State<VideoPlayerGestureDetector> with SingleTickerProviderStateMixin {
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;
  Timer? _doubleTapTimer;
  Duration? _seekTargetPosition;
  IconData? _feedbackIcon;
  String? _feedbackText;
  late AnimationController _feedbackController;
  double? _dragStartVolume;
  double? _dragStartBrightness;
  Duration? _dragStartPlaybackPosition;
  double? _currentVolume;
  double? _currentBrightness;
  double? _dragStartPlaybackSpeed;
  double? _currentPlaybackSpeed;
  int _pointerCount = 0;
  Offset? _scaleStartPosition;
  bool _hadSignificantMovement = false;
  _GestureType? _lockedGestureType;
  Offset? _lastTapPosition;
  bool _wasPlayingBeforeSeek = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(VideoPlayerGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _hideControlsTimer?.cancel();
    _doubleTapTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  /// Called when the controller value changes.
  /// Handles auto-hide timer when playback starts.
  void _onControllerChanged() {
    // Only start the auto-hide timer if it's not already running
    // This prevents constantly resetting the timer on every controller update
    if (widget.controller.value.isPlaying &&
        _controlsVisible &&
        widget.autoHideControls &&
        _hideControlsTimer == null) {
      _resetHideTimer();
    }
  }

  void _toggleControlsVisibility() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    widget.onControlsVisibilityChanged?.call(_controlsVisible);
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    if (widget.autoHideControls && _controlsVisible && widget.controller.value.isPlaying) {
      _hideControlsTimer = Timer(widget.autoHideDelay, () {
        if (mounted && widget.controller.value.isPlaying) {
          setState(() => _controlsVisible = false);
          widget.onControlsVisibilityChanged?.call(false);
        }
      });
    }
  }

  void _handleDoubleTap(Offset position) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final width = renderBox.size.width;
    final relativeX = position.dx / width;

    if (relativeX <= 0.3) {
      // Left side - seek backward (30% of width)
      unawaited(_seekBackward());
    } else if (relativeX >= 0.7) {
      // Right side - seek forward (30% of width)
      unawaited(_seekForward());
    } else {
      // Center - play/pause (40% of width)
      unawaited(_togglePlayPause());
    }
  }

  Future<void> _seekBackward() async {
    final currentPosition = widget.controller.value.position;
    final newPosition = currentPosition - widget.seekDuration;
    final targetPosition = newPosition.isNegative ? Duration.zero : newPosition;

    await widget.controller.seekTo(targetPosition);

    if (widget.showFeedback) {
      _showFeedback(Icons.fast_rewind, '${widget.seekDuration.inSeconds}s');
    }
  }

  Future<void> _seekForward() async {
    final currentPosition = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    final newPosition = currentPosition + widget.seekDuration;
    final targetPosition = newPosition > duration ? duration : newPosition;

    await widget.controller.seekTo(targetPosition);

    if (widget.showFeedback) {
      _showFeedback(Icons.fast_forward, '${widget.seekDuration.inSeconds}s');
    }
  }

  Future<void> _togglePlayPause() async {
    if (widget.controller.value.isPlaying) {
      await widget.controller.pause();
      if (widget.showFeedback) {
        _showFeedback(Icons.pause, null);
      }
    } else {
      await widget.controller.play();
      if (widget.showFeedback) {
        _showFeedback(Icons.play_arrow, null);
      }
    }
  }

  void _showFeedback(IconData icon, String? text) {
    setState(() {
      _feedbackIcon = icon;
      _feedbackText = text;
    });
    unawaited(_feedbackController.forward(from: 0));
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        unawaited(_feedbackController.reverse());
      }
    });
  }

  /// Checks if brightness gestures are supported on this platform.
  /// Brightness control is only available on mobile platforms (iOS/Android).
  bool get _isBrightnessGestureSupported {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Checks if volume gestures are supported on this platform.
  /// Volume control is available on all non-web platforms.
  bool get _isVolumeGestureSupported {
    if (kIsWeb) return false;
    return true; // Available on all native platforms
  }

  /// Checks if a position is within the valid brightness gesture area (left edge, above bottom).
  bool _isInBrightnessGestureArea(Offset position, RenderBox renderBox) {
    final width = renderBox.size.width;
    final height = renderBox.size.height;
    final relativeX = position.dx / width;

    // Must be on the left edge (within sideGestureAreaFraction)
    if (relativeX >= widget.sideGestureAreaFraction) return false;

    // Must be above the bottom exclusion zone
    if (position.dy > height - widget.bottomExclusionHeight) return false;

    return true;
  }

  /// Checks if a position is within the valid volume gesture area (right edge, above bottom).
  bool _isInVolumeGestureArea(Offset position, RenderBox renderBox) {
    final width = renderBox.size.width;
    final height = renderBox.size.height;
    final relativeX = position.dx / width;

    // Must be on the right edge (within sideGestureAreaFraction from right)
    if (relativeX < 1.0 - widget.sideGestureAreaFraction) return false;

    // Must be above the bottom exclusion zone
    if (position.dy > height - widget.bottomExclusionHeight) return false;

    return true;
  }

  Future<void> _updateBrightness(double brightness) async {
    // Use the platform brightness API
    await widget.controller.setScreenBrightness(brightness);
  }

  /// Fetches the current screen brightness asynchronously when a brightness gesture starts.
  void _fetchScreenBrightnessForGesture() {
    // Use a sensible default while fetching
    _dragStartBrightness = _currentBrightness ?? 0.5;
    // Fetch actual screen brightness asynchronously
    unawaited(
      widget.controller.getScreenBrightness().then((brightness) {
        if (mounted && _dragStartBrightness != null) {
          _dragStartBrightness = brightness;
        }
      }),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _scaleStartPosition = details.localFocalPoint;
    _lastTapPosition = details.localFocalPoint;
    _hadSignificantMovement = false;
    _lockedGestureType = null;

    if (_pointerCount == 2 && widget.enablePlaybackSpeedGesture) {
      // Two-finger gesture for playback speed
      // Only store start value; _currentPlaybackSpeed will be set during update
      _dragStartPlaybackSpeed = widget.controller.value.playbackSpeed;
    } else if (_pointerCount == 1) {
      // Single-finger gesture - prepare for volume/brightness/seek
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      // Prepare for vertical drag (volume/brightness)
      // Only store start values here; _currentVolume/_currentBrightness will be set
      // after the threshold is exceeded to avoid showing feedback prematurely
      // Gestures only work on the side edges and above the bottom toolbar area
      if (_isInBrightnessGestureArea(details.localFocalPoint, renderBox) &&
          widget.enableBrightnessGesture &&
          _isBrightnessGestureSupported) {
        // Fetch screen brightness asynchronously for gesture start
        _fetchScreenBrightnessForGesture();
      } else if (_isInVolumeGestureArea(details.localFocalPoint, renderBox) &&
          widget.enableVolumeGesture &&
          _isVolumeGestureSupported) {
        // Fetch device volume asynchronously for gesture start
        _fetchDeviceVolumeForGesture();
      }

      // Prepare for horizontal drag (seek)
      if (widget.enableSeekGesture) {
        _dragStartPlaybackPosition = widget.controller.value.position;
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_scaleStartPosition == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final deltaX = details.localFocalPoint.dx - _scaleStartPosition!.dx;
    final deltaY = details.localFocalPoint.dy - _scaleStartPosition!.dy;
    final absDeltaX = deltaX.abs();
    final absDeltaY = deltaY.abs();

    // Mark as significant movement if threshold exceeded - this is a swipe, not a tap.
    // Using a small threshold (10 pixels) to distinguish from minor finger jitter.
    if (absDeltaX > 10 || absDeltaY > 10) {
      _hadSignificantMovement = true;
    }

    if (_pointerCount == 2 && widget.enablePlaybackSpeedGesture && _dragStartPlaybackSpeed != null) {
      // Two-finger vertical gesture for playback speed
      // Only activate after threshold is exceeded (use same threshold as vertical gestures)
      if (absDeltaY >= widget.verticalGestureThreshold) {
        _lockedGestureType = _GestureType.playbackSpeed;
        // Cancel any pending double-tap timer since this is a gesture, not a tap
        _doubleTapTimer?.cancel();
        _doubleTapTimer = null;

        final height = renderBox.size.height;
        final relativeChange = -deltaY / height;

        // Fine-grained speed control: continuous adjustment from 0.25x to 3.0x
        // Round to 0.05 intervals for smoother control (0.25, 0.30, 0.35, etc.)
        final newSpeed = (_dragStartPlaybackSpeed! + relativeChange * 2.75).clamp(0.25, 3.0);
        final fineTunedSpeed = (newSpeed * 20).round() / 20;

        setState(() {
          _currentPlaybackSpeed = fineTunedSpeed;
        });
        unawaited(widget.controller.setPlaybackSpeed(fineTunedSpeed));
      }
    } else if (_pointerCount == 1) {
      // Single-finger gesture - determine gesture type if not locked
      if (_lockedGestureType == null) {
        // Determine which gesture type to lock based on movement direction
        // During double-tap window (300ms after first tap), require larger movement
        // to activate seek gesture to prevent accidental activation from finger drift
        final seekThreshold = _doubleTapTimer != null ? 30.0 : 10.0;

        if (absDeltaX > absDeltaY && absDeltaX > seekThreshold && widget.enableSeekGesture) {
          _lockedGestureType = _GestureType.seek;
          // Cancel any pending double-tap timer since this is a gesture, not a tap
          _doubleTapTimer?.cancel();
          _doubleTapTimer = null;

          // Pause video during seek if it's currently playing
          _wasPlayingBeforeSeek = widget.controller.value.isPlaying;
          if (_wasPlayingBeforeSeek) {
            unawaited(widget.controller.pause());
          }
        } else if (absDeltaY > absDeltaX && absDeltaY >= widget.verticalGestureThreshold) {
          // Lock to volume or brightness based on starting position
          // Use the helper methods that check for valid gesture areas (side edges, above bottom)
          if (_isInBrightnessGestureArea(_scaleStartPosition!, renderBox) &&
              widget.enableBrightnessGesture &&
              _isBrightnessGestureSupported) {
            _lockedGestureType = _GestureType.brightness;
          } else if (_isInVolumeGestureArea(_scaleStartPosition!, renderBox) &&
              widget.enableVolumeGesture &&
              _isVolumeGestureSupported) {
            _lockedGestureType = _GestureType.volume;
          }
          // Cancel any pending double-tap timer since this is a gesture, not a tap
          if (_lockedGestureType != null) {
            _doubleTapTimer?.cancel();
            _doubleTapTimer = null;
          }
        }
      }

      // Process only the locked gesture type
      switch (_lockedGestureType) {
        case _GestureType.seek:
          if (_dragStartPlaybackPosition != null) {
            _processSeekGesture(deltaX, renderBox);
          }
        case _GestureType.volume:
          if (_dragStartVolume != null) {
            _processVolumeGesture(deltaY, renderBox);
          }
        case _GestureType.brightness:
          if (_dragStartBrightness != null) {
            _processBrightnessGesture(deltaY, renderBox);
          }
        case _GestureType.playbackSpeed:
        case null:
          // Already handled above or no gesture locked yet
          break;
      }
    }
  }

  void _processSeekGesture(double deltaX, RenderBox renderBox) {
    // Horizontal drag - seek using physical distance (inches)
    // 160 logical pixels ≈ 1 inch in Flutter's density-independent system
    const pixelsPerInch = 160.0;
    final seekSeconds = deltaX * widget.seekSecondsPerInch / pixelsPerInch;
    final seekAmount = Duration(milliseconds: (seekSeconds * 1000).round());
    final duration = widget.controller.value.duration;
    final newPosition = _dragStartPlaybackPosition! + seekAmount;

    Duration targetPosition;
    if (newPosition < Duration.zero) {
      targetPosition = Duration.zero;
    } else if (newPosition > duration) {
      targetPosition = duration;
    } else {
      targetPosition = newPosition;
    }

    setState(() {
      _seekTargetPosition = targetPosition;
    });
    widget.onSeekGestureUpdate?.call(targetPosition);
  }

  /// Fetches the current device volume asynchronously when a volume gesture starts.
  void _fetchDeviceVolumeForGesture() {
    // Use a sensible default while fetching
    _dragStartVolume = _currentVolume ?? 0.5;
    // Fetch actual device volume asynchronously
    unawaited(
      widget.controller.getDeviceVolume().then((volume) {
        if (mounted && _dragStartVolume != null) {
          _dragStartVolume = volume;
        }
      }),
    );
  }

  void _processVolumeGesture(double deltaY, RenderBox renderBox) {
    final height = renderBox.size.height;
    final relativeChange = -deltaY / height;

    final newVolume = (_dragStartVolume! + relativeChange).clamp(0.0, 1.0);
    setState(() {
      _currentVolume = newVolume;
    });
    // Use device volume instead of player volume
    unawaited(widget.controller.setDeviceVolume(newVolume));
  }

  void _processBrightnessGesture(double deltaY, RenderBox renderBox) {
    final height = renderBox.size.height;
    final relativeChange = -deltaY / height;

    final newBrightness = (_dragStartBrightness! + relativeChange).clamp(0.0, 1.0);
    setState(() {
      _currentBrightness = newBrightness;
    });
    widget.onBrightnessChanged?.call(newBrightness);
    unawaited(_updateBrightness(newBrightness));
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Handle seek completion
    if (_seekTargetPosition != null) {
      unawaited(widget.controller.seekTo(_seekTargetPosition!));

      // Resume playback if it was playing before seek
      if (_wasPlayingBeforeSeek) {
        unawaited(widget.controller.play());
      }
    }

    // Only treat as tap if:
    // - No significant movement occurred (small touch without much drag)
    // - No gesture was locked (user didn't start a swipe gesture)
    // - Single finger was used (not multi-touch)
    // - We have a valid tap position
    final shouldTreatAsTap =
        !_hadSignificantMovement && _lockedGestureType == null && _lastTapPosition != null && _pointerCount <= 1;

    if (shouldTreatAsTap) {
      _handleTapAtPosition(_lastTapPosition!);
    }

    // Clear all state
    _scaleStartPosition = null;
    _dragStartVolume = null;
    _dragStartBrightness = null;
    _dragStartPlaybackPosition = null;
    _dragStartPlaybackSpeed = null;
    _lastTapPosition = null;
    _lockedGestureType = null;
    _wasPlayingBeforeSeek = false;

    setState(() {
      _seekTargetPosition = null;
      _currentVolume = null;
      _currentBrightness = null;
      _currentPlaybackSpeed = null;
    });
    widget.onSeekGestureUpdate?.call(null);
  }

  void _handleTapAtPosition(Offset position) {
    if (_doubleTapTimer != null) {
      // This is a double tap
      _doubleTapTimer?.cancel();
      _doubleTapTimer = null;
      if (widget.enableDoubleTapSeek) {
        _handleDoubleTap(position);
      }
    } else {
      // Start timer for double tap detection
      // Only toggle controls if no second tap comes within 300ms
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        _doubleTapTimer = null;
        // Single tap confirmed
        if (!_controlsVisible) {
          // Controls are hidden - show them
          setState(() {
            _controlsVisible = true;
          });
          widget.onControlsVisibilityChanged?.call(true);
          _resetHideTimer();
        } else {
          // Controls are visible - toggle (hide) them
          _toggleControlsVisibility();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Listener(
        onPointerDown: (event) {
          setState(() => _pointerCount++);
        },
        onPointerUp: (event) {
          setState(() => _pointerCount--);
        },
        onPointerCancel: (event) {
          setState(() => _pointerCount--);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: widget.child,
        ),
      ),
      if (widget.showFeedback &&
          (_feedbackIcon != null ||
              _seekTargetPosition != null ||
              _currentVolume != null ||
              _currentBrightness != null ||
              _currentPlaybackSpeed != null))
        _buildFeedbackOverlay(),
    ],
  );

  Widget _buildFeedbackOverlay() {
    final theme = VideoPlayerThemeData.of(context);

    // Show seek preview when dragging horizontally
    if (_seekTargetPosition != null && _dragStartPlaybackPosition != null) {
      return IgnorePointer(child: Center(child: _buildSeekPreview(theme)));
    }

    // Show volume feedback - aligned LEFT (opposite to right-side gesture)
    if (_currentVolume != null) {
      return IgnorePointer(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(padding: const EdgeInsets.only(left: 48), child: _buildVolumeOverlay(theme)),
        ),
      );
    }

    // Show brightness feedback - aligned RIGHT (opposite to left-side gesture)
    if (_currentBrightness != null) {
      return IgnorePointer(
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(padding: const EdgeInsets.only(right: 48), child: _buildBrightnessOverlay(theme)),
        ),
      );
    }

    // Show playback speed feedback
    if (_currentPlaybackSpeed != null) {
      return IgnorePointer(child: Center(child: _buildPlaybackSpeedOverlay(theme)));
    }

    // Show standard feedback for other gestures
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _feedbackController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _feedbackIcon,
                size: theme.seekIconSize,
                color: theme.primaryColor,
                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
              ),
              if (_feedbackText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _feedbackText!,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeekPreview(VideoPlayerTheme theme) {
    final difference = _seekTargetPosition! - _dragStartPlaybackPosition!;
    final isForward = difference.inMilliseconds >= 0;
    final absDifference = Duration(milliseconds: difference.inMilliseconds.abs());
    final value = widget.controller.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatVideoDuration(_seekTargetPosition!),
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isForward ? Icons.fast_forward : Icons.fast_rewind,
                color: theme.secondaryColor,
                size: 18,
                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
              ),
              const SizedBox(width: 6),
              Text(
                '${isForward ? '+' : '-'}${formatVideoDuration(absDifference)}',
                style: TextStyle(
                  color: theme.secondaryColor,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mini progress bar showing position, buffered, and seek target
          SeekPreviewProgressBar(
            currentPosition: _dragStartPlaybackPosition!,
            seekTargetPosition: _seekTargetPosition!,
            duration: value.duration,
            bufferedPosition: value.bufferedPosition,
            chapters: value.chapters,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeOverlay(VideoPlayerTheme theme) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        _currentVolume! > 0.5 ? Icons.volume_up : (_currentVolume! > 0 ? Icons.volume_down : Icons.volume_off),
        size: theme.seekIconSize,
        color: theme.primaryColor,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
      ),
      const SizedBox(height: 12),
      Container(
        width: 40,
        height: 160,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 160 * _currentVolume!,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${(_currentVolume! * 100).round()}%',
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
        ),
      ),
    ],
  );

  Widget _buildBrightnessOverlay(VideoPlayerTheme theme) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        _currentBrightness! > 0.5 ? Icons.brightness_high : Icons.brightness_low,
        size: theme.seekIconSize,
        color: theme.primaryColor,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
      ),
      const SizedBox(height: 12),
      Container(
        width: 40,
        height: 160,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 160 * _currentBrightness!,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${(_currentBrightness! * 100).round()}%',
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
        ),
      ),
    ],
  );

  Widget _buildPlaybackSpeedOverlay(VideoPlayerTheme theme) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.speed,
        size: theme.seekIconSize,
        color: theme.primaryColor,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
      ),
      const SizedBox(height: 8),
      Text(
        '${_currentPlaybackSpeed!.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}x',
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Playback Speed',
        style: TextStyle(
          color: theme.secondaryColor,
          fontSize: 16,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
        ),
      ),
    ],
  );
}
