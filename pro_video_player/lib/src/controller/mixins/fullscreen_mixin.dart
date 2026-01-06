import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

/// Mixin providing fullscreen and orientation lock functionality.
mixin FullscreenMixin on ProVideoPlayerControllerBase {
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
    ensureInitializedInternal();
    return services.fullscreenManager.enterFullscreen(orientation: orientation);
  }

  /// Exits fullscreen mode.
  ///
  /// This restores the system UI and orientation to normal.
  Future<void> exitFullscreen() async {
    ensureInitializedInternal();
    await services.fullscreenManager.exitFullscreen();
  }

  /// Toggles fullscreen mode.
  Future<void> toggleFullscreen() async {
    ensureInitializedInternal();
    await services.fullscreenManager.toggleFullscreen();
  }

  /// Sets the fullscreen state for Flutter-managed fullscreen (no native call).
  ///
  /// Use this on desktop platforms where Flutter controls handle fullscreen
  /// via route navigation rather than native fullscreen windows.
  ///
  /// This updates the [VideoPlayerValue.isFullscreen] state without triggering
  /// native fullscreen behavior (like creating a separate window on macOS).
  void setFlutterFullscreenState({required bool isFullscreen}) {
    services.fullscreenManager.setFlutterFullscreenState(isFullscreen: isFullscreen);
  }

  /// Locks the screen orientation to the specified [orientation].
  ///
  /// This is typically used in fullscreen mode to allow users to lock the
  /// screen to a specific orientation (e.g., landscape only).
  ///
  /// The orientation lock persists until [unlockOrientation] is called or
  /// fullscreen mode is exited.
  Future<void> lockOrientation(FullscreenOrientation orientation) async {
    ensureInitializedInternal();
    await services.fullscreenManager.lockOrientation(orientation);
  }

  /// Unlocks the screen orientation.
  ///
  /// When unlocked in fullscreen mode, the orientation follows the
  /// [VideoPlayerOptions.fullscreenOrientation] setting.
  /// When unlocked outside fullscreen, all orientations are allowed.
  Future<void> unlockOrientation() async {
    ensureInitializedInternal();
    await services.fullscreenManager.unlockOrientation();
  }

  /// Toggles the orientation lock.
  ///
  /// If currently unlocked, locks to [FullscreenOrientation.landscapeBoth].
  /// If currently locked, unlocks the orientation.
  Future<void> toggleOrientationLock() async {
    ensureInitializedInternal();
    await services.fullscreenManager.toggleOrientationLock();
  }

  /// Cycles through orientation lock options.
  ///
  /// Cycles through: Unlocked → Landscape Both → Landscape Left → Landscape Right → Unlocked
  ///
  /// This is useful for a toolbar button that cycles through lock states.
  Future<void> cycleOrientationLock() async {
    ensureInitializedInternal();
    await services.fullscreenManager.cycleOrientationLock();
  }

  /// Whether the screen orientation is currently locked.
  bool get isOrientationLocked => value.isOrientationLocked;

  /// The currently locked orientation, or `null` if not locked.
  FullscreenOrientation? get lockedOrientation => value.lockedOrientation;
}
