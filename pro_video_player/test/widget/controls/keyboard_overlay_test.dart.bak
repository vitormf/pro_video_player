import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('KeyboardOverlay', () {
    group('null handling', () {
      testWidgets('returns empty widget when type is null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: null, value: 0.5, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
        expect(find.byType(Text), findsNothing);
      });

      testWidgets('returns empty widget when value is null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            KeyboardOverlay(type: KeyboardOverlayType.volume, value: null, theme: VideoPlayerTheme.light()),
          ),
        );
        await tester.pump();

        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
        expect(find.byType(Text), findsNothing);
      });

      testWidgets('returns empty widget when both are null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: null, value: null, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
        expect(find.byType(Text), findsNothing);
      });
    });

    group('volume overlay', () {
      testWidgets('displays volume_off icon when volume is 0', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_off);
      });

      testWidgets('displays volume_down icon when volume > 0 and <= 0.5', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.3, theme: VideoPlayerTheme.light()),
          ),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_down);
      });

      testWidgets('displays volume_up icon when volume > 0.5', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.8, theme: VideoPlayerTheme.light()),
          ),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_up);
      });

      testWidgets('displays volume percentage', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.75, theme: VideoPlayerTheme.light()),
          ),
        );
        await tester.pump();

        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('rounds volume percentage correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.666, theme: VideoPlayerTheme.light()),
          ),
        );
        await tester.pump();

        expect(find.text('67%'), findsOneWidget);
      });

      testWidgets('uses theme primary color', (tester) async {
        final theme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.red);

        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.volume, value: 0.5, theme: theme)),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, Colors.red);

        final text = tester.widget<Text>(find.text('50%'));
        expect(text.style?.color, Colors.red);
      });
    });

    group('seek overlay', () {
      testWidgets('displays fast_forward icon for positive seek', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: 10, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.fast_forward);
      });

      testWidgets('displays fast_rewind icon for negative seek', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: -10, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.fast_rewind);
      });

      testWidgets('displays fast_forward icon for zero seek', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: 0, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.fast_forward);
      });

      testWidgets('displays seek duration with + prefix for positive', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: 15, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        expect(find.text('+15s'), findsOneWidget);
      });

      testWidgets('displays seek duration with - prefix for negative', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: -15, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        expect(find.text('-15s'), findsOneWidget);
      });

      testWidgets('uses theme primary color', (tester) async {
        final theme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.blue);

        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.seek, value: 10, theme: theme)),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, Colors.blue);

        final text = tester.widget<Text>(find.text('+10s'));
        expect(text.style?.color, Colors.blue);
      });
    });

    group('speed overlay', () {
      testWidgets('displays speed icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            KeyboardOverlay(type: KeyboardOverlayType.speed, value: 1.5, theme: VideoPlayerTheme.light()),
          ),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.speed);
      });

      testWidgets('displays speed multiplier with x suffix', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.speed, value: 2, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        expect(find.text('2.0x'), findsOneWidget);
      });

      testWidgets('displays fractional speed correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            KeyboardOverlay(type: KeyboardOverlayType.speed, value: 0.5, theme: VideoPlayerTheme.light()),
          ),
        );
        await tester.pump();

        expect(find.text('0.5x'), findsOneWidget);
      });

      testWidgets('uses theme primary color', (tester) async {
        final theme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.green);

        await tester.pumpWidget(
          buildTestWidget(KeyboardOverlay(type: KeyboardOverlayType.speed, value: 1.5, theme: theme)),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, Colors.green);

        final text = tester.widget<Text>(find.text('1.5x'));
        expect(text.style?.color, Colors.green);
      });
    });
  });
}
