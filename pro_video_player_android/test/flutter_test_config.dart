import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Global test configuration for this package.
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
  );

  await testMain();
}
