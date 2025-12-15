import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Mock platform implementation for testing.
class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

/// Sets up all fallback values for mocktail.
///
/// This should be called once in setUpAll() in each test file.
void registerFallbackValues() {
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

/// Test fixture that manages controller, mock platform, and event stream lifecycle.
///
/// This class ensures proper resource management by closing the event stream
/// when the fixture is disposed.
///
/// Example usage:
/// ```dart
/// final fixture = TestControllerFixture();
/// await fixture.initialize();
/// // ... test code ...
/// await fixture.dispose();
/// ```
class TestControllerFixture {
  late final ProVideoPlayerController controller;
  late final MockProVideoPlayerPlatform mockPlatform;
  late final StreamController<VideoPlayerEvent> _eventController;

  /// Whether the fixture has been set up.
  bool _isSetUp = false;

  /// Sets up the test fixture with mocked platform and event stream.
  void setUp() {
    if (_isSetUp) return;

    mockPlatform = MockProVideoPlayerPlatform();
    _eventController = StreamController<VideoPlayerEvent>.broadcast();

    ProVideoPlayerPlatform.instance = mockPlatform;
    when(() => mockPlatform.events(any())).thenAnswer((_) => _eventController.stream);

    controller = ProVideoPlayerController();
    _isSetUp = true;
  }

  /// Initializes the controller with standard mocking setup.
  ///
  /// This handles the common pattern of:
  /// - Mocking platform.create()
  /// - Waiting for initialization
  /// - Returning the player ID
  Future<void> initialize({
    VideoSource source = const VideoSource.network('https://example.com/video.mp4'),
    VideoPlayerOptions options = const VideoPlayerOptions(),
    int playerId = 1,
  }) async {
    if (!_isSetUp) setUp();

    when(
      () => mockPlatform.create(
        source: any(named: 'source'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => playerId);

    await controller.initialize(source: source, options: options);
  }

  /// Sends an event through the event stream.
  void sendEvent(VideoPlayerEvent event) {
    _eventController.add(event);
  }

  /// Cleans up test resources.
  ///
  /// Disposes the controller and closes the event stream.
  Future<void> dispose() async {
    if (!_isSetUp) return;

    await _eventController.close();
    if (!controller.isDisposed) {
      when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
      await controller.dispose();
    }
    _isSetUp = false;
  }
}
