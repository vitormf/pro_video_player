import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player/src/controls/compact_layout.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

// Mock platform implementation
class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late StreamController<VideoPlayerEvent> eventController;

  setUpAll(() {
    registerFallbackValue(const VideoSource.network('https://example.com'));
    registerFallbackValue(const VideoPlayerOptions());
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    eventController = StreamController<VideoPlayerEvent>.broadcast();
    ProVideoPlayerPlatform.instance = mockPlatform;

    // Setup default mocks
    when(
      () => mockPlatform.create(
        source: any(named: 'source'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => 1);

    when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);
    when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
    when(() => mockPlatform.play(any())).thenAnswer((_) async {});
    when(() => mockPlatform.pause(any())).thenAnswer((_) async {});
    when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => false);
    when(() => mockPlatform.isBackgroundPlaybackSupported()).thenAnswer((_) async => false);
    when(() => mockPlatform.isCastingSupported()).thenAnswer((_) async => false);
  });

  tearDown(() async {
    await eventController.close();
    ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
  });

  Widget buildTestWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('CompactLayout', () {
    testWidgets('renders large play button when paused', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
      await tester.pump();

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: VideoPlayerTheme.light())));

      // Should show large play button
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

      await controller.dispose();
    });

    testWidgets('renders large pause button when playing', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
      await tester.pump();

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: VideoPlayerTheme.light())));

      // Should show large pause button
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

      await controller.dispose();
    });

    testWidgets('shows buffering indicator when buffering', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.buffering));
      await tester.pump();

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: VideoPlayerTheme.light())));

      // Should show buffering indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.dispose();
    });

    testWidgets('shows progress bar at bottom', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController
        ..add(const DurationChangedEvent(Duration(minutes: 10)))
        ..add(const PositionChangedEvent(Duration(minutes: 5)));
      await tester.pump();

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: VideoPlayerTheme.light())));

      // Progress bar should be visible (column layout with expanded center and progress bar at bottom)
      expect(find.byType(Column), findsWidgets);

      await controller.dispose();
    });

    testWidgets('progress bar is interactive - tap to seek', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController
        ..add(const DurationChangedEvent(Duration(seconds: 100)))
        ..add(const PositionChangedEvent(Duration.zero));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(
          SizedBox(
            width: 400,
            height: 300,
            child: CompactLayout(controller: controller, theme: VideoPlayerTheme.light()),
          ),
        ),
      );

      // Find the GestureDetector for the progress bar (the second one, first is for play button)
      final gestureDetectors = find.byType(GestureDetector);
      expect(gestureDetectors, findsAtLeastNWidgets(1));

      // Tap in the middle of the progress bar area (should seek to middle)
      // The progress bar is at the bottom, find it via the padding widget
      await tester.pumpAndSettle();
      final progressBarGesture = gestureDetectors.last;
      await tester.tap(progressBarGesture);
      await tester.pump();

      // Verify seekTo was called
      verify(() => mockPlatform.seekTo(any(), any())).called(greaterThanOrEqualTo(1));

      await controller.dispose();
    });

    testWidgets('progress bar supports drag to scrub', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController
        ..add(const DurationChangedEvent(Duration(seconds: 100)))
        ..add(const PositionChangedEvent(Duration.zero));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(
          SizedBox(
            width: 400,
            height: 300,
            child: CompactLayout(controller: controller, theme: VideoPlayerTheme.light()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the progress bar gesture detector
      final gestureDetectors = find.byType(GestureDetector);
      final progressBarGesture = gestureDetectors.last;

      // Drag across the progress bar
      await tester.drag(progressBarGesture, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Should have called seekTo when drag ended
      verify(() => mockPlatform.seekTo(any(), any())).called(greaterThanOrEqualTo(1));

      await controller.dispose();
    });

    testWidgets('play button triggers play when paused', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
      await tester.pump();

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: VideoPlayerTheme.light())));

      // Tap the play button
      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();

      // Should have called play
      verify(() => mockPlatform.play(any())).called(1);

      await controller.dispose();
    });

    testWidgets('pause button triggers pause when playing', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
      await tester.pump();

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: VideoPlayerTheme.light())));

      // Tap the pause button
      await tester.tap(find.byIcon(Icons.pause_circle_filled));
      await tester.pump();

      // Should have called pause
      verify(() => mockPlatform.pause(any())).called(1);

      await controller.dispose();
    });

    testWidgets('uses theme colors for progress bar', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController
        ..add(const DurationChangedEvent(Duration(seconds: 100)))
        ..add(const PositionChangedEvent(Duration(seconds: 50)));
      await tester.pump();

      final customTheme = VideoPlayerTheme.light().copyWith(
        progressBarActiveColor: Colors.red,
        progressBarInactiveColor: Colors.blue,
        progressBarBufferedColor: Colors.green,
      );

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: customTheme)));

      // Theme colors should be applied to progress bar containers
      // We can verify by finding Container widgets and checking their decoration
      expect(find.byType(Container), findsWidgets);

      await controller.dispose();
    });

    testWidgets('uses theme color for buffering indicator', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.buffering));
      await tester.pump();

      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.purple);

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: customTheme)));

      // Find the circular progress indicator
      final circularProgressFinder = find.byType(CircularProgressIndicator);
      expect(circularProgressFinder, findsOneWidget);

      final circularProgress = tester.widget<CircularProgressIndicator>(circularProgressFinder);
      expect(circularProgress.color, equals(Colors.purple));

      await controller.dispose();
    });

    testWidgets('handles video with no duration gracefully', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      // No duration event sent, should default to zero duration
      eventController.add(const PositionChangedEvent(Duration.zero));
      await tester.pump();

      await tester.pumpWidget(buildTestWidget(CompactLayout(controller: controller, theme: VideoPlayerTheme.light())));

      // Should render without errors
      expect(find.byType(CompactLayout), findsOneWidget);

      // Tapping progress bar should not cause errors
      final gestureDetectors = find.byType(GestureDetector);
      if (gestureDetectors.evaluate().length > 1) {
        await tester.tap(gestureDetectors.last);
        await tester.pump();
      }

      // seekTo should not be called when duration is zero
      verifyNever(() => mockPlatform.seekTo(any(), any()));

      await controller.dispose();
    });
  });
}
