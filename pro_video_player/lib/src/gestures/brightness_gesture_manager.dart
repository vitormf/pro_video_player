import 'dart:async' show unawaited;

/// Manages vertical swipe brightness control gesture (left edge).
///
/// Handles:
/// - Brightness gesture detection (left edge, above bottom zone)
/// - Brightness calculation from vertical swipe
/// - Clamping (0.0-1.0)
/// - Platform support checking (iOS/Android only)
/// - Async initial brightness fetching
class BrightnessGestureManager {
  /// Creates a brightness gesture manager with dependency injection via callbacks.
  BrightnessGestureManager({
    required this.getScreenBrightness,
    required this.setScreenBrightness,
    required this.setCurrentBrightness,
    required this.onBrightnessChanged,
    required this.isBrightnessSupported,
  });

  /// Gets the current screen brightness (async, from platform).
  final Future<double> Function() getScreenBrightness;

  /// Sets the screen brightness.
  final Future<void> Function(double) setScreenBrightness;

  /// Updates the current brightness state (for overlay).
  final void Function(double?) setCurrentBrightness;

  /// Optional external callback when brightness changes.
  final void Function(double)? onBrightnessChanged;

  /// Whether brightness control is supported on this platform.
  final bool Function() isBrightnessSupported;

  // Internal state
  double? _dragStartBrightness;
  double? _currentBrightness;

  /// Starts a brightness gesture.
  Future<void> startBrightnessGesture() async {
    if (!isBrightnessSupported()) return;

    // Use a sensible default while fetching
    _dragStartBrightness = _currentBrightness ?? 0.5;

    // Fetch actual screen brightness asynchronously (fire-and-forget)
    unawaited(
      getScreenBrightness().then((brightness) {
        // Only update if gesture is still active
        if (_dragStartBrightness != null) {
          _dragStartBrightness = brightness;
        }
      }),
    );
  }

  /// Updates the brightness based on vertical delta.
  void updateBrightness(double deltaY, double screenHeight) {
    if (_dragStartBrightness == null) return;

    // Calculate relative change from vertical movement
    // Negative deltaY (swipe up) = increase brightness
    final relativeChange = -deltaY / screenHeight;

    // Calculate new brightness and clamp to [0.0, 1.0]
    final newBrightness = (_dragStartBrightness! + relativeChange).clamp(0.0, 1.0);

    _currentBrightness = newBrightness;
    setCurrentBrightness(newBrightness);

    // Update screen brightness
    unawaited(setScreenBrightness(newBrightness));

    // Call external callback
    onBrightnessChanged?.call(newBrightness);
  }

  /// Ends the brightness gesture.
  void endBrightnessGesture() {
    _dragStartBrightness = null;
    _currentBrightness = null;
    setCurrentBrightness(null);
  }

  /// Disposes resources.
  void dispose() {
    // No timers or subscriptions to clean up
  }
}
