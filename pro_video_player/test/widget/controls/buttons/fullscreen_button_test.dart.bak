import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/buttons/fullscreen_button.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

void main() {
  group('FullscreenButton', () {
    testWidgets('shows fullscreen icon when not in fullscreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenButton(theme: VideoPlayerTheme.light(), isFullscreen: false, onEnter: () {}, onExit: () {}),
          ),
        ),
      );

      // Should show fullscreen icon
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows fullscreen_exit icon when in fullscreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenButton(theme: VideoPlayerTheme.light(), isFullscreen: true, onEnter: () {}, onExit: () {}),
          ),
        ),
      );

      // Should show fullscreen exit icon
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
    });

    testWidgets('uses theme primary color', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(primaryColor: Colors.purple);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenButton(theme: customTheme, isFullscreen: false, onEnter: () {}, onExit: () {}),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.color, equals(Colors.purple));
    });

    testWidgets('uses theme icon size', (tester) async {
      final customTheme = VideoPlayerTheme.light().copyWith(iconSize: 32);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenButton(theme: customTheme, isFullscreen: false, onEnter: () {}, onExit: () {}),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.iconSize, equals(32));
    });

    testWidgets('calls onEnter when tapped in non-fullscreen', (tester) async {
      var enterCalled = false;
      var exitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenButton(
              theme: VideoPlayerTheme.light(),
              isFullscreen: false,
              onEnter: () => enterCalled = true,
              onExit: () => exitCalled = true,
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(enterCalled, isTrue);
      expect(exitCalled, isFalse);
    });

    testWidgets('calls onExit when tapped in fullscreen', (tester) async {
      var enterCalled = false;
      var exitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenButton(
              theme: VideoPlayerTheme.light(),
              isFullscreen: true,
              onEnter: () => enterCalled = true,
              onExit: () => exitCalled = true,
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(enterCalled, isFalse);
      expect(exitCalled, isTrue);
    });

    testWidgets('has fullscreen tooltip when not in fullscreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenButton(theme: VideoPlayerTheme.light(), isFullscreen: false, onEnter: () {}, onExit: () {}),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Fullscreen'));
    });

    testWidgets('has exit fullscreen tooltip when in fullscreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullscreenButton(theme: VideoPlayerTheme.light(), isFullscreen: true, onEnter: () {}, onExit: () {}),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Exit fullscreen'));
    });
  });
}
