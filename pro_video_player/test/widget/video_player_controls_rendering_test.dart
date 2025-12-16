import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../shared/test_constants.dart';
import '../shared/test_helpers.dart';

class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late StreamController<VideoPlayerEvent> eventController;

  setUpAll(() {
    registerFallbackValue(const VideoSource.network('https://example.com'));
    registerFallbackValue(const VideoPlayerOptions());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const PipOptions());
    registerFallbackValue(VideoScalingMode.fit);
    registerFallbackValue(VideoQualityTrack.auto);

    // Mock SystemChrome calls for fullscreen tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (methodCall) async => null,
    );
  });

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    eventController = StreamController<VideoPlayerEvent>.broadcast();
    ProVideoPlayerPlatform.instance = mockPlatform;

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
    when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
    when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});
    when(() => mockPlatform.setPlaybackSpeed(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);
    when(() => mockPlatform.enterPip(any(), options: any(named: 'options'))).thenAnswer((_) async => true);
    when(() => mockPlatform.isBackgroundPlaybackSupported()).thenAnswer((_) async => false);
    when(() => mockPlatform.isCastingSupported()).thenAnswer((_) async => false);
  });

  tearDown(() async {
    await eventController.close();
    ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
  });

  group('VideoPlayerControls', () {
    testWidgets('renders play button when paused', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      // Set state to paused
      eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('renders pause button when playing', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      // Set state to playing
      eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('calls play when play button is tapped', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(() => mockPlatform.play(1)).called(1);

      // Cancel the _startingPlaybackTimeout timer by calling pause
      await controller.pause();
    });

    testWidgets('calls pause when pause button is tapped', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      verify(() => mockPlatform.pause(1)).called(1);
    });

    testWidgets('displays current position and duration', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      eventController
        ..add(const DurationChangedEvent(TestMetadata.duration))
        ..add(const PositionChangedEvent(Duration(minutes: 2, seconds: 30)));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      expect(find.text('2:30'), findsOneWidget);
      expect(find.text('5:00'), findsOneWidget);
    });

    testWidgets('displays progress bar', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      eventController
        ..add(const DurationChangedEvent(TestMetadata.duration))
        ..add(const PositionChangedEvent(Duration(minutes: 1)));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      // The progress bar is a custom widget, not a Slider
      // Find the progress bar by looking for the container with the progress indicator
      expect(find.byType(FractionallySizedBox), findsWidgets);
    });

    testWidgets('seeks when progress bar is tapped', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      eventController
        ..add(const DurationChangedEvent(Duration(minutes: 10)))
        ..add(const PositionChangedEvent(Duration.zero));
      await tester.pump();

      // Find the ProgressBar widget specifically
      final progressBarFinder = find.byType(ProgressBar);
      expect(progressBarFinder, findsOneWidget);

      // Tap at the center of the progress bar
      await tester.tap(progressBarFinder);
      await tester.pump();

      verify(() => mockPlatform.seekTo(1, any())).called(1);
    });

    testWidgets('renders fullscreen button by default', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('does not render fullscreen button when showFullscreenButton is false', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      await tester.pumpWidget(
        buildTestWidget(
          VideoPlayerControls(
            controller: controller,
            showFullscreenButton: false,
            enableGestures: false,
            forceMobileLayout: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.fullscreen), findsNothing);
      expect(find.byIcon(Icons.fullscreen_exit), findsNothing);
    });

    testWidgets('calls onEnterFullscreen callback when fullscreen button is tapped', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      var enterFullscreenCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          VideoPlayerControls(
            controller: controller,
            enableGestures: false,
            forceMobileLayout: true,
            onEnterFullscreen: () => enterFullscreenCalled = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pump();

      expect(enterFullscreenCalled, isTrue);
    });

    testWidgets('shows fullscreen_exit icon when in fullscreen', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      eventController.add(const FullscreenStateChangedEvent(isFullscreen: true));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
    });

    testWidgets('calls onExitFullscreen callback when fullscreen_exit button is tapped', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      eventController.add(const FullscreenStateChangedEvent(isFullscreen: true));
      await tester.pump();

      var exitFullscreenCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          VideoPlayerControls(
            controller: controller,
            enableGestures: false,
            forceMobileLayout: true,
            onExitFullscreen: () => exitFullscreenCalled = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.fullscreen_exit));
      await tester.pump();

      expect(exitFullscreenCalled, isTrue);
    });

    testWidgets('shows loading indicator when buffering', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.buffering));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders play button when completed', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.completed));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      // When completed, the play button is shown (not isPlaying)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('calls play when play button is tapped after completion', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      eventController.add(const PlaybackStateChangedEvent(PlaybackState.completed));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
      );

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(() => mockPlatform.play(1)).called(1);

      // Cancel the _startingPlaybackTimeout timer by calling pause
      await controller.pause();
    });

    group('customization', () {
      testWidgets('uses theme colors from VideoPlayerThemeData', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        final customTheme = VideoPlayerTheme.light();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoPlayerThemeData(
                theme: customTheme,
                child: VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true),
              ),
            ),
          ),
        );

        expect(find.byType(VideoPlayerControls), findsOneWidget);
      });

      testWidgets('uses theme icon size', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        final customTheme = const VideoPlayerTheme().copyWith(iconSize: 48);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoPlayerThemeData(
                theme: customTheme,
                child: VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true),
              ),
            ),
          ),
        );

        expect(find.byType(VideoPlayerControls), findsOneWidget);
      });
    });
  });
}
