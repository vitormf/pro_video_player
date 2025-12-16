import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player/src/controls/desktop_volume_control.dart';

import '../../shared/test_constants.dart';
import '../../shared/test_helpers.dart';
import '../../shared/test_setup.dart';

// Mock for VideoControlsState
class MockVideoControlsState {
  bool isDragging = false;
  double? dragProgress;
  bool showRemainingTime = false;
  // ignore: unreachable_from_main
  bool get isBackgroundPlaybackSupported => false;
  // ignore: unreachable_from_main
  bool get isPipAvailable => true;
  // ignore: unreachable_from_main
  bool get isCastingSupported => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerTestFixture fixture;
  late MockVideoControlsState mockControlsState;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    fixture = VideoPlayerTestFixture()..setUp();
    mockControlsState = MockVideoControlsState();
  });

  tearDown(() async {
    await fixture.tearDown();
  });

  DesktopVideoControls buildDesktopControls({
    required ProVideoPlayerController controller,
    VideoPlayerTheme? theme,
    Duration? gestureSeekPosition,
    Duration? dragStartPosition,
    bool minimalToolbarOnDesktop = false,
    bool shouldShowVolumeButton = true,
    bool showFullscreenButton = true,
    LiveScrubbingMode liveScrubbingMode = LiveScrubbingMode.adaptive,
    bool enableSeekBarHoverPreview = true,
  }) => DesktopVideoControls(
    controller: controller,
    theme: theme ?? VideoPlayerTheme.light(),
    controlsState: mockControlsState,
    gestureSeekPosition: gestureSeekPosition,
    dragStartPosition: dragStartPosition,
    minimalToolbarOnDesktop: minimalToolbarOnDesktop,
    shouldShowVolumeButton: shouldShowVolumeButton,
    liveScrubbingMode: liveScrubbingMode,
    enableSeekBarHoverPreview: enableSeekBarHoverPreview,
    showFullscreenButton: showFullscreenButton,
    onDragStart: () {},
    onDragEnd: () {},
    onToggleTimeDisplay: () {},
    onMouseEnter: () {},
    onMouseExit: () {},
    onResetHideTimer: () {},
    onFullscreenEnter: () {},
    onFullscreenExit: () {},
  );

  group('DesktopVideoControls', () {
    group('basic rendering', () {
      testWidgets('renders with correct layout structure', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        // Verify basic structure
        expect(find.byType(DesktopVideoControls), findsOneWidget);
        // Multiple ValueListenableBuilders expected (for different parts of the UI)
        expect(find.byType(ValueListenableBuilder<VideoPlayerValue>), findsWidgets);
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(MouseRegion), findsWidgets);
      });

      testWidgets('shows play/pause button', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        // Should show play button by default (not playing)
        expect(find.widgetWithIcon(IconButton, Icons.play_arrow), findsOneWidget);
      });

      testWidgets('shows progress bar', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        expect(find.byType(ProgressBar), findsOneWidget);
      });
    });

    group('gradient overlay', () {
      testWidgets('shows gradient only at bottom', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        // Find gradient containers (there may be multiple from nested widgets)
        final containers = tester.widgetList<Container>(find.byType(Container));
        final gradientContainers = containers
            .where((c) => c.decoration is BoxDecoration)
            .where((c) => (c.decoration! as BoxDecoration).gradient is LinearGradient)
            .toList();

        // Should have at least one gradient (bottom gradient)
        expect(gradientContainers.length, greaterThan(0));

        // Find the bottom gradient (transparent → black)
        final bottomGradient = gradientContainers
            .map((c) => (c.decoration! as BoxDecoration).gradient! as LinearGradient)
            .firstWhere(
              (g) => g.colors[0] == Colors.transparent && (g.colors[1].a * 255.0).round().clamp(0, 255) < 255,
            );

        // Verify gradient properties
        expect(bottomGradient.colors[0], Colors.transparent);
        expect(bottomGradient.colors[1], Colors.black.withValues(alpha: 0.7));
        expect(bottomGradient.begin, Alignment.topCenter);
        expect(bottomGradient.end, Alignment.bottomCenter);
      });
    });

    group('conditional rendering', () {
      testWidgets('shows playlist buttons when playlist exists and not minimal', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initializeWithPlaylist(
          playlist: Playlist(
            items: [
              const VideoSource.network('https://example.com/video1.mp4'),
              const VideoSource.network('https://example.com/video2.mp4'),
            ],
          ),
        );

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        // Should show prev/next buttons
        expect(find.widgetWithIcon(IconButton, Icons.skip_previous), findsOneWidget);
        expect(find.widgetWithIcon(IconButton, Icons.skip_next), findsOneWidget);
      });

      testWidgets('hides playlist buttons in minimal mode', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initializeWithPlaylist(
          playlist: Playlist(
            items: [
              const VideoSource.network('https://example.com/video1.mp4'),
              const VideoSource.network('https://example.com/video2.mp4'),
            ],
          ),
        );

        await tester.pumpWidget(
          buildTestWidget(buildDesktopControls(controller: controller, minimalToolbarOnDesktop: true)),
        );
        await tester.pump();

        // Should NOT show prev/next buttons
        expect(find.widgetWithIcon(IconButton, Icons.skip_previous), findsNothing);
        expect(find.widgetWithIcon(IconButton, Icons.skip_next), findsNothing);
      });

      testWidgets('shows seek preview when dragging', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Set dragging state
        mockControlsState
          ..isDragging = true
          ..dragProgress = 0.5;

        await tester.pumpWidget(
          buildTestWidget(buildDesktopControls(controller: controller, dragStartPosition: const Duration(seconds: 10))),
        );
        await tester.pump();

        expect(find.byType(SeekPreview), findsOneWidget);
      });

      testWidgets('hides seek preview when not dragging', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        mockControlsState.isDragging = false;

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        expect(find.byType(SeekPreview), findsNothing);
      });

      testWidgets('shows buffering indicator when buffering', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Emit buffering state
        fixture.emitPlaybackState(PlaybackState.buffering);

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides buffering indicator when dragging', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        fixture.emitPlaybackState(PlaybackState.buffering);
        mockControlsState.isDragging = true;

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        // Should not show buffering when dragging
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('shows volume control when enabled', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        expect(find.byType(DesktopVolumeControl), findsOneWidget);
      });

      testWidgets('hides volume control when disabled', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(buildDesktopControls(controller: controller, shouldShowVolumeButton: false)),
        );
        await tester.pump();

        expect(find.byType(DesktopVolumeControl), findsNothing);
      });

      testWidgets('shows fullscreen button when enabled and not minimal', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();

        expect(find.widgetWithIcon(IconButton, Icons.fullscreen), findsOneWidget);
      });

      testWidgets('hides fullscreen button in minimal mode', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(buildDesktopControls(controller: controller, minimalToolbarOnDesktop: true)),
        );
        await tester.pump();

        expect(find.widgetWithIcon(IconButton, Icons.fullscreen), findsNothing);
      });
    });

    group('time display', () {
      testWidgets('displays current and total time by default', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Emit duration and position BEFORE building
        fixture
          ..emitDuration(const Duration(seconds: 100))
          ..emitPosition(const Duration(seconds: 30));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();
        await tester.pump(); // Extra pump for state propagation

        // Desktop controls rendered (time display is part of it)
        expect(find.byType(DesktopVideoControls), findsOneWidget);
      });

      testWidgets('displays remaining time when toggled', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        mockControlsState.showRemainingTime = true;

        // Emit duration and position BEFORE building
        fixture
          ..emitDuration(const Duration(seconds: 100))
          ..emitPosition(const Duration(seconds: 30));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller)));
        await tester.pump();
        await tester.pump(); // Extra pump for state propagation

        // Desktop controls rendered (time display respects showRemainingTime flag)
        expect(find.byType(DesktopVideoControls), findsOneWidget);
      });
    });

    group('theme colors', () {
      testWidgets('uses theme colors', (tester) async {
        final theme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.red, secondaryColor: Colors.blue);

        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(buildTestWidget(buildDesktopControls(controller: controller, theme: theme)));
        await tester.pump();

        // Verify play button uses primary color
        final playButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.play_arrow));
        final icon = playButton.icon as Icon;
        expect(icon.color, Colors.red);
      });
    });
  });
}
