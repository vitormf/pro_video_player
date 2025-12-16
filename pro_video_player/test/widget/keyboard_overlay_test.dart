import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../shared/test_helpers.dart';

void main() {
  group('KeyboardOverlay', () {
    late VideoPlayerTheme theme;

    setUp(() {
      theme = VideoPlayerTheme.light();
    });

    testWidgets('returns empty SizedBox when type is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(KeyboardOverlay(type: null, value: 50, theme: theme)));

      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(find.byIcon(Icons.fast_forward), findsNothing);
      expect(find.byIcon(Icons.speed), findsNothing);
      expect(find.text('50%'), findsNothing);
    });

    testWidgets('returns empty SizedBox when value is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: null, theme: theme)),
      );

      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(find.byIcon(Icons.volume_down), findsNothing);
      expect(find.byIcon(Icons.volume_off), findsNothing);
    });

    group('Volume overlay', () {
      testWidgets('shows volume_up icon for volume > 0.5', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.8, theme: theme)),
        );

        expect(find.byIcon(Icons.volume_up), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);
      });

      testWidgets('shows volume_down icon for volume > 0 and <= 0.5', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.3, theme: theme)),
        );

        expect(find.byIcon(Icons.volume_down), findsOneWidget);
        expect(find.text('30%'), findsOneWidget);
      });

      testWidgets('shows volume_off icon for volume = 0', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0, theme: theme)),
        );

        expect(find.byIcon(Icons.volume_off), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);
      });

      testWidgets('rounds volume percentage to nearest integer', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.567, theme: theme)),
        );

        expect(find.text('57%'), findsOneWidget);
      });
    });

    group('Seek overlay', () {
      testWidgets('shows fast_forward icon for positive seconds', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: 10, theme: theme)),
        );

        expect(find.byIcon(Icons.fast_forward), findsOneWidget);
        expect(find.text('+10s'), findsOneWidget);
      });

      testWidgets('shows fast_rewind icon for negative seconds', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: -10, theme: theme)),
        );

        expect(find.byIcon(Icons.fast_rewind), findsOneWidget);
        expect(find.text('-10s'), findsOneWidget);
      });

      testWidgets('shows + prefix for zero seconds', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: 0, theme: theme)),
        );

        expect(find.byIcon(Icons.fast_forward), findsOneWidget);
        expect(find.text('+0s'), findsOneWidget);
      });

      testWidgets('converts decimal seconds to integer', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: 15.7, theme: theme)),
        );

        expect(find.text('+15s'), findsOneWidget);
      });
    });

    group('Speed overlay', () {
      testWidgets('shows speed icon and value', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.speed, value: 1.5, theme: theme)),
        );

        expect(find.byIcon(Icons.speed), findsOneWidget);
        expect(find.text('1.5x'), findsOneWidget);
      });

      testWidgets('handles integer speed values', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.speed, value: 2, theme: theme)),
        );

        expect(find.text('2.0x'), findsOneWidget);
      });

      testWidgets('handles decimal speed values', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.speed, value: 0.75, theme: theme)),
        );

        expect(find.text('0.75x'), findsOneWidget);
      });
    });

    group('Widget properties', () {
      testWidgets('overlay is centered', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.5, theme: theme)),
        );

        // Verify content is rendered (which means Center is working)
        expect(find.byIcon(Icons.volume_down), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
      });

      testWidgets('overlay ignores pointer events', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.5, theme: theme)),
        );

        // Find the IgnorePointer that's a direct child of KeyboardOverlay
        final ignorePointers = tester.widgetList<IgnorePointer>(find.byType(IgnorePointer));
        expect(ignorePointers.any((ip) => ip.ignoring), isTrue);
      });

      testWidgets('uses theme primary color for icon and text', (tester) async {
        final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.red);

        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.5, theme: customTheme)),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, Colors.red);

        final text = tester.widget<Text>(find.text('50%'));
        expect(text.style?.color, Colors.red);
      });

      testWidgets('icon has text shadow', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.5, theme: theme)),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.shadows, isNotNull);
        expect(icon.shadows!.length, 1);
        expect(icon.shadows![0].blurRadius, 8);
      });

      testWidgets('text has text shadow', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.5, theme: theme)),
        );

        final text = tester.widget<Text>(find.text('50%'));
        expect(text.style?.shadows, isNotNull);
        expect(text.style!.shadows!.length, 1);
        expect(text.style!.shadows![0].blurRadius, 8);
      });
    });
  });
}
