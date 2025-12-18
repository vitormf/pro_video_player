import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import 'brightness_gesture_manager.dart';
import 'playback_speed_gesture_manager.dart';
import 'seek_gesture_manager.dart';
import 'tap_gesture_manager.dart';
import 'volume_gesture_manager.dart';

/// The type of gesture currently being performed.
enum GestureType {
  /// Horizontal swipe for seeking through video.
  seek,

  /// Vertical swipe on right side for volume control.
  volume,

  /// Vertical swipe on left side for brightness control.
  brightness,

  /// Two-finger vertical swipe for playback speed.
  playbackSpeed,
}

/// Callback interface for gesture coordinator configuration.
abstract class GestureCoordinatorCallbacks {
  /// Whether seek gesture is enabled.
  bool get enableSeekGesture;

  /// Whether volume gesture is enabled.
  bool get enableVolumeGesture;

  /// Whether brightness gesture is enabled.
  bool get enableBrightnessGesture;

  /// Whether playback speed gesture is enabled.
  bool get enablePlaybackSpeedGesture;

  /// Fraction of screen width for side gestures (0.0-1.0).
  double get sideGestureAreaFraction;

  /// Height of bottom exclusion zone.
  double get bottomGestureExclusionHeight;

  /// Minimum vertical movement to trigger volume/brightness/speed gestures.
  double get verticalGestureThreshold;

  /// Gets current controls visibility state.
  bool getControlsVisible();

  /// Sets controls visibility.
  ///
  /// If [instantly] is true, controls should hide without animation.
  void setControlsVisible({required bool visible, bool instantly = false});
}

/// Orchestrates all gesture managers and implements gesture locking.
///
/// Responsibilities:
/// - Coordinate lifecycle of all gesture managers
/// - Implement gesture locking mechanism
/// - Route gesture events to appropriate manager
/// - Pointer tracking (1 finger vs 2 fingers)
/// - Detect gesture type from movement direction
/// - Threshold enforcement (30px vertical, 10px horizontal)
class GestureCoordinator {
  /// Creates a gesture coordinator with all manager instances.
  GestureCoordinator({
    required this.tapManager,
    required this.seekManager,
    required this.volumeManager,
    required this.brightnessManager,
    required this.speedManager,
    required this.callbacks,
  });

  /// Tap gesture manager instance.
  final TapGestureManager tapManager;

  /// Seek gesture manager instance.
  final SeekGestureManager seekManager;

  /// Volume gesture manager instance.
  final VolumeGestureManager volumeManager;

  /// Brightness gesture manager instance.
  final BrightnessGestureManager brightnessManager;

  /// Playback speed gesture manager instance.
  final PlaybackSpeedGestureManager speedManager;

  /// Callbacks for configuration.
  final GestureCoordinatorCallbacks callbacks;

  // Internal state
  int _pointerCount = 0;
  int _maxPointerCountInGesture = 0;
  Offset? _startPosition;
  Size? _screenSize;
  bool _hadSignificantMovement = false;
  GestureType? _lockedGestureType;
  bool? _controlsWereVisibleBeforeGesture;

  /// Current pointer count.
  int get pointerCount => _pointerCount;

  /// Start position of the gesture.
  Offset? get startPosition => _startPosition;

  /// Handles pointer down event (finger touched screen).
  void onPointerDown() {
    _pointerCount++;
    // Update max pointer count if we're in an active gesture
    if (_startPosition != null && _pointerCount > _maxPointerCountInGesture) {
      _maxPointerCountInGesture = _pointerCount;
    }
  }

  /// Handles pointer up event (finger lifted from screen).
  void onPointerUp() {
    _pointerCount = (_pointerCount - 1).clamp(0, 100);
  }

