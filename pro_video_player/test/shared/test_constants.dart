/// Test constants for consistent timing and test data.
///
/// This file eliminates magic numbers and provides self-documenting
/// constants for common test scenarios.
library;

/// Timing constants for async operations in tests.
///
/// Using named constants instead of magic numbers makes tests more
/// maintainable and self-documenting.
///
/// Example:
/// ```dart
/// // ❌ BAD: Magic number, unclear why 50ms
/// await Future<void>.delayed(const Duration(milliseconds: 50));
///
/// // ✅ GOOD: Self-documenting, explains purpose
/// await Future<void>.delayed(TestDelays.eventPropagation);
/// ```
class TestDelays {
  TestDelays._();

  /// Wait for event stream to process and notify listeners.
  ///
  /// Use after emitting an event to the controller's event stream.
  /// This gives time for the event to:
  /// 1. Travel through the stream
  /// 2. Be processed by event handlers
  /// 3. Trigger notifyListeners() calls
  /// 4. Update widget state
  ///
  /// Example:
  /// ```dart
  /// eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
  /// await Future<void>.delayed(TestDelays.eventPropagation);
  /// expect(controller.value.playbackState, PlaybackState.playing);
  /// ```
  static const eventPropagation = Duration(milliseconds: 50);

  /// Wait for async platform calls during controller initialization.
  ///
  /// Use after calling `controller.initialize()` when you need to verify
  /// async state that's set during initialization (like PiP availability,
  /// background playback support, etc.).
  ///
  /// Example:
  /// ```dart
  /// await controller.initialize(source: VideoSource.network('...'));
  /// await Future<void>.delayed(TestDelays.controllerInitialization);
  /// expect(controller.value.isInitialized, isTrue);
  /// ```
  static const controllerInitialization = Duration(milliseconds: 150);

  /// Wait for state changes to propagate through notifiers.
  ///
  /// Use when a state change needs time to cascade through multiple
  /// layers (e.g., VideoControlsController → UI state → widget rebuild).
  ///
  /// Example:
  /// ```dart
  /// controlsController.togglePlayPause();
  /// await Future<void>.delayed(TestDelays.stateUpdate);
  /// expect(controlsController.isPlaying, isTrue);
  /// ```
  static const stateUpdate = Duration(milliseconds: 100);

  /// Wait for timer callbacks to execute.
  ///
  /// Use when testing timers with specific durations. Add this delay
  /// AFTER the timer duration to ensure the callback has executed.
  ///
  /// Example:
  /// ```dart
  /// state.startHideTimer(const Duration(milliseconds: 100), callback);
  /// await Future<void>.delayed(const Duration(milliseconds: 100) + TestDelays.timerCallback);
  /// expect(callbackExecuted, isTrue);
  /// ```
  static const timerCallback = Duration(milliseconds: 50);

