import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/quality_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

import '../../../shared/test_helpers.dart';

void main() {
  group('QualityButton', () {
    testWidgets('displays quality label correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(QualityButton(theme: VideoPlayerTheme.light(), qualityLabel: '1080p', onPressed: () {})),
      );

      // Should show quality label text
      expect(find.text('1080p'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('displays high_quality icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(QualityButton(theme: VideoPlayerTheme.light(), qualityLabel: 'Auto', onPressed: () {})),
      );

      expect(find.byIcon(Icons.high_quality), findsOneWidget);
    });

    testWidgets('displays Auto label when in auto mode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(QualityButton(theme: VideoPlayerTheme.light(), qualityLabel: 'Auto', onPressed: () {})),
      );

      expect(find.text('Auto'), findsOneWidget);
    });

    testWidgets('uses theme primary color for text and icon', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.purple);

      await tester.pumpWidget(
        buildTestWidget(QualityButton(theme: customTheme, qualityLabel: '720p', onPressed: () {})),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final row = textButton.child! as Row;
      final icon = row.children[0] as Icon;
      final text = row.children[2] as Text;

      expect(icon.color, equals(Colors.purple));
      expect(text.style?.color, equals(Colors.purple));
    });

    testWidgets('uses correct text font size', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(QualityButton(theme: VideoPlayerTheme.light(), qualityLabel: '1080p', onPressed: () {})),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final row = textButton.child! as Row;
      final text = row.children[2] as Text;

      expect(text.style?.fontSize, equals(14));
    });

    testWidgets('uses correct icon size', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(QualityButton(theme: VideoPlayerTheme.light(), qualityLabel: '480p', onPressed: () {})),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final row = textButton.child! as Row;
      final icon = row.children[0] as Icon;

      expect(icon.size, equals(18));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestWidget(
          QualityButton(theme: VideoPlayerTheme.light(), qualityLabel: 'Auto', onPressed: () => pressed = true),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has Video quality tooltip', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(QualityButton(theme: VideoPlayerTheme.light(), qualityLabel: '1080p', onPressed: () {})),
      );

      // Tooltip wraps the TextButton
      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Video quality'));
    });

    testWidgets('has correct button padding', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(QualityButton(theme: VideoPlayerTheme.light(), qualityLabel: '720p', onPressed: () {})),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(textButton.style?.padding?.resolve({}), equals(const EdgeInsets.symmetric(horizontal: 8)));
    });
  });
}
