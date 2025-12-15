import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_video_player_example/utils/responsive_utils.dart';

void main() {
  group('ScreenSize', () {
    test('has correct breakpoint values', () {
      expect(ScreenSize.compact.maxWidth, 599);
      expect(ScreenSize.medium.maxWidth, 839);
      expect(ScreenSize.expanded.maxWidth, double.infinity);
    });
  });

  group('ResponsiveUtils.getScreenSize', () {
    testWidgets('returns compact for width < 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(599, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getScreenSize(context), ScreenSize.compact);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns medium for width 600-839', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getScreenSize(context), ScreenSize.medium);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(839, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getScreenSize(context), ScreenSize.medium);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns expanded for width >= 840', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(840, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getScreenSize(context), ScreenSize.expanded);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getScreenSize(context), ScreenSize.expanded);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ResponsiveUtils convenience methods', () {
    testWidgets('isCompact returns true only for compact', (tester) async {
      // Compact
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isCompact(context), isTrue);
              expect(ResponsiveUtils.isMedium(context), isFalse);
              expect(ResponsiveUtils.isExpanded(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isMedium returns true only for medium', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isCompact(context), isFalse);
              expect(ResponsiveUtils.isMedium(context), isTrue);
              expect(ResponsiveUtils.isExpanded(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isExpanded returns true only for expanded', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isCompact(context), isFalse);
              expect(ResponsiveUtils.isMedium(context), isFalse);
              expect(ResponsiveUtils.isExpanded(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ResponsiveUtils.getGridCrossAxisCount', () {
    testWidgets('returns 1 for compact', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getGridCrossAxisCount(context), 1);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns 2 for medium', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getGridCrossAxisCount(context), 2);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns 3 for expanded', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getGridCrossAxisCount(context), 3);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ResponsiveUtils.getScreenSizeFromWidth', () {
    test('returns correct screen size for various widths', () {
      expect(ResponsiveUtils.getScreenSizeFromWidth(0), ScreenSize.compact);
      expect(ResponsiveUtils.getScreenSizeFromWidth(400), ScreenSize.compact);
      expect(ResponsiveUtils.getScreenSizeFromWidth(599), ScreenSize.compact);
      expect(ResponsiveUtils.getScreenSizeFromWidth(600), ScreenSize.medium);
      expect(ResponsiveUtils.getScreenSizeFromWidth(700), ScreenSize.medium);
      expect(ResponsiveUtils.getScreenSizeFromWidth(839), ScreenSize.medium);
      expect(ResponsiveUtils.getScreenSizeFromWidth(840), ScreenSize.expanded);
      expect(ResponsiveUtils.getScreenSizeFromWidth(1200), ScreenSize.expanded);
    });
  });

  group('ResponsiveUtils.shouldUseSideBySideLayout', () {
    testWidgets('returns false for compact', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.shouldUseSideBySideLayout(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for medium in landscape', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 400)), // landscape
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.shouldUseSideBySideLayout(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for expanded', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 768)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.shouldUseSideBySideLayout(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
