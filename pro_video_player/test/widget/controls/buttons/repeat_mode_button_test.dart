import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/repeat_mode_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../../shared/test_helpers.dart';

void main() {
  group('RepeatModeButton', () {
    testWidgets('shows repeat icon with primary color when mode is none', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(
        progressBarActiveColor: Colors.green,
        primaryColor: Colors.blue,
      );

      await tester.pumpWidget(
        buildTestWidget(RepeatModeButton(theme: customTheme, repeatMode: PlaylistRepeatMode.none, onPressed: () {})),
      );

      expect(find.byIcon(Icons.repeat), findsOneWidget);
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.blue));
    });

    testWidgets('shows repeat icon with active color when mode is all', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(
        progressBarActiveColor: Colors.green,
        primaryColor: Colors.blue,
      );

      await tester.pumpWidget(
        buildTestWidget(RepeatModeButton(theme: customTheme, repeatMode: PlaylistRepeatMode.all, onPressed: () {})),
      );

      expect(find.byIcon(Icons.repeat), findsOneWidget);
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.green));
    });

    testWidgets('shows repeat_one icon with active color when mode is one', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(
        progressBarActiveColor: Colors.green,
        primaryColor: Colors.blue,
      );

      await tester.pumpWidget(
        buildTestWidget(RepeatModeButton(theme: customTheme, repeatMode: PlaylistRepeatMode.one, onPressed: () {})),
      );

      expect(find.byIcon(Icons.repeat_one), findsOneWidget);
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.green));
    });

    testWidgets('has correct tooltip for none mode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          RepeatModeButton(theme: VideoPlayerTheme.light(), repeatMode: PlaylistRepeatMode.none, onPressed: () {}),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Repeat off'));
    });

    testWidgets('has correct tooltip for all mode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          RepeatModeButton(theme: VideoPlayerTheme.light(), repeatMode: PlaylistRepeatMode.all, onPressed: () {}),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Repeat all'));
    });

    testWidgets('has correct tooltip for one mode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          RepeatModeButton(theme: VideoPlayerTheme.light(), repeatMode: PlaylistRepeatMode.one, onPressed: () {}),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Repeat one'));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestWidget(
          RepeatModeButton(
            theme: VideoPlayerTheme.light(),
            repeatMode: PlaylistRepeatMode.none,
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('uses correct icon size', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          RepeatModeButton(theme: VideoPlayerTheme.light(), repeatMode: PlaylistRepeatMode.all, onPressed: () {}),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.iconSize, equals(20));
    });
  });
}
