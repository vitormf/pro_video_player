import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'controls/controls_enums.dart';

/// Configuration for toolbar behavior (from widget properties).
class ToolbarConfig {
  /// Creates a toolbar configuration.
  const ToolbarConfig({
    this.showSubtitleButton = true,
    this.showAudioButton = true,
    this.showQualityButton = true,
    this.showSpeedButton = true,
    this.showScalingModeButton = false,
    this.showBackgroundPlaybackButton = true,
    this.showPipButton = true,
    this.showOrientationLockButton = true,
    this.showFullscreenButton = true,
    this.fullscreenOnly = false,
  });

  /// Whether to show the subtitle button.
  final bool showSubtitleButton;

  /// Whether to show the audio track button.
  final bool showAudioButton;

  /// Whether to show the quality selection button.
  final bool showQualityButton;

  /// Whether to show the playback speed button.
  final bool showSpeedButton;

  /// Whether to show the scaling mode button.
  final bool showScalingModeButton;

  /// Whether to show the background playback toggle button.
  final bool showBackgroundPlaybackButton;

  /// Whether to show the picture-in-picture button.
  final bool showPipButton;

  /// Whether to show the orientation lock button.
  final bool showOrientationLockButton;

  /// Whether to show the fullscreen button.
  final bool showFullscreenButton;

  /// Whether the player is in fullscreen-only mode.
  final bool fullscreenOnly;
}

/// Current state for toolbar visibility decisions.
class ToolbarState {
  /// Creates a toolbar state.
  const ToolbarState({
    this.hasPlaylist = false,
    this.hasSubtitleTracks = false,
    this.audioTrackCount = 0,
    this.qualityTrackCount = 0,
    this.hasChapters = false,
    this.isCasting = false,
    this.isBackgroundPlaybackSupported = false,
    this.isPipAvailable = false,
    this.isCastingSupported = false,
    this.isFullscreen = false,
    this.isDesktopPlatform = false,
  });

  /// Whether a playlist is currently loaded.
  final bool hasPlaylist;

  /// Whether subtitle tracks are available.
  final bool hasSubtitleTracks;

  /// Number of audio tracks available.
  final int audioTrackCount;

  /// Number of quality tracks available.
  final int qualityTrackCount;

  /// Whether chapters are available.
  final bool hasChapters;

  /// Whether currently casting to a device.
  final bool isCasting;

  /// Whether background playback is supported.
  final bool isBackgroundPlaybackSupported;

  /// Whether PiP is available.
  final bool isPipAvailable;

  /// Whether casting is supported.
  final bool isCastingSupported;

  /// Whether currently in fullscreen mode.
  final bool isFullscreen;

  /// Whether running on a desktop platform.
  final bool isDesktopPlatform;
}

/// Manages toolbar action visibility and metadata.
///
/// This class contains pure business logic for determining which toolbar actions
/// should be visible based on configuration and current state. All methods are
/// static and have no side effects, making them easy to test.
class VideoToolbarManager {
  /// Private constructor to prevent instantiation.
  VideoToolbarManager._();

  /// Determines if the volume button should be shown.
  ///
  /// Volume button is shown on platforms where volume gestures control player
  /// volume instead of device volume (macOS and web).
  static bool shouldShowVolumeButton({required bool isWeb, required bool isMacOS}) => isWeb || isMacOS;

  /// Returns the label for a toolbar action.
  static String getActionLabel(PlayerToolbarAction action) => switch (action) {
    PlayerToolbarAction.shuffle => 'Shuffle',
    PlayerToolbarAction.repeatMode => 'Repeat',
    PlayerToolbarAction.subtitles => 'Subtitles',
    PlayerToolbarAction.audio => 'Audio',
    PlayerToolbarAction.chapters => 'Chapters',
    PlayerToolbarAction.quality => 'Quality',
    PlayerToolbarAction.speed => 'Speed',
    PlayerToolbarAction.scalingMode => 'Scaling',
    PlayerToolbarAction.backgroundPlayback => 'Background',
    PlayerToolbarAction.pip => 'Picture-in-Picture',
    PlayerToolbarAction.casting => 'Cast',
    PlayerToolbarAction.orientationLock => 'Orientation',
    PlayerToolbarAction.fullscreen => 'Fullscreen',
  };

