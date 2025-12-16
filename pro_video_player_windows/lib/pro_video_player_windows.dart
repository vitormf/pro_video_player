// ignore_for_file: deprecated_member_use

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
      PlatformCapabilities.desktop(platformName: 'Windows', nativePlayerType: 'Media Foundation (placeholder)');

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) =>
      const Text('Windows video view placeholder');
}
