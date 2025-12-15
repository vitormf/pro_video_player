import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

void main() {
  group('SeekPreview', () {
    late VideoPlayerTheme theme;

    setUp(() {
      theme = VideoPlayerTheme.light();
    });

    testWidgets('displays target position and forward difference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 0.5,
              dragStartPosition: const Duration(seconds: 10),
              duration: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        ),
      );

      // Target position: 50 seconds (0.5 * 100)
      expect(find.text('0:50'), findsOneWidget);
      // Difference: +40 seconds (50 - 10)
      expect(find.text('+0:40'), findsOneWidget);
      expect(find.byIcon(Icons.fast_forward), findsOneWidget);
    });

    testWidgets('displays target position and backward difference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 0.2,
              dragStartPosition: const Duration(seconds: 50),
              duration: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        ),
      );

      // Target position: 20 seconds (0.2 * 100)
      expect(find.text('0:20'), findsOneWidget);
      // Difference: -30 seconds (20 - 50)
      expect(find.text('-0:30'), findsOneWidget);
      expect(find.byIcon(Icons.fast_rewind), findsOneWidget);
    });

    testWidgets('handles zero difference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 0.3,
              dragStartPosition: const Duration(seconds: 30),
              duration: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        ),
      );

      // Target position: 30 seconds (0.3 * 100)
      expect(find.text('0:30'), findsOneWidget);
      // Difference: 0 seconds (30 - 30)
      expect(find.text('+0:00'), findsOneWidget);
      expect(find.byIcon(Icons.fast_forward), findsOneWidget);
    });

    testWidgets('formats duration with hours correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 0.5,
              dragStartPosition: const Duration(hours: 1),
              duration: const Duration(hours: 2),
              theme: theme,
            ),
          ),
        ),
      );

      // Target position: 1 hour (0.5 * 2 hours = 60 minutes)
      expect(find.text('60:00'), findsOneWidget);
      // Difference: 0 hours (60:00 - 60:00)
      expect(find.text('+0:00'), findsOneWidget);
    });

    testWidgets('handles drag to beginning', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 0,
              dragStartPosition: const Duration(seconds: 50),
              duration: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('-0:50'), findsOneWidget);
      expect(find.byIcon(Icons.fast_rewind), findsOneWidget);
    });

    testWidgets('handles drag to end', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 1,
              dragStartPosition: const Duration(seconds: 50),
              duration: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        ),
      );

      expect(find.text('1:40'), findsOneWidget);
      expect(find.text('+0:50'), findsOneWidget);
      expect(find.byIcon(Icons.fast_forward), findsOneWidget);
    });

    testWidgets('uses theme primary color for position text', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.red);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 0.5,
              dragStartPosition: const Duration(seconds: 10),
              duration: const Duration(seconds: 100),
              theme: customTheme,
            ),
          ),
        ),
      );

      final positionText = tester.widget<Text>(find.text('0:50'));
      expect(positionText.style?.color, Colors.red);
    });

    testWidgets('uses theme secondary color for difference text and icon', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(secondaryColor: Colors.blue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 0.5,
              dragStartPosition: const Duration(seconds: 10),
              duration: const Duration(seconds: 100),
              theme: customTheme,
            ),
          ),
        ),
      );

      final differenceText = tester.widget<Text>(find.text('+0:40'));
      expect(differenceText.style?.color, Colors.blue);

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.blue);
    });

    testWidgets('has text shadows for better visibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekPreview(
              dragProgress: 0.5,
              dragStartPosition: const Duration(seconds: 10),
              duration: const Duration(seconds: 100),
              theme: theme,
            ),
          ),
        ),
      );

      final positionText = tester.widget<Text>(find.text('0:50'));
      expect(positionText.style?.shadows, isNotNull);
      expect(positionText.style!.shadows!.length, 1);

      final differenceText = tester.widget<Text>(find.text('+0:40'));
      expect(differenceText.style?.shadows, isNotNull);
      expect(differenceText.style!.shadows!.length, 1);

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.shadows, isNotNull);
      expect(icon.shadows!.length, 1);
    });

    testWidgets('scales down when content is too large (FittedBox)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 50, // Very narrow
              height: 50, // Very short
              child: SeekPreview(
                dragProgress: 0.5,
                dragStartPosition: const Duration(seconds: 10),
                duration: const Duration(seconds: 100),
                theme: theme,
              ),
            ),
          ),
        ),
      );

      // Verify FittedBox is used
      expect(find.byType(FittedBox), findsOneWidget);
      final fittedBox = tester.widget<FittedBox>(find.byType(FittedBox));
      expect(fittedBox.fit, BoxFit.scaleDown);
    });
  });
}
