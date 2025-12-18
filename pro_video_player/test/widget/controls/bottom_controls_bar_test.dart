import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('BottomControlsBar', () {
    late ProVideoPlayerController controller;
    late VideoPlayerTheme theme;

    setUp(() {
      controller = ProVideoPlayerController();
      theme = VideoPlayerTheme.light();
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('renders progress bar', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      expect(find.byType(ProgressBar), findsOneWidget);
    });

    testWidgets('renders play/pause button when paused', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // Should show play button when paused (default state)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows skip buttons when enabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: true,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // Skip buttons use icons based on duration (10 seconds = replay_10 / forward_10)
      expect(find.byIcon(Icons.replay_10), findsOneWidget);
      expect(find.byIcon(Icons.forward_10), findsOneWidget);
    });

    testWidgets('hides skip buttons when disabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // Should not show skip buttons
      expect(find.byIcon(Icons.replay_10), findsNothing);
      expect(find.byIcon(Icons.forward_10), findsNothing);
    });

    testWidgets('displays time in correct format', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // Default value should show 0:00 for position and duration
      expect(find.text('0:00'), findsNWidgets(2));
    });

    testWidgets('shows remaining time when enabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: true,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // Should show negative time (remaining) - in this case -0:00
      expect(find.text('-0:00'), findsOneWidget);
    });

    testWidgets('calls onToggleTimeDisplay when time is tapped', (tester) async {
      var toggleCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {
              toggleCalled = true;
            },
          ),
        ),
      );

      // Find and tap the duration text (right side wrapped in GestureDetector)
      final gestureDetectors = find.byType(GestureDetector);
      // The last GestureDetector should be the time display
      await tester.tap(gestureDetectors.last);
      await tester.pump();

      expect(toggleCalled, isTrue);
    });

    testWidgets('uses custom skip duration for icons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: true,
            skipDuration: const Duration(seconds: 5),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // 5 seconds should use replay_5 / forward_5 icons
      expect(find.byIcon(Icons.replay_5), findsOneWidget);
      expect(find.byIcon(Icons.forward_5), findsOneWidget);
    });

    testWidgets('uses theme colors', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.red, secondaryColor: Colors.blue);

      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: customTheme,
            isFullscreen: true,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // Find the play button icon
      final playButton = tester.widget<Icon>(find.byIcon(Icons.play_arrow));
      expect(playButton.color, Colors.red);

      // Find time text widgets
      final timeTexts = tester.widgetList<Text>(find.text('0:00'));
      for (final text in timeTexts) {
        expect(text.style?.color, Colors.blue);
      }
    });

    testWidgets('applies theme padding in fullscreen', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(controlsPadding: const EdgeInsets.all(32));

      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: customTheme,
            isFullscreen: true,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // Find the Container with padding
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, const EdgeInsets.all(32));
    });

    testWidgets('uses reduced padding when not in fullscreen', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BottomControlsBar(
            controller: controller,
            theme: theme,
            isFullscreen: false,
            showRemainingTime: false,
            gestureSeekPosition: null,
            showSkipButtons: false,
            skipDuration: const Duration(seconds: 10),
            liveScrubbingMode: LiveScrubbingMode.adaptive,
            enableSeekBarHoverPreview: false,
            onDragStart: () {},
            onDragEnd: () {},
            onToggleTimeDisplay: () {},
          ),
        ),
      );

      // Find the Container with padding - should use reduced padding
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 6));
    });
  });
}
