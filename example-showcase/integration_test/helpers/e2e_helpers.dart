import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shared/e2e_constants.dart';

/// Common helper functions for E2E integration tests.
///
/// These helpers eliminate duplication across E2E test files and provide
/// reusable patterns for waiting, tapping, and asserting in integration tests.
///
/// Key differences from unit test helpers:
/// - Work with REAL platform implementations (not mocks)
/// - Use longer timeouts for video loading and network operations
/// - Handle platform-specific behaviors (autoplay restrictions, timing differences)
/// - Poll for conditions instead of injecting mock events

// ==========================================================================
// Widget Waiting Helpers
// ==========================================================================

/// Waits for a widget matching [finder] to appear.
///
/// Polls every [pollInterval] until the widget appears or [timeout] is reached.
/// Returns true if widget appeared, false if timeout.
///
/// Example:
/// ```dart
/// final appeared = await waitForWidget(
///   tester,
///   find.byKey(TestKeys.playButton),
///   timeout: E2EDelays.videoInitialization,
/// );
/// expect(appeared, isTrue, reason: 'Play button should appear after init');
/// ```
Future<bool> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration? timeout,
  Duration? pollInterval,
  bool pumpBetweenChecks = true,
}) async {
  final effectiveTimeout = timeout ?? E2EDelays.videoInitialization;
  final effectivePollInterval = pollInterval ?? E2EDelays.retryPoll;

  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < effectiveTimeout) {
    if (finder.evaluate().isNotEmpty) {
      return true;
    }

    if (pumpBetweenChecks) {
      await tester.pump(effectivePollInterval);
    } else {
      await Future<void>.delayed(effectivePollInterval);
    }
  }

  return false; // Timeout
}

/// Waits for a widget with specific text to appear.
///
/// Convenience wrapper around [waitForWidget] for text-based searches.
///
/// Example:
/// ```dart
/// await waitForWidgetWithText(tester, 'Video Player');
/// expect(find.text('Video Player'), findsOneWidget);
/// ```
Future<bool> waitForWidgetWithText(
  WidgetTester tester,
  String text, {
  Duration? timeout,
  Duration? pollInterval,
}) async => waitForWidget(tester, find.text(text), timeout: timeout, pollInterval: pollInterval);

/// Waits for a widget to disappear.
///
/// Polls until the widget is no longer found or timeout is reached.
/// Returns true if widget disappeared, false if still present at timeout.
///
/// Example:
/// ```dart
/// await tester.tap(find.byKey(TestKeys.closeButton));
/// final disappeared = await waitForWidgetToDisappear(tester, find.byKey(TestKeys.modal));
/// expect(disappeared, isTrue);
/// ```
Future<bool> waitForWidgetToDisappear(
  WidgetTester tester,
  Finder finder, {
  Duration? timeout,
  Duration? pollInterval,
}) async {
  final effectiveTimeout = timeout ?? E2EDelays.navigation;
  final effectivePollInterval = pollInterval ?? E2EDelays.retryPoll;

  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < effectiveTimeout) {
    if (finder.evaluate().isEmpty) {
      return true;
    }

    await tester.pump(effectivePollInterval);
  }

  return false; // Still present at timeout
}

// ==========================================================================
// Video-Specific Waiting Helpers
// ==========================================================================

/// Waits for video to initialize (duration text appears and is not "00:00").
///
/// Polls the [durationFinder] widget for text content, waiting until:
/// 1. The widget exists (player initialized)
/// 2. The text is not "00:00" (video metadata loaded)
///
/// Returns the final duration string if successful, null if timeout.
///
/// Example:
/// ```dart
/// final duration = await waitForVideoInitialization(
///   tester,
///   find.byKey(TestKeys.durationText),
/// );
/// expect(duration, isNot('00:00'), reason: 'Video should have loaded');
/// ```
Future<String?> waitForVideoInitialization(WidgetTester tester, Finder durationFinder, {Duration? timeout}) async {
  final effectiveTimeout = timeout ?? E2EDelays.videoLoading;
  final maxAttempts = E2ERetry.maxInitializationAttempts;

  // First, wait for the widget to appear
  for (var i = 0; i < maxAttempts; i++) {
    await tester.pump(E2EDelays.videoLoadingPoll);

    if (durationFinder.evaluate().isNotEmpty) {
      // Widget exists, now check if duration is loaded
      try {
        final durationText = tester.widget<Text>(durationFinder).data ?? '00:00';
        final durationSeconds = parseTimeString(durationText);

        if (durationSeconds > 0) {
          debugPrint('✓ Video initialized with duration: $durationText');
          return durationText;
        }
      } catch (e) {
        // Widget exists but might not be a Text widget, continue waiting
        debugPrint('Waiting for video initialization... attempt ${i + 1}/$maxAttempts');
      }
    } else {
      debugPrint('Waiting for duration widget... attempt ${i + 1}/$maxAttempts');
    }
  }

  debugPrint('⚠️ Video initialization timeout after ${effectiveTimeout.inSeconds}s');
  return null;
}

