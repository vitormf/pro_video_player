import 'dart:async' show unawaited;

/// Manages two-finger vertical swipe playback speed control gesture.
///
/// Handles:
/// - Two-finger gesture detection
/// - Playback speed calculation (0.25x-3.0x, rounded to 0.05 intervals)
/// - Speed adjustment based on vertical movement
class PlaybackSpeedGestureManager {
  /// Creates a playback speed gesture manager with dependency injection via callbacks.
  PlaybackSpeedGestureManager({
    required this.getPlaybackSpeed,
    required this.setPlaybackSpeed,
    required this.setCurrentSpeed,
  });

  /// Gets the current playback speed.
  final double Function() getPlaybackSpeed;

  /// Sets the playback speed.
  final Future<void> Function(double) setPlaybackSpeed;

  /// Updates the current speed state (for overlay).
  final void Function(double?) setCurrentSpeed;

  // Internal state
  /// Drag start speed for playback speed gesture.
  double? dragStartSpeed;

  /// Updates the playback speed based on vertical delta.
  void updateSpeed(double deltaY, double screenHeight) {
    if (dragStartSpeed == null) return;

    // Calculate relative change from vertical movement
    // Negative deltaY (swipe up) = increase speed
    final relativeChange = -deltaY / screenHeight;

    // Calculate new speed
    final rawSpeed = dragStartSpeed! + relativeChange;

    // Round to nearest 0.05
    final roundedSpeed = (rawSpeed * 20).round() / 20;

    // Clamp to [0.25, 3.0]
    final newSpeed = roundedSpeed.clamp(0.25, 3.0);

    setCurrentSpeed(newSpeed);

    // Update playback speed
    unawaited(setPlaybackSpeed(newSpeed));
  }

  /// Ends the playback speed gesture.
  void endSpeedGesture() {
    dragStartSpeed = null;
    setCurrentSpeed(null);
  }

  /// Disposes resources.
  void dispose() {
    // No timers or subscriptions to clean up
  }
}
