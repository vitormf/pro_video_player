import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/chapters_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

void main() {
  group('ChaptersButton', () {
    testWidgets('displays icon only when no chapter title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChaptersButton(theme: VideoPlayerTheme.light(), currentChapterTitle: null, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      // Should not find any chapter title text
      expect(find.text('Chapter 1'), findsNothing);
    });

    testWidgets('displays icon and chapter title when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChaptersButton(
              theme: VideoPlayerTheme.light(),
              currentChapterTitle: 'Introduction',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.text('Introduction'), findsOneWidget);
    });

    testWidgets('uses theme primary color for icon and text', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.purple);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChaptersButton(theme: customTheme, currentChapterTitle: 'Chapter 1', onPressed: () {}),
          ),
        ),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final row = textButton.child! as Row;
      final icon = row.children[0] as Icon;

      expect(icon.color, equals(Colors.purple));

      // Find the text widget within the ConstrainedBox
      final constrainedBox = row.children[2] as ConstrainedBox;
      final text = constrainedBox.child! as Text;
      expect(text.style?.color, equals(Colors.purple));
    });

    testWidgets('uses correct icon size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChaptersButton(theme: VideoPlayerTheme.light(), currentChapterTitle: null, onPressed: () {}),
          ),
        ),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final row = textButton.child! as Row;
      final icon = row.children[0] as Icon;

      expect(icon.size, equals(18));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChaptersButton(
              theme: VideoPlayerTheme.light(),
              currentChapterTitle: 'Test',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has Chapters tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChaptersButton(theme: VideoPlayerTheme.light(), currentChapterTitle: null, onPressed: () {}),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Chapters'));
    });

    testWidgets('truncates long chapter titles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChaptersButton(
              theme: VideoPlayerTheme.light(),
              currentChapterTitle: 'This is a very long chapter title that should be truncated',
              onPressed: () {},
            ),
          ),
        ),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final row = textButton.child! as Row;
      final constrainedBox = row.children[2] as ConstrainedBox;
      final text = constrainedBox.child! as Text;

      expect(text.overflow, equals(TextOverflow.ellipsis));
      expect(text.maxLines, equals(1));
      expect(constrainedBox.constraints.maxWidth, equals(100));
    });
  });
}
