import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/e2e_helpers.dart';
import '../helpers/e2e_navigation.dart' as nav;
import '../helpers/e2e_platform.dart';
import 'e2e_constants.dart';
import 'e2e_viewport.dart';

/// E2E test fixture providing common setup and utilities for integration tests.
///
/// This fixture eliminates boilerplate by providing:
/// - Viewport setup based on platform
/// - Section timing and logging
/// - Error suppression for overflow errors
/// - Convenient access to all E2E helper functions
///
/// Usage:
/// ```dart
/// testWidgets('My E2E test', (tester) async {
///   final fixture = E2ETestFixture();
///   await fixture.setUp(tester);
///
///   fixture.startSection('Test setup');
///   // ... test code ...
///   fixture.endSection('Test setup');
///
///   fixture.tearDown();
/// });
/// ```
class E2ETestFixture {
  /// Creates an E2E test fixture.
  ///
  /// Parameters:
  /// - [suppressOverflowErrors]: Whether to suppress overflow errors in tests (default: true)
  /// - [setViewport]: Whether to automatically set viewport size (default: true)
  /// - [customViewportSize]: Custom viewport size (overrides platform default)
  /// - [enableDetailedLogging]: Whether to log detailed platform/viewport info (default: false)
  E2ETestFixture({
    this.suppressOverflowErrors = true,
    this.setViewport = true,
    this.customViewportSize,
    this.enableDetailedLogging = false,
  });

  /// Whether to suppress overflow errors in tests.
  final bool suppressOverflowErrors;

  /// Whether to automatically set viewport size.
  final bool setViewport;

  /// Custom viewport size (overrides platform default).
  final Size? customViewportSize;

  /// Whether to log detailed platform/viewport info.
  final bool enableDetailedLogging;

  // Internal state
  Stopwatch? _sectionStopwatch;
  late Stopwatch _totalStopwatch;
  FlutterExceptionHandler? _originalOnError;
  Size? _actualViewportSize;

  /// The actual viewport size that was set during setUp.
  Size? get viewportSize => _actualViewportSize;

  /// Total elapsed time since setUp was called.
  Duration get totalElapsed => _totalStopwatch.elapsed;

  // ==========================================================================
  // Setup & Teardown
  // ==========================================================================

  /// Sets up the test fixture.
  ///
  /// Call this at the beginning of your test, after `pumpWidget()`.
  ///
  /// Example:
  /// ```dart
  /// testWidgets('My test', (tester) async {
  ///   final fixture = E2ETestFixture();
  ///   await tester.pumpWidget(MyApp());
  ///   await fixture.setUp(tester);
  ///   // ... test code ...
  /// });
  /// ```
  Future<void> setUp(WidgetTester tester) async {
    // Start total timer
    _totalStopwatch = Stopwatch()..start();

    // Set up error suppression
    if (suppressOverflowErrors) {
      _setupErrorSuppression();
    }

    // Set up viewport
    if (setViewport) {
      await _setupViewport(tester);
    }

    // Log platform info if requested
    if (enableDetailedLogging) {
      logPlatformInfo();
      if (_actualViewportSize != null) {
        logViewportInfo(tester);
      }
    }
  }

  /// Tears down the test fixture.
  ///
  /// Call this at the end of your test to clean up resources.
  ///
  /// Example:
  /// ```dart
  /// testWidgets('My test', (tester) async {
  ///   final fixture = E2ETestFixture();
  ///   await fixture.setUp(tester);
  ///   // ... test code ...
  ///   fixture.tearDown(); // Clean up
  /// });
  /// ```
  void tearDown() {
    // Stop timers
    _totalStopwatch.stop();
    _sectionStopwatch?.stop();

    // Restore error handler
    if (_originalOnError != null) {
      FlutterError.onError = _originalOnError;
    }
  }

