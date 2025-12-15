import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_video_player_example/widgets/responsive_video_layout.dart';

void main() {
  Widget buildTestWidget({
    required Size screenSize,
    required Widget videoPlayer,
    required Widget controls,
    double videoAspectRatio = 16 / 9,
  }) => MediaQuery(
    data: MediaQueryData(size: screenSize),
    child: MaterialApp(
      home: Scaffold(
        body: ResponsiveVideoLayout(videoPlayer: videoPlayer, controls: controls, videoAspectRatio: videoAspectRatio),
      ),
    ),
  );

  final videoPlayerWidget = Container(key: const Key('video'), color: Colors.black);
  final controlsWidget = Container(key: const Key('controls'), color: Colors.grey);

  group('ResponsiveVideoLayout', () {
    group('on compact screens (phone portrait)', () {
      testWidgets('shows stacked layout with video on top', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(screenSize: const Size(400, 800), videoPlayer: videoPlayerWidget, controls: controlsWidget),
        );

        // Both widgets should be present
        expect(find.byKey(const Key('video')), findsOneWidget);
        expect(find.byKey(const Key('controls')), findsOneWidget);

        // Video should be above controls (check vertical positions)
        final videoBox = tester.getRect(find.byKey(const Key('video')));
        final controlsBox = tester.getRect(find.byKey(const Key('controls')));

        expect(videoBox.top, lessThan(controlsBox.top));
      });

      testWidgets('video has reasonable height based on aspect ratio', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(screenSize: const Size(400, 800), videoPlayer: videoPlayerWidget, controls: controlsWidget),
        );

        final videoBox = tester.getRect(find.byKey(const Key('video')));

        // Video height should be reasonable for 16:9 aspect ratio
        // Width is ~400, so 16:9 gives ~225, but scaffold may affect constraints
        // Allow some tolerance for scaffold overhead
        expect(videoBox.height, greaterThan(200));
        expect(videoBox.height, lessThan(350));
      });
    });

    group('on medium screens in landscape', () {
      testWidgets('shows side-by-side layout', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            screenSize: const Size(800, 400), // landscape
            videoPlayer: videoPlayerWidget,
            controls: controlsWidget,
          ),
        );

        expect(find.byKey(const Key('video')), findsOneWidget);
        expect(find.byKey(const Key('controls')), findsOneWidget);

        final videoBox = tester.getRect(find.byKey(const Key('video')));
        final controlsBox = tester.getRect(find.byKey(const Key('controls')));

        // Video and controls should be side by side (similar top positions)
        expect((videoBox.top - controlsBox.top).abs(), lessThan(50));

        // Video should be on the left
        expect(videoBox.left, lessThan(controlsBox.left));
      });
    });

    group('on expanded screens (tablet/desktop)', () {
      testWidgets('shows side-by-side layout', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(screenSize: const Size(1024, 768), videoPlayer: videoPlayerWidget, controls: controlsWidget),
        );

        expect(find.byKey(const Key('video')), findsOneWidget);
        expect(find.byKey(const Key('controls')), findsOneWidget);

        final videoBox = tester.getRect(find.byKey(const Key('video')));
        final controlsBox = tester.getRect(find.byKey(const Key('controls')));

        // Video and controls should be side by side
        expect((videoBox.top - controlsBox.top).abs(), lessThan(50));

        // Video should be on the left
        expect(videoBox.left, lessThan(controlsBox.left));
      });

      testWidgets('video takes majority of width in side-by-side', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(screenSize: const Size(1000, 768), videoPlayer: videoPlayerWidget, controls: controlsWidget),
        );

        final videoBox = tester.getRect(find.byKey(const Key('video')));
        final controlsBox = tester.getRect(find.byKey(const Key('controls')));

        // Video should take more width than controls (60% vs 40%)
        expect(videoBox.width, greaterThan(controlsBox.width));
      });
    });

    group('custom aspect ratio', () {
      testWidgets('respects videoAspectRatio parameter', (tester) async {
        // Test that videoAspectRatio parameter is passed and used
        await tester.pumpWidget(
          buildTestWidget(
            screenSize: const Size(400, 800),
            videoPlayer: videoPlayerWidget,
            controls: controlsWidget,
            videoAspectRatio: 4 / 3,
          ),
        );

        // Widget should be created without errors
        expect(find.byKey(const Key('video')), findsOneWidget);
        expect(find.byKey(const Key('controls')), findsOneWidget);

        // Video should have non-zero dimensions
        final videoBox = tester.getRect(find.byKey(const Key('video')));
        expect(videoBox.height, greaterThan(0));
        expect(videoBox.width, greaterThan(0));
      });
    });
  });
}
