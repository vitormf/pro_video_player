import 'package:flutter/services.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Manages fullscreen state and orientation for the video player.
///
/// This manager handles:
/// - Entering and exiting fullscreen mode
/// - System UI visibility (status bar, navigation bar)
/// - Orientation locking and unlocking
/// - Flutter-managed fullscreen (for desktop platforms)
class FullscreenManager {
  /// Creates a fullscreen manager with dependency injection via callbacks.
  FullscreenManager({
    required this.getValue,
    required this.setValue,
    required this.getPlayerId,
    required this.getOptions,
    required this.platform,
    required this.ensureInitialized,
  });

  /// Gets the current video player value.
  final VideoPlayerValue Function() getValue;

  /// Updates the video player value.
  final void Function(VideoPlayerValue) setValue;

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Gets the video player options.
  final VideoPlayerOptions Function() getOptions;

  /// Platform implementation for fullscreen operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

  /// Enters fullscreen mode.
  ///
  /// This hides the system UI (status bar, navigation bar) and sets
  /// the orientation based on [orientation] parameter or the
  /// `fullscreenOrientation` option if not specified.
  ///
  /// The app should respond to `value.isFullscreen` to expand the video
  /// widget to fill the screen.
  ///
  /// Returns `true` if fullscreen was entered successfully.
  Future<bool> enterFullscreen({FullscreenOrientation? orientation}) async {
    ensureInitialized();

    final effectiveOrientation = orientation ?? getOptions().fullscreenOrientation;

    // Hide system UI and set orientation based on options
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(_getOrientationsForFullscreen(effectiveOrientation));

    // Update state and notify native layer
    final value = getValue();
    setValue(value.copyWith(isFullscreen: true));
    return platform.enterFullscreen(getPlayerId()!);
  }

  /// Exits fullscreen mode.
  ///
  /// This restores the system UI and orientation to normal.
  Future<void> exitFullscreen() async {
    ensureInitialized();

    // Restore system UI
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // First force portrait to rotate the device back from landscape
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Brief delay to allow the rotation to take effect
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Then allow all orientations for normal app behavior
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Update state and notify native layer
    final value = getValue();
    setValue(value.copyWith(isFullscreen: false));
    await platform.exitFullscreen(getPlayerId()!);
  }

  /// Toggles fullscreen mode.
  Future<void> toggleFullscreen() async {
    final value = getValue();
    if (value.isFullscreen) {
      await exitFullscreen();
    } else {
      await enterFullscreen();
    }
  }

  /// Sets the fullscreen state for Flutter-managed fullscreen (no native call).
  ///
  /// Use this on desktop platforms where Flutter controls handle fullscreen
  /// via route navigation rather than native fullscreen windows.
  ///
  /// This updates the [VideoPlayerValue.isFullscreen] state without triggering
  /// native fullscreen behavior (like creating a separate window on macOS).
  void setFlutterFullscreenState({required bool isFullscreen}) {
    final value = getValue();
    setValue(value.copyWith(isFullscreen: isFullscreen));
  }

  /// Locks the screen orientation to the specified [orientation].
  ///
  /// This is typically used in fullscreen mode to allow users to lock the
  /// screen to a specific orientation (e.g., landscape only).
  ///
  /// The orientation lock persists until [unlockOrientation] is called or
  /// fullscreen mode is exited.
  ///
  /// Example:
  /// ```dart
  /// // Lock to landscape only
  /// await controller.lockOrientation(FullscreenOrientation.landscapeBoth);
  ///
  /// // Lock to portrait only
  /// await controller.lockOrientation(FullscreenOrientation.portraitBoth);
  /// ```
  Future<void> lockOrientation(FullscreenOrientation orientation) async {
    await SystemChrome.setPreferredOrientations(_getOrientationsForFullscreen(orientation));
    final value = getValue();
    setValue(value.copyWith(lockedOrientation: orientation));
  }

  /// Unlocks the screen orientation.
  ///
  /// When unlocked in fullscreen mode, the orientation follows the
  /// [VideoPlayerOptions.fullscreenOrientation] setting.
  /// When unlocked outside fullscreen, all orientations are allowed.
  Future<void> unlockOrientation() async {
    final value = getValue();
    if (value.isFullscreen) {
      // In fullscreen, revert to the fullscreen orientation setting
      await SystemChrome.setPreferredOrientations(_getOrientationsForFullscreen(getOptions().fullscreenOrientation));
    } else {
      // Outside fullscreen, allow all orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setValue(value.copyWith(clearLockedOrientation: true));
  }

  /// Toggles the orientation lock.
  ///
  /// If currently unlocked, locks to [FullscreenOrientation.landscapeBoth].
  /// If currently locked, unlocks the orientation.
  Future<void> toggleOrientationLock() async {
    final value = getValue();
    if (value.isOrientationLocked) {
      await unlockOrientation();
    } else {
      await lockOrientation(FullscreenOrientation.landscapeBoth);
    }
  }

  /// Cycles through orientation lock options.
  ///
  /// Cycles through: Unlocked → Landscape Both → Landscape Left → Landscape Right → Unlocked
  ///
  /// This is useful for a toolbar button that cycles through lock states.
  Future<void> cycleOrientationLock() async {
    final value = getValue();
    final current = value.lockedOrientation;
    switch (current) {
      case null:
        await lockOrientation(FullscreenOrientation.landscapeBoth);
      case FullscreenOrientation.landscapeBoth:
        await lockOrientation(FullscreenOrientation.landscapeLeft);
      case FullscreenOrientation.landscapeLeft:
        await lockOrientation(FullscreenOrientation.landscapeRight);
      case FullscreenOrientation.landscapeRight:
      case FullscreenOrientation.portraitUp:
      case FullscreenOrientation.portraitDown:
      case FullscreenOrientation.portraitBoth:
      case FullscreenOrientation.all:
        await unlockOrientation();
    }
  }

  /// Converts [FullscreenOrientation] to a list of [DeviceOrientation].
  List<DeviceOrientation> _getOrientationsForFullscreen(FullscreenOrientation orientation) {
    switch (orientation) {
      case FullscreenOrientation.portraitUp:
        return [DeviceOrientation.portraitUp];
      case FullscreenOrientation.portraitDown:
        return [DeviceOrientation.portraitDown];
      case FullscreenOrientation.portraitBoth:
        return [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];
      case FullscreenOrientation.landscapeLeft:
        return [DeviceOrientation.landscapeLeft];
      case FullscreenOrientation.landscapeRight:
        return [DeviceOrientation.landscapeRight];
      case FullscreenOrientation.landscapeBoth:
        return [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];
      case FullscreenOrientation.all:
        return [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ];
    }
  }
}
