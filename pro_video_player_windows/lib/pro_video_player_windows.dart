import 'package:flutter/widgets.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// The Windows implementation of [ProVideoPlayerPlatform].
///
/// This class uses Media Foundation for video playback on Windows.
class ProVideoPlayerWindows extends MethodChannelBase {
  /// Constructs a ProVideoPlayerWindows.
  ProVideoPlayerWindows() : super('pro_video_player_windows');

  /// Registers this class as the default instance of [ProVideoPlayerPlatform].
  static void registerWith() {
    ProVideoPlayerPlatform.instance = ProVideoPlayerWindows();
  }

  @override
  Future<bool> enterPip(int playerId, {PipOptions options = const PipOptions()}) async => false; // PiP not supported on Windows

  @override
  Future<void> exitPip(int playerId) async {
    // PiP not supported on Windows
  }

  @override
  Future<bool> isPipSupported() async => false; // PiP not supported on Windows

  @override
  Future<PlatformCapabilities> getPlatformCapabilities() async =>
      // Windows platform capabilities (placeholder - native implementation needed)
      const PlatformCapabilities(
        supportsPictureInPicture: false, // Not implemented yet
        supportsFullscreen: false, // Not implemented yet
        supportsBackgroundPlayback: false, // Not implemented yet
        supportsCasting: false, // Miracast could be supported in future
        supportsAirPlay: false, // AirPlay is iOS/macOS only
        supportsChromecast: false, // Android only
        supportsRemotePlayback: false, // Web only
        supportsQualitySelection: false, // Not implemented yet
        supportsPlaybackSpeedControl: true, // Media Foundation supports this
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
        platformName: 'Windows',
        nativePlayerType: 'Media Foundation (placeholder)',
      );

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) =>
      const Text('Windows video view placeholder');
}
