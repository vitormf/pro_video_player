import 'package:flutter/widgets.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// The Linux implementation of [ProVideoPlayerPlatform].
///
/// This class uses GStreamer for video playback on Linux.
class ProVideoPlayerLinux extends PigeonMethodChannelBase {
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
  Future<PlatformInfo> getPlatformInfo() async =>
      const PlatformInfo(platformName: 'Linux', nativePlayerType: 'GStreamer (placeholder)');

  // Platform capabilities - Linux desktop (placeholder - native implementation needed)
  @override
  Future<bool> supportsPictureInPicture() async => false;

  @override
  Future<bool> supportsFullscreen() async => false;

  @override
  Future<bool> supportsBackgroundPlayback() async => false;

  @override
  Future<bool> supportsCasting() async => false;

  @override
  Future<bool> supportsAirPlay() async => false;

  @override
  Future<bool> supportsChromecast() async => false;

  @override
  Future<bool> supportsRemotePlayback() async => false;

  @override
  Future<bool> supportsQualitySelection() async => false;

  @override
  Future<bool> supportsPlaybackSpeedControl() async => true; // GStreamer supports this

  @override
  Future<bool> supportsSubtitles() async => false;

  @override
  Future<bool> supportsExternalSubtitles() async => false;

  @override
  Future<bool> supportsAudioTrackSelection() async => false;

  @override
  Future<bool> supportsChapters() async => false;

  @override
  Future<bool> supportsVideoMetadataExtraction() async => false;

  @override
  Future<bool> supportsNetworkMonitoring() async => false;

  @override
  Future<bool> supportsBandwidthEstimation() async => false;

  @override
  Future<bool> supportsAdaptiveBitrate() async => false;

  @override
  Future<bool> supportsHLS() async => false;

  @override
  Future<bool> supportsDASH() async => false;

  @override
  Future<bool> supportsDeviceVolumeControl() async => false;

  @override
  Future<bool> supportsScreenBrightnessControl() async => false;

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) =>
      const Text('Linux video view placeholder');
}
