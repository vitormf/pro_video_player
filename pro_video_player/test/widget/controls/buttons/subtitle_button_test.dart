import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/subtitle_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

import '../../../shared/test_helpers.dart';

void main() {
  group('SubtitleButton', () {
    testWidgets('shows closed_caption_off icon when no subtitle selected', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(SubtitleButton(theme: VideoPlayerTheme.light(), hasSelectedSubtitle: false, onPressed: () {})),
      );

      // Should show closed caption off icon
      expect(find.byIcon(Icons.closed_caption_off), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows closed_caption icon when subtitle selected', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(SubtitleButton(theme: VideoPlayerTheme.light(), hasSelectedSubtitle: true, onPressed: () {})),
      );

      // Should show closed caption icon
      expect(find.byIcon(Icons.closed_caption), findsOneWidget);
    });

    testWidgets('uses theme primary color', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.purple);

      await tester.pumpWidget(
        buildTestWidget(SubtitleButton(theme: customTheme, hasSelectedSubtitle: false, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.purple));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestWidget(
          SubtitleButton(theme: VideoPlayerTheme.light(), hasSelectedSubtitle: false, onPressed: () => pressed = true),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has Subtitles tooltip', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(SubtitleButton(theme: VideoPlayerTheme.light(), hasSelectedSubtitle: false, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Subtitles'));
    });

    testWidgets('uses correct icon size', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(SubtitleButton(theme: VideoPlayerTheme.light(), hasSelectedSubtitle: false, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.iconSize, equals(20));
    });
  });
}
