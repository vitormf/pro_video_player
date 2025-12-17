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
  Future<PlatformCapabilities> getPlatformCapabilities() async =>
      // Linux platform capabilities (placeholder - native implementation needed)
      PlatformCapabilities.desktop(platformName: 'Linux', nativePlayerType: 'GStreamer (placeholder)');

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) =>
      const Text('Linux video view placeholder');
}
