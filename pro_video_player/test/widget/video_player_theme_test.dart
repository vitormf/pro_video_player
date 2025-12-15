import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

void main() {
  group('formatVideoDuration', () {
    test('formats zero duration', () {
      expect(formatVideoDuration(Duration.zero), '0:00');
    });

    test('formats seconds only', () {
      expect(formatVideoDuration(const Duration(seconds: 5)), '0:05');
      expect(formatVideoDuration(const Duration(seconds: 30)), '0:30');
      expect(formatVideoDuration(const Duration(seconds: 59)), '0:59');
    });

    test('formats minutes and seconds', () {
      expect(formatVideoDuration(const Duration(minutes: 1)), '1:00');
      expect(formatVideoDuration(const Duration(minutes: 5, seconds: 30)), '5:30');
      expect(formatVideoDuration(const Duration(minutes: 10, seconds: 5)), '10:05');
    });

    test('formats hours as minutes', () {
      expect(formatVideoDuration(const Duration(hours: 1)), '60:00');
      expect(formatVideoDuration(const Duration(hours: 1, minutes: 30, seconds: 45)), '90:45');
    });

    test('pads seconds with zero', () {
      expect(formatVideoDuration(const Duration(minutes: 5, seconds: 1)), '5:01');
      expect(formatVideoDuration(const Duration(minutes: 5, seconds: 9)), '5:09');
    });
  });

  group('VideoPlayerTheme', () {
    test('default theme has correct values', () {
      const theme = VideoPlayerTheme();

      expect(theme.primaryColor, Colors.white);
      expect(theme.secondaryColor, Colors.white70);
      expect(theme.backgroundColor, const Color(0xCC000000));
      expect(theme.progressBarActiveColor, Colors.white);
      expect(theme.progressBarInactiveColor, Colors.white24);
      expect(theme.progressBarBufferedColor, Colors.white38);
      expect(theme.iconSize, 32.0);
      expect(theme.seekIconSize, 48.0);
      expect(theme.borderRadius, 8.0);
      expect(theme.controlsPadding, const EdgeInsets.all(16));
    });

    test('dark theme has correct values', () {
      final theme = VideoPlayerTheme.dark();

      expect(theme.primaryColor, Colors.white);
      expect(theme.secondaryColor, Colors.white70);
      expect(theme.backgroundColor, const Color(0xCC000000));
      expect(theme.progressBarActiveColor, Colors.white);
    });

    test('light theme has correct values', () {
      final theme = VideoPlayerTheme.light();

      expect(theme.primaryColor, Colors.black87);
      expect(theme.secondaryColor, Colors.black54);
      expect(theme.backgroundColor, const Color(0xCCFFFFFF));
      expect(theme.progressBarActiveColor, Colors.blue);
    });

    test('christmas theme has correct values', () {
      final theme = VideoPlayerTheme.christmas();

      expect(theme.primaryColor, Colors.white);
      expect(theme.progressBarActiveColor, Colors.white);
      expect(theme.progressBarInactiveColor, Colors.green.shade200);
    });

    test('halloween theme has correct values', () {
      final theme = VideoPlayerTheme.halloween();

      expect(theme.primaryColor, Colors.orange);
      expect(theme.backgroundColor, const Color(0xCC1A0A00));
      expect(theme.progressBarActiveColor, Colors.deepOrange);
    });

    test('copyWith works correctly', () {
      const theme = VideoPlayerTheme();
      final modified = theme.copyWith(primaryColor: Colors.blue, iconSize: 48);

      expect(modified.primaryColor, Colors.blue);
      expect(modified.iconSize, 48.0);
      expect(modified.secondaryColor, theme.secondaryColor);
      expect(modified.backgroundColor, theme.backgroundColor);
    });

    test('copyWith with all nulls returns identical theme', () {
      const theme = VideoPlayerTheme();
      final modified = theme.copyWith();

      expect(modified.primaryColor, theme.primaryColor);
      expect(modified.secondaryColor, theme.secondaryColor);
      expect(modified.backgroundColor, theme.backgroundColor);
      expect(modified.progressBarActiveColor, theme.progressBarActiveColor);
      expect(modified.iconSize, theme.iconSize);
    });

    test('equality works correctly', () {
      const theme1 = VideoPlayerTheme();
      const theme2 = VideoPlayerTheme();
      final theme3 = theme1.copyWith(primaryColor: Colors.blue);

      expect(theme1, equals(theme2));
      expect(theme1, isNot(equals(theme3)));
    });

    test('equality checks all properties', () {
      // Test that equality compares each property by changing each one individually
      // This exercises lines 199-207 which are the property comparisons
      const base = VideoPlayerTheme();

      // Each of these should be not equal due to differing in one property
      // Using non-const to avoid identical() short-circuit
      expect(base, isNot(equals(base.copyWith(secondaryColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(backgroundColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(progressBarActiveColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(progressBarInactiveColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(progressBarBufferedColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(iconSize: 999))));
      expect(base, isNot(equals(base.copyWith(seekIconSize: 999))));
      expect(base, isNot(equals(base.copyWith(borderRadius: 999))));
      expect(base, isNot(equals(base.copyWith(controlsPadding: EdgeInsets.zero))));
    });

    test('equality returns true for identical values (not same instance)', () {
      // Create two themes with the same values using copyWith to ensure non-identical
      const base = VideoPlayerTheme();
      final theme1 = base.copyWith(); // Creates a new instance
      final theme2 = base.copyWith(); // Creates another new instance

      // These are not identical() but should be equal
      expect(identical(theme1, theme2), isFalse);
      expect(theme1, equals(theme2));
    });

    test('hashCode works correctly', () {
      const theme1 = VideoPlayerTheme();
      const theme2 = VideoPlayerTheme();
      final theme3 = theme1.copyWith(primaryColor: Colors.blue);

      expect(theme1.hashCode, equals(theme2.hashCode));
      expect(theme1.hashCode, isNot(equals(theme3.hashCode)));
    });
  });

  group('VideoPlayerThemeData', () {
    testWidgets('provides default theme when not wrapped', (tester) async {
      late VideoPlayerTheme capturedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedTheme = VideoPlayerThemeData.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedTheme.primaryColor, Colors.white);
      expect(capturedTheme.backgroundColor, const Color(0xCC000000));
    });

    testWidgets('provides theme from VideoPlayerThemeData', (tester) async {
      final customTheme = VideoPlayerTheme.light();
      late VideoPlayerTheme capturedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoPlayerThemeData(
            theme: customTheme,
            child: Builder(
              builder: (context) {
                capturedTheme = VideoPlayerThemeData.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedTheme.primaryColor, customTheme.primaryColor);
      expect(capturedTheme.backgroundColor, customTheme.backgroundColor);
    });

    testWidgets('updateShouldNotify returns true when theme changes', (tester) async {
      const theme1 = VideoPlayerTheme();
      final theme2 = VideoPlayerTheme.light();

      const widget1 = VideoPlayerThemeData(theme: theme1, child: SizedBox());
      final widget2 = VideoPlayerThemeData(theme: theme2, child: const SizedBox());

      expect(widget2.updateShouldNotify(widget1), isTrue);
    });

    testWidgets('updateShouldNotify returns false when theme is same', (tester) async {
      const theme = VideoPlayerTheme();

      const widget1 = VideoPlayerThemeData(theme: theme, child: SizedBox());
      const widget2 = VideoPlayerThemeData(theme: theme, child: SizedBox());

      expect(widget2.updateShouldNotify(widget1), isFalse);
    });
  });
}
