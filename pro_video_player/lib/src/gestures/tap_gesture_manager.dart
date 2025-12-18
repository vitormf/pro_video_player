import 'dart:async';
import 'package:flutter/material.dart';

/// Manages tap gesture detection and controls visibility.
///
/// Handles:
/// - Single tap detection with double-tap delay (300ms timer)
/// - Double tap routing (left/center/right zones)
/// - Controls visibility toggling
/// - Auto-hide timer management
class TapGestureManager {
  /// Creates a tap gesture manager with dependency injection via callbacks.
  TapGestureManager({
    required this.onSingleTap,
    required this.onDoubleTapLeft,
    required this.onDoubleTapCenter,
    required this.onDoubleTapRight,
    required this.getControlsVisible,
    required this.setControlsVisible,
    required this.getIsPlaying,
    required this.autoHideEnabled,
    required this.autoHideDelay,
    required this.doubleTapEnabled,
    required this.context,
  });

  /// Callback when single tap is detected (after double-tap timeout).
  final VoidCallback onSingleTap;

  /// Callback when double tap on left side is detected (seek backward).
  final ValueChanged<Offset> onDoubleTapLeft;

  /// Callback when double tap on center is detected (play/pause).
  final ValueChanged<Offset> onDoubleTapCenter;

  /// Callback when double tap on right side is detected (seek forward).
  final ValueChanged<Offset> onDoubleTapRight;

  /// Gets the current controls visibility state.
  final bool Function() getControlsVisible;

  /// Sets the controls visibility state.
  final void Function({required bool visible}) setControlsVisible;

  /// Gets whether the video is currently playing.
  final bool Function() getIsPlaying;

  /// Whether auto-hide controls is enabled.
  final bool autoHideEnabled;

  /// Delay before auto-hiding controls.
  final Duration autoHideDelay;

  /// Whether double tap to seek is enabled.
  final bool doubleTapEnabled;

  /// Widget context for render box calculations.
  final BuildContext context;

  // Internal state
  Timer? _hideControlsTimer;
  Timer? _doubleTapTimer;

  /// Handles a tap at the given position.
  void handleTap(Offset position) {
    if (_doubleTapTimer != null) {
      // This is a double tap
      _doubleTapTimer?.cancel();
      _doubleTapTimer = null;
      if (doubleTapEnabled) {
        _handleDoubleTap(position);
      }
    } else {
      // Start timer for double tap detection
      // REDUCED timeout (150ms instead of 300ms) makes single taps feel more responsive
      _doubleTapTimer = Timer(const Duration(milliseconds: 150), () {
        _doubleTapTimer = null;
        // Single tap confirmed
        onSingleTap();

        // Toggle controls visibility
        final currentlyVisible = getControlsVisible();
        setControlsVisible(visible: !currentlyVisible);

        // Reset auto-hide timer
        resetHideTimer();
      });
    }
  }

  /// Handles a double tap at the given position.
  void _handleDoubleTap(Offset position) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final width = renderBox.size.width;
    final relativeX = position.dx / width;

    if (relativeX < 0.3) {
      // Left side - seek backward (< 30% of width)
      onDoubleTapLeft(position);
    } else if (relativeX > 0.7) {
      // Right side - seek forward (> 70% of width)
      onDoubleTapRight(position);
    } else {
      // Center - play/pause (30-70% of width)
      onDoubleTapCenter(position);
    }
  }

  /// Resets the auto-hide timer.
  void resetHideTimer() {
    _hideControlsTimer?.cancel();
    if (autoHideEnabled && getControlsVisible() && getIsPlaying()) {
      _hideControlsTimer = Timer(autoHideDelay, () {
        setControlsVisible(visible: false);
      });
    }
  }

  /// Starts the auto-hide timer if conditions are met.
  void startHideTimerIfNeeded() {
    // Only start the auto-hide timer if it's not already running
    // This prevents constantly resetting the timer on every update
    if (getIsPlaying() && getControlsVisible() && autoHideEnabled && _hideControlsTimer == null) {
      resetHideTimer();
    }
  }

  /// Cancels the pending double-tap timer.
  /// Called when another gesture (like seek/volume) starts to prevent accidental tap detection.
  void cancelDoubleTapTimer() {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
  }

  /// Disposes resources (cancels timers).
  void dispose() {
    _hideControlsTimer?.cancel();
    _doubleTapTimer?.cancel();
  }
}