/// Waits for playback position to advance beyond [minSeconds].
///
/// Polls the [positionFinder] widget, waiting for position to exceed [minSeconds].
/// Useful for verifying that video is actually playing.
///
/// Returns the final position string if successful, null if timeout.
///
/// Example:
/// ```dart
/// await tester.tap(find.byKey(TestKeys.playButton));
/// final position = await waitForPlaybackPosition(
///   tester,
///   find.byKey(TestKeys.positionText),
///   minSeconds: 2,
/// );
/// expect(position, isNotNull, reason: 'Playback should have advanced');
/// ```
Future<String?> waitForPlaybackPosition(
  WidgetTester tester,
  Finder positionFinder, {
  required int minSeconds,
  Duration? timeout,
}) async {
  final effectiveTimeout = timeout ?? E2EDelays.playbackPositionCheck;
  final maxAttempts = effectiveTimeout.inSeconds;

  for (var i = 0; i < maxAttempts; i++) {
    await tester.pump(const Duration(seconds: 1));

    if (positionFinder.evaluate().isNotEmpty) {
      try {
        final positionText = tester.widget<Text>(positionFinder).data ?? '00:00';
        final positionSeconds = parseTimeString(positionText);

        if (positionSeconds >= minSeconds) {
          debugPrint('✓ Playback position advanced to: $positionText');
          return positionText;
        }

        debugPrint('Waiting for position >= ${minSeconds}s, current: $positionText');
      } catch (e) {
        debugPrint('Error reading position: $e');
      }
    }
  }

  debugPrint('⚠️ Playback position did not advance to ${minSeconds}s within timeout');
  return null;
}

// ==========================================================================
// Tapping and Interaction Helpers
// ==========================================================================

/// Taps a widget and waits for controls to appear.
///
/// Useful for videos where controls auto-hide - tap to make them visible
/// before asserting their presence or tapping specific buttons.
///
/// Example:
/// ```dart
/// await tapAndWaitForControls(tester, find.byType(ProVideoPlayer));
/// // Now controls are visible and can be interacted with
/// await tester.tap(find.byKey(TestKeys.playButton));
/// ```
Future<void> tapAndWaitForControls(WidgetTester tester, Finder videoPlayerFinder, {Duration? waitAfterTap}) async {
  final effectiveWait = waitAfterTap ?? E2EDelays.controlsAnimation;

  await tester.tap(videoPlayerFinder);
  await tester.pump(effectiveWait);
}

/// Taps a widget and waits for settling.
///
/// Convenience helper for tap + wait pattern.
///
/// Example:
/// ```dart
/// await tapAndSettle(tester, find.byKey(TestKeys.settingsButton));
/// ```
Future<void> tapAndSettle(WidgetTester tester, Finder finder, {Duration? waitAfterTap}) async {
  final effectiveWait = waitAfterTap ?? E2EDelays.tapSettle;

  await tester.tap(finder);
  await tester.pump(effectiveWait);
}

// ==========================================================================
// Time Parsing and Assertions
// ==========================================================================

/// Parses a time string in "MM:SS" or "HH:MM:SS" format to total seconds.
///
/// Examples:
/// - "01:30" → 90 seconds
/// - "00:05" → 5 seconds
/// - "1:05:30" → 3930 seconds
///
/// Returns 0 if parsing fails.
///
/// Example:
/// ```dart
/// final seconds = parseTimeString('02:30'); // 150 seconds
/// ```
int parseTimeString(String timeStr) {
  try {
    final parts = timeStr.split(':');

    if (parts.length == 2) {
      // MM:SS format
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      return minutes * 60 + seconds;
    } else if (parts.length == 3) {
      // HH:MM:SS format
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return hours * 3600 + minutes * 60 + seconds;
    }
  } catch (e) {
    debugPrint('⚠️ Error parsing time string "$timeStr": $e');
  }

  return 0;
}

