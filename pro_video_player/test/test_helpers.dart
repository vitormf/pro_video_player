import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Mock platform implementation for testing
class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

/// Registers all fallback values needed for mocktail
void registerFallbackValues() {
  // Register fallback values for mocktail using actual instances
  // since VideoSource is a sealed class
  registerFallbackValue(const VideoSource.network('https://example.com'));
  registerFallbackValue(const VideoPlayerOptions());
  registerFallbackValue(const PipOptions());
  registerFallbackValue(const SubtitleTrack(id: 'test', label: 'Test'));
  registerFallbackValue(const AudioTrack(id: 'test', label: 'Test'));
  registerFallbackValue(Duration.zero);
  registerFallbackValue(VideoScalingMode.fit);
  registerFallbackValue(VideoQualityTrack.auto);
  registerFallbackValue(MediaMetadata.empty);
  registerFallbackValue(const SubtitleSource.network('https://example.com/subs.vtt'));
  registerFallbackValue(FullscreenOrientation.landscapeBoth);
}

/// Test fixture for ProVideoPlayerController tests
class ControllerTestFixture {
  ControllerTestFixture() {
    mockPlatform = MockProVideoPlayerPlatform();
    ProVideoPlayerPlatform.instance = mockPlatform;
    controller = ProVideoPlayerController();
    eventController = StreamController<VideoPlayerEvent>.broadcast();

    when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);
  }

  late MockProVideoPlayerPlatform mockPlatform;
  late ProVideoPlayerController controller;
  late StreamController<VideoPlayerEvent> eventController;

  /// Disposes the fixture
  Future<void> dispose() async {
    await eventController.close();
    if (!controller.isDisposed) {
      when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
      await controller.dispose();
    }
  }
}
