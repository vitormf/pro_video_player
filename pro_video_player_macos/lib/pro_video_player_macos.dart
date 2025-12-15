import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// The macOS implementation of [ProVideoPlayerPlatform].
///
/// This class uses AVPlayer for video playback on macOS.
class ProVideoPlayerMacOS extends MethodChannelBase {
  /// Constructs a ProVideoPlayerMacOS.
  ProVideoPlayerMacOS() : super('pro_video_player_macos');

  /// Registers this class as the default instance of [ProVideoPlayerPlatform].
  static void registerWith() {
    ProVideoPlayerPlatform.instance = ProVideoPlayerMacOS();
  }

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) => AppKitView(
    viewType: 'com.example.pro_video_player_macos/video_view',
    creationParams: {'playerId': playerId, 'controlsMode': controlsMode.name},
    creationParamsCodec: const StandardMessageCodec(),
  );
}
