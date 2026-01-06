/// Web options for video_player API compatibility.
///
/// These classes match the exact signatures from Flutter's video_player library.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'package:flutter/foundation.dart';

import 'compat_annotation.dart';

/// Options to control how the video player's controls behave on web.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@immutable
@videoPlayerCompat
class VideoPlayerWebOptionsControls {
  /// Disables native controls. Default behavior.
  const VideoPlayerWebOptionsControls.disabled()
    : enabled = false,
      allowDownload = false,
      allowFullscreen = false,
      allowPlaybackRate = false,
      allowPictureInPicture = false;

  /// Enables native controls with customizable options.
  const VideoPlayerWebOptionsControls.enabled({
    this.allowDownload = true,
    this.allowFullscreen = true,
    this.allowPlaybackRate = true,
    this.allowPictureInPicture = true,
  }) : enabled = true;

  /// Whether native controls are enabled.
  final bool enabled;

  /// Whether download control is displayed.
  final bool allowDownload;

  /// Whether fullscreen control is enabled.
  final bool allowFullscreen;

  /// Whether playback rate control is displayed.
  final bool allowPlaybackRate;

  /// Whether picture-in-picture control is displayed.
  final bool allowPictureInPicture;

  /// A string representation of disallowed controls for the HTML controlsList attribute.
  String get controlsList {
    if (!enabled) return '';
    final disallowed = <String>[];
    if (!allowDownload) disallowed.add('nodownload');
    if (!allowFullscreen) disallowed.add('nofullscreen');
    if (!allowPlaybackRate) disallowed.add('noplaybackrate');
    // Note: Picture-in-picture is controlled via disablePictureInPicture attribute, not controlsList
    return disallowed.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoPlayerWebOptionsControls &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          allowDownload == other.allowDownload &&
          allowFullscreen == other.allowFullscreen &&
          allowPlaybackRate == other.allowPlaybackRate &&
          allowPictureInPicture == other.allowPictureInPicture;

  @override
  int get hashCode => Object.hash(enabled, allowDownload, allowFullscreen, allowPlaybackRate, allowPictureInPicture);
}

/// Web-specific options for the video player.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@immutable
@videoPlayerCompat
class VideoPlayerWebOptions {
  /// Creates web-specific video player options.
  const VideoPlayerWebOptions({
    this.controls = const VideoPlayerWebOptionsControls.disabled(),
    this.allowContextMenu = true,
    this.allowRemotePlayback = true,
    this.poster,
  });

  /// Additional settings for how control options are displayed.
  final VideoPlayerWebOptionsControls controls;

  /// Whether context menu (right click) is allowed.
  final bool allowContextMenu;

  /// Whether remote playback is allowed.
  final bool allowRemotePlayback;

  /// The URL of the poster image to be displayed before the video starts.
  final Uri? poster;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoPlayerWebOptions &&
          runtimeType == other.runtimeType &&
          controls == other.controls &&
          allowContextMenu == other.allowContextMenu &&
          allowRemotePlayback == other.allowRemotePlayback &&
          poster == other.poster;

  @override
  int get hashCode => Object.hash(controls, allowContextMenu, allowRemotePlayback, poster);
}
