import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Type of keyboard overlay feedback to display.
enum KeyboardOverlayType {
  /// Volume adjustment overlay.
  volume,

  /// Seek/skip overlay.
  seek,

  /// Playback speed overlay.
  speed,
}

/// Manages UI-specific state for video player controls.
///
/// This class separates UI concerns (visibility, timers, drag state, etc.)
/// from video playback state managed by the controller. It uses Flutter's
/// built-in [ChangeNotifier] for reactive updates.
///
/// Example:
/// ```dart
/// final controlsState = VideoControlsState();
///
/// // Show controls and auto-hide after 3 seconds
/// controlsState.showControls();
/// controlsState.startHideTimer(
///   const Duration(seconds: 3),
///   () => controlsState.hideControls(),
/// );
///
/// // Listen to state changes
/// controlsState.addListener(() {
///   print('Controls visible: ${controlsState.visible}');
/// });
/// ```
class VideoControlsState extends ChangeNotifier {
  /// Creates a new video controls state manager.
  VideoControlsState();

  // ========== Visibility ==========

  bool _visible = true;
  bool _isFullyVisible = true;

  /// Whether the controls are currently visible.
  bool get visible => _visible;

  /// Whether the controls visibility animation has completed.
  ///
  /// This tracks if the show/hide animation is fully finished.
  bool get isFullyVisible => _isFullyVisible;

  /// Shows the controls and notifies listeners.
  void showControls() {
    _visible = true;
    _isFullyVisible = true; // Immediately mark as fully visible for tests/instant show
    notifyListeners();
  }

  /// Hides the controls and notifies listeners.
  void hideControls() {
    _visible = false;
    _isFullyVisible = false;
    notifyListeners();
  }

  /// Toggles the controls visibility state.
  void toggleVisibility() {
    _visible = !_visible;
    notifyListeners();
  }

  /// Sets whether the controls visibility animation is complete.
  void setFullyVisible({required bool fullyVisible}) {
    _isFullyVisible = fullyVisible;
    notifyListeners();
  }

  // ========== Hide Timer ==========

  Timer? _hideTimer;

  /// The active auto-hide timer, or null if none.
  Timer? get hideTimer => _hideTimer;

  /// Starts a timer that executes [onHide] after [duration].
  ///
  /// Any existing hide timer is cancelled first.
  void startHideTimer(Duration duration, VoidCallback onHide) {
    _hideTimer?.cancel();
    _hideTimer = Timer(duration, onHide);
  }

  /// Cancels the active hide timer if any.
  void cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  /// Resets the hide timer with a new duration and callback.
  ///
  /// This cancels any existing timer and starts a new one.
  void resetHideTimer(Duration duration, VoidCallback onHide) {
    cancelHideTimer();
    startHideTimer(duration, onHide);
  }

  // ========== Feature Support ==========

  bool _isPipAvailable = false;
  bool _isBackgroundPlaybackSupported = false;
  bool _isCastingSupported = false;

  /// Whether Picture-in-Picture is available on this device.
  bool get isPipAvailable => _isPipAvailable;

  /// Whether background playback is supported on this platform.
  bool get isBackgroundPlaybackSupported => _isBackgroundPlaybackSupported;

  /// Whether casting is supported on this device.
  bool get isCastingSupported => _isCastingSupported;

  /// Sets whether PiP is available.
  void setIsPipAvailable({required bool available}) {
    _isPipAvailable = available;
    notifyListeners();
  }

  /// Sets whether background playback is supported.
  void setIsBackgroundPlaybackSupported({required bool supported}) {
    _isBackgroundPlaybackSupported = supported;
    notifyListeners();
  }

  /// Sets whether casting is supported.
  void setIsCastingSupported({required bool supported}) {
    _isCastingSupported = supported;
    notifyListeners();
  }

  // ========== Time Display ==========

  bool _showRemainingTime = false;

  /// Whether to show remaining time instead of elapsed time.
  bool get showRemainingTime => _showRemainingTime;

  /// Toggles between showing elapsed time and remaining time.
  void toggleTimeDisplay() {
    _showRemainingTime = !_showRemainingTime;
    notifyListeners();
  }

