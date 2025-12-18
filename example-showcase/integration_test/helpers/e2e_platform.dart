import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shared/e2e_constants.dart';

/// Platform-specific helpers for E2E integration tests.
///
/// Handles platform differences in widget testing behavior, particularly:
/// - Web/macOS: pumpAndSettle() hangs (video players cause continuous frames)
/// - Mobile: pumpAndSettle() works normally
///
/// These helpers provide cross-platform compatibility for settling widgets,
/// detecting autoplay restrictions, and handling platform-specific timeouts.

// ==========================================================================
// Widget Settling (Cross-Platform)
// ==========================================================================

/// Extension to provide cross-platform settle functionality.
///
/// On web/macOS, `pumpAndSettle()` hangs indefinitely because video players
/// cause continuous frame updates. This extension provides a `settle()` method
/// that uses `pump()` with explicit frames on problematic platforms.
extension E2EPlatformTester on WidgetTester {
  /// Settles the widget tree in a cross-platform way.
  ///
  /// **Web/macOS:** Pumps multiple frames to allow widgets to build
  /// (video player causes pumpAndSettle to hang)
  ///
  /// **Other platforms:** Uses `pumpAndSettle()` with [timeout]
  ///
  /// Parameters:
  /// - [webFrames]: Number of frames to pump on web/macOS (default: 10)
  /// - [timeout]: Timeout for pumpAndSettle on other platforms (default: 10s)
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpWidget(MyApp());
  /// await tester.settle(); // Cross-platform safe
  /// ```
  Future<void> settle({
    int webFrames = E2EDelays.settlingFrames,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final usePump = E2EPlatform.isWeb || E2EPlatform.isMacOS;

    if (usePump) {
      // On web/macOS, pump multiple frames to allow widgets to render
      // pumpAndSettle hangs because video player causes continuous frame updates
      for (var i = 0; i < webFrames; i++) {
        await pump(E2EDelays.settlingPump);
      }
    } else {
      await pumpAndSettle(timeout);
    }
  }

  /// Settles with more frames, useful after navigation or video loading.
  ///
  /// Uses 30 frames on web/macOS (vs 10 for standard settle).
  ///
  /// Example:
  /// ```dart
  /// await navigateToDemo(tester, cardKey, title);
  /// await tester.settleLong(); // Extra settling for complex screen
  /// ```
  Future<void> settleLong({Duration timeout = const Duration(seconds: 15)}) async {
    await settle(webFrames: E2EDelays.settlingFramesLong, timeout: timeout);
  }

  /// Pumps a single frame in a cross-platform way.
  ///
  /// Uses platform-appropriate frame duration.
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(key));
  /// await tester.pumpFrame(); // Single frame update
  /// ```
  Future<void> pumpFrame() async {
    await pump(E2EDelays.singleFrame);
  }

  /// Pumps multiple frames with specified interval.
  ///
  /// Useful for waiting through animations or async operations.
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpFrames(5, interval: Duration(milliseconds: 100));
  /// ```
  Future<void> pumpFrames(int count, {Duration? interval}) async {
    final effectiveInterval = interval ?? E2EDelays.settlingPump;
    for (var i = 0; i < count; i++) {
      await pump(effectiveInterval);
    }
  }
}

// ==========================================================================
// Autoplay and Playback Restrictions
// ==========================================================================

/// Returns true if playback tests should be skipped on this platform.
///
/// Web and macOS have autoplay restrictions in automated tests - videos
/// won't play without real user gestures (simulated taps don't count).
///
/// Use this to conditionally skip playback verification tests.
///
/// Example:
/// ```dart
/// if (!shouldSkipPlaybackTests()) {
///   await tester.tap(find.byKey(TestKeys.playButton));
///   await waitForPlaybackPosition(tester, positionFinder, minSeconds: 2);
/// } else {
///   debugPrint('Skipping playback test (autoplay restrictions)');
/// }
/// ```
bool shouldSkipPlaybackTests() => E2EPlatform.hasAutoplayRestrictions;

/// Returns true if platform has autoplay restrictions.
///
/// Browsers and macOS don't allow video autoplay in automated tests.
///
/// Example:
/// ```dart
/// if (hasAutoplayRestrictions()) {
///   debugPrint('⚠️ Autoplay restrictions active - skipping playback tests');
/// }
/// ```
bool hasAutoplayRestrictions() => E2EPlatform.hasAutoplayRestrictions;

