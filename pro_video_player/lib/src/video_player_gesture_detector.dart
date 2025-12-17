import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'controls/seek_preview.dart';
import 'controls/seek_preview_progress_bar.dart';
import 'controls/widgets/value_indicator_overlay.dart';
import 'gestures/brightness_gesture_manager.dart';
import 'gestures/gesture_coordinator.dart';
import 'gestures/playback_speed_gesture_manager.dart';
import 'gestures/seek_gesture_manager.dart';
import 'gestures/tap_gesture_manager.dart';
import 'gestures/volume_gesture_manager.dart';
import 'pro_video_player_controller.dart';
import 'video_player_theme.dart';

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

class _VideoPlayerGestureDetectorState extends State<VideoPlayerGestureDetector>
    with SingleTickerProviderStateMixin
    implements GestureCoordinatorCallbacks {
  // UI state (feedback overlays)
  bool _controlsVisible = true;
  Duration? _seekTargetPosition;
  Duration? _dragStartPlaybackPosition; // Needed for seek preview
  IconData? _feedbackIcon;
  String? _feedbackText;
  late AnimationController _feedbackController;
  double? _currentVolume;
  double? _currentBrightness;
  double? _currentPlaybackSpeed;

  // Gesture managers
  late TapGestureManager _tapManager;
  late SeekGestureManager _seekManager;
  late VolumeGestureManager _volumeManager;
  late BrightnessGestureManager _brightnessManager;
  late PlaybackSpeedGestureManager _speedManager;
  late GestureCoordinator _gestureCoordinator;

  // GestureCoordinatorCallbacks implementation
  @override
  bool get enableSeekGesture => widget.enableSeekGesture;
  @override
  bool get enableVolumeGesture => widget.enableVolumeGesture;
  @override
  bool get enableBrightnessGesture => widget.enableBrightnessGesture;
  @override
  bool get enablePlaybackSpeedGesture => widget.enablePlaybackSpeedGesture;
  @override
  double get sideGestureAreaFraction => widget.sideGestureAreaFraction;
  @override
  double get bottomGestureExclusionHeight => widget.bottomExclusionHeight;
  @override
  double get verticalGestureThreshold => widget.verticalGestureThreshold;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    // Initialize gesture managers
    _tapManager = TapGestureManager(
      getControlsVisible: () => _controlsVisible,
      setControlsVisible: ({required visible}) {
        setState(() => _controlsVisible = visible);
        widget.onControlsVisibilityChanged?.call(visible);
      },
      getIsPlaying: () => widget.controller.value.isPlaying,
      onSingleTap: () {}, // Single tap just toggles controls (handled by setControlsVisible)
      onDoubleTapLeft: (position) => _handleDoubleTapSeek(-widget.seekDuration),
      onDoubleTapCenter: (position) => _handleDoubleTapPlayPause(),
      onDoubleTapRight: (position) => _handleDoubleTapSeek(widget.seekDuration),
      autoHideEnabled: widget.autoHideControls,
      autoHideDelay: widget.autoHideDelay,
      doubleTapEnabled: widget.enableDoubleTapSeek,
      context: context,
    );

    _seekManager = SeekGestureManager(
      getCurrentPosition: () => widget.controller.value.position,
      getDuration: () => widget.controller.value.duration,
      getIsPlaying: () => widget.controller.value.isPlaying,
      seekSecondsPerInch: 10,
      setSeekTarget: (target) {
        setState(() {
          if (target != null && _dragStartPlaybackPosition == null) {
            _dragStartPlaybackPosition = widget.controller.value.position;
          } else if (target == null) {
            _dragStartPlaybackPosition = null;
          }
          _seekTargetPosition = target;
        });
      },
      seekTo: widget.controller.seekTo,
      pause: widget.controller.pause,
      play: widget.controller.play,
      onSeekGestureUpdate: (target) => widget.onSeekGestureUpdate?.call(target),
    );

    _volumeManager = VolumeGestureManager(
      getDeviceVolume: widget.controller.getDeviceVolume,
      setDeviceVolume: widget.controller.setDeviceVolume,
      setCurrentVolume: (volume) => setState(() => _currentVolume = volume),
    );

    _brightnessManager = BrightnessGestureManager(
      getScreenBrightness: widget.controller.getScreenBrightness,
      setScreenBrightness: widget.controller.setScreenBrightness,
      setCurrentBrightness: (brightness) => setState(() => _currentBrightness = brightness),
      onBrightnessChanged: (brightness) => widget.onBrightnessChanged?.call(brightness),
      isBrightnessSupported: () => !kIsWeb && (Platform.isIOS || Platform.isAndroid),
    );

    _speedManager = PlaybackSpeedGestureManager(
      getPlaybackSpeed: () => widget.controller.value.playbackSpeed,
      setPlaybackSpeed: widget.controller.setPlaybackSpeed,
      setCurrentSpeed: (speed) => setState(() => _currentPlaybackSpeed = speed),
    );

    _gestureCoordinator = GestureCoordinator(
      tapManager: _tapManager,
      seekManager: _seekManager,
      volumeManager: _volumeManager,
      brightnessManager: _brightnessManager,
      speedManager: _speedManager,
      callbacks: this,
    );

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
    _gestureCoordinator.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  /// Called when the controller value changes.
  /// Handles auto-hide timer when playback starts.
  void _onControllerChanged() {
    // Delegate to tap manager for auto-hide logic
    _tapManager.resetHideTimer();
  }

  /// Handles double-tap seek (left/right zones).
  void _handleDoubleTapSeek(Duration offset) {
    final currentPosition = widget.controller.value.position;
    final newPosition = currentPosition + offset;
    final duration = widget.controller.value.duration;

    // Clamp to valid range
    Duration clampedPosition;
    if (newPosition < Duration.zero) {
      clampedPosition = Duration.zero;
    } else if (newPosition > duration) {
      clampedPosition = duration;
    } else {
      clampedPosition = newPosition;
    }

    // Seek and show feedback
    unawaited(widget.controller.seekTo(clampedPosition));

    if (widget.showFeedback) {
      final isForward = !offset.isNegative;
      _showFeedback(isForward ? Icons.fast_forward : Icons.fast_rewind, '${offset.inSeconds.abs()}s');
    }
  }

  /// Handles double-tap play/pause (center zone).
  void _handleDoubleTapPlayPause() {
    final isPlaying = widget.controller.value.isPlaying;

    if (isPlaying) {
      unawaited(widget.controller.pause());
      if (widget.showFeedback) {
        _showFeedback(Icons.pause, null);
      }
    } else {
      unawaited(widget.controller.play());
      if (widget.showFeedback) {
        _showFeedback(Icons.play_arrow, null);
      }
    }
  }

  /// Shows visual feedback for gestures.
  void _showFeedback(IconData icon, String? text) {
    setState(() {
      _feedbackIcon = icon;
      _feedbackText = text;
    });
    unawaited(_feedbackController.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      // Content layer (child)
      widget.child,

      // Gesture detection layer covering ONLY the video area (not bottom controls)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: widget.bottomExclusionHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get the actual rendered size of this gesture area
            final gestureAreaSize = constraints.biggest;
            // Calculate full screen size including the excluded bottom area
            final fullScreenHeight = gestureAreaSize.height + widget.bottomExclusionHeight;
            final fullScreenSize = Size(gestureAreaSize.width, fullScreenHeight);

            return Listener(
              onPointerDown: (event) => _gestureCoordinator.onPointerDown(),
              onPointerUp: (event) => _gestureCoordinator.onPointerUp(),
              onPointerCancel: (event) => _gestureCoordinator.onPointerUp(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _gestureCoordinator.onGestureStart(details.localFocalPoint, fullScreenSize);
                },
                onScaleUpdate: (details) {
                  _gestureCoordinator.onGestureUpdate(details.localFocalPoint, fullScreenSize);
                },
                onScaleEnd: (details) => _gestureCoordinator.onGestureEnd(),
              ),
            );
          },
        ),
      ),
      // Feedback overlay on top
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
    final value = widget.controller.value;
    final dragProgress = _seekTargetPosition!.inMilliseconds / value.duration.inMilliseconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SeekPreview(
          dragProgress: dragProgress,
          dragStartPosition: _dragStartPlaybackPosition!,
          duration: value.duration,
          theme: theme,
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
    );
  }

  Widget _buildVolumeOverlay(VideoPlayerTheme theme) {
    final volumeIcon = _currentVolume! > 0.5
        ? Icons.volume_up
        : (_currentVolume! > 0 ? Icons.volume_down : Icons.volume_off);
    return ValueIndicatorOverlay(value: _currentVolume!, icon: volumeIcon, theme: theme);
  }

  Widget _buildBrightnessOverlay(VideoPlayerTheme theme) {
    final brightnessIcon = _currentBrightness! > 0.5 ? Icons.brightness_high : Icons.brightness_low;
    return ValueIndicatorOverlay(value: _currentBrightness!, icon: brightnessIcon, theme: theme);
  }

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
