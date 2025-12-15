import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// The Android implementation of [ProVideoPlayerPlatform].
///
/// This class uses ExoPlayer for video playback on Android.
class ProVideoPlayerAndroid extends MethodChannelBase {
  /// Constructs a ProVideoPlayerAndroid.
  ProVideoPlayerAndroid() : super('pro_video_player_android');

  /// Registers this class as the default instance of [ProVideoPlayerPlatform].
  static void registerWith() {
    ProVideoPlayerPlatform.instance = ProVideoPlayerAndroid();
  }

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) =>
      // Use PlatformViewLink with Hybrid Composition to avoid race condition crashes
      // in Flutter's Virtual Display platform view implementation.
      // See: https://github.com/flutter/flutter/issues/103630
      PlatformViewLink(
        viewType: 'com.example.pro_video_player_android/video_view',
        surfaceFactory: (context, controller) => AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        ),
        onCreatePlatformView: (params) {
          final controller = PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'com.example.pro_video_player_android/video_view',
            layoutDirection: TextDirection.ltr,
            creationParams: {'playerId': playerId, 'controlsMode': controlsMode.name},
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged(true),
          )..addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
          unawaited(controller.create());
          return controller;
        },
      );
}
