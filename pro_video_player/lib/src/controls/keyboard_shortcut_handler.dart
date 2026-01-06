import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult, VoidCallback;

import '../pro_video_player_controller.dart';
import '../video_controls_state.dart';

/// Handles keyboard shortcuts for video player controls.
///
/// This class encapsulates all keyboard input handling logic, making it
/// easier to test in isolation and maintain separately from UI state management.
class KeyboardShortcutHandler {
  /// Creates a keyboard shortcut handler.
  KeyboardShortcutHandler({
    required ProVideoPlayerController videoController,
    required Duration keyboardSeekDuration,
    required void Function(KeyboardOverlayType type, double value) onShowOverlay,
    required VoidCallback onResetHideTimer,
    required VoidCallback? onShowKeyboardShortcuts,
  }) : _videoController = videoController,
       _keyboardSeekDuration = keyboardSeekDuration,
       _onShowOverlay = onShowOverlay,
       _onResetHideTimer = onResetHideTimer,
       _onShowKeyboardShortcuts = onShowKeyboardShortcuts;

  final ProVideoPlayerController _videoController;
  final Duration _keyboardSeekDuration;
  final void Function(KeyboardOverlayType type, double value) _onShowOverlay;
  final VoidCallback _onResetHideTimer;
  final VoidCallback? _onShowKeyboardShortcuts;

  // Track previous volume for mute/unmute toggle
  double _previousVolume = 1;

  /// Handles keyboard events for video player shortcuts.
  ///
  /// Works on all platforms including mobile devices with keyboards
  /// (tablets with keyboard cases, Bluetooth keyboards, etc.).
  KeyEventResult handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;
    final isKeyDown = event is KeyDownEvent;
    final isKeyRepeat = event is KeyRepeatEvent;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Arrow keys: handle both key down and key repeat (for holding)
    if (isKeyDown || isKeyRepeat) {
      final result = _handleArrowKeys(key, isShiftPressed);
      if (result == KeyEventResult.handled) return result;
    }

    // Only handle key down for toggle actions (not repeat)
    if (!isKeyDown) {
      return KeyEventResult.ignored;
    }

    // Toggle actions
    final toggleResult = _handleToggleKeys(key, isShiftPressed);
    if (toggleResult == KeyEventResult.handled) return toggleResult;

    // Media keys
    return _handleMediaKeys(key);
  }

  KeyEventResult _handleArrowKeys(LogicalKeyboardKey key, bool isShiftPressed) {
    // Left Arrow: Seek backward (Shift = longer jump)
    if (key == LogicalKeyboardKey.arrowLeft) {
      final seekAmount = isShiftPressed ? _keyboardSeekDuration * 3 : _keyboardSeekDuration;
      final position = _videoController.value.position;
      final newPosition = position - seekAmount;
      unawaited(_videoController.seekTo(newPosition.isNegative ? Duration.zero : newPosition));
      _onShowOverlay(KeyboardOverlayType.seek, -seekAmount.inSeconds.toDouble());
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    // Right Arrow: Seek forward (Shift = longer jump)
    if (key == LogicalKeyboardKey.arrowRight) {
      final seekAmount = isShiftPressed ? _keyboardSeekDuration * 3 : _keyboardSeekDuration;
      final position = _videoController.value.position;
      final duration = _videoController.value.duration;
      final newPosition = position + seekAmount;
      unawaited(_videoController.seekTo(newPosition > duration ? duration : newPosition));
      _onShowOverlay(KeyboardOverlayType.seek, seekAmount.inSeconds.toDouble());
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    // Up Arrow: Increase volume / Shift+Up: Increase playback speed
    if (key == LogicalKeyboardKey.arrowUp) {
      if (isShiftPressed) {
        final currentSpeed = _videoController.value.playbackSpeed;
        final newSpeed = (currentSpeed + 0.25).clamp(0.25, 2.0);
        unawaited(_videoController.setPlaybackSpeed(newSpeed));
        _onShowOverlay(KeyboardOverlayType.speed, newSpeed);
      } else {
        final currentVolume = _videoController.value.volume;
        final newVolume = (currentVolume + 0.05).clamp(0.0, 1.0);
        unawaited(_videoController.setVolume(newVolume));
        _onShowOverlay(KeyboardOverlayType.volume, newVolume);
      }
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    // Down Arrow: Decrease volume / Shift+Down: Decrease playback speed
    if (key == LogicalKeyboardKey.arrowDown) {
      if (isShiftPressed) {
        final currentSpeed = _videoController.value.playbackSpeed;
        final newSpeed = (currentSpeed - 0.25).clamp(0.25, 2.0);
        unawaited(_videoController.setPlaybackSpeed(newSpeed));
        _onShowOverlay(KeyboardOverlayType.speed, newSpeed);
      } else {
        final currentVolume = _videoController.value.volume;
        final newVolume = (currentVolume - 0.05).clamp(0.0, 1.0);
        unawaited(_videoController.setVolume(newVolume));
        _onShowOverlay(KeyboardOverlayType.volume, newVolume);
      }
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleToggleKeys(LogicalKeyboardKey key, bool isShiftPressed) {
    // Space: Toggle play/pause
    if (key == LogicalKeyboardKey.space) {
      if (_videoController.value.isPlaying) {
        unawaited(_videoController.pause());
      } else {
        unawaited(_videoController.play());
      }
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    // M: Toggle mute
    if (key == LogicalKeyboardKey.keyM) {
      final currentVolume = _videoController.value.volume;
      if (currentVolume > 0) {
        // Mute: save current volume and set to 0
        _previousVolume = currentVolume;
        unawaited(_videoController.setVolume(0));
      } else {
        // Unmute: restore previous volume
        unawaited(_videoController.setVolume(_previousVolume));
      }
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    // ?: Show keyboard shortcuts help
    if (key == LogicalKeyboardKey.slash && isShiftPressed) {
      _onShowKeyboardShortcuts?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleMediaKeys(LogicalKeyboardKey key) {
    // Media keys: Play/Pause
    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause) {
      if (_videoController.value.isPlaying) {
        unawaited(_videoController.pause());
      } else {
        unawaited(_videoController.play());
      }
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    // Media keys: Stop
    if (key == LogicalKeyboardKey.mediaStop) {
      unawaited(_videoController.pause());
      unawaited(_videoController.seekTo(Duration.zero));
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    // Media keys: Next/Previous track (for playlists)
    if (key == LogicalKeyboardKey.mediaTrackNext) {
      if (_videoController.value.playlist != null) {
        unawaited(_videoController.playlistNext());
      }
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      if (_videoController.value.playlist != null) {
        unawaited(_videoController.playlistPrevious());
      }
      _onResetHideTimer();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
