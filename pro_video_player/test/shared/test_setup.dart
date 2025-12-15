import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'mocks.dart';

/// Registers all fallback values needed for mocktail.
///
/// Call this in `setUpAll()` before any tests that use mocktail with
/// video player types.
///
/// Example:
/// ```dart
/// setUpAll(() {
///   registerVideoPlayerFallbackValues();
/// });
/// ```
void registerVideoPlayerFallbackValues() {
  registerFallbackValue(const VideoSource.network('https://example.com'));
  registerFallbackValue(const VideoPlayerOptions());
  registerFallbackValue(const PipOptions());
  registerFallbackValue(const SubtitleTrack(id: 'test', label: 'Test'));
  registerFallbackValue(const AudioTrack(id: 'test', label: 'Test'));
  registerFallbackValue(
    const ExternalSubtitleTrack(
      id: 'ext-0',
      label: 'Test',
      path: 'https://example.com/sub.srt',
      sourceType: 'network',
      format: SubtitleFormat.srt,
    ),
  );
  registerFallbackValue(const SubtitleSource.network('https://example.com/sub.srt'));
  registerFallbackValue(VideoQualityTrack.auto);
  registerFallbackValue(Duration.zero);
  registerFallbackValue(VideoScalingMode.fit);
  registerFallbackValue(MediaMetadata.empty);
  registerFallbackValue(ControlsMode.none);
  registerFallbackValue(FullscreenOrientation.all);
  registerFallbackValue(const CastDevice(id: 'test', name: 'Test Device', type: CastDeviceType.airPlay));
}

/// Test fixture for video player tests that use a mock platform.
///
/// Provides common setup and teardown logic for platform mock tests.
///
/// Example:
/// ```dart
/// late VideoPlayerTestFixture fixture;
///
/// setUp(() async {
///   fixture = VideoPlayerTestFixture()..setUp();
///   await fixture.initializeController();
/// });
///
/// tearDown(() => fixture.tearDown());
/// ```
class VideoPlayerTestFixture {
  late MockProVideoPlayerPlatform mockPlatform;
  late StreamController<VideoPlayerEvent> eventController;
  ProVideoPlayerController? _controller;

  /// The video player controller. Only available after [initializeController].
  ProVideoPlayerController get controller {
    if (_controller == null) {
      throw StateError('Controller not initialized. Call initializeController() first.');
    }
    return _controller!;
  }

  /// Whether [initializeController] was called.
  bool get hasController => _controller != null;

  /// Sets up the mock platform with default stubs.
  ///
  /// Call this in your test's `setUp()` method.
  void setUp() {
    mockPlatform = MockProVideoPlayerPlatform();
    eventController = StreamController<VideoPlayerEvent>.broadcast();
    ProVideoPlayerPlatform.instance = mockPlatform;

    _setupDefaultStubs();
  }

  /// Tears down the fixture and cleans up resources.
  ///
  /// Call this in your test's `tearDown()` method.
  Future<void> tearDown() async {
    await eventController.close();
    if (_controller != null && !_controller!.isDisposed) {
      when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
      await _controller!.dispose();
    }
    _controller = null;
    ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
  }

  /// Creates and initializes a controller with the mock platform.
  ///
  /// [source] defaults to a network video source.
  /// [options] defaults to empty options.
  Future<ProVideoPlayerController> initializeController({
    VideoSource source = const VideoSource.network('https://example.com/video.mp4'),
    VideoPlayerOptions options = const VideoPlayerOptions(),
  }) async {
    _controller = ProVideoPlayerController();
    await _controller!.initialize(source: source, options: options);
    return _controller!;
  }

  /// Emits a video player event to the mock event stream.
  void emitEvent(VideoPlayerEvent event) {
    eventController.add(event);
  }

  /// Emits a playback state changed event.
  void emitPlaybackState(PlaybackState state) {
    emitEvent(PlaybackStateChangedEvent(state));
  }

  /// Emits a position changed event.
  void emitPosition(Duration position) {
    emitEvent(PositionChangedEvent(position));
  }

  /// Emits a duration changed event.
  void emitDuration(Duration duration) {
    emitEvent(DurationChangedEvent(duration));
  }

  /// Emits a video size changed event.
  void emitVideoSize(int width, int height) {
    emitEvent(VideoSizeChangedEvent(width: width, height: height));
  }

  void _setupDefaultStubs() {
    // Creation and lifecycle
    when(
      () => mockPlatform.create(
        source: any(named: 'source'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => 1);
    when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);
    when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});

    // Playback controls
    when(() => mockPlatform.play(any())).thenAnswer((_) async {});
    when(() => mockPlatform.pause(any())).thenAnswer((_) async {});
    when(() => mockPlatform.stop(any())).thenAnswer((_) async {});
    when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

    // Settings
    when(() => mockPlatform.setPlaybackSpeed(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setVolume(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setLooping(any(), looping: any(named: 'looping'))).thenAnswer((_) async {});
    when(() => mockPlatform.setScalingMode(any(), any())).thenAnswer((_) async {});

    // Track selection
    when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setAudioTrack(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setVideoQuality(any(), any())).thenAnswer((_) async => true);

    // Features
    when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
    when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});
    when(() => mockPlatform.enterPip(any(), options: any(named: 'options'))).thenAnswer((_) async => true);
    when(() => mockPlatform.exitPip(any())).thenAnswer((_) async {});
    when(() => mockPlatform.setPipActions(any(), any())).thenAnswer((_) async {});

    // Capability queries
    when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => false);
    when(() => mockPlatform.isBackgroundPlaybackSupported()).thenAnswer((_) async => false);
    when(() => mockPlatform.isCastingSupported()).thenAnswer((_) async => false);

    // Background playback
    when(() => mockPlatform.setBackgroundPlayback(any(), enabled: any(named: 'enabled'))).thenAnswer((_) async => true);
    when(() => mockPlatform.setMediaMetadata(any(), any())).thenAnswer((_) async {});

    // Casting
    when(() => mockPlatform.startCasting(any(), device: any(named: 'device'))).thenAnswer((_) async => true);
    when(() => mockPlatform.stopCasting(any())).thenAnswer((_) async => true);

    // External subtitles
    when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer(
      (_) async => const ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'Test',
        path: 'https://example.com/sub.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
      ),
    );
    when(() => mockPlatform.removeExternalSubtitle(any(), any())).thenAnswer((_) async => true);

    // View building
    when(
      () => mockPlatform.buildView(any(), controlsMode: any(named: 'controlsMode')),
    ).thenReturn(const SizedBox(key: Key('video_view')));
  }

  /// Sets up stubs for a fully-featured player (PiP, background playback, casting).
  void setupFullFeaturedPlayer() {
    when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);
    when(() => mockPlatform.isBackgroundPlaybackSupported()).thenAnswer((_) async => true);
    when(() => mockPlatform.isCastingSupported()).thenAnswer((_) async => true);
  }
}

/// Test constants for video player tests.
class VideoPlayerTestConstants {
  VideoPlayerTestConstants._();

  /// A test network video URL.
  static const testNetworkUrl = 'https://example.com/video.mp4';

  /// A test HLS stream URL.
  static const testHlsUrl = 'https://example.com/stream.m3u8';

  /// A test asset path.
  static const testAssetPath = 'assets/video.mp4';

  /// A test file path.
  static const testFilePath = '/path/to/video.mp4';

  /// Default test video duration.
  static const testDuration = Duration(minutes: 5);

  /// Default test video width.
  static const testVideoWidth = 1920;

  /// Default test video height.
  static const testVideoHeight = 1080;
}
