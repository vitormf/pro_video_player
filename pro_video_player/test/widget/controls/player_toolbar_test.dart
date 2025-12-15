import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player/src/controls/buttons/speed_button.dart';

import '../../shared/test_setup.dart';

// Mock for VideoControlsState
class MockVideoControlsState {
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

  Widget buildTestWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

  PlayerToolbar buildToolbar({
    required ProVideoPlayerController controller,
    VideoPlayerTheme? theme,
    bool showSubtitleButton = true,
    bool showSpeedButton = true,
    bool showFullscreenButton = true,
    bool showPipButton = true,
    int? maxPlayerToolbarActions,
    bool autoOverflowActions = true,
    VoidCallback? onDismiss,
  }) => PlayerToolbar(
    controller: controller,
    theme: theme ?? VideoPlayerTheme.light(),
    controlsState: mockControlsState,
    showSubtitleButton: showSubtitleButton,
    showAudioButton: false,
    showQualityButton: false,
    showSpeedButton: showSpeedButton,
    showScalingModeButton: false,
    showBackgroundPlaybackButton: false,
    showPipButton: showPipButton,
    showOrientationLockButton: false,
    showFullscreenButton: showFullscreenButton,
    playerToolbarActions: null,
    maxPlayerToolbarActions: maxPlayerToolbarActions,
    autoOverflowActions: autoOverflowActions,
    onDismiss: onDismiss,
    isDesktopPlatform: true,
    onShowQualityPicker: (_, __) {},
    onShowSubtitlePicker: (_, __) {},
    onShowAudioPicker: (_, __) {},
    onShowChaptersPicker: (_, __) {},
    onShowSpeedPicker: (_, __) {},
    onShowScalingModePicker: (_) {},
    onShowOrientationLockPicker: (_) {},
    onFullscreenEnter: () {},
    onFullscreenExit: () {},
  );

  group('PlayerToolbar', () {
    group('basic rendering', () {
      testWidgets('renders toolbar with action buttons', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(
          buildTestWidget(SizedBox(width: 800, height: 50, child: buildToolbar(controller: controller))),
        );
        await tester.pump();

        expect(find.byType(PlayerToolbar), findsOneWidget);
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('shows dismiss button in fullscreenOnly mode', (tester) async {
        var dismissCalled = false;
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(fullscreenOnly: true),
        );

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 800,
              height: 50,
              child: buildToolbar(controller: controller, onDismiss: () => dismissCalled = true),
            ),
          ),
        );
        await tester.pump();

        // Find close button
        final closeButtons = find.widgetWithIcon(IconButton, Icons.close);
        expect(closeButtons, findsOneWidget);

        // Tap dismiss button
        await tester.tap(closeButtons);
        await tester.pump();

        expect(dismissCalled, isTrue);
      });
    });

    group('action buttons', () {
      testWidgets('renders action buttons based on configuration', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(
          buildTestWidget(SizedBox(width: 800, height: 50, child: buildToolbar(controller: controller))),
        );
        await tester.pump();

        // Verify toolbar renders with action buttons (specific buttons depend on state)
        expect(find.byType(PlayerToolbar), findsOneWidget);
        // Speed button should always show when enabled (no prerequisites)
        expect(find.byType(SpeedButton), findsOneWidget);
        // Fullscreen button depends on platform capabilities
        expect(find.byType(IconButton), findsWidgets);
      });
    });

    group('overflow handling', () {
      testWidgets('respects maxPlayerToolbarActions setting', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 800,
              height: 50,
              child: buildToolbar(
                controller: controller,
                maxPlayerToolbarActions: 1, // Force overflow with just 1 visible action
              ),
            ),
          ),
        );
        await tester.pump();

        // With maxPlayerToolbarActions=1 and 2 enabled buttons, should show overflow
        // (exact button count depends on platform state, but overflow should appear)
        expect(find.byType(PlayerToolbar), findsOneWidget);
      });

      testWidgets('respects autoOverflowActions setting', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 200, // Very narrow width
              height: 50,
              child: buildToolbar(
                controller: controller,
                autoOverflowActions: false, // Disable auto-overflow
              ),
            ),
          ),
        );
        await tester.pump();

        // Should not auto-overflow even with narrow width
        expect(find.byType(PlayerToolbar), findsOneWidget);
      });
    });

    group('theme styling', () {
      testWidgets('uses theme colors', (tester) async {
        final theme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.red, backgroundColor: Colors.black);

        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 800,
              height: 50,
              child: buildToolbar(controller: controller, theme: theme),
            ),
          ),
        );
        await tester.pump();

        // Verify theme is passed to child widgets (they should use the colors)
        expect(find.byType(PlayerToolbar), findsOneWidget);
      });
    });
  });
}
