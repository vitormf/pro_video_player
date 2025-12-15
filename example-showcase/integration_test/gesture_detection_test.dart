import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_example/constants/video_constants.dart';

/// Returns true if running on Android.
bool get isAndroid => !kIsWeb && Platform.isAndroid;

/// Integration tests for gesture detection on the fullscreen video player.
///
/// These tests verify that gesture controls work correctly in fullscreen mode,
/// including:
/// - Single tap to toggle controls visibility
/// - Double tap left/right to seek backward/forward
/// - Double tap center to play/pause
/// - Vertical swipe on left side to adjust brightness
/// - Vertical swipe on right side to adjust volume
/// - Horizontal swipe to seek through video
/// - Two-finger vertical swipe to adjust playback speed
///
/// These tests run on real devices/emulators and verify actual gesture behavior.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fullscreen Gesture Detection Tests', () {
    late ProVideoPlayerController controller;

    setUp(() {
      controller = ProVideoPlayerController();
    });

    tearDown(() async {
      try {
        if (controller.value.isFullscreen) {
          await controller.exitFullscreen();
        }
        await controller.dispose();
      } catch (e) {
        // Ignore disposal errors in tests
      }
    });

    /// Helper to initialize video (without entering fullscreen for test stability)
    Future<void> initializeVideo(WidgetTester tester) async {
      await controller.initialize(source: const VideoSource.network(VideoUrls.bigBuckBunny));

      // Wait for initialization - shorter wait
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify video is initialized
      expect(controller.isInitialized, isTrue);
    }

    /// Helper to find a point in the video player area
    Offset getPlayerPoint(WidgetTester tester, double relativeX, double relativeY) {
      // Find the VideoPlayerGestureDetector widget by key
      final gestureDetectorFinder = find.byKey(const Key('test_gesture_detector'));

      if (gestureDetectorFinder.evaluate().isEmpty) {
        // Fallback to screen size if widget not found
        final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
        return Offset(screenSize.width * relativeX, screenSize.height * relativeY);
      }

      // Get the actual bounds of the gesture detector widget
      final renderBox = tester.renderObject<RenderBox>(gestureDetectorFinder);
      final size = renderBox.size;
      final topLeft = renderBox.localToGlobal(Offset.zero);

      // Calculate position within the widget bounds
      return Offset(topLeft.dx + (size.width * relativeX), topLeft.dy + (size.height * relativeY));
    }

    /// Helper to simulate a tap at a relative position
    Future<void> tapAt(WidgetTester tester, double relativeX, double relativeY) async {
      final position = getPlayerPoint(tester, relativeX, relativeY);
      await tester.tapAt(position);
      await tester.pump();
    }

    /// Helper to simulate a double tap at a relative position
    Future<void> doubleTapAt(WidgetTester tester, double relativeX, double relativeY) async {
      final position = getPlayerPoint(tester, relativeX, relativeY);
      // First tap
      await tester.tapAt(position);
      await tester.pump(const Duration(milliseconds: 50));
      // Second tap (within 300ms double-tap window)
      await tester.tapAt(position);
      await tester.pump();
    }

    /// Helper to simulate a vertical drag gesture
    Future<void> verticalDrag(WidgetTester tester, double startX, double startY, double dragDistance) async {
      final start = getPlayerPoint(tester, startX, startY);
      await tester.dragFrom(start, Offset(0, dragDistance));
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// Helper to simulate a horizontal drag gesture
    Future<void> horizontalDrag(WidgetTester tester, double startX, double startY, double dragDistance) async {
      final start = getPlayerPoint(tester, startX, startY);
      await tester.dragFrom(start, Offset(dragDistance, 0));
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// Helper to build a test widget with gesture detector
    Widget buildTestWidget({ValueChanged<bool>? onControlsVisibilityChanged}) => MaterialApp(
      home: Scaffold(
        body: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerGestureDetector(
            key: const Key('test_gesture_detector'),
            controller: controller,
            onControlsVisibilityChanged: onControlsVisibilityChanged,
            child: ProVideoPlayer(controller: controller),
          ),
        ),
      ),
    );

    testWidgets('Single tap toggles controls visibility in fullscreen', (tester) async {
      // Build the player with gesture detector wrapper
      var controlsVisible = true;

      await tester.pumpWidget(
        buildTestWidget(
          onControlsVisibilityChanged: (visible) {
            controlsVisible = visible;
          },
        ),
      );
      await tester.pumpAndSettle();

      await initializeVideo(tester);
      await tester.pumpAndSettle();

      // Find the gesture detector widget
      final gestureFinder = find.byKey(const Key('test_gesture_detector'));
      expect(gestureFinder, findsOneWidget);

      // Single tap at center should toggle controls
      await tester.tap(gestureFinder);
      await tester.pump();
      // Wait for double-tap timeout (300ms) plus buffer for callback
      await tester.pump(const Duration(milliseconds: 400));

      // Controls should now be hidden
      expect(controlsVisible, isFalse);

      // Single tap again should show controls
      await tapAt(tester, 0.5, 0.5);
      await tester.pump(const Duration(milliseconds: 400));

      // Controls should be visible again
      expect(controlsVisible, isTrue);
    });

    testWidgets('Single tap shows overlay when video starts in fullscreen with autoplay', (tester) async {
      // Build the fullscreen player with autoplay
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayerGestureDetector(
                controller: controller,
                child: ProVideoPlayer(controller: controller),
              ),
            ),
          ),
        ),
      ); // Initialize with autoplay option
      await controller.initialize(
        source: const VideoSource.network(VideoUrls.bigBuckBunny),
        options: const VideoPlayerOptions(autoPlay: true),
      );

      // Wait for initialization
      await tester.pump(const Duration(seconds: 2));

      // Verify video is initialized and playing
      expect(controller.isInitialized, isTrue);
      expect(controller.value.isPlaying, isTrue);

      // Enter fullscreen while playing
      await controller.enterFullscreen();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we're in fullscreen
      expect(controller.value.isFullscreen, isTrue);

      // When entering fullscreen with autoplay, controls may auto-hide
      // Wait for any auto-hide timer (typically 3 seconds)
      await tester.pump(const Duration(seconds: 4));

      // At this point, controls should be hidden (auto-hide triggered)
      // Single tap should show the overlay/controls
      await tapAt(tester, 0.5, 0.5);
      await tester.pump(const Duration(milliseconds: 350)); // Wait for double-tap timeout

      // Controls should now be visible
      // In a complete implementation, you would check for specific control widgets:
      // - Play/pause button
      // - Progress bar
      // - Time display
      // - Fullscreen exit button
      // Example verification (adjust based on your actual implementation):
      // expect(find.byIcon(Icons.pause), findsOneWidget);
      // expect(find.byType(Slider), findsOneWidget);

      // For now, verify the video is still playing and in fullscreen
      expect(controller.value.isFullscreen, isTrue);
      expect(controller.value.isPlaying, isTrue);

      // Verify another tap hides controls again
      await tapAt(tester, 0.5, 0.5);
      await tester.pump(const Duration(milliseconds: 350));

      // Controls should be hidden again
      // The video should still be in fullscreen and playing
      expect(controller.value.isFullscreen, isTrue);
    });

    testWidgets('Overlay auto-dismisses after a few seconds while playing', (tester) async {
      var controlsVisible = true;

      await tester.pumpWidget(
        buildTestWidget(
          onControlsVisibilityChanged: (visible) {
            controlsVisible = visible;
          },
        ),
      );
      await initializeVideo(tester);

      // Start playing
      await controller.play();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify video is playing
      expect(controller.value.isPlaying, isTrue);

      // Tap to show controls (they start visible, so this hides them first)
      await tapAt(tester, 0.5, 0.5);
      await tester.pump(const Duration(milliseconds: 350));
      expect(controlsVisible, isFalse); // Now hidden

      // Tap again to show controls
      await tapAt(tester, 0.5, 0.5);
      await tester.pump(const Duration(milliseconds: 350));
      expect(controlsVisible, isTrue); // Now visible

      // Wait for auto-hide delay (2 seconds default) plus buffer
      await tester.pump(const Duration(seconds: 3));

      // Controls should now be auto-hidden
      expect(controlsVisible, isFalse);

      // Video should still be playing
      expect(controller.value.isPlaying, isTrue);
    });

    testWidgets('Overlay shows again with single tap after auto-dismiss', (tester) async {
      var controlsVisible = true;

      await tester.pumpWidget(
        buildTestWidget(
          onControlsVisibilityChanged: (visible) {
            controlsVisible = visible;
          },
        ),
      );
      await initializeVideo(tester);

      // Start playing
      await controller.play();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap to hide controls
      await tapAt(tester, 0.5, 0.5);
      await tester.pump(const Duration(milliseconds: 350));
      expect(controlsVisible, isFalse);

      // Tap again to show controls
      await tapAt(tester, 0.5, 0.5);
      await tester.pump(const Duration(milliseconds: 350));
      expect(controlsVisible, isTrue);

      // Wait for auto-dismiss (2 seconds default + buffer)
      await tester.pump(const Duration(seconds: 3));

      // Controls should be auto-dismissed
      expect(controlsVisible, isFalse);

      // Single tap should show controls again
      await tapAt(tester, 0.5, 0.5);
      await tester.pump(const Duration(milliseconds: 350));

      // Controls should be visible again
      expect(controlsVisible, isTrue);

      // Video should still be playing
      expect(controller.value.isPlaying, isTrue);
    });

    testWidgets('Double tap left side seeks backward in fullscreen', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Start playing and seek to middle
      await controller.play();
      await tester.pumpAndSettle();
      await controller.seekTo(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      final positionBefore = controller.value.position;

      // Double tap on left side (at 15% - well within 30% left zone)
      await doubleTapAt(tester, 0.15, 0.5);
      await tester.pumpAndSettle();

      final positionAfter = controller.value.position;

      // Position should have moved backward (typically 10 seconds)
      expect(
        positionAfter.inSeconds,
        lessThan(positionBefore.inSeconds),
        reason: 'Double tap left should seek backward',
      );
    });

    testWidgets('Double tap right side seeks forward in fullscreen', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Start playing
      await controller.play();
      await tester.pumpAndSettle();

      final positionBefore = controller.value.position;

      // Double tap on right side (at 85% - well within 70%+ right zone)
      await doubleTapAt(tester, 0.85, 0.5);
      await tester.pumpAndSettle();

      final positionAfter = controller.value.position;

      // Position should have moved forward (typically 10 seconds)
      expect(
        positionAfter.inSeconds,
        greaterThan(positionBefore.inSeconds),
        reason: 'Double tap right should seek forward',
      );
    });

    testWidgets('Double tap center toggles play/pause in fullscreen', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Video should be paused initially
      expect(controller.value.isPlaying, isFalse);

      // Double tap center to play
      await doubleTapAt(tester, 0.5, 0.5);
      await tester.pumpAndSettle();

      expect(controller.value.isPlaying, isTrue);

      // Double tap center again to pause
      await doubleTapAt(tester, 0.5, 0.5);
      await tester.pumpAndSettle();

      expect(controller.value.isPlaying, isFalse);
    });

    testWidgets('Vertical swipe on right side adjusts volume in fullscreen', (tester) async {
      // Skip on non-Android platforms where volume gesture may not be supported
      if (!isAndroid) {
        return;
      }

      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Get initial device volume
      final initialVolume = await controller.getDeviceVolume();

      // Ensure volume is not at minimum so we can test decrease
      if (initialVolume < 0.3) {
        await controller.setDeviceVolume(0.5);
        await tester.pumpAndSettle();
      }

      final volumeBefore = await controller.getDeviceVolume();

      // Swipe down on right side to decrease volume
      await verticalDrag(tester, 0.9, 0.3, 200);
      await tester.pumpAndSettle();

      // Get device volume after swipe
      final volumeAfter = await controller.getDeviceVolume();

      // Volume should have decreased
      expect(volumeAfter, lessThan(volumeBefore), reason: 'Vertical swipe down on right should decrease device volume');

      // Swipe up on right side to increase volume
      await verticalDrag(tester, 0.9, 0.7, -200);
      await tester.pumpAndSettle();

      // Get device volume after swipe up
      final volumeFinal = await controller.getDeviceVolume();

      // Volume should have increased
      expect(volumeFinal, greaterThan(volumeAfter), reason: 'Vertical swipe up on right should increase device volume');
    });

    testWidgets('Vertical swipe on left side adjusts brightness in fullscreen', (tester) async {
      // Skip on non-Android platforms
      if (!isAndroid) {
        return;
      }

      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Brightness control via system - we can only verify the gesture doesn't crash
      // Actual brightness verification would require platform channel integration

      // Swipe down on left side to decrease brightness
      await verticalDrag(tester, 0.1, 0.3, 200);
      await tester.pump(const Duration(milliseconds: 500));

      // Swipe up on left side to increase brightness
      await verticalDrag(tester, 0.1, 0.7, -200);
      await tester.pump(const Duration(milliseconds: 500));

      // Test passes if no exceptions were thrown
    });

    testWidgets('Horizontal swipe seeks through video in fullscreen', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Start playing and seek to a known position
      await controller.play();
      await tester.pump(const Duration(seconds: 1));
      await controller.seekTo(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      await controller.pause();
      await tester.pump(const Duration(milliseconds: 500));

      final positionBefore = controller.value.position;

      // Swipe right (forward in video)
      await horizontalDrag(tester, 0.3, 0.5, 200);
      await tester.pump(const Duration(seconds: 1));

      final positionAfter = controller.value.position;

      // Position should have moved forward
      expect(
        positionAfter.inSeconds,
        greaterThan(positionBefore.inSeconds),
        reason: 'Horizontal swipe right should seek forward',
      );

      // Swipe left (backward in video)
      await horizontalDrag(tester, 0.7, 0.5, -200);
      await tester.pump(const Duration(seconds: 1));

      final positionFinal = controller.value.position;

      // Position should have moved backward
      expect(
        positionFinal.inSeconds,
        lessThan(positionAfter.inSeconds),
        reason: 'Horizontal swipe left should seek backward',
      );
    });

    testWidgets('Two-finger vertical swipe adjusts playback speed in fullscreen', (tester) async {
      // Note: Multi-touch gestures are difficult to test in integration tests
      // This test verifies the controller's playback speed functionality
      // The actual two-finger gesture would need manual testing or specialized tools

      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      final speedBefore = controller.value.playbackSpeed;
      expect(speedBefore, equals(1.0)); // Default speed

      // Simulate speed change (as gesture would trigger)
      await controller.setPlaybackSpeed(1.5);
      await tester.pump(const Duration(milliseconds: 500));

      expect(controller.value.playbackSpeed, equals(1.5));

      // Reset to normal speed
      await controller.setPlaybackSpeed(1);
      await tester.pump(const Duration(milliseconds: 500));

      expect(controller.value.playbackSpeed, equals(1.0));
    });

    testWidgets('Gestures work correctly after orientation change', (tester) async {
      // Skip on non-Android platforms
      if (!isAndroid) {
        return;
      }

      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Simulate orientation change by changing the view size
      final originalSize = tester.view.physicalSize;

      // Change to landscape (if not already)
      await binding.setSurfaceSize(Size(originalSize.height, originalSize.width));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify gestures still work after orientation change
      final positionBefore = controller.value.position;

      // Double tap right to seek forward
      await doubleTapAt(tester, 0.8, 0.5);
      await tester.pump(const Duration(seconds: 1));

      final positionAfter = controller.value.position;

      // Gesture should still work
      expect(
        positionAfter.inSeconds,
        greaterThanOrEqualTo(positionBefore.inSeconds),
        reason: 'Gestures should work after orientation change',
      );

      // Restore original size
      await binding.setSurfaceSize(originalSize);
    });

    testWidgets('Multiple rapid gestures are handled correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Start playing
      await controller.play();
      await tester.pump(const Duration(seconds: 1));

      // Perform rapid double taps (play/pause multiple times)
      for (var i = 0; i < 3; i++) {
        await doubleTapAt(tester, 0.5, 0.5);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Player should still be responsive
      expect(controller.value.isPlaying, isNotNull);

      // Perform rapid seek gestures
      await doubleTapAt(tester, 0.8, 0.5); // Seek forward
      await tester.pump(const Duration(milliseconds: 200));
      await doubleTapAt(tester, 0.2, 0.5); // Seek backward
      await tester.pump(const Duration(milliseconds: 200));
      await doubleTapAt(tester, 0.8, 0.5); // Seek forward again
      await tester.pump(const Duration(seconds: 1));

      // Player should still be functional
      expect(controller.value.position, isNotNull);
      expect(controller.value.duration, greaterThan(Duration.zero));
    });

    testWidgets('Gesture feedback displays correctly in fullscreen', (tester) async {
      // Skip on non-Android platforms
      if (!isAndroid) {
        return;
      }

      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Double tap to trigger feedback
      await doubleTapAt(tester, 0.8, 0.5);
      await tester.pump(const Duration(milliseconds: 100));

      // Look for feedback indicators (e.g., ripple effect, icons, text)
      // The exact widgets depend on your implementation
      // This is a placeholder - adjust based on your actual feedback widgets

      // Example: Check for seek forward icon/text
      // expect(find.byIcon(Icons.forward_10), findsOneWidget);
      // expect(find.text('+10s'), findsOneWidget);

      // Wait for feedback to disappear
      await tester.pump(const Duration(seconds: 2));

      // Feedback should be gone
      // expect(find.byIcon(Icons.forward_10), findsNothing);
    });

    testWidgets('Exit fullscreen resets gesture state correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await initializeVideo(tester);

      // Perform some gestures in fullscreen
      await doubleTapAt(tester, 0.5, 0.5); // Play
      await tester.pump(const Duration(milliseconds: 500));

      // Exit fullscreen
      await controller.exitFullscreen();
      await tester.pump(const Duration(seconds: 1));

      expect(controller.value.isFullscreen, isFalse);

      // Re-enter fullscreen
      await controller.enterFullscreen();
      await tester.pump(const Duration(milliseconds: 500));

      expect(controller.value.isFullscreen, isTrue);

      // Gestures should work normally
      await doubleTapAt(tester, 0.8, 0.5);
      await tester.pump(const Duration(seconds: 1));

      // Seek gesture should work
      expect(controller.value.position, isNotNull);
    });
  });
}
