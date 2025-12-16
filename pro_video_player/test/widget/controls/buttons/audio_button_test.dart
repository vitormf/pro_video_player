import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/audio_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

import '../../../shared/test_helpers.dart';

void main() {
  group('AudioButton', () {
    testWidgets('renders icon button with correct icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(AudioButton(theme: VideoPlayerTheme.light(), onPressed: () {})));

      // Should show audio track icon
      expect(find.byIcon(Icons.audiotrack), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('uses theme primary color for icon', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.purple);

      await tester.pumpWidget(buildTestWidget(AudioButton(theme: customTheme, onPressed: () {})));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.purple));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestWidget(AudioButton(theme: VideoPlayerTheme.light(), onPressed: () => pressed = true)),
      );

      // Tap the button
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has Audio track tooltip', (tester) async {
      await tester.pumpWidget(buildTestWidget(AudioButton(theme: VideoPlayerTheme.light(), onPressed: () {})));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Audio track'));
    });

    testWidgets('uses correct icon size', (tester) async {
      await tester.pumpWidget(buildTestWidget(AudioButton(theme: VideoPlayerTheme.light(), onPressed: () {})));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.iconSize, equals(20));
    });
  });
}
