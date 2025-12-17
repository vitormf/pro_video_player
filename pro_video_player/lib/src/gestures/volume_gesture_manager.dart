import 'dart:async' show unawaited;

/// Manages vertical swipe volume control gesture (right edge).
///
/// Handles:
/// - Volume gesture detection (right edge, above bottom zone)
/// - Volume calculation from vertical swipe
/// - Clamping (0.0-1.0)
/// - Async initial volume fetching
class VolumeGestureManager {
  /// Creates a volume gesture manager with dependency injection via callbacks.
  VolumeGestureManager({required this.getDeviceVolume, required this.setDeviceVolume, required this.setCurrentVolume});

  /// Gets the current device volume (async, from platform).
  final Future<double> Function() getDeviceVolume;

  /// Sets the device volume.
  final Future<void> Function(double) setDeviceVolume;

  /// Updates the current volume state (for overlay).
  final void Function(double?) setCurrentVolume;

  // Internal state
  double? _dragStartVolume;
  double? _currentVolume;

  /// Starts a volume gesture.
  Future<void> startVolumeGesture() async {
    // Use a sensible default while fetching
    _dragStartVolume = _currentVolume ?? 0.5;

    // Fetch actual device volume asynchronously (fire-and-forget)
    unawaited(
      getDeviceVolume().then((volume) {
        // Only update if gesture is still active
        if (_dragStartVolume != null) {
          _dragStartVolume = volume;
        }
      }),
    );
  }

  /// Updates the volume based on vertical delta.
  void updateVolume(double deltaY, double screenHeight) {
    if (_dragStartVolume == null) return;

    // Calculate relative change from vertical movement
    // Negative deltaY (swipe up) = increase volume
    final relativeChange = -deltaY / screenHeight;

    // Calculate new volume and clamp to [0.0, 1.0]
    final newVolume = (_dragStartVolume! + relativeChange).clamp(0.0, 1.0);

    _currentVolume = newVolume;
    setCurrentVolume(newVolume);

    // Update device volume
    unawaited(setDeviceVolume(newVolume));
  }

  /// Ends the volume gesture.
  void endVolumeGesture() {
    _dragStartVolume = null;
    _currentVolume = null;
    setCurrentVolume(null);
  }

  /// Disposes resources.
  void dispose() {
    // No timers or subscriptions to clean up
  }
}
