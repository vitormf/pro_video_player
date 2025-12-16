import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../../shared/test_constants.dart';

void main() {
  group('SeekPreviewProgressBar', () {
    late VideoPlayerTheme theme;

    setUp(() {
      theme = const VideoPlayerTheme();
    });

    Widget buildTestWidget(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

    group('construction', () {
      test('creates with required parameters', () {
        expect(
          () => SeekPreviewProgressBar(
            currentPosition: const Duration(seconds: 10),
            seekTargetPosition: const Duration(seconds: 20),
            duration: const Duration(seconds: 100),
            bufferedPosition: const Duration(seconds: 30),
            theme: theme,
          ),
          returnsNormally,
        );
      });

      test('has default values for optional parameters', () {
        const progressBar = SeekPreviewProgressBar(
          currentPosition: Duration(seconds: 10),
          seekTargetPosition: Duration(seconds: 20),
          duration: Duration(seconds: 100),
          bufferedPosition: Duration(seconds: 30),
          theme: VideoPlayerTheme(),
        );

        expect(progressBar.chapters, isEmpty);
        expect(progressBar.width, 280.0);
        expect(progressBar.height, 4.0);
      });

      test('accepts custom width and height', () {
        const progressBar = SeekPreviewProgressBar(
          currentPosition: Duration(seconds: 10),
          seekTargetPosition: Duration(seconds: 20),
          duration: Duration(seconds: 100),
          bufferedPosition: Duration(seconds: 30),
          theme: VideoPlayerTheme(),
          width: 320,
          height: 6,
        );

        expect(progressBar.width, 320.0);
        expect(progressBar.height, 6.0);
      });

      test('accepts chapters', () {
        final chapters = <Chapter>[
          const Chapter(id: 'chap-0', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 30)),
          const Chapter(
            id: 'chap-1',
            title: 'Chapter 2',
            startTime: Duration(seconds: 30),
            endTime: Duration(seconds: 60),
          ),
        ];

        final progressBar = SeekPreviewProgressBar(
          currentPosition: const Duration(seconds: 10),
          seekTargetPosition: const Duration(seconds: 40),
          duration: const Duration(seconds: 100),
          bufferedPosition: const Duration(seconds: 50),
          theme: theme,
          chapters: chapters,
        );

        expect(progressBar.chapters, hasLength(2));
        expect(progressBar.chapters[0].title, 'Chapter 1');
        expect(progressBar.chapters[1].title, 'Chapter 2');
      });
    });

    group('rendering', () {
      testWidgets('renders with valid duration', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 10),
              seekTargetPosition: const Duration(seconds: 20),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 30),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        // Should render a Container
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('renders nothing when duration is zero', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 10),
              seekTargetPosition: const Duration(seconds: 20),
              duration: Duration.zero,
              bufferedPosition: const Duration(seconds: 30),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        // Should render SizedBox.shrink when duration is zero
        expect(find.byType(SizedBox), findsOneWidget);
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.width, 0.0);
        expect(sizedBox.height, 0.0);
      });

      testWidgets('renders nothing when duration is negative', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 10),
              seekTargetPosition: const Duration(seconds: 20),
              duration: const Duration(seconds: -1),
              bufferedPosition: const Duration(seconds: 30),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        // Should render SizedBox.shrink when duration is negative
        expect(find.byType(SizedBox), findsOneWidget);
      });

      testWidgets('displays all visual components', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 10),
              seekTargetPosition: const Duration(seconds: 50),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 60),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        // Should have multiple containers for:
        // - Outer container
        // - Background track
        // - Buffered region
        // - Current position marker
        // - Seek target marker
        expect(find.byType(Container), findsWidgets);

        // Should have Stack widgets for layering (multiple from MaterialApp + widget)
        expect(find.byType(Stack), findsWidgets);
      });

      testWidgets('renders chapter markers when provided', (tester) async {
        final chapters = <Chapter>[
          const Chapter(id: 'chap-0', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 25)),
          const Chapter(
            id: 'chap-1',
            title: 'Chapter 2',
            startTime: Duration(seconds: 25),
            endTime: Duration(seconds: 50),
          ),
          const Chapter(
            id: 'chap-2',
            title: 'Chapter 3',
            startTime: Duration(seconds: 50),
            endTime: Duration(seconds: 100),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 10),
              seekTargetPosition: const Duration(seconds: 30),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 40),
              theme: theme,
              chapters: chapters,
            ),
          ),
        );
        await tester.pump();

        // Verify widget was built
        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });
    });

    group('position calculation', () {
      testWidgets('handles current position at start', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: Duration.zero,
              seekTargetPosition: const Duration(seconds: 50),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 60),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });

      testWidgets('handles current position at end', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 100),
              seekTargetPosition: const Duration(seconds: 50),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });

      testWidgets('handles seek target beyond duration', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 50),
              seekTargetPosition: const Duration(seconds: 150),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        // Should clamp to duration (no error)
        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });

      testWidgets('handles seek target before zero', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 50),
              seekTargetPosition: const Duration(seconds: -10),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 60),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        // Should clamp to zero (no error)
        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });

      testWidgets('handles buffered position beyond duration', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 50),
              seekTargetPosition: const Duration(seconds: 70),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 150),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        // Should clamp to duration (no error)
        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });
    });

    group('theme integration', () {
      testWidgets('uses theme colors for markers', (tester) async {
        const customTheme = VideoPlayerTheme(primaryColor: Colors.red, secondaryColor: Colors.blue);

        await tester.pumpWidget(
          buildTestWidget(
            const SeekPreviewProgressBar(
              currentPosition: Duration(seconds: 10),
              seekTargetPosition: Duration(seconds: 50),
              duration: Duration(seconds: 100),
              bufferedPosition: Duration(seconds: 60),
              theme: customTheme,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles all positions at zero', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: Duration.zero,
              seekTargetPosition: Duration.zero,
              duration: const Duration(seconds: 100),
              bufferedPosition: Duration.zero,
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });

      testWidgets('handles all positions at duration', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 100),
              seekTargetPosition: const Duration(seconds: 100),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });

      testWidgets('handles very short duration', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: TestDelays.eventPropagation,
              seekTargetPosition: TestDelays.stateUpdate,
              duration: const Duration(milliseconds: 200),
              bufferedPosition: TestDelays.controllerInitialization,
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });

      testWidgets('handles very long duration', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(hours: 1),
              seekTargetPosition: const Duration(hours: 2),
              duration: const Duration(hours: 3),
              bufferedPosition: const Duration(hours: 2, minutes: 30),
              theme: theme,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });

      testWidgets('handles many chapters', (tester) async {
        final chapters = List<Chapter>.generate(
          20,
          (i) => Chapter(
            id: 'chap-$i',
            title: 'Chapter ${i + 1}',
            startTime: Duration(seconds: i * 5),
            endTime: Duration(seconds: (i + 1) * 5),
          ),
        );

        await tester.pumpWidget(
          buildTestWidget(
            SeekPreviewProgressBar(
              currentPosition: const Duration(seconds: 10),
              seekTargetPosition: const Duration(seconds: 50),
              duration: const Duration(seconds: 100),
              bufferedPosition: const Duration(seconds: 60),
              theme: theme,
              chapters: chapters,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SeekPreviewProgressBar), findsOneWidget);
      });
    });
  });
}
