import 'package:flutter/material.dart';
import '../controller/manager_callbacks.dart' show ManagerCallbacks;
import '../pro_video_player_controller.dart';

/// Mixin providing standard callbacks for gesture managers.
///
/// Similar to [ManagerCallbacks] in the controller package, but tailored
/// for gesture detection needs. Provides access to controller, configuration,
/// and state update callbacks.
///
/// This pattern achieves dependency injection via callbacks, preventing
/// circular dependencies and enabling isolated unit testing.
mixin GestureManagerCallbacks {
  /// Gets the video player controller.
  ProVideoPlayerController get controller;

  /// Whether this gesture type is enabled.
  bool get enableGesture;

  /// Whether to show visual feedback for gestures.
  bool get enableFeedback;

  /// Updates the seek target position (for seek preview overlay).
  void Function(Duration?) get setSeekTarget;

  /// Updates the current volume (for volume overlay).
  void Function(double?) get setCurrentVolume;

  /// Updates the current brightness (for brightness overlay).
  void Function(double?) get setCurrentBrightness;

  /// Updates the current playback speed (for speed overlay).
  void Function(double?) get setCurrentSpeed;

  /// Sets the controls visibility state.
  void Function({required bool visible}) get setControlsVisible;

  /// Optional external callback when controls visibility changes.
  ValueChanged<bool>? get onControlsVisibilityChanged;

  /// Optional external callback when seek gesture updates.
  ValueChanged<Duration?>? get onSeekGestureUpdate;

  /// Optional external callback when brightness changes.
  ValueChanged<double>? get onBrightnessChanged;

  /// Shows visual feedback with icon and optional text.
  void Function(IconData icon, String? text) get showFeedback;

  /// Gets the current widget context (for render box calculations).
  BuildContext get context;
}

/// Callbacks specific to tap gesture management.
mixin TapGestureCallbacks on GestureManagerCallbacks {
  /// Whether auto-hide controls is enabled.
  bool get autoHideControls;

  /// Delay before auto-hiding controls.
  Duration get autoHideDelay;

  /// Duration to seek forward/backward on double tap.
  Duration get seekDuration;

  /// Whether double tap to seek is enabled.
  bool get enableDoubleTapSeek;
}

/// Callbacks specific to seek gesture management.
mixin SeekGestureCallbacks on GestureManagerCallbacks {
  /// How many seconds to seek per inch of horizontal swipe.
  double get seekSecondsPerInch;
}

/// Callbacks specific to volume gesture management.
mixin VolumeGestureCallbacks on GestureManagerCallbacks {
  /// Fraction of screen width reserved for side gestures (left/right).
  double get sideGestureAreaFraction;

  /// Height of bottom exclusion zone (prevents accidental gestures).
  double get bottomExclusionHeight;
}

/// Callbacks specific to brightness gesture management.
mixin BrightnessGestureCallbacks on GestureManagerCallbacks {
  /// Fraction of screen width reserved for side gestures (left/right).
  double get sideGestureAreaFraction;

  /// Height of bottom exclusion zone (prevents accidental gestures).
  double get bottomExclusionHeight;
}

/// Callbacks specific to playback speed gesture management.
mixin PlaybackSpeedGestureCallbacks on GestureManagerCallbacks {
  // Currently no specific callbacks needed
}
