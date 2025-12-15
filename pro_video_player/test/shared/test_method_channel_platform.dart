import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Test-only implementation of [MethodChannelBase] for testing.
///
/// This class extends [MethodChannelBase] with a hardcoded channel name
/// specifically for testing purposes. It should NOT be used in production code.
class TestMethodChannelPlatform extends MethodChannelBase {
  /// Creates a [TestMethodChannelPlatform].
  TestMethodChannelPlatform() : super('pro_video_player');

  /// Standard message codec for platform view creation params.
  static const _codec = StandardMessageCodec();

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) {
    const viewType = 'com.example.pro_video_player/video_view';

    final creationParams = {'playerId': playerId, 'controlsMode': controlsMode.toJson()};

    // Use a ValueKey that includes controlsMode to force recreation when mode changes
    final viewKey = ValueKey('video_view_${playerId}_${controlsMode.name}');

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidView(
        key: viewKey,
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: _codec,
      ),
      TargetPlatform.iOS => UiKitView(
        key: viewKey,
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: _codec,
      ),
      _ => const Center(child: Text('Platform not supported')),
    };
  }
}
