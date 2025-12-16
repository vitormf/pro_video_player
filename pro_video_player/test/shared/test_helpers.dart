import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

/// Shared test helper functions for widget testing.
///
/// These helpers eliminate duplication across test files and provide
/// consistent patterns for common testing scenarios.

/// Builds a test widget wrapped in MaterialApp and Scaffold.
///
/// This is the standard wrapper for widget tests. It provides:
/// - MaterialApp for theme and navigation context
/// - Scaffold for proper Material Design structure
/// - Body with the child widget
///
/// Example:
/// ```dart
/// await tester.pumpWidget(buildTestWidget(MyWidget()));
/// ```
Widget buildTestWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Builds a test widget with specific size constraints.
///
/// Useful when testing responsive behavior or widgets that need
/// specific dimensions.
///
/// Example:
/// ```dart
/// await tester.pumpWidget(
///   buildSizedTestWidget(
///     MyWidget(),
///     width: 400,
///     height: 300,
///   ),
/// );
/// ```
Widget buildSizedTestWidget(Widget child, {double width = 800, double height = 600}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: width, height: height, child: child),
  ),
);

/// Builds a test app with platform override.
///
/// Useful for testing platform-specific behavior, especially for
/// keyboard shortcuts and other platform-dependent features.
///
/// Example:
/// ```dart
/// await tester.pumpWidget(
///   buildTestApp(
///     platform: TargetPlatform.windows,
///     child: MyWidget(),
///   ),
/// );
/// ```
Widget buildTestApp({required Widget child, TargetPlatform? platform}) => MaterialApp(
  theme: platform != null ? ThemeData(platform: platform) : null,
  home: Scaffold(body: child),
);

/// Calculates the center position of a widget for tap testing.
///
/// Returns the global offset of the widget's center, which can be
/// used with `tester.tapAt()`.
///
/// Example:
/// ```dart
/// final center = getWidgetCenter(tester, find.byType(MyButton));
/// await tester.tapAt(center);
/// ```
Offset getWidgetCenter(WidgetTester tester, Finder finder) {
  final renderBox = tester.renderObject<RenderBox>(finder);
  return renderBox.localToGlobal(renderBox.size.center(Offset.zero));
}

/// Calculates a specific position within a widget based on percentage.
///
/// Returns the global offset at the specified percentage of the widget's
/// width and height.
///
/// Example:
/// ```dart
/// // Tap at 75% across the progress bar (seek to 75% of duration)
/// final position = getWidgetPosition(tester, find.byType(ProgressBar), 0.75, 0.5);
/// await tester.tapAt(position);
/// ```
Offset getWidgetPosition(WidgetTester tester, Finder finder, double widthPercent, double heightPercent) {
  final renderBox = tester.renderObject<RenderBox>(finder);
  final size = renderBox.size;
  final localOffset = Offset(size.width * widthPercent, size.height * heightPercent);
  return renderBox.localToGlobal(localOffset);
}

/// Self-documenting assertion that controller is in playing state.
///
/// More readable than `expect(controller.value.playbackState, PlaybackState.playing)`.
///
/// Example:
/// ```dart
/// await controller.play();
/// expectPlaying(controller);
/// ```
void expectPlaying(ProVideoPlayerController controller) {
  expect(controller.value.playbackState, PlaybackState.playing, reason: 'Expected controller to be playing');
}

/// Self-documenting assertion that controller is in paused state.
///
/// Example:
/// ```dart
/// await controller.pause();
/// expectPaused(controller);
/// ```
void expectPaused(ProVideoPlayerController controller) {
  expect(controller.value.playbackState, PlaybackState.paused, reason: 'Expected controller to be paused');
}

/// Self-documenting assertion that controller is in buffering state.
///
/// Example:
/// ```dart
/// expectBuffering(controller);
/// ```
void expectBuffering(ProVideoPlayerController controller) {
  expect(controller.value.playbackState, PlaybackState.buffering, reason: 'Expected controller to be buffering');
}

/// Self-documenting assertion that controller is in completed state.
///
/// Example:
/// ```dart
/// // Wait for video to complete
/// expectCompleted(controller);
/// ```
void expectCompleted(ProVideoPlayerController controller) {
  expect(controller.value.playbackState, PlaybackState.completed, reason: 'Expected controller to be completed');
}

/// Self-documenting assertion that controller is in fullscreen mode.
///
/// Example:
/// ```dart
/// await controller.enterFullscreen();
/// expectInFullscreen(controller);
/// ```
void expectInFullscreen(ProVideoPlayerController controller) {
  expect(controller.value.isFullscreen, isTrue, reason: 'Expected controller to be in fullscreen');
}

/// Self-documenting assertion that controller is not in fullscreen mode.
///
/// Example:
/// ```dart
/// await controller.exitFullscreen();
/// expectNotInFullscreen(controller);
/// ```
void expectNotInFullscreen(ProVideoPlayerController controller) {
  expect(controller.value.isFullscreen, isFalse, reason: 'Expected controller to not be in fullscreen');
}

/// Self-documenting assertion that controller is in PiP mode.
///
/// Example:
/// ```dart
/// await controller.enterPip();
/// expectInPip(controller);
/// ```
void expectInPip(ProVideoPlayerController controller) {
  expect(controller.value.isPipActive, isTrue, reason: 'Expected controller to be in PiP');
}

/// Self-documenting assertion that controller is not in PiP mode.
///
/// Example:
/// ```dart
/// await controller.exitPip();
/// expectNotInPip(controller);
/// ```
void expectNotInPip(ProVideoPlayerController controller) {
  expect(controller.value.isPipActive, isFalse, reason: 'Expected controller to not be in PiP');
}

/// Self-documenting assertion for controller position.
///
/// Allows for small timing variations (±100ms tolerance).
///
/// Example:
/// ```dart
/// await controller.seekTo(const Duration(minutes: 2));
/// expectPosition(controller, const Duration(minutes: 2));
/// ```
void expectPosition(ProVideoPlayerController controller, Duration expected) {
  const tolerance = Duration(milliseconds: 100);
  final actual = controller.value.position;
  final difference = (actual - expected).abs();

  expect(difference <= tolerance, isTrue, reason: 'Expected position $expected, got $actual (difference: $difference)');
}

/// Self-documenting assertion for controller duration.
///
/// Example:
/// ```dart
/// expectDuration(controller, const Duration(minutes: 5));
/// ```
void expectDuration(ProVideoPlayerController controller, Duration expected) {
  expect(controller.value.duration, expected, reason: 'Expected duration $expected, got ${controller.value.duration}');
}

/// Self-documenting assertion for playback speed.
///
/// Example:
/// ```dart
/// await controller.setPlaybackSpeed(1.5);
/// expectSpeed(controller, 1.5);
/// ```
void expectSpeed(ProVideoPlayerController controller, double expected) {
  expect(
    controller.value.playbackSpeed,
    expected,
    reason: 'Expected speed $expected, got ${controller.value.playbackSpeed}',
  );
}

/// Self-documenting assertion for volume.
///
/// Example:
/// ```dart
/// await controller.setVolume(0.5);
/// expectVolume(controller, 0.5);
/// ```
void expectVolume(ProVideoPlayerController controller, double expected) {
  expect(controller.value.volume, expected, reason: 'Expected volume $expected, got ${controller.value.volume}');
}