/// Formats seconds into "MM:SS" time string.
///
/// Example:
/// ```dart
/// final timeStr = formatTimeString(150); // "02:30"
/// ```
String formatTimeString(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Asserts that playback time has advanced.
///
/// Compares [beforeStr] and [afterStr] time strings, asserting that
/// [afterStr] is greater than [beforeStr] by at least [minDelta] seconds.
///
/// Example:
/// ```dart
/// final before = '00:05';
/// // ... video plays ...
/// final after = '00:08';
/// expectTimeAdvanced(before, after, minDelta: 2); // Passes
/// ```
void expectTimeAdvanced(String beforeStr, String afterStr, {int minDelta = 1, String? reason}) {
  final beforeSeconds = parseTimeString(beforeStr);
  final afterSeconds = parseTimeString(afterStr);
  final delta = afterSeconds - beforeSeconds;

  expect(
    delta,
    greaterThanOrEqualTo(minDelta),
    reason:
        reason ??
        'Playback should advance by at least ${minDelta}s (was: $beforeStr, now: $afterStr, delta: ${delta}s)',
  );
}

/// Asserts that time string represents a non-zero duration.
///
/// Useful for verifying that video has loaded and has a duration.
///
/// Example:
/// ```dart
/// final duration = await waitForVideoInitialization(tester, durationFinder);
/// expectNonZeroDuration(duration);
/// ```
void expectNonZeroDuration(String? durationStr) {
  expect(durationStr, isNotNull, reason: 'Duration should not be null');
  final seconds = parseTimeString(durationStr!);
  expect(seconds, greaterThan(0), reason: 'Duration should be > 0 (was: $durationStr)');
}

// ==========================================================================
// Conditional Execution Helpers
// ==========================================================================

/// Executes [callback] only if [condition] is true, otherwise logs skip message.
///
/// Useful for platform-conditional test sections.
///
/// Example:
/// ```dart
/// await executeIf(
///   condition: !E2EPlatform.hasAutoplayRestrictions,
///   callback: () async {
///     await tester.tap(find.byKey(TestKeys.playButton));
///     await waitForPlaybackPosition(tester, positionFinder, minSeconds: 2);
///   },
///   skipMessage: 'Skipping playback test on web/macOS (autoplay restrictions)',
/// );
/// ```
Future<void> executeIf({
  required bool condition,
  required Future<void> Function() callback,
  String? skipMessage,
}) async {
  if (condition) {
    await callback();
  } else if (skipMessage != null) {
    debugPrint('⊗ $skipMessage');
  }
}

/// Executes [callback] and returns true if it succeeds, false if it throws.
///
/// Useful for optional operations that may fail on some platforms.
///
/// Example:
/// ```dart
/// final success = await tryExecute(() async {
///   await tester.tap(find.byKey(TestKeys.pipButton));
///   await tester.pump(E2EDelays.controlsAnimation);
/// });
/// if (!success) {
///   debugPrint('PiP not available on this device');
/// }
/// ```
Future<bool> tryExecute(Future<void> Function() callback) async {
  try {
    await callback();
    return true;
  } catch (e) {
    debugPrint('⚠️ Operation failed: $e');
    return false;
  }
}

// ==========================================================================
// Logging and Debugging Helpers
// ==========================================================================

/// Logs current video state for debugging.
///
/// Example:
/// ```dart
/// logVideoState(
///   positionStr: '02:30',
///   durationStr: '10:00',
///   state: 'playing',
/// );
/// // Output: [Video State] Position: 02:30 | Duration: 10:00 | State: playing
/// ```
void logVideoState({String? positionStr, String? durationStr, String? state, Map<String, dynamic>? extra}) {
  final parts = <String>[];
  if (positionStr != null) parts.add('Position: $positionStr');
  if (durationStr != null) parts.add('Duration: $durationStr');
  if (state != null) parts.add('State: $state');
  if (extra != null) {
    extra.forEach((key, value) => parts.add('$key: $value'));
  }

  debugPrint('[Video State] ${parts.join(' | ')}');
}

/// Logs test section timing.
///
/// Example:
/// ```dart
/// final stopwatch = Stopwatch()..start();
/// // ... test operations ...
/// logTiming('Video initialization', stopwatch);
/// // Output: [Timing] Video initialization: 2.5s (2500ms)
/// ```
void logTiming(String operationName, Stopwatch stopwatch) {
  final elapsed = stopwatch.elapsedMilliseconds;
  final seconds = (elapsed / 1000).toStringAsFixed(1);
  debugPrint('[Timing] $operationName: ${seconds}s (${elapsed}ms)');
}

/// Creates a scoped timing logger that automatically logs on dispose.
///
/// Example:
/// ```dart
/// final timing = ScopedTiming('Video loading');
/// // ... operations ...
/// timing.dispose(); // Logs: [Timing] Video loading: 2.5s
/// ```
class ScopedTiming {
  ScopedTiming(this.operationName) : _stopwatch = Stopwatch()..start();

  final String operationName;
  final Stopwatch _stopwatch;

  void dispose() {
    _stopwatch.stop();
    logTiming(operationName, _stopwatch);
  }
}
