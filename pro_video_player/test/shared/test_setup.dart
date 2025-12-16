import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'mocks.dart';
import 'test_constants.dart';

/// Registers all fallback values needed for mocktail.
///
/// This registers fallback values for all video player types that may be used
/// in any() matchers. Call this in `setUpAll()` before any tests that use
/// mocktail with video player types.
///
/// Example:
/// ```dart
/// setUpAll(() {
///   registerVideoPlayerFallbackValues();
/// });
/// ```
void registerVideoPlayerFallbackValues() {
  // Core types
  registerFallbackValue(const VideoSource.network('https://example.com'));
  registerFallbackValue(const VideoPlayerOptions());
  registerFallbackValue(const PipOptions());
  registerFallbackValue(Duration.zero);

  // Tracks and subtitles
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

  // Quality and playback
  registerFallbackValue(VideoQualityTrack.auto);
  registerFallbackValue(VideoScalingMode.fit);

  // Metadata and controls
  registerFallbackValue(MediaMetadata.empty);
  registerFallbackValue(ControlsMode.none);
  registerFallbackValue(FullscreenOrientation.all);

  // Casting
  registerFallbackValue(const CastDevice(id: 'test', name: 'Test Device', type: CastDeviceType.airPlay));

  // Additional types used in manager tests
  registerFallbackValue(VideoPlayerError.fromCode(message: 'Unknown error', code: 'unknown'));
  registerFallbackValue(PlaybackState.paused);
  registerFallbackValue(VideoMetadata.empty);
  registerFallbackValue(const <Chapter>[]);
  registerFallbackValue(const <SubtitleTrack>[]);
}

/// Test fixture for video player tests that use a mock platform.
///
/// Provides common setup and teardown logic for platform mock tests.
///
/// This fixture creates an uninitialized controller by default, which can be
/// used immediately in tests. Call [initializeController] to initialize it
/// with a video source.
///
/// Example for controller tests:
/// ```dart
/// late VideoPlayerTestFixture fixture;
///
/// setUp(() {
///   fixture = VideoPlayerTestFixture()..setUp();
///   // fixture.controller is available but uninitialized
/// });
///
/// test('some test', () async {
///   await fixture.initializeController(); // Initialize with default source
///   expect(fixture.controller.isInitialized, isTrue);
/// });
///
/// tearDown(() => fixture.tearDown());
/// ```
///
/// Example for widget tests with renderWidget:
/// ```dart
/// late VideoPlayerTestFixture fixture;
///
/// setUp(() async {
///   fixture = VideoPlayerTestFixture()..setUp();
///   await fixture.initializeController();
/// });
///
/// testWidgets('some widget test', (tester) async {
///   await fixture.renderWidget(tester, MyWidget(controller: fixture.controller));
///   expect(find.byType(MyWidget), findsOneWidget);
/// });
/// ```
class VideoPlayerTestFixture {
  late MockProVideoPlayerPlatform mockPlatform;
  late StreamController<VideoPlayerEvent> eventController;
  late ProVideoPlayerController controller;

  /// Sets up the mock platform with default stubs and creates an uninitialized controller.
  ///
  /// Call this in your test's `setUp()` method.
  void setUp() {
    mockPlatform = MockProVideoPlayerPlatform();
    eventController = StreamController<VideoPlayerEvent>.broadcast();
    ProVideoPlayerPlatform.instance = mockPlatform;
    controller = ProVideoPlayerController();

    _setupDefaultStubs();
  }

  /// Tears down the fixture and cleans up resources.
  ///
  /// Call this in your test's `tearDown()` method.
  Future<void> tearDown() async {
    await eventController.close();
    if (!controller.isDisposed) {
      when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
      await controller.dispose();
    }
    ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
  }

