import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// The iOS implementation of [ProVideoPlayerPlatform].
///
/// This class uses AVPlayer for video playback on iOS.
class ProVideoPlayerIOS extends MethodChannelBase {
  /// Constructs a ProVideoPlayerIOS.
  ProVideoPlayerIOS() : super('pro_video_player_ios');

  /// Registers this class as the default instance of [ProVideoPlayerPlatform].
  static void registerWith() {
    ProVideoPlayerPlatform.instance = ProVideoPlayerIOS();
  }

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) => UiKitView(
    viewType: 'com.example.pro_video_player_ios/video_view',
    creationParams: {'playerId': playerId, 'controlsMode': controlsMode.name},
    creationParamsCodec: const StandardMessageCodec(),
  );
}