  // ========== Drag State ==========

  bool _isDragging = false;
  double? _dragProgress;

  /// Whether the user is currently dragging the seek bar.
  bool get isDragging => _isDragging;

  /// The current drag progress (0.0 to 1.0), or null if not dragging.
  double? get dragProgress => _dragProgress;

  /// Starts a drag operation on the seek bar.
  void startDragging() {
    _isDragging = true;
    notifyListeners();
  }

  /// Updates the current drag progress (0.0 to 1.0).
  void updateDragProgress(double progress) {
    _dragProgress = progress;
    notifyListeners();
  }

  /// Ends the drag operation and clears drag progress.
  void endDragging() {
    _isDragging = false;
    _dragProgress = null;
    notifyListeners();
  }

  // ========== Playback State Tracking ==========

  /// The last known playing state, used to detect play/pause changes.
  ///
  /// This is used internally to track state changes and doesn't trigger
  /// listener notifications when updated.
  bool? lastIsPlaying;

  /// The last known fullscreen state, used to detect fullscreen changes.
  ///
  /// This is used internally to track state changes and doesn't trigger
  /// listener notifications when updated.
  bool? lastIsFullscreen;

  /// The last known PiP active state, used to detect PiP changes.
  ///
  /// This is used internally to track state changes and doesn't trigger
  /// listener notifications when updated.
  bool? lastIsPipActive;

  // ========== Mouse Hover ==========

  bool _isMouseOverControls = false;

  /// Whether the mouse is currently hovering over the controls area.
  ///
  /// Used on desktop platforms to keep controls visible on hover.
  bool get isMouseOverControls => _isMouseOverControls;

  /// Sets whether the mouse is over the controls area.
  void setMouseOverControls({required bool isOver}) {
    _isMouseOverControls = isOver;
    notifyListeners();
  }

  // ========== Context Menu Position ==========

  /// The last position where a context menu was opened.
  ///
  /// Used on desktop platforms for submenu positioning. Does not trigger
  /// listener notifications when updated as position tracking doesn't require UI rebuilds.
  Offset? lastContextMenuPosition;

  /// Clears the stored context menu position.
  void clearLastContextMenuPosition() {
    lastContextMenuPosition = null;
  }

  // ========== Keyboard Overlay ==========

  Timer? _keyboardOverlayTimer;
  KeyboardOverlayType? _keyboardOverlayType;
  double? _keyboardOverlayValue;

  /// The active keyboard overlay timer, or null if none.
  Timer? get keyboardOverlayTimer => _keyboardOverlayTimer;

  /// The type of keyboard overlay currently shown, or null if none.
  KeyboardOverlayType? get keyboardOverlayType => _keyboardOverlayType;

  /// The current keyboard overlay value (volume, speed, or seek delta).
  double? get keyboardOverlayValue => _keyboardOverlayValue;

  /// Shows a keyboard overlay with the given type and value.
  ///
  /// The overlay automatically hides after [duration] and executes [onHide].
  /// Any existing overlay is cancelled first.
  ///
  /// The [value] can represent:
  /// - Volume (0.0 to 1.0) when type is [KeyboardOverlayType.volume]
  /// - Playback speed (0.25 to 2.0) when type is [KeyboardOverlayType.speed]
  /// - Seek delta in seconds when type is [KeyboardOverlayType.seek]
  void showKeyboardOverlay(KeyboardOverlayType type, double value, Duration duration, VoidCallback onHide) {
    _keyboardOverlayTimer?.cancel();
    _keyboardOverlayType = type;
    _keyboardOverlayValue = value;
    _keyboardOverlayTimer = Timer(duration, onHide);
    notifyListeners();
  }

  /// Hides the keyboard overlay and cancels its timer.
  void hideKeyboardOverlay() {
    _keyboardOverlayTimer?.cancel();
    _keyboardOverlayTimer = null;
    _keyboardOverlayType = null;
    _keyboardOverlayValue = null;
    notifyListeners();
  }

  // ========== Lifecycle ==========

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _keyboardOverlayTimer?.cancel();
    _keyboardOverlayTimer = null;
    super.dispose();
  }
}
