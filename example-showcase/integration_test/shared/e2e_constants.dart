import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection helpers for E2E tests.
///
/// These helpers determine the current platform to apply platform-specific
/// timing, viewport sizes, and behavior in integration tests.
class E2EPlatform {
  E2EPlatform._();

  /// Returns true if running on a mobile platform (iOS or Android).
  static bool get isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Returns true if running on a desktop platform (macOS, Windows, Linux).
  static bool get isDesktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// Returns true if running on macOS specifically.
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Returns true if running on iOS specifically.
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Returns true if running on Android specifically.
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Returns true if running on web.
  static bool get isWeb => kIsWeb;

  /// Returns true if the platform needs longer timeouts (mobile simulators/emulators).
  ///
  /// Mobile platforms are significantly slower than desktop/web for video operations:
  /// - Video initialization: 45s mobile vs 15s desktop
  /// - Video loading: 45s mobile vs 15s desktop
  /// - Network operations: Slower on emulators/simulators
  static bool get needsLongerTimeouts => isMobile;

  /// Returns true if platform has autoplay restrictions (web, macOS).
  ///
  /// These platforms don't allow video autoplay in automated tests without
  /// real user gestures. E2E tests should skip playback verification on these platforms.
  static bool get hasAutoplayRestrictions => kIsWeb || isMacOS;

  /// Returns true if volume controls can be tested on this platform.
  ///
  /// Web E2E tests require muted videos for autoplay bypass, so volume changes
  /// don't work/make sense. Volume controls should be skipped on web.
  ///
  /// Note: This applies to ALL web browsers (Chrome, Safari, Firefox) due to
  /// WebDriver autoplay restrictions requiring muted videos.
  static bool get canTestVolumeControls => !kIsWeb;
}

/// Standard delays for E2E tests with platform-aware timing.
///
/// These constants replace hardcoded delays in E2E tests to provide
/// self-documenting, platform-appropriate timing values.
///
/// Usage:
/// ```dart
/// await tester.pump(E2EDelays.videoInitialization);
/// ```
class E2EDelays {
  E2EDelays._();

  // ============================================================================
  // Video Loading & Initialization
  // ============================================================================

  /// Wait for video player to initialize (platform instance created, ready to load).
  ///
  /// Mobile: 15 seconds (slower emulators/simulators)
  /// Desktop/Web: 10 seconds (faster hardware)
  static Duration get videoInitialization =>
      E2EPlatform.needsLongerTimeouts ? const Duration(seconds: 15) : const Duration(seconds: 10);

  /// Wait for video to fully load (duration available, ready to play).
  ///
  /// Mobile: 45 seconds (network slower on emulators)
  /// Desktop/Web: 15 seconds
  static Duration get videoLoading =>
      E2EPlatform.needsLongerTimeouts ? const Duration(seconds: 45) : const Duration(seconds: 15);

  /// Polling interval when waiting for video to load.
  ///
  /// Check every 500ms whether video is loaded (duration != "00:00")
  static const Duration videoLoadingPoll = Duration(milliseconds: 500);

  /// Maximum attempts when polling for video loading.
  ///
  /// Mobile: 90 attempts (45s total at 500ms intervals)
  /// Desktop/Web: 30 attempts (15s total at 500ms intervals)
  static int get maxVideoLoadAttempts => E2EPlatform.needsLongerTimeouts ? 90 : 30;

  /// Wait for video playback position to advance.
  ///
  /// After pressing play, wait this long before checking if position changed.
  static const Duration playbackPositionCheck = Duration(seconds: 4);

  // ============================================================================
  // UI & Controls
  // ============================================================================

  /// Wait for controls to animate in/out.
  ///
  /// Controls fade in/out with animation. Wait for animation to complete.
  static const Duration controlsAnimation = Duration(milliseconds: 500);

  /// Wait for navigation to complete (screen transitions, route changes).
  static const Duration navigation = Duration(seconds: 1);

  /// Longer navigation wait for complex screens with video players.
  static const Duration navigationLong = Duration(seconds: 2);

  /// Wait for modal dialogs to appear (bottom sheets, pickers).
  static const Duration modalAppear = Duration(milliseconds: 800);

  /// Wait for fullscreen transition to complete.
  static const Duration fullscreenTransition = Duration(milliseconds: 600);

  // ============================================================================
  // Widget Settling & Pumping
  // ============================================================================

  /// Interval for each pump when settling widgets.
  ///
  /// Used in `settleCrossPlatform()` to pump multiple frames.
  static const Duration settlingPump = Duration(milliseconds: 100);

  /// Number of frames to pump for standard settling (web/macOS).
  ///
  /// On web/macOS, pumpAndSettle() hangs because video players cause continuous
  /// frame updates. Use multiple pump() calls instead.
  static const int settlingFrames = 10;

  /// Number of frames to pump for longer settling (navigation, video loading).
  static const int settlingFramesLong = 30;

  /// Single frame pump duration.
  static const Duration singleFrame = Duration(milliseconds: 16);

  // ============================================================================
  // Scrolling & Interaction
  // ============================================================================

  /// Wait after scroll gesture before checking widget visibility.
  static const Duration scrollSettle = Duration(milliseconds: 200);

  /// Wait after tap gesture before checking state changes.
  static const Duration tapSettle = Duration(milliseconds: 100);

  /// Wait for keyboard input to process.
  static const Duration keyboardInput = Duration(milliseconds: 300);

  // ============================================================================
  // Master-Detail Layout Detection
  // ============================================================================

  /// Wait for "Open Demo" button to appear in master-detail layout.
  ///
  /// Master-detail layout (web/macOS) shows detail pane on card tap.
  /// Single-pane layout (mobile) navigates directly.
  static const Duration masterDetailDetection = Duration(milliseconds: 500);

  // ============================================================================
  // Error Recovery & Retries
  // ============================================================================

  /// Retry interval when polling for widgets to appear.
  static const Duration retryPoll = Duration(milliseconds: 500);

  /// Maximum retry attempts for widget appearance.
  static const int maxRetryAttempts = 10;

  /// Wait before retrying a failed operation.
  static const Duration retryDelay = Duration(seconds: 1);
}

/// Retry configuration for E2E operations.
///
/// Provides platform-aware retry counts for operations that may take
/// different amounts of time on different platforms.
class E2ERetry {
  E2ERetry._();

  /// Maximum attempts to wait for a widget to appear.
  ///
  /// Mobile: More attempts due to slower performance
  /// Desktop/Web: Fewer attempts (faster)
  static int get maxWidgetWaitAttempts => E2EPlatform.needsLongerTimeouts ? 30 : 15;

  /// Maximum attempts to wait for video initialization.
  ///
  /// Mobile: 30 attempts (15s at 500ms intervals)
  /// Desktop/Web: 20 attempts (10s at 500ms intervals)
  static int get maxInitializationAttempts => E2EPlatform.needsLongerTimeouts ? 30 : 20;

  /// Maximum attempts to wait for video loading.
  ///
  /// Mobile: 90 attempts (45s at 500ms intervals)
  /// Desktop/Web: 30 attempts (15s at 500ms intervals)
  static int get maxVideoLoadAttempts => E2EPlatform.needsLongerTimeouts ? 90 : 30;

  /// Maximum scroll attempts when searching for a card.
  ///
  /// Mobile: More scrolls may be needed on smaller screens
  /// Desktop/Web: Fewer scrolls (larger viewport)
  static int get maxScrollAttempts => E2EPlatform.needsLongerTimeouts ? 40 : 35;
}
