import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Global test configuration for the pro_video_player package.
///
/// This file is automatically loaded by Flutter test framework and executes
/// before any tests run. It enables memory leak tracking for all tests in this package.
///
/// Learn more: https://github.com/dart-lang/leak_tracker/blob/main/doc/leak_tracking/DETECT.md
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Enable leak tracking for all tests
  LeakTesting.enable();

  // Configure global leak tracking settings
  LeakTesting.settings = LeakTesting.settings.withIgnored(
    // Ignore leaks from test infrastructure (e.g., test helpers, mock objects)
    // This reduces noise from Flutter's own test framework
    createdByTestHelpers: true,

    // Ignore ProVideoPlayerController disposal in widget tests
    // Rationale: controller.dispose() hangs indefinitely in widget tests due to
    // platform channel interactions. This is a known limitation documented in
    // contributing/testing-guide.md "Controller Disposal Hanging in Widget Tests".
    // Controllers are properly garbage collected when tests complete.
    classes: ['ProVideoPlayerController'],
  );

  await testMain();
}