  /// Wait for animations to complete.
  ///
  /// Use when you need a brief animation to finish before making assertions.
  /// This is shorter than pumpAndSettle() and useful when you know the
  /// animation duration.
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byIcon(Icons.settings));
  /// await tester.pump(TestDelays.animation);
  /// expect(find.text('Settings'), findsOneWidget);
  /// ```
  static const animation = Duration(milliseconds: 300);

  /// Wait for debounced operations.
  ///
  /// Use when testing operations that use debouncing (e.g., search input,
  /// rapid button clicks, seek bar dragging).
  ///
  /// Example:
  /// ```dart
  /// await tester.enterText(find.byType(TextField), 'search query');
  /// await Future<void>.delayed(TestDelays.debounce);
  /// verify(() => mockSearch.search('search query')).called(1);
  /// ```
  static const debounce = Duration(milliseconds: 500);

  /// Wait for PlaybackManager's internal play() timer to complete.
  ///
  /// The PlaybackManager.play() method creates a 2-second timeout timer.
  /// Tests must wait for this timer to complete before tearDown to avoid
  /// "Pending timers" errors.
  ///
  /// Example:
  /// ```dart
  /// await controller.play();
  /// verify(() => mockPlatform.play(1)).called(1);
  /// await tester.pump(TestDelays.playbackManagerTimer); // Wait for internal timer
  /// ```
  static const playbackManagerTimer = Duration(seconds: 3);

  /// Wait for double-tap gesture to complete.
  ///
  /// GestureDetector has a 300ms window for double-taps. This constant includes
  /// a small buffer (50ms) to ensure the gesture fully completes before assertions.
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byType(VideoPlayer));
  /// await tester.pump(TestDelays.doubleTap);
  /// // Now safe to verify single-tap wasn't triggered
  /// ```
  static const doubleTap = Duration(milliseconds: 350);

  /// Duration for drag gestures in tests.
  ///
  /// Use with tester.timedDragFrom() to simulate realistic drag speeds.
  ///
  /// Example:
  /// ```dart
  /// await tester.timedDragFrom(
  ///   start,
  ///   const Offset(100, 0),
  ///   TestDelays.dragGesture,
  /// );
  /// ```
  static const dragGesture = Duration(milliseconds: 200);

  /// Single animation frame delay.
  ///
  /// Use when you need to wait for a single frame to process
  /// (approximately 60fps = 16.7ms, rounded to 20ms for safety).
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byIcon(Icons.play));
  /// await tester.pump(TestDelays.singleFrame);
  /// ```
  static const singleFrame = Duration(milliseconds: 20);

  /// Wait for longer async operations to complete.
  ///
  /// Use when testing operations that take longer than standard delays
  /// (e.g., network timeouts, complex state updates).
  ///
  /// Example:
  /// ```dart
  /// await tester.pump(TestDelays.longOperation);
  /// expect(controller.value.isLoading, isFalse);
  /// ```
  static const longOperation = Duration(milliseconds: 600);
}

/// Size constants for widget testing.
///
/// Provides standard widget sizes for responsive testing.
class TestSizes {
  TestSizes._();

  /// Default Flutter test surface size.
  ///
  /// This is the size used by `tester.pumpWidget()` when no size is specified.
  static const defaultWidth = 800.0;
  static const defaultHeight = 600.0;

  /// Compact mode threshold.
  ///
  /// Below this size, compact controls should be shown.
  /// Above this size, full controls should be shown.
  static const compactWidth = 300.0;
  static const compactHeight = 200.0;

  /// Mobile phone sizes (portrait).
  static const mobileWidth = 375.0;
  static const mobileHeight = 667.0;

  /// Tablet sizes (landscape).
  static const tabletWidth = 1024.0;
  static const tabletHeight = 768.0;

  /// Desktop sizes.
  static const desktopWidth = 1920.0;
  static const desktopHeight = 1080.0;
}

/// Test video URLs and paths.
///
/// Consolidates all test media sources in one place.
class TestMedia {
  TestMedia._();

  /// Standard test network video URL.
  static const networkUrl = 'https://example.com/video.mp4';

  /// Test HLS stream URL.
  static const hlsUrl = 'https://example.com/stream.m3u8';

  /// Test DASH manifest URL.
  static const dashUrl = 'https://example.com/manifest.mpd';

  /// Test asset path.
  static const assetPath = 'assets/video.mp4';

  /// Test file path.
  static const filePath = '/path/to/video.mp4';

  /// Test subtitle URL.
  static const subtitleUrl = 'https://example.com/subtitles.srt';
}

/// Test video metadata values.
///
/// Standard metadata for test videos.
class TestMetadata {
  TestMetadata._();

  /// Default test video duration.
  static const duration = Duration(minutes: 5);

  /// Default test video width.
  static const videoWidth = 1920;

  /// Default test video height.
  static const videoHeight = 1080;

  /// Default test video aspect ratio.
  static const aspectRatio = 16.0 / 9.0;
}

/// Test player IDs.
///
/// Standard player ID values for mocking.
class TestPlayerIds {
  TestPlayerIds._();

  /// Default test player ID returned by platform.create().
  static const defaultPlayerId = 1;

  /// Second player ID for multi-player tests.
  static const secondPlayerId = 2;
}
