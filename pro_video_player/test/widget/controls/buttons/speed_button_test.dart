import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/speed_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

void main() {
  group('SpeedButton', () {
    testWidgets('displays speed text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1, onPressed: () {}),
          ),
        ),
      );

      // Should show "1x" (trailing zeros removed)
      expect(find.text('1x'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('displays different speeds correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 2, onPressed: () {}),
          ),
        ),
      );

      expect(find.text('2x'), findsOneWidget);
    });

    testWidgets('displays fractional speeds correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 0.5, onPressed: () {}),
          ),
        ),
      );

      expect(find.text('0.5x'), findsOneWidget);
    });

    testWidgets('uses theme primary color for text', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.purple);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedButton(theme: customTheme, speed: 1, onPressed: () {}),
          ),
        ),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final text = textButton.child! as Text;
      expect(text.style?.color, equals(Colors.purple));
    });

    testWidgets('uses correct font size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1, onPressed: () {}),
          ),
        ),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final text = textButton.child! as Text;
      expect(text.style?.fontSize, equals(14));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1, onPressed: () => pressed = true),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has correct button padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1, onPressed: () {}),
          ),
        ),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(textButton.style?.padding?.resolve({}), equals(const EdgeInsets.symmetric(horizontal: 8)));
    });

    testWidgets('has Playback speed tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1, onPressed: () {}),
          ),
        ),
      );

      // Tooltip wraps the TextButton
      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Playback speed'));
    });

    group('speed formatting', () {
      testWidgets('removes trailing zeros from whole numbers', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1, onPressed: () {}),
            ),
          ),
        );

        expect(find.text('1x'), findsOneWidget);
      });

      testWidgets('keeps one decimal place when needed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1.5, onPressed: () {}),
            ),
          ),
        );

        expect(find.text('1.5x'), findsOneWidget);
      });

      testWidgets('keeps two decimal places when needed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1.25, onPressed: () {}),
            ),
          ),
        );

        expect(find.text('1.25x'), findsOneWidget);
      });

      testWidgets('limits to 2 decimal places', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 1.333333, onPressed: () {}),
            ),
          ),
        );

        expect(find.text('1.33x'), findsOneWidget);
      });

      testWidgets('removes trailing zero from one decimal place', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 2.50, onPressed: () {}),
            ),
          ),
        );

        expect(find.text('2.5x'), findsOneWidget);
      });

      testWidgets('formats speeds less than 1', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 0.25, onPressed: () {}),
            ),
          ),
        );

        expect(find.text('0.25x'), findsOneWidget);
      });

      testWidgets('formats speeds greater than 2', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeedButton(theme: VideoPlayerTheme.light(), speed: 2.75, onPressed: () {}),
            ),
          ),
        );

        expect(find.text('2.75x'), findsOneWidget);
      });
    });
  });
}