  void _setupErrorSuppression() {
    _originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final isOverflowError = details.toString().contains('overflowed');
      if (!isOverflowError) {
        _originalOnError?.call(details);
      }
    };
  }

  Future<void> _setupViewport(WidgetTester tester) async {
    if (customViewportSize != null) {
      // Use custom size
      await tester.setViewport(customViewportSize!);
      _actualViewportSize = customViewportSize;
    } else {
      // Use platform default
      _actualViewportSize = await tester.setDefaultViewportForPlatform();
    }
  }

  // ==========================================================================
  // Section Timing
  // ==========================================================================

  /// Starts timing a test section.
  ///
  /// Call this at the beginning of a logical test section to start timing.
  /// Follow with [endSection] to log the elapsed time.
  ///
  /// Example:
  /// ```dart
  /// fixture.startSection('Video loading');
  /// // ... video loading code ...
  /// fixture.endSection('Video loading');
  /// // Output: <<< END: Video loading (2.5s) [Total: 5.2s]
  /// ```
  void startSection(String name) {
    _sectionStopwatch = Stopwatch()..start();
    debugPrint('\n>>> START: $name');
  }

  /// Ends timing a test section and logs the elapsed time.
  ///
  /// Must be called after [startSection].
  ///
  /// Example:
  /// ```dart
  /// fixture.startSection('Navigation');
  /// await navigateToDemo(tester, cardKey, title);
  /// fixture.endSection('Navigation');
  /// ```
  void endSection(String name) {
    _sectionStopwatch?.stop();
    final elapsed = _sectionStopwatch?.elapsedMilliseconds ?? 0;
    final totalElapsed = _totalStopwatch.elapsedMilliseconds;

    debugPrint(
      '<<< END: $name (${elapsed}ms / ${(elapsed / 1000).toStringAsFixed(1)}s) '
      '[Total: ${(totalElapsed / 1000).toStringAsFixed(1)}s]',
    );
  }

  /// Times a section automatically using a callback.
  ///
  /// Convenience method that calls [startSection] before the callback and
  /// [endSection] after.
  ///
  /// Example:
  /// ```dart
  /// await fixture.timedSection('Video loading', () async {
  ///   await waitForVideoInitialization(tester, durationFinder);
  /// });
  /// ```
  Future<void> timedSection(String name, Future<void> Function() callback) async {
    startSection(name);
    try {
      await callback();
    } finally {
      endSection(name);
    }
  }

  // ==========================================================================
  // Video State Logging
  // ==========================================================================

  /// Logs current video state for debugging.
  ///
  /// Convenience wrapper around the global [logVideoState] function.
  ///
  /// Example:
  /// ```dart
  /// fixture.logVideoState(
  ///   positionStr: '02:30',
  ///   durationStr: '10:00',
  ///   state: 'playing',
  /// );
  /// ```
  void logVideoState({String? positionStr, String? durationStr, String? state, Map<String, dynamic>? extra}) {
    // Delegate to global helper
    logVideoState(positionStr: positionStr, durationStr: durationStr, state: state, extra: extra);
  }

  // ==========================================================================
  // Platform & Viewport Info
  // ==========================================================================

  /// Returns true if current viewport uses master-detail layout.
  bool get isMasterDetailLayout => _actualViewportSize != null && _actualViewportSize!.width >= 600;

  /// Returns true if current viewport uses single-pane layout.
  bool get isSinglePaneLayout => !isMasterDetailLayout;

  /// Returns true if platform has autoplay restrictions (web/macOS).
  bool get hasAutoplayRestrictions => E2EPlatform.hasAutoplayRestrictions;

  /// Returns true if platform needs longer timeouts (mobile).
  bool get needsLongerTimeouts => E2EPlatform.needsLongerTimeouts;

  /// Logs current platform and viewport info.
  void logEnvironmentInfo(WidgetTester tester) {
    logPlatformInfo();
    logViewportInfo(tester);
  }
}

