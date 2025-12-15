import 'package:flutter/material.dart';

/// Callbacks for triggering state updates in the controls widget.
///
/// This interface bundles all callbacks that child widgets need to trigger
/// setState updates in the parent VideoPlayerControls widget, reducing
/// parameter coupling and creating a clean contract.
///
/// Example:
/// ```dart
/// final stateCallbacks = ControlsStateCallbacks(
///   onDragStart: () => setState(() => _controlsState.startDragging()),
///   onDragEnd: () => setState(() => _controlsState.endDragging()),
///   onToggleTimeDisplay: () => setState(() => _controlsState.toggleTimeDisplay()),
///   onToggleVisibility: () => setState(() => _controlsState.toggleVisibility()),
///   onMouseEnter: () => setState(() => _controlsState.setMouseOverControls(isOver: true)),
///   onMouseExit: () => setState(() => _controlsState.setMouseOverControls(isOver: false)),
/// );
/// ```
class ControlsStateCallbacks {
  /// Creates a controls state callbacks bundle.
  const ControlsStateCallbacks({
    required this.onDragStart,
    required this.onDragEnd,
    required this.onToggleTimeDisplay,
    required this.onToggleVisibility,
    required this.onMouseEnter,
    required this.onMouseExit,
  });

  /// Called when the user starts dragging the progress bar.
  ///
  /// This triggers a state update that sets isDragging to true,
  /// which prevents controls from auto-hiding during drag.
  final VoidCallback onDragStart;

  /// Called when the user finishes dragging the progress bar.
  ///
  /// This triggers a state update that sets isDragging to false,
  /// allowing controls to auto-hide again.
  final VoidCallback onDragEnd;

  /// Called when the user taps the time display to toggle between
  /// total duration and remaining time.
  ///
  /// This triggers a state update that toggles showRemainingTime.
  final VoidCallback onToggleTimeDisplay;

  /// Called when the controls visibility should be toggled.
  ///
  /// This triggers a state update that toggles the visible state,
  /// showing/hiding the entire controls overlay.
  final VoidCallback onToggleVisibility;

  /// Called when the mouse enters the controls area (desktop/web only).
  ///
  /// This triggers a state update that sets isMouseOverControls to true,
  /// preventing controls from auto-hiding while the mouse is over them.
  final VoidCallback onMouseEnter;

  /// Called when the mouse exits the controls area (desktop/web only).
  ///
  /// This triggers a state update that sets isMouseOverControls to false,
  /// allowing controls to auto-hide again.
  final VoidCallback onMouseExit;
}
