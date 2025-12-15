import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('SubtitlePosition', () {
    test('has all expected values', () {
      expect(SubtitlePosition.values, hasLength(3));
      expect(SubtitlePosition.values, contains(SubtitlePosition.top));
      expect(SubtitlePosition.values, contains(SubtitlePosition.middle));
      expect(SubtitlePosition.values, contains(SubtitlePosition.bottom));
    });
  });

  group('SubtitleTextAlignment', () {
    test('has all expected values', () {
      expect(SubtitleTextAlignment.values, hasLength(3));
      expect(SubtitleTextAlignment.values, contains(SubtitleTextAlignment.left));
      expect(SubtitleTextAlignment.values, contains(SubtitleTextAlignment.center));
      expect(SubtitleTextAlignment.values, contains(SubtitleTextAlignment.right));
    });
  });

  group('SubtitleStyle', () {
    group('constructor', () {
      test('creates with default values', () {
        const style = SubtitleStyle();

        expect(style.fontSizePercent, equals(1.0));
        expect(style.fontFamily, isNull);
        expect(style.fontWeight, isNull);
        expect(style.textColor, isNull);
        expect(style.backgroundColor, isNull);
        expect(style.strokeColor, isNull);
        expect(style.strokeWidth, isNull);
        expect(style.position, equals(SubtitlePosition.bottom));
        expect(style.textAlignment, equals(SubtitleTextAlignment.center));
        expect(style.containerBorderRadius, equals(4.0));
        expect(style.containerPadding, equals(const EdgeInsets.symmetric(horizontal: 12, vertical: 6)));
        expect(style.marginFromEdge, equals(48.0));
        expect(style.horizontalMargin, equals(16.0));
      });

      test('creates with custom values', () {
        const style = SubtitleStyle(
          fontSizePercent: 1.5, // 150% of default
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
          textColor: Color(0xFFFFFF00),
          backgroundColor: Color(0x80000000),
          strokeColor: Color(0xFF000000),
          strokeWidth: 2,
          position: SubtitlePosition.top,
          textAlignment: SubtitleTextAlignment.left,
          containerBorderRadius: 8,
          containerPadding: EdgeInsets.all(16),
          marginFromEdge: 100,
          horizontalMargin: 32,
        );

        expect(style.fontSizePercent, equals(1.5));
        expect(style.fontFamily, equals('Roboto'));
        expect(style.fontWeight, equals(FontWeight.bold));
        expect(style.textColor, equals(const Color(0xFFFFFF00)));
        expect(style.backgroundColor, equals(const Color(0x80000000)));
        expect(style.strokeColor, equals(const Color(0xFF000000)));
        expect(style.strokeWidth, equals(2.0));
        expect(style.position, equals(SubtitlePosition.top));
        expect(style.textAlignment, equals(SubtitleTextAlignment.left));
        expect(style.containerBorderRadius, equals(8.0));
        expect(style.containerPadding, equals(const EdgeInsets.all(16)));
        expect(style.marginFromEdge, equals(100.0));
        expect(style.horizontalMargin, equals(32.0));
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const original = SubtitleStyle(
          fontSizePercent: 1.25,
          textColor: Color(0xFFFFFFFF),
          position: SubtitlePosition.middle,
        );

        final copy = original.copyWith();

        expect(copy.fontSizePercent, equals(original.fontSizePercent));
        expect(copy.textColor, equals(original.textColor));
        expect(copy.position, equals(original.position));
      });

      test('copies with changes', () {
        const original = SubtitleStyle(fontSizePercent: 1.25, textColor: Color(0xFFFFFFFF));

        final copy = original.copyWith(fontSizePercent: 1.5, strokeColor: const Color(0xFF000000), strokeWidth: 1.5);

        expect(copy.fontSizePercent, equals(1.5));
        expect(copy.textColor, equals(original.textColor));
        expect(copy.strokeColor, equals(const Color(0xFF000000)));
        expect(copy.strokeWidth, equals(1.5));
      });
    });

    group('toTextAlign', () {
      test('converts left alignment', () {
        const style = SubtitleStyle(textAlignment: SubtitleTextAlignment.left);
        expect(style.toTextAlign(), equals(TextAlign.left));
      });

      test('converts center alignment', () {
        const style = SubtitleStyle();
        expect(style.toTextAlign(), equals(TextAlign.center));
      });

      test('converts right alignment', () {
        const style = SubtitleStyle(textAlignment: SubtitleTextAlignment.right);
        expect(style.toTextAlign(), equals(TextAlign.right));
      });
    });

    group('hasStroke', () {
      test('returns false when strokeColor is null', () {
        const style = SubtitleStyle(strokeWidth: 2);
        expect(style.hasStroke, isFalse);
      });

      test('returns false when strokeWidth is null', () {
        const style = SubtitleStyle(strokeColor: Color(0xFF000000));
        expect(style.hasStroke, isFalse);
      });

      test('returns false when strokeWidth is zero', () {
        const style = SubtitleStyle(strokeColor: Color(0xFF000000), strokeWidth: 0);
        expect(style.hasStroke, isFalse);
      });

      test('returns true when both strokeColor and strokeWidth are set', () {
        const style = SubtitleStyle(strokeColor: Color(0xFF000000), strokeWidth: 2);
        expect(style.hasStroke, isTrue);
      });
    });

    group('equality', () {
      test('equal styles are equal', () {
        const style1 = SubtitleStyle(fontSizePercent: 1.25, textColor: Color(0xFFFFFFFF));
        const style2 = SubtitleStyle(fontSizePercent: 1.25, textColor: Color(0xFFFFFFFF));

        expect(style1, equals(style2));
        expect(style1.hashCode, equals(style2.hashCode));
      });

      test('styles with different fontSizePercent are not equal', () {
        const style1 = SubtitleStyle(fontSizePercent: 1.25);
        const style2 = SubtitleStyle(fontSizePercent: 1.5);

        expect(style1, isNot(equals(style2)));
      });

      test('styles with different position are not equal', () {
        const style1 = SubtitleStyle(position: SubtitlePosition.top);
        const style2 = SubtitleStyle();

        expect(style1, isNot(equals(style2)));
      });

      test('styles with different alignment are not equal', () {
        const style1 = SubtitleStyle(textAlignment: SubtitleTextAlignment.left);
        const style2 = SubtitleStyle(textAlignment: SubtitleTextAlignment.right);

        expect(style1, isNot(equals(style2)));
      });

      test('identical styles are equal', () {
        const style = SubtitleStyle(fontSizePercent: 1.25);
        expect(style, equals(style));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        const style = SubtitleStyle(fontSizePercent: 1.25, textColor: Color(0xFFFFFFFF));

        final str = style.toString();
        expect(str, contains('SubtitleStyle'));
        expect(str, contains('fontSizePercent: 1.25'));
        expect(str, contains('position: SubtitlePosition.bottom'));
      });
    });

    group('default styles work correctly', () {
      test('default position is bottom', () {
        const style = SubtitleStyle();
        expect(style.position, equals(SubtitlePosition.bottom));
      });

      test('default alignment is center', () {
        const style = SubtitleStyle();
        expect(style.textAlignment, equals(SubtitleTextAlignment.center));
      });

      test('default border radius is 4', () {
        const style = SubtitleStyle();
        expect(style.containerBorderRadius, equals(4.0));
      });

      test('default marginFromEdge is 48 to avoid controls overlap', () {
        const style = SubtitleStyle();
        expect(style.marginFromEdge, equals(48.0));
      });

      test('default fontSizePercent is 100%', () {
        const style = SubtitleStyle();
        expect(style.fontSizePercent, equals(1.0));
      });
    });
  });
}
