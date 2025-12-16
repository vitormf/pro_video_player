import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/background_playback_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

import '../../../shared/test_helpers.dart';

void main() {
  group('BackgroundPlaybackButton', () {
    testWidgets('shows enabled icon when enabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(BackgroundPlaybackButton(theme: VideoPlayerTheme.light(), isEnabled: true, onPressed: () {})),
      );

      // Should show filled headphones icon when enabled
      expect(find.byIcon(Icons.headphones), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows disabled icon when disabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(BackgroundPlaybackButton(theme: VideoPlayerTheme.light(), isEnabled: false, onPressed: () {})),
      );

      // Should show outlined headphones icon when disabled
      expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
    });

    testWidgets('uses active color when enabled', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(
        progressBarActiveColor: Colors.green,
        primaryColor: Colors.blue,
      );

      await tester.pumpWidget(
        buildTestWidget(BackgroundPlaybackButton(theme: customTheme, isEnabled: true, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.green));
    });

    testWidgets('uses primary color when disabled', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(
        progressBarActiveColor: Colors.green,
        primaryColor: Colors.blue,
      );

      await tester.pumpWidget(
        buildTestWidget(BackgroundPlaybackButton(theme: customTheme, isEnabled: false, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.blue));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestWidget(
          BackgroundPlaybackButton(theme: VideoPlayerTheme.light(), isEnabled: false, onPressed: () => pressed = true),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has enable tooltip when disabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(BackgroundPlaybackButton(theme: VideoPlayerTheme.light(), isEnabled: false, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Enable background playback'));
    });

    testWidgets('has disable tooltip when enabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(BackgroundPlaybackButton(theme: VideoPlayerTheme.light(), isEnabled: true, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Disable background playback'));
    });

    testWidgets('uses correct icon size', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(BackgroundPlaybackButton(theme: VideoPlayerTheme.light(), isEnabled: false, onPressed: () {})),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.iconSize, equals(20));
    });
  });
}