/// E2E test fixture with convenience methods for common test patterns.
///
/// This extended fixture adds higher-level helpers that combine multiple
/// low-level operations into common test patterns.
///
/// Usage:
/// ```dart
/// testWidgets('My test', (tester) async {
///   final fixture = E2ETestFixtureWithHelpers();
///   await fixture.setUp(tester);
///
///   // Navigate with automatic timing
///   await fixture.navigateToDemo(tester, cardKey, 'Screen Title');
///
///   fixture.tearDown();
/// });
/// ```
class E2ETestFixtureWithHelpers extends E2ETestFixture {
  /// Creates an extended E2E test fixture with convenience helpers.
  E2ETestFixtureWithHelpers({
    super.suppressOverflowErrors,
    super.setViewport,
    super.customViewportSize,
    super.enableDetailedLogging,
  });

  // ==========================================================================
  // Navigation Helpers with Automatic Timing
  // ==========================================================================

  /// Navigates to a demo screen with automatic section timing.
  ///
  /// Combines [navigateToDemo] with [timedSection] for convenience.
  ///
  /// Example:
  /// ```dart
  /// await fixture.navigateToDemo(tester, TestKeys.playerFeaturesCard, 'Player Features');
  /// ```
  Future<void> navigateToDemo(WidgetTester tester, Key cardKey, String screenTitle, {bool scrollToCard = true}) async {
    await timedSection('Navigate to $screenTitle', () async {
      await nav.navigateToDemo(tester, cardKey, screenTitle, scrollToCard: scrollToCard);
    });
  }

  /// Navigates back to home screen with automatic section timing.
  ///
  /// Example:
  /// ```dart
  /// await fixture.goHome(tester);
  /// ```
  Future<void> goHome(WidgetTester tester, {Key? homeCardKey}) async {
    await timedSection('Navigate to home', () async {
      await nav.goHome(tester, homeCardKey: homeCardKey);
    });
  }

  // ==========================================================================
  // Video Testing Helpers
  // ==========================================================================

  /// Waits for video initialization with automatic timing and logging.
  ///
  /// Example:
  /// ```dart
  /// final duration = await fixture.waitForVideoInitialization(tester, durationFinder);
  /// expect(duration, isNotNull);
  /// ```
  Future<String?> waitForVideoInitialization(WidgetTester tester, Finder durationFinder, {Duration? timeout}) async {
    startSection('Wait for video initialization');

    final duration = await waitForVideoInitialization(tester, durationFinder, timeout: timeout);

    if (duration != null) {
      debugPrint('✓ Video initialized with duration: $duration');
    } else {
      debugPrint('⚠️ Video initialization timeout');
    }

    endSection('Wait for video initialization');
    return duration;
  }

  /// Waits for playback position to advance with automatic timing.
  ///
  /// Example:
  /// ```dart
  /// final position = await fixture.waitForPlaybackPosition(
  ///   tester,
  ///   positionFinder,
  ///   minSeconds: 2,
  /// );
  /// ```
  Future<String?> waitForPlaybackPosition(
    WidgetTester tester,
    Finder positionFinder, {
    required int minSeconds,
    Duration? timeout,
  }) async {
    startSection('Wait for playback to advance');

    final position = await waitForPlaybackPosition(tester, positionFinder, minSeconds: minSeconds, timeout: timeout);

    endSection('Wait for playback to advance');
    return position;
  }

  // ==========================================================================
  // Conditional Execution
  // ==========================================================================

  /// Executes callback only if playback tests should run (no autoplay restrictions).
  ///
  /// Example:
  /// ```dart
  /// await fixture.ifPlaybackAllowed(tester, () async {
  ///   await tester.tap(find.byKey(TestKeys.playButton));
  ///   await fixture.waitForPlaybackPosition(tester, positionFinder, minSeconds: 2);
  /// });
  /// ```
  Future<void> ifPlaybackAllowed(WidgetTester tester, Future<void> Function() callback) async {
    final playbackAllowed = !E2EPlatform.hasAutoplayRestrictions;
    await executeIf(
      condition: playbackAllowed,
      callback: callback,
      skipMessage: '⊗ Skipping playback test (autoplay restrictions on ${E2EPlatform.isWeb ? 'web' : 'macOS'})',
    );
  }
}