  /// Handles gesture start (finger begins moving).
  void onGestureStart(Offset position, Size screenSize) {
    _startPosition = position;
    _screenSize = screenSize;
    _hadSignificantMovement = false;
    _lockedGestureType = null;
    // Initialize max pointer count for this gesture (or keep higher value if already set)
    if (_maxPointerCountInGesture == 0) {
      _maxPointerCountInGesture = _pointerCount;
    }
  }

  /// Handles gesture update (finger moving).
  void onGestureUpdate(Offset currentPosition, Size screenSize) {
    if (_startPosition == null) return;

    // Cancel double-tap timer immediately when ANY movement is detected
    // This prevents the timer from firing while the user is dragging
    // even if they haven't moved beyond the significant movement threshold yet
    tapManager.cancelDoubleTapTimer();

    final deltaX = currentPosition.dx - _startPosition!.dx;
    final deltaY = currentPosition.dy - _startPosition!.dy;
    final absDeltaX = deltaX.abs();
    final absDeltaY = deltaY.abs();

    // Track if significant movement occurred (for tap vs drag detection)
    if (absDeltaX > 5 || absDeltaY > 5) {
      _hadSignificantMovement = true;
    }

    // Determine gesture type if not yet locked
    if (_lockedGestureType == null) {
      _detectAndLockGesture(absDeltaX, absDeltaY, screenSize);
    }

    // Route to appropriate manager based on locked type
    _routeGestureUpdate(deltaX, deltaY, screenSize);
  }

  /// Handles gesture end (finger lifted).
  void onGestureEnd() {
    // If no significant movement and no locked gesture AND single finger, treat as tap
    // The maxPointerCount check prevents treating multi-finger gestures as taps
    if (!_hadSignificantMovement &&
        _lockedGestureType == null &&
        _startPosition != null &&
        _maxPointerCountInGesture <= 1) {
      tapManager.handleTap(_startPosition!);
    }

    // End any active gesture
    switch (_lockedGestureType) {
      case GestureType.seek:
        unawaited(seekManager.endSeek());
      case GestureType.volume:
        volumeManager.endVolumeGesture();
      case GestureType.brightness:
        brightnessManager.endBrightnessGesture();
      case GestureType.playbackSpeed:
        speedManager.endSpeedGesture();
      case null:
        break;
    }

    _resetState();
  }

  /// Detects gesture type based on movement and locks to that type.
  void _detectAndLockGesture(double absDeltaX, double absDeltaY, Size screenSize) {
    // Two-finger gesture for playback speed
    if (_pointerCount == 2 && callbacks.enablePlaybackSpeedGesture) {
      if (absDeltaY >= callbacks.verticalGestureThreshold) {
        _lockedGestureType = GestureType.playbackSpeed;
        tapManager.cancelDoubleTapTimer(); // Cancel any pending double-tap
        speedManager.dragStartSpeed = speedManager.getPlaybackSpeed();
        _hideControlsDuringGesture();
      }
      return;
    }

    // Single-finger gestures
    if (_pointerCount == 1) {
      // Horizontal movement = seek (but not in bottom exclusion zone where progress bar is)
      if (absDeltaX > absDeltaY && absDeltaX > 20.0 && callbacks.enableSeekGesture) {
        // Check if gesture started in bottom exclusion zone (progress bar area)
        if (_startPosition != null && _screenSize != null) {
          final relativeY = _startPosition!.dy / _screenSize!.height;
          final bottomFraction = callbacks.bottomGestureExclusionHeight / _screenSize!.height;

          // Don't intercept horizontal gestures in bottom area - let progress bar handle them
          if (relativeY >= (1.0 - bottomFraction)) {
            return;
          }
        }

        _lockedGestureType = GestureType.seek;
        tapManager.cancelDoubleTapTimer(); // Cancel any pending double-tap
        seekManager.startSeek(seekManager.getCurrentPosition(), isPlaying: seekManager.getIsPlaying());
        _hideControlsDuringGesture();
        return;
      }

      // Vertical movement = volume or brightness
      if (absDeltaY > absDeltaX && absDeltaY >= callbacks.verticalGestureThreshold) {
        if (_startPosition != null && _screenSize != null) {
          // Check if in brightness area (left side)
          if (_isInBrightnessArea(_startPosition!, _screenSize!) && callbacks.enableBrightnessGesture) {
            _lockedGestureType = GestureType.brightness;
            tapManager.cancelDoubleTapTimer(); // Cancel any pending double-tap
            unawaited(brightnessManager.startBrightnessGesture());
            _hideControlsDuringGesture();
          }
          // Check if in volume area (right side)
          else if (_isInVolumeArea(_startPosition!, _screenSize!) && callbacks.enableVolumeGesture) {
            _lockedGestureType = GestureType.volume;
            tapManager.cancelDoubleTapTimer(); // Cancel any pending double-tap
            unawaited(volumeManager.startVolumeGesture());
            _hideControlsDuringGesture();
          }
        }
      }
    }
  }

