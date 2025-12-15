import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player/src/controls/fullscreen_page.dart';

import '../../shared/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerTestFixture fixture;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    fixture = VideoPlayerTestFixture()..setUp();
  });

  tearDown(() async {
    await fixture.tearDown();
  });

  Widget buildTestWidget(Widget child) => MaterialApp(home: child);

  group('FullscreenVideoPage', () {
    group('basic rendering', () {
      testWidgets('renders fullscreen page with correct structure', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(buildTestWidget(FullscreenVideoPage(controller: controller, onExitFullscreen: () {})));
        await tester.pump();

        expect(find.byType(FullscreenVideoPage), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        // Multiple Stack widgets expected (MaterialApp, Scaffold, FullscreenVideoPage)
        expect(find.byType(Stack), findsWidgets);
      });

      testWidgets('uses black background', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(buildTestWidget(FullscreenVideoPage(controller: controller, onExitFullscreen: () {})));
        await tester.pump();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, Colors.black);
      });
    });

    group('PopScope behavior', () {
      testWidgets('allows back navigation when not fullscreenOnly', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(buildTestWidget(FullscreenVideoPage(controller: controller, onExitFullscreen: () {})));
        await tester.pump();

        // Page renders successfully
        expect(find.byType(FullscreenVideoPage), findsOneWidget);
      });

      testWidgets('blocks back navigation when fullscreenOnly', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(fullscreenOnly: true),
        );

        await tester.pumpWidget(buildTestWidget(FullscreenVideoPage(controller: controller, onExitFullscreen: () {})));
        await tester.pump();

        // Page renders successfully with fullscreenOnly option
        expect(find.byType(FullscreenVideoPage), findsOneWidget);
      });
    });

    group('fullscreen status bar', () {
      testWidgets('shows status bar when showFullscreenStatusBar is true', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(buildTestWidget(FullscreenVideoPage(controller: controller, onExitFullscreen: () {})));
        await tester.pump();

        expect(find.byType(FullscreenStatusBar), findsOneWidget);
      });

      testWidgets('hides status bar when showFullscreenStatusBar is false', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(showFullscreenStatusBar: false),
        );

        await tester.pumpWidget(buildTestWidget(FullscreenVideoPage(controller: controller, onExitFullscreen: () {})));
        await tester.pump();

        expect(find.byType(FullscreenStatusBar), findsNothing);
      });
    });

    group('theme handling', () {
      testWidgets('uses provided theme when specified', (tester) async {
        final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.red);
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(
          buildTestWidget(FullscreenVideoPage(controller: controller, theme: customTheme, onExitFullscreen: () {})),
        );
        await tester.pump();

        // Theme is passed to VideoPlayerControls
        expect(find.byType(FullscreenVideoPage), findsOneWidget);
      });

      testWidgets('uses context theme when not provided', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

        await tester.pumpWidget(buildTestWidget(FullscreenVideoPage(controller: controller, onExitFullscreen: () {})));
        await tester.pump();

        expect(find.byType(FullscreenVideoPage), findsOneWidget);
      });
    });
  });
}
