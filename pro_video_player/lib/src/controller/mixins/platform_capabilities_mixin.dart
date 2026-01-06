import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

/// Mixin providing platform capability checks.
mixin PlatformCapabilitiesMixin on ProVideoPlayerControllerBase {
  /// Gets static platform information.
  ///
  /// Returns metadata about the platform (name, player type, additional info).
  Future<PlatformInfo> getPlatformInfo() => platform.getPlatformInfo();

  /// Checks if Picture-in-Picture mode is supported.
  Future<bool> supportsPictureInPicture() => platform.supportsPictureInPicture();

  /// Checks if fullscreen mode is supported.
  Future<bool> supportsFullscreen() => platform.supportsFullscreen();

  /// Checks if background playback is supported.
  Future<bool> supportsBackgroundPlayback() => platform.supportsBackgroundPlayback();

  /// Checks if any form of casting is supported.
  Future<bool> supportsCasting() => platform.supportsCasting();

  /// Checks if AirPlay is supported.
  Future<bool> supportsAirPlay() => platform.supportsAirPlay();

  /// Checks if Chromecast is supported.
  Future<bool> supportsChromecast() => platform.supportsChromecast();

  /// Checks if Remote Playback API is supported.
  Future<bool> supportsRemotePlayback() => platform.supportsRemotePlayback();

  /// Checks if quality selection is supported.
  Future<bool> supportsQualitySelection() => platform.supportsQualitySelection();

  /// Checks if playback speed control is supported.
  Future<bool> supportsPlaybackSpeedControl() => platform.supportsPlaybackSpeedControl();

  /// Checks if subtitles are supported.
  Future<bool> supportsSubtitles() => platform.supportsSubtitles();

  /// Checks if external subtitles are supported.
  Future<bool> supportsExternalSubtitles() => platform.supportsExternalSubtitles();

  /// Checks if audio track selection is supported.
  Future<bool> supportsAudioTrackSelection() => platform.supportsAudioTrackSelection();

  /// Checks if chapters are supported.
  Future<bool> supportsChapters() => platform.supportsChapters();

  /// Checks if video metadata extraction is supported.
  Future<bool> supportsVideoMetadataExtraction() => platform.supportsVideoMetadataExtraction();

  /// Checks if network monitoring is supported.
  Future<bool> supportsNetworkMonitoring() => platform.supportsNetworkMonitoring();

  /// Checks if bandwidth estimation is supported.
  Future<bool> supportsBandwidthEstimation() => platform.supportsBandwidthEstimation();

  /// Checks if adaptive bitrate streaming is supported.
  Future<bool> supportsAdaptiveBitrate() => platform.supportsAdaptiveBitrate();

  /// Checks if HLS is supported.
  Future<bool> supportsHLS() => platform.supportsHLS();

  /// Checks if DASH is supported.
  Future<bool> supportsDASH() => platform.supportsDASH();

  /// Checks if device volume control is supported.
  Future<bool> supportsDeviceVolumeControl() => platform.supportsDeviceVolumeControl();

  /// Checks if screen brightness control is supported.
  Future<bool> supportsScreenBrightnessControl() => platform.supportsScreenBrightnessControl();
}
