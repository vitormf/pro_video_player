import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/shuffle_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

import '../../../shared/test_helpers.dart';

void main() {
  group('ShuffleButton', () {
    testWidgets('shows shuffle icon when not shuffled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(ShuffleButton(theme: VideoPlayerTheme.light(), isShuffled: false, onPressed: () {})),
      );

      expect(find.byIcon(Icons.shuffle), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows shuffle_on icon when shuffled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(ShuffleButton(theme: VideoPlayerTheme.light(), isShuffled: true, onPressed: () {})),
      );

      expect(find.byIcon(Icons.shuffle_on), findsOneWidget);
    });

    testWidgets('uses active color when shuffled', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(
        progressBarActiveColor: Colors.green,
        primaryColor: Colors.blue,
      );

      await tester.pumpWidget(buildTestWidget(ShuffleButton(theme: customTheme, isShuffled: true, onPressed: () {})));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.green));
    });

    testWidgets('uses primary color when not shuffled', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(
        progressBarActiveColor: Colors.green,
        primaryColor: Colors.blue,
      );

      await tester.pumpWidget(buildTestWidget(ShuffleButton(theme: customTheme, isShuffled: false, onPressed: () {})));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.blue));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestWidget(
          ShuffleButton(theme: VideoPlayerTheme.light(), isShuffled: false, onPressed: () => pressed = true),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has shuffle on tooltip when shuffled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(ShuffleButton(theme: VideoPlayerTheme.light(), isShuffled: true, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Shuffle on'));
    });

    testWidgets('has shuffle off tooltip when not shuffled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(ShuffleButton(theme: VideoPlayerTheme.light(), isShuffled: false, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Shuffle off'));
    });

    testWidgets('uses correct icon size', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(ShuffleButton(theme: VideoPlayerTheme.light(), isShuffled: false, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.iconSize, equals(20));
    });
  });
}