  /// Initializes the controller with a video source.
  ///
  /// [source] defaults to a network video source.
  /// [options] defaults to empty options.
  ///
  /// Returns the same controller instance (for convenience).
  Future<ProVideoPlayerController> initializeController({
    VideoSource source = const VideoSource.network('https://example.com/video.mp4'),
    VideoPlayerOptions options = const VideoPlayerOptions(),
  }) async {
    await controller.initialize(source: source, options: options);
    return controller;
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

  /// Emits an error event.
  void emitError(String message, {String? code}) {
    emitEvent(ErrorEvent(message, code: code));
  }

  /// Emits buffering started event.
  void emitBufferingStarted() {
    emitEvent(const BufferingStartedEvent());
  }

  /// Emits buffering ended event.
  void emitBufferingEnded() {
    emitEvent(const BufferingEndedEvent());
  }

  /// Emits volume changed event.
  void emitVolume(double volume) {
    emitEvent(VolumeChangedEvent(volume));
  }

  /// Emits playback speed changed event.
  void emitPlaybackSpeed(double speed) {
    emitEvent(PlaybackSpeedChangedEvent(speed));
  }

  /// Emits PiP state changed event.
  void emitPipState({required bool isActive}) {
    emitEvent(PipStateChangedEvent(isActive: isActive));
  }

  /// Emits fullscreen state changed event.
  void emitFullscreenState({required bool isFullscreen}) {
    emitEvent(FullscreenStateChangedEvent(isFullscreen: isFullscreen));
  }

  /// Builds a test widget wrapped in MaterialApp and Scaffold.
  ///
  /// This is the standard wrapper for widget tests.
  ///
  /// Example:
  /// ```dart
  /// final widget = fixture.buildTestWidget(VideoPlayerControls(controller: controller));
  /// await tester.pumpWidget(widget);
  /// ```
  Widget buildTestWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

  /// Builds a test widget with specific size constraints.
  ///
  /// Example:
  /// ```dart
  /// final widget = fixture.buildSizedTestWidget(
  ///   VideoPlayerControls(controller: controller),
  ///   width: 400,
  ///   height: 300,
  /// );
  /// await tester.pumpWidget(widget);
  /// ```
  Widget buildSizedTestWidget(Widget child, {double width = 800, double height = 600}) => MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, height: height, child: child),
    ),
  );

  /// Pumps a widget and renders one frame.
  ///
  /// This is the standard pattern for widget testing: pumpWidget + pump.
  /// Use this for most widget rendering scenarios.
  ///
  /// Example:
  /// ```dart
  /// await fixture.renderWidget(tester, VideoPlayerControls(controller: controller));
  /// expect(find.byType(VideoPlayerControls), findsOneWidget);
  /// ```
  Future<void> renderWidget(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(buildTestWidget(child));
    await tester.pump();
  }

  /// Pumps a sized widget and renders one frame.
  ///
  /// Example:
  /// ```dart
  /// await fixture.renderSizedWidget(tester, MyWidget(), width: 400, height: 300);
  /// ```
  Future<void> renderSizedWidget(WidgetTester tester, Widget child, {double width = 800, double height = 600}) async {
    await tester.pumpWidget(buildSizedTestWidget(child, width: width, height: height));
    await tester.pump();
  }

  /// Taps a widget and pumps one frame.
  ///
  /// This is the standard pattern for tap testing: tap + pump.
  ///
  /// Example:
  /// ```dart
  /// await fixture.tap(tester, find.byIcon(Icons.play_arrow));
  /// verify(() => mockPlatform.play(1)).called(1);
  /// ```
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  /// Taps a widget and waits for animations to settle.
  ///
  /// Use this for interactions that trigger animations (e.g., opening
  /// bottom sheets, expanding menus). Do NOT use with modal bottom sheets
  /// as pumpAndSettle() will hang.
  ///
  /// Example:
  /// ```dart
  /// await fixture.tapAndSettle(tester, find.byIcon(Icons.expand_more));
  /// expect(find.text('Expanded Content'), findsOneWidget);
  /// ```
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Waits for animations to complete with a timeout.
  ///
  /// Safer alternative to pumpAndSettle() that prevents hanging.
  /// Use when you need to wait for animations but want protection
  /// against infinite loops.
  ///
  /// Example:
  /// ```dart
  /// await fixture.waitForAnimation(tester);
  /// ```
  Future<void> waitForAnimation(WidgetTester tester, {Duration timeout = const Duration(seconds: 5)}) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, timeout);
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
    when(() => mockPlatform.setLooping(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setScalingMode(any(), any())).thenAnswer((_) async {});

    // Track selection
    when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setSubtitleOffset(any(), any())).thenAnswer((_) async {});
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

  // ==================== COMMON TEST PATTERNS ====================

  /// Initializes the controller with a default network source.
  ///
  /// This is the most common test setup pattern. Use in group setUp() to
  /// initialize the controller before each test.
  ///
  /// Example:
  /// ```dart
  /// group('some feature tests', () {
  ///   setUp(() async {
  ///     await fixture.initializeWithDefaultSource();
  ///   });
  ///
  ///   test('some test', () async {
  ///     // controller is already initialized
  ///     expect(fixture.controller.isInitialized, isTrue);
  ///   });
  /// });
  /// ```
  Future<void> initializeWithDefaultSource([String url = TestMedia.networkUrl]) async {
    await controller.initialize(source: VideoSource.network(url));
  }

  /// Emits a sequence of events to set up a playing video at a specific position.
  ///
  /// This is a common pattern when testing seek, forward/backward, etc.
  ///
  /// Example:
  /// ```dart
  /// fixture.emitPlayingAt(
  ///   position: Duration(seconds: 30),
  ///   duration: Duration(minutes: 5),
  /// );
  /// // Controller is now at 30s of a 5-minute video
  /// ```
  void emitPlayingAt({required Duration position, Duration duration = TestMetadata.duration}) {
    emitPlaybackState(PlaybackState.playing);
    emitPosition(position);
    emitDuration(duration);
  }

  /// Emits events to set up a paused video at a specific position.
  void emitPausedAt({required Duration position, Duration duration = TestMetadata.duration}) {
    emitPlaybackState(PlaybackState.paused);
    emitPosition(position);
    emitDuration(duration);
  }

  /// Waits for events to be processed.
  ///
  /// After emitting events, call this to allow the controller to process them.
  /// Equivalent to `await Future<void>.delayed(Duration.zero)`.
  Future<void> waitForEvents() async {
    await Future<void>.delayed(Duration.zero);
  }

  // ==================== VERIFICATION HELPERS ====================

  /// Verifies that play() was called on the platform with playerId 1.
  void verifyPlay({int times = 1}) {
    verify(() => mockPlatform.play(1)).called(times);
  }

  /// Verifies that pause() was called on the platform with playerId 1.
  void verifyPause({int times = 1}) {
    verify(() => mockPlatform.pause(1)).called(times);
  }

  /// Verifies that stop() was called on the platform with playerId 1.
  void verifyStop({int times = 1}) {
    verify(() => mockPlatform.stop(1)).called(times);
  }

  /// Verifies that seekTo() was called with specific position.
  void verifySeekTo(Duration position, {int times = 1}) {
    verify(() => mockPlatform.seekTo(1, position)).called(times);
  }

  /// Verifies that setVolume() was called with specific volume.
  void verifySetVolume(double volume, {int times = 1}) {
    verify(() => mockPlatform.setVolume(1, volume)).called(times);
  }

  /// Verifies that setPlaybackSpeed() was called with specific speed.
  void verifySetPlaybackSpeed(double speed, {int times = 1}) {
    verify(() => mockPlatform.setPlaybackSpeed(1, speed)).called(times);
  }

  /// Verifies that enterFullscreen() was called.
  void verifyEnterFullscreen({int times = 1}) {
    verify(() => mockPlatform.enterFullscreen(1)).called(times);
  }

  /// Verifies that exitFullscreen() was called.
  void verifyExitFullscreen({int times = 1}) {
    verify(() => mockPlatform.exitFullscreen(1)).called(times);
  }

  /// Verifies that enterPip() was called.
  void verifyEnterPip({int times = 1}) {
    verify(() => mockPlatform.enterPip(1, options: any(named: 'options'))).called(times);
  }

  /// Verifies that exitPip() was called.
  void verifyExitPip({int times = 1}) {
    verify(() => mockPlatform.exitPip(1)).called(times);
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