  /// Hides controls during gesture and saves previous visibility state.
  void _hideControlsDuringGesture() {
    if (_controlsWereVisibleBeforeGesture == null) {
      // Save current visibility state
      _controlsWereVisibleBeforeGesture = callbacks.getControlsVisible();
      // Hide controls instantly (no animation) during gesture
      if (_controlsWereVisibleBeforeGesture!) {
        callbacks.setControlsVisible(visible: false, instantly: true);
      }
    }
  }

  /// Routes gesture updates to the appropriate locked manager.
  void _routeGestureUpdate(double deltaX, double deltaY, Size screenSize) {
    switch (_lockedGestureType) {
      case GestureType.seek:
        seekManager.updateSeek(deltaX, screenSize.width);
      case GestureType.volume:
        volumeManager.updateVolume(deltaY, screenSize.height);
      case GestureType.brightness:
        brightnessManager.updateBrightness(deltaY, screenSize.height);
      case GestureType.playbackSpeed:
        speedManager.updateSpeed(deltaY, screenSize.height);
      case null:
        break;
    }
  }

  /// Checks if position is in brightness gesture area (left edge).
  bool _isInBrightnessArea(Offset position, Size screenSize) {
    final relativeX = position.dx / screenSize.width;
    final relativeY = position.dy / screenSize.height;
    final bottomFraction = callbacks.bottomGestureExclusionHeight / screenSize.height;

    // Must be on left edge (within sideGestureAreaFraction) and not in bottom exclusion zone
    return relativeX < callbacks.sideGestureAreaFraction && relativeY < (1.0 - bottomFraction);
  }

  /// Checks if position is in volume gesture area (right edge).
  bool _isInVolumeArea(Offset position, Size screenSize) {
    final relativeX = position.dx / screenSize.width;
    final relativeY = position.dy / screenSize.height;
    final bottomFraction = callbacks.bottomGestureExclusionHeight / screenSize.height;

    // Must be on right edge (within sideGestureAreaFraction from right) and not in bottom exclusion zone
    return relativeX > (1.0 - callbacks.sideGestureAreaFraction) && relativeY < (1.0 - bottomFraction);
  }

  /// Resets gesture state.
  void _resetState() {
    _startPosition = null;
    _screenSize = null;
    _hadSignificantMovement = false;
    _lockedGestureType = null;
    _maxPointerCountInGesture = 0;

    // Restore controls visibility to pre-gesture state
    // IMPORTANT: Always call setControlsVisible to reset hideInstantly flag,
    // even if visibility doesn't change (e.g., was hidden, stays hidden)
    if (_controlsWereVisibleBeforeGesture != null) {
      callbacks.setControlsVisible(visible: _controlsWereVisibleBeforeGesture!);
      _controlsWereVisibleBeforeGesture = null;
    }
  }

  /// Disposes all managers.
  void dispose() {
    tapManager.dispose();
    seekManager.dispose();
    volumeManager.dispose();
    brightnessManager.dispose();
    speedManager.dispose();
  }
}
