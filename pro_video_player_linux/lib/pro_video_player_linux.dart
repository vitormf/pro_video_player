import 'package:flutter/widgets.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// The Linux implementation of [ProVideoPlayerPlatform].
///
/// This class uses GStreamer for video playback on Linux.
class ProVideoPlayerLinux extends MethodChannelBase {
  /// Constructs a ProVideoPlayerLinux.
  ProVideoPlayerLinux() : super('pro_video_player_linux');

  /// Registers this class as the default instance of [ProVideoPlayerPlatform].
  static void registerWith() {
    ProVideoPlayerPlatform.instance = ProVideoPlayerLinux();
  }

  @override
  Future<bool> enterPip(int playerId, {PipOptions options = const PipOptions()}) async => false; // PiP not typically supported on Linux

  @override
  Future<void> exitPip(int playerId) async {
    // PiP not typically supported on Linux
  }

  @override
  Future<bool> isPipSupported() async => false; // PiP not typically supported on Linux

  @override
  Future<PlatformCapabilities> getPlatformCapabilities() async =>
      // Linux platform capabilities (placeholder - native implementation needed)
      const PlatformCapabilities(
        supportsPictureInPicture: false, // Not implemented yet
        supportsFullscreen: false, // Not implemented yet
        supportsBackgroundPlayback: false, // Not implemented yet
        supportsCasting: false, // Could support DLNA/UPnP in future
        supportsAirPlay: false, // AirPlay is iOS/macOS only
        supportsChromecast: false, // Android only
        supportsRemotePlayback: false, // Web only
        supportsQualitySelection: false, // Not implemented yet
        supportsPlaybackSpeedControl: true, // GStreamer supports this
        supportsSubtitles: false, // Not implemented yet
        supportsExternalSubtitles: false, // Not implemented yet
        supportsAudioTrackSelection: false, // Not implemented yet
        supportsChapters: false, // Not implemented yet
        supportsVideoMetadataExtraction: false, // Not implemented yet
        supportsNetworkMonitoring: false, // Not implemented yet
        supportsBandwidthEstimation: false, // Not implemented yet
        supportsAdaptiveBitrate: false, // Not implemented yet
        supportsHLS: false, // Not implemented yet
        supportsDASH: false, // Not implemented yet
        supportsDeviceVolumeControl: false, // Not implemented yet
        supportsScreenBrightnessControl: false, // Not supported on desktop
        platformName: 'Linux',
        nativePlayerType: 'GStreamer (placeholder)',
      );

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) =>
      const Text('Linux video view placeholder');
}
