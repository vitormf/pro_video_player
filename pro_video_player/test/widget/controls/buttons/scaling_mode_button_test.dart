import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/scaling_mode_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

import '../../../shared/test_helpers.dart';

void main() {
  group('ScalingModeButton', () {
    testWidgets('renders icon button with correct icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(ScalingModeButton(theme: VideoPlayerTheme.light(), onPressed: () {})));

      expect(find.byIcon(Icons.aspect_ratio), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('uses theme primary color for icon', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.purple);

      await tester.pumpWidget(buildTestWidget(ScalingModeButton(theme: customTheme, onPressed: () {})));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.purple));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestWidget(ScalingModeButton(theme: VideoPlayerTheme.light(), onPressed: () => pressed = true)),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has Scaling mode tooltip', (tester) async {
      await tester.pumpWidget(buildTestWidget(ScalingModeButton(theme: VideoPlayerTheme.light(), onPressed: () {})));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Scaling mode'));
    });

    testWidgets('uses correct icon size', (tester) async {
      await tester.pumpWidget(buildTestWidget(ScalingModeButton(theme: VideoPlayerTheme.light(), onPressed: () {})));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.iconSize, equals(20));
    });
  });
}
