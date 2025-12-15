import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('WebVttConverter', () {
    group('convert', () {
      test('converts empty cue list to minimal WebVTT', () {
        final result = WebVttConverter.convert([]);

        expect(result, equals('WEBVTT\n'));
      });

      test('converts single plain text cue', () {
        final cues = [
          const SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello World'),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'Hello World\n',
          ),
        );
      });

      test('converts multiple cues', () {
        final cues = [
          const SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'First subtitle'),
          const SubtitleCue(index: 2, start: Duration(seconds: 6), end: Duration(seconds: 10), text: 'Second subtitle'),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'First subtitle\n\n'
            '00:00:06.000 --> 00:00:10.000\n'
            'Second subtitle\n',
          ),
        );
      });

      test('converts multiline text', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
            text: 'Line 1\nLine 2\nLine 3',
          ),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'Line 1\n'
            'Line 2\n'
            'Line 3\n',
          ),
        );
      });

      test('handles timestamps with hours and milliseconds correctly', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678),
            end: Duration(hours: 2, minutes: 34, seconds: 56, milliseconds: 789),
            text: 'Test',
          ),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '01:23:45.678 --> 02:34:56.789\n'
            'Test\n',
          ),
        );
      });

      test('converts cue with bold styling', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
            text: 'Hello world',
            styledSpans: [
              StyledTextSpan(text: 'Hello ', style: SubtitleTextStyle()),
              StyledTextSpan(text: 'world', style: SubtitleTextStyle(isBold: true)),
            ],
          ),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'Hello <b>world</b>\n',
          ),
        );
      });

      test('converts cue with italic styling', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
            text: 'Hello world',
            styledSpans: [
              StyledTextSpan(text: 'Hello ', style: SubtitleTextStyle()),
              StyledTextSpan(text: 'world', style: SubtitleTextStyle(isItalic: true)),
            ],
          ),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'Hello <i>world</i>\n',
          ),
        );
      });

      test('converts cue with underline styling', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
            text: 'Hello world',
            styledSpans: [
              StyledTextSpan(text: 'Hello ', style: SubtitleTextStyle()),
              StyledTextSpan(text: 'world', style: SubtitleTextStyle(isUnderline: true)),
            ],
          ),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'Hello <u>world</u>\n',
          ),
        );
      });

      test('converts cue with combined styling (bold + italic)', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
            text: 'Hello world',
            styledSpans: [
              StyledTextSpan(text: 'Hello ', style: SubtitleTextStyle()),
              StyledTextSpan(text: 'world', style: SubtitleTextStyle(isBold: true, isItalic: true)),
            ],
          ),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'Hello <b><i>world</i></b>\n',
          ),
        );
      });

      test('converts cue with multiple styled spans', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
            text: 'Hello world again',
            styledSpans: [
              StyledTextSpan(text: 'Hello ', style: SubtitleTextStyle(isBold: true)),
              StyledTextSpan(text: 'world ', style: SubtitleTextStyle(isItalic: true)),
              StyledTextSpan(text: 'again', style: SubtitleTextStyle(isUnderline: true)),
            ],
          ),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            '<b>Hello </b><i>world </i><u>again</u>\n',
          ),
        );
      });

      test('ignores unsupported styling (colors, fonts)', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
            text: 'Hello world',
            styledSpans: [
              StyledTextSpan(text: 'Hello ', style: SubtitleTextStyle()),
              StyledTextSpan(
                text: 'world',
                style: SubtitleTextStyle(
                  isBold: true,
                  color: Color(0xFFFF0000), // Red - not supported in basic WebVTT
                  fontSize: 20, // Not supported in basic WebVTT
                ),
              ),
            ],
          ),
        ];

        final result = WebVttConverter.convert(cues);

        // Should only apply bold, ignore color and fontSize
        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'Hello <b>world</b>\n',
          ),
        );
      });

      test('falls back to plain text when no styling', () {
        final cues = [
          const SubtitleCue(
            index: 1,
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
            text: 'Plain text',
            styledSpans: [], // Empty styled spans
          ),
        ];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'Plain text\n',
          ),
        );
      });

      test('handles cues without indices', () {
        final cues = [const SubtitleCue(start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'No index')];

        final result = WebVttConverter.convert(cues);

        expect(
          result,
          equals(
            'WEBVTT\n\n'
            '00:00:01.000 --> 00:00:05.000\n'
            'No index\n',
          ),
        );
      });
    });

    group('formatTimestamp', () {
      test('formats zero duration', () {
        expect(WebVttConverter.formatTimestamp(Duration.zero), equals('00:00:00.000'));
      });

      test('formats seconds only', () {
        expect(WebVttConverter.formatTimestamp(const Duration(seconds: 45)), equals('00:00:45.000'));
      });

      test('formats minutes and seconds', () {
        expect(WebVttConverter.formatTimestamp(const Duration(minutes: 12, seconds: 34)), equals('00:12:34.000'));
      });

      test('formats hours, minutes, and seconds', () {
        expect(
          WebVttConverter.formatTimestamp(const Duration(hours: 2, minutes: 30, seconds: 15)),
          equals('02:30:15.000'),
        );
      });

      test('formats with milliseconds', () {
        expect(
          WebVttConverter.formatTimestamp(const Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678)),
          equals('01:23:45.678'),
        );
      });

      test('pads single digits correctly', () {
        expect(
          WebVttConverter.formatTimestamp(const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 4)),
          equals('01:02:03.004'),
        );
      });
    });
  });
}