  /// Returns the icon for a toolbar action based on current state.
  static IconData getActionIcon(
    PlayerToolbarAction action, {
    required bool isShuffled,
    required PlaylistRepeatMode playlistRepeatMode,
    required bool hasSelectedSubtitle,
    required bool isBackgroundPlaybackEnabled,
    required bool isCasting,
    required bool isOrientationLocked,
    required bool isFullscreen,
  }) => switch (action) {
    PlayerToolbarAction.shuffle => isShuffled ? Icons.shuffle_on : Icons.shuffle,
    PlayerToolbarAction.repeatMode => playlistRepeatMode == PlaylistRepeatMode.one ? Icons.repeat_one : Icons.repeat,
    PlayerToolbarAction.subtitles => hasSelectedSubtitle ? Icons.closed_caption : Icons.closed_caption_off,
    PlayerToolbarAction.audio => Icons.audiotrack,
    PlayerToolbarAction.chapters => Icons.list,
    PlayerToolbarAction.quality => Icons.high_quality,
    PlayerToolbarAction.speed => Icons.speed,
    PlayerToolbarAction.scalingMode => Icons.aspect_ratio,
    PlayerToolbarAction.backgroundPlayback =>
      isBackgroundPlaybackEnabled ? Icons.headphones : Icons.headphones_outlined,
    PlayerToolbarAction.pip => Icons.picture_in_picture_alt,
    PlayerToolbarAction.casting => isCasting ? Icons.cast_connected : Icons.cast,
    PlayerToolbarAction.orientationLock => isOrientationLocked ? Icons.screen_lock_rotation : Icons.screen_rotation,
    PlayerToolbarAction.fullscreen => isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
  };

  /// Determines if a specific toolbar action should be visible.
  ///
  /// Takes into account widget configuration and current player state.
  static bool shouldShowAction(
    PlayerToolbarAction action, {
    required ToolbarConfig config,
    required ToolbarState state,
  }) {
    final isCasting = state.isCasting;

    return switch (action) {
      PlayerToolbarAction.shuffle || PlayerToolbarAction.repeatMode => state.hasPlaylist,
      PlayerToolbarAction.subtitles => config.showSubtitleButton && state.hasSubtitleTracks,
      PlayerToolbarAction.audio => config.showAudioButton && state.audioTrackCount > 1,
      PlayerToolbarAction.chapters => state.hasChapters,
      PlayerToolbarAction.quality => config.showQualityButton && state.qualityTrackCount > 1 && !isCasting,
      PlayerToolbarAction.speed => config.showSpeedButton && !isCasting,
      PlayerToolbarAction.scalingMode => config.showScalingModeButton && !isCasting,
      PlayerToolbarAction.backgroundPlayback =>
        config.showBackgroundPlaybackButton &&
            state.isBackgroundPlaybackSupported &&
            !state.isDesktopPlatform &&
            !isCasting,
      PlayerToolbarAction.pip => config.showPipButton && state.isPipAvailable && !isCasting,
      PlayerToolbarAction.casting => state.isCastingSupported,
      PlayerToolbarAction.orientationLock => config.showOrientationLockButton && state.isFullscreen && !isCasting,
      // Hide exit fullscreen button when in fullscreen-only mode and already in fullscreen
      PlayerToolbarAction.fullscreen =>
        config.showFullscreenButton && !isCasting && !(config.fullscreenOnly && state.isFullscreen),
    };
  }

  /// Returns the default list of toolbar actions based on configuration and state.
  ///
  /// This builds the toolbar action list dynamically based on what features are
  /// available and enabled.
  static List<PlayerToolbarAction> getDefaultToolbarActions({
    required ToolbarConfig config,
    required ToolbarState state,
  }) => <PlayerToolbarAction>[
    // Casting is first so it's prominently visible when devices are available
    if (state.isCastingSupported) PlayerToolbarAction.casting,
    if (state.hasPlaylist) ...[PlayerToolbarAction.shuffle, PlayerToolbarAction.repeatMode],
    if (config.showSubtitleButton && state.hasSubtitleTracks) PlayerToolbarAction.subtitles,
    if (config.showAudioButton && state.audioTrackCount > 1) PlayerToolbarAction.audio,
    if (config.showQualityButton && state.qualityTrackCount > 1) PlayerToolbarAction.quality,
    if (config.showSpeedButton) PlayerToolbarAction.speed,
    if (config.showScalingModeButton) PlayerToolbarAction.scalingMode,
    if (config.showBackgroundPlaybackButton && state.isBackgroundPlaybackSupported)
      PlayerToolbarAction.backgroundPlayback,
    if (config.showPipButton && state.isPipAvailable) PlayerToolbarAction.pip,
    if (config.showOrientationLockButton && state.isFullscreen) PlayerToolbarAction.orientationLock,
    if (config.showFullscreenButton) PlayerToolbarAction.fullscreen,
  ];

  /// Determines if an action cannot be moved to the overflow menu.
  ///
  /// The casting button uses a native platform view that must be tapped directly
  /// to show the device picker. It cannot work from a popup menu.
  static bool isNonOverflowableAction(PlayerToolbarAction action) => action == PlayerToolbarAction.casting;
}
