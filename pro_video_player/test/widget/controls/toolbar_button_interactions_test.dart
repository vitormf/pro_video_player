import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../../shared/test_setup.dart';

/// Tests for toolbar button interactions through gesture detectors.
///
/// These tests verify that toolbar buttons can receive taps even when
/// wrapped in gesture detectors (mobile or desktop wrappers).
///
/// CRITICAL: These tests prevent regression of the bug where gesture detectors
/// with HitTestBehavior.opaque blocked all toolbar button taps.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerTestFixture fixture;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    fixture = VideoPlayerTestFixture()..setUp();
  });

  tearDown(() => fixture.tearDown());

  //Note: Real PlayerToolbar tests are in E2E tests (integration_test/mobile_toolbar_buttons_test.dart)
  // because PlayerToolbar has complex conditional rendering that requires full integration testing.

  group('Mobile Toolbar Button Interactions (VideoPlayerGestureDetector)', () {
    /// Helper to build a mobile video player with toolbar inside gesture detector
    Widget buildMobilePlayerWithToolbar({
      required ProVideoPlayerController controller,
      bool showPipButton = true,
      bool showSubtitleButton = true,
      bool showQualityButton = true,
      bool showSpeedButton = true,
      VoidCallback? onPipTap,
      VoidCallback? onSubtitleTap,
      VoidCallback? onQualityTap,
      VoidCallback? onSpeedTap,
    }) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: VideoPlayerGestureDetector(
            controller: controller,
            child: Stack(
              children: [
                // Video player
                Container(color: Colors.black),

                // Toolbar at top (inside gesture detection area)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        if (showPipButton)
                          IconButton(
                            key: const Key('test_pip_button'),
                            icon: const Icon(Icons.picture_in_picture),
                            onPressed: onPipTap,
                          ),
                        if (showSubtitleButton)
                          IconButton(
                            key: const Key('test_subtitle_button'),
                            icon: const Icon(Icons.closed_caption),
                            onPressed: onSubtitleTap,
                          ),
                        if (showQualityButton)
                          IconButton(
                            key: const Key('test_quality_button'),
                            icon: const Icon(Icons.settings),
                            onPressed: onQualityTap,
                          ),
                        if (showSpeedButton)
                          IconButton(
                            key: const Key('test_speed_button'),
                            icon: const Icon(Icons.speed),
                            onPressed: onSpeedTap,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('PiP button receives tap through gesture detector', (tester) async {
      await fixture.initializeController();

      var pipTapped = false;

      await fixture.renderWidget(
        tester,
        buildMobilePlayerWithToolbar(controller: fixture.controller, onPipTap: () => pipTapped = true),
      );

      // Find and tap the PiP button
      final pipButton = find.byKey(const Key('test_pip_button'));
      expect(pipButton, findsOneWidget);

      await tester.tap(pipButton);
      await tester.pump();

      // Button should have received the tap
      expect(pipTapped, isTrue, reason: 'PiP button should receive tap through gesture detector');
    });

    testWidgets('subtitle button receives tap through gesture detector', (tester) async {
      await fixture.initializeController();

      var subtitleTapped = false;

      await fixture.renderWidget(
        tester,
        buildMobilePlayerWithToolbar(controller: fixture.controller, onSubtitleTap: () => subtitleTapped = true),
      );

      final subtitleButton = find.byKey(const Key('test_subtitle_button'));
      expect(subtitleButton, findsOneWidget);

      await tester.tap(subtitleButton);
      await tester.pump();

      expect(subtitleTapped, isTrue, reason: 'Subtitle button should receive tap');
    });

    testWidgets('quality button receives tap through gesture detector', (tester) async {
      await fixture.initializeController();

      var qualityTapped = false;

      await fixture.renderWidget(
        tester,
        buildMobilePlayerWithToolbar(controller: fixture.controller, onQualityTap: () => qualityTapped = true),
      );

      final qualityButton = find.byKey(const Key('test_quality_button'));
      expect(qualityButton, findsOneWidget);

      await tester.tap(qualityButton);
      await tester.pump();

      expect(qualityTapped, isTrue, reason: 'Quality button should receive tap');
    });

    testWidgets('speed button receives tap through gesture detector', (tester) async {
      await fixture.initializeController();

      var speedTapped = false;

      await fixture.renderWidget(
        tester,
        buildMobilePlayerWithToolbar(controller: fixture.controller, onSpeedTap: () => speedTapped = true),
      );

      final speedButton = find.byKey(const Key('test_speed_button'));
      expect(speedButton, findsOneWidget);

      await tester.tap(speedButton);
      await tester.pump();

      expect(speedTapped, isTrue, reason: 'Speed button should receive tap');
    });

    testWidgets('multiple toolbar buttons can be tapped independently', (tester) async {
      await fixture.initializeController();

      var pipTapped = false;
      var subtitleTapped = false;
      var qualityTapped = false;

      await fixture.renderWidget(
        tester,
        buildMobilePlayerWithToolbar(
          controller: fixture.controller,
          onPipTap: () => pipTapped = true,
          onSubtitleTap: () => subtitleTapped = true,
          onQualityTap: () => qualityTapped = true,
        ),
      );

      // Tap each button
      await tester.tap(find.byKey(const Key('test_pip_button')));
      await tester.pump();
      expect(pipTapped, isTrue);

      await tester.tap(find.byKey(const Key('test_subtitle_button')));
      await tester.pump();
      expect(subtitleTapped, isTrue);

      await tester.tap(find.byKey(const Key('test_quality_button')));
      await tester.pump();
      expect(qualityTapped, isTrue);
    });

    testWidgets('toolbar button tap does not trigger gesture detector single tap', (tester) async {
      await fixture.initializeController();

      var pipTapped = false;
      var controlsToggled = false;

      await fixture.renderWidget(
        tester,
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: VideoPlayerGestureDetector(
                controller: fixture.controller,
                onControlsVisibilityChanged: (visible, {instantly = false}) {
                  controlsToggled = true;
                },
                child: Stack(
                  children: [
                    Container(color: Colors.black),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IconButton(
                        key: const Key('test_pip_button'),
                        icon: const Icon(Icons.picture_in_picture),
                        onPressed: () => pipTapped = true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Tap toolbar button
      await tester.tap(find.byKey(const Key('test_pip_button')));
      await tester.pump();

      // Wait for single-tap timeout (300ms for double-tap detection)
      await tester.pump(const Duration(milliseconds: 400));

      // Button should receive tap
      expect(pipTapped, isTrue, reason: 'Button should receive tap');

      // Controls should NOT toggle (button consumed the tap)
      expect(controlsToggled, isFalse, reason: 'Controls should not toggle when tapping toolbar button');
    });

    testWidgets('gesture detector still detects swipes when toolbar exists', (tester) async {
      await fixture.initializeController();

      var controlsVisibilityChanged = false;

      await fixture.renderWidget(
        tester,
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: VideoPlayerGestureDetector(
                controller: fixture.controller,
                onControlsVisibilityChanged: (visible, {instantly = false}) {
                  controlsVisibilityChanged = true;
                },
                child: Stack(
                  children: [
                    Container(color: const Color(0x01000000)), // Hit-testable background
                    // Toolbar at top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        color: Colors.black54,
                        child: IconButton(
                          key: const Key('test_pip_button'),
                          icon: const Icon(Icons.picture_in_picture),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Find an area outside toolbar buttons (center of screen, below toolbar)
      final gestureArea = tester.getCenter(find.byType(VideoPlayerGestureDetector));

      // Single tap outside toolbar should trigger controls toggle
      await tester.tapAt(gestureArea);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // Wait for single-tap timeout

      // Controls visibility callback should have been triggered
      expect(controlsVisibilityChanged, isTrue, reason: 'Gestures should still work outside toolbar buttons');
    });
  });

  group('Desktop Toolbar Button Interactions (DesktopControlsWrapper)', () {
    testWidgets('toolbar buttons work with desktop wrapper tap handler', (tester) async {
      // This test verifies the fix for HitTestBehavior.deferToChild in DesktopControlsWrapper
      await fixture.initializeController();

      var buttonTapped = false;

      await fixture.renderWidget(
        tester,
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: GestureDetector(
                // Simulates DesktopControlsWrapper's tap behavior
                behavior: HitTestBehavior.deferToChild,
                onTap: () {
                  // Play/pause handler
                },
                child: Stack(
                  children: [
                    Container(color: Colors.black),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        key: const Key('test_toolbar_button'),
                        icon: const Icon(Icons.settings),
                        onPressed: () => buttonTapped = true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final button = find.byKey(const Key('test_toolbar_button'));
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      expect(buttonTapped, isTrue, reason: 'Toolbar button should work with deferToChild behavior');
    });

    testWidgets('desktop wrapper still allows video area taps when using deferToChild', (tester) async {
      await fixture.initializeController();

      var videoAreaTapped = false;

      await fixture.renderWidget(
        tester,
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onTap: () => videoAreaTapped = true,
                child: Stack(
                  children: [
                    // Video area (hit-testable container)
                    Container(
                      key: const Key('video_area'),
                      color: const Color(0x01000000), // Almost transparent but hit-testable
                    ),
                    // Toolbar at top
                    Positioned(top: 0, left: 0, right: 0, child: Container(height: 50, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Tap in the middle of the video area (not on toolbar)
      final videoArea = find.byKey(const Key('video_area'));
      await tester.tap(videoArea);
      await tester.pump();

      expect(videoAreaTapped, isTrue, reason: 'Video area taps should still work with deferToChild');
    });
  });
}