/// Returns true if volume controls can be tested on this platform.
///
/// Web E2E tests require muted videos for autoplay bypass, so volume
/// changes don't work. This applies to ALL web browsers (Chrome, Safari, Firefox).
///
/// Use this to skip volume-related tests on web.
///
/// Example:
/// ```dart
/// if (canTestVolumeControls()) {
///   await tester.drag(volumeSlider, Offset(-100, 0));
///   expect(find.text('50%'), findsOneWidget);
/// } else {
///   debugPrint('Skipping volume test (videos muted on web for autoplay)');
/// }
/// ```
bool canTestVolumeControls() => E2EPlatform.canTestVolumeControls;

// ==========================================================================
// Platform-Aware Retry Counts
// ==========================================================================

/// Returns max retry attempts for video loading based on platform.
///
/// Mobile: 90 attempts (45 seconds at 500ms intervals)
/// Desktop/Web: 30 attempts (15 seconds)
///
/// Mobile emulators/simulators are slower, need more time.
///
/// Example:
/// ```dart
/// for (var i = 0; i < getMaxVideoLoadAttempts(); i++) {
///   await tester.pump(Duration(milliseconds: 500));
///   if (videoLoaded()) break;
/// }
/// ```
int getMaxVideoLoadAttempts() => E2ERetry.maxVideoLoadAttempts;

/// Returns max retry attempts for widget appearance based on platform.
///
/// Mobile: 30 attempts
/// Desktop/Web: 15 attempts
///
/// Example:
/// ```dart
/// for (var i = 0; i < getMaxWidgetWaitAttempts(); i++) {
///   if (finder.evaluate().isNotEmpty) break;
///   await tester.pump(Duration(milliseconds: 500));
/// }
/// ```
int getMaxWidgetWaitAttempts() => E2ERetry.maxWidgetWaitAttempts;

// ==========================================================================
// Platform Detection Helpers
// ==========================================================================

/// Returns true if running on mobile platform (iOS or Android).
bool isMobilePlatform() => E2EPlatform.isMobile;

/// Returns true if running on desktop platform (macOS, Windows, Linux).
bool isDesktopPlatform() => E2EPlatform.isDesktop;

/// Returns true if running on web platform.
bool isWebPlatform() => E2EPlatform.isWeb;

/// Returns true if running on macOS specifically.
bool isMacOSPlatform() => E2EPlatform.isMacOS;

/// Returns true if running on iOS specifically.
bool isIOSPlatform() => E2EPlatform.isIOS;

/// Returns true if running on Android specifically.
bool isAndroidPlatform() => E2EPlatform.isAndroid;

/// Returns true if platform needs longer timeouts (mobile).
///
/// Mobile emulators/simulators are slower than desktop/web:
/// - Video operations take 3x longer
/// - Network operations slower
/// - UI rendering slower
///
/// Example:
/// ```dart
/// final timeout = needsLongerTimeouts()
///     ? Duration(seconds: 45)
///     : Duration(seconds: 15);
/// ```
bool needsLongerTimeouts() => E2EPlatform.needsLongerTimeouts;

// ==========================================================================
// Platform-Specific Timeout Helpers
// ==========================================================================

/// Returns video initialization timeout based on platform.
///
/// Mobile: 15 seconds
/// Desktop/Web: 10 seconds
Duration getVideoInitializationTimeout() => E2EDelays.videoInitialization;

/// Returns video loading timeout based on platform.
///
/// Mobile: 45 seconds
/// Desktop/Web: 15 seconds
Duration getVideoLoadingTimeout() => E2EDelays.videoLoading;

// ==========================================================================
// Logging Helpers
// ==========================================================================

/// Logs current platform info for debugging.
///
/// Example:
/// ```dart
/// logPlatformInfo();
/// // Output:
/// // [Platform] mobile=false, desktop=true, web=false, macOS=true
/// // [Platform] autoplay restrictions=true, longer timeouts=false
/// ```
void logPlatformInfo() {
  debugPrint(
    '[Platform] mobile=${E2EPlatform.isMobile}, '
    'desktop=${E2EPlatform.isDesktop}, '
    'web=${E2EPlatform.isWeb}, '
    'macOS=${E2EPlatform.isMacOS}',
  );

  debugPrint(
    '[Platform] autoplay restrictions=${E2EPlatform.hasAutoplayRestrictions}, '
    'longer timeouts=${E2EPlatform.needsLongerTimeouts}',
  );
}

/// Logs viewport and layout info for debugging.
///
/// Example:
/// ```dart
/// logViewportInfo(tester);
/// // Output:
/// // [Viewport] size=Size(1200.0, 800.0), master-detail=true
/// ```
void logViewportInfo(WidgetTester tester) {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  final isMasterDetail = size.width >= 600;

  debugPrint('[Viewport] size=$size, master-detail=$isMasterDetail');
}
