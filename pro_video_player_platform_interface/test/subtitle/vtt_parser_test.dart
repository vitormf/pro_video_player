import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'test_logger.dart';

/// Loads a fixture file from the test/subtitle/fixtures directory.
String loadFixture(String path) {
  final file = File('test/subtitle/fixtures/$path');
  return file.readAsStringSync();
}

void main() {
  group('VttParser', () {
    late VttParser parser;

    setUp(() {
      parser = const VttParser();
    });

    test('parses simple WebVTT content', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Hello, world!

00:00:06.000 --> 00:00:10.500
This is a test.
''';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(2));

      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(cues[0].end, equals(const Duration(seconds: 5)));
      expect(cues[0].text, equals('Hello, world!'));

      expect(cues[1].start, equals(const Duration(seconds: 6)));
      expect(cues[1].end, equals(const Duration(seconds: 10, milliseconds: 500)));
      expect(cues[1].text, equals('This is a test.'));
    });

    test('parses VTT with cue identifiers', () {
      const vtt = '''
WEBVTT

intro
00:00:01.000 --> 00:00:05.000
Introduction

main-content
00:00:06.000 --> 00:00:10.000
Main content
''';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(2));
      expect(cues[0].text, equals('Introduction'));
      expect(cues[1].text, equals('Main content'));
    });

    test('parses multi-line cues', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Line one
Line two
Line three
''';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Line one\nLine two\nLine three'));
    });

    test('handles VTT header with metadata', () {
      const vtt = '''
WEBVTT
Kind: captions
Language: en

00:00:01.000 --> 00:00:05.000
With metadata
''';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('With metadata'));
    });

    test('handles NOTE comments', () {
      const vtt = '''
WEBVTT

NOTE This is a comment

00:00:01.000 --> 00:00:05.000
After comment

NOTE Another comment
that spans multiple lines

00:00:06.000 --> 00:00:10.000
After multi-line comment
''';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(2));
      expect(cues[0].text, equals('After comment'));
      expect(cues[1].text, equals('After multi-line comment'));
    });

    test('handles STYLE blocks', () {
      const vtt = '''
WEBVTT

STYLE
::cue {
  color: white;
  background: black;
}

00:00:01.000 --> 00:00:05.000
Styled text
''';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Styled text'));
    });

    test('handles REGION blocks', () {
      const vtt = '''
WEBVTT

REGION
id:top
width:40%
lines:3

00:00:01.000 --> 00:00:05.000
In region
''';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('In region'));
    });

    test('ignores cue settings', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000 position:50% line:63% align:middle
Positioned subtitle
''';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(1));
      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(cues[0].end, equals(const Duration(seconds: 5)));
    });

    test('strips voice tags', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
<v Speaker1>Hello there!
''';

      final cues = parser.parse(vtt);

      expect(cues[0].text, equals('Hello there!'));
    });

    test('strips class tags', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
<c.yellow>Yellow text</c>
''';

      final cues = parser.parse(vtt);

      expect(cues[0].text, equals('Yellow text'));
    });

    test('strips timestamp tags', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Word<00:00:02.000> by<00:00:03.000> word
''';

      final cues = parser.parse(vtt);

      expect(cues[0].text, equals('Word by word'));
    });

    test('handles timestamps without hours', () {
      const vtt = '''
WEBVTT

01:30.500 --> 01:35.750
Short format
''';

      final cues = parser.parse(vtt);

      expect(cues[0].start, equals(const Duration(minutes: 1, seconds: 30, milliseconds: 500)));
      expect(cues[0].end, equals(const Duration(minutes: 1, seconds: 35, milliseconds: 750)));
    });

    test('handles timestamps with hours', () {
      const vtt = '''
WEBVTT

01:30:45.123 --> 02:00:00.000
Long video
''';

      final cues = parser.parse(vtt);

      expect(cues[0].start, equals(const Duration(hours: 1, minutes: 30, seconds: 45, milliseconds: 123)));
      expect(cues[0].end, equals(const Duration(hours: 2)));
    });

    test('handles empty content', () {
      const vtt = 'WEBVTT\n\n';

      final cues = parser.parse(vtt);

      expect(cues, isEmpty);
    });

    test('handles content without WEBVTT header', () {
      const vtt = '''
00:00:01.000 --> 00:00:05.000
No header
''';

      // Some VTT files may lack the header, parser should still try to parse
      final cues = parser.parse(vtt);

      expect(cues, hasLength(1));
    });

    test('handles Windows line endings', () {
      const vtt = 'WEBVTT\r\n\r\n00:00:01.000 --> 00:00:05.000\r\nTest\r\n';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Test'));
    });

    test('handles BOM', () {
      const vtt = '\uFEFFWEBVTT\n\n00:00:01.000 --> 00:00:05.000\nWith BOM\n';

      final cues = parser.parse(vtt);

      expect(cues, hasLength(1));
    });

    group('timestamp parsing', () {
      test('parses HH:MM:SS.mmm format', () {
        final duration = VttParser.parseTimestamp('01:23:45.678');
        expect(duration, equals(const Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678)));
      });

      test('parses MM:SS.mmm format', () {
        final duration = VttParser.parseTimestamp('23:45.678');
        expect(duration, equals(const Duration(minutes: 23, seconds: 45, milliseconds: 678)));
      });

      test('parses zero timestamp', () {
        final duration = VttParser.parseTimestamp('00:00:00.000');
        expect(duration, equals(Duration.zero));
      });

      test('returns null for invalid timestamp', () {
        expect(VttParser.parseTimestamp('invalid'), isNull);
        expect(VttParser.parseTimestamp('1:2:3'), isNull);
        expect(VttParser.parseTimestamp(''), isNull);
      });
    });

    // Real-world samples based on W3C spec and MDN examples
    group('real-world samples', () {
      // Source: https://developer.mozilla.org/en-US/docs/Web/API/WebVTT_API
      test('parses MDN basic example', () {
        const vtt = '''
WEBVTT

00:00.000 --> 00:00.900
Hildy!

00:01.000 --> 00:01.400
How are you?

00:01.500 --> 00:02.900
Tell me, is the lord of the universe in?
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Hildy!'));
        expect(cues[0].start, equals(Duration.zero));
        expect(cues[0].end, equals(const Duration(milliseconds: 900)));

        expect(cues[1].text, equals('How are you?'));
        expect(cues[1].start, equals(const Duration(seconds: 1)));

        expect(cues[2].text, equals('Tell me, is the lord of the universe in?'));
      });

      // Source: https://www.w3.org/TR/webvtt1/ (W3C WebVTT Specification)
      test('parses W3C speaker annotation example', () {
        const vtt = '''
WEBVTT

00:11.000 --> 00:13.000
<v Roger Bingham>We are in New York City

00:13.000 --> 00:16.000
<v Roger Bingham>We're actually at the Lucern Hotel, just down the street

00:16.000 --> 00:18.000
<v Neil deGrasse Tyson>Didn't you stay at the Lucern?
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));
        // Speaker tags should be stripped
        expect(cues[0].text, equals('We are in New York City'));
        expect(cues[1].text, equals("We're actually at the Lucern Hotel, just down the street"));
        expect(cues[2].text, equals("Didn't you stay at the Lucern?"));
      });

      // Source: https://gist.github.com/brenopolanski/subtitle-example
      test('parses cues with identifiers and formatting', () {
        const vtt = '''
WEBVTT

1
00:00:22.230 --> 00:00:24.606
This is the first subtitle.

2 Some Text
00:00:30.739 --> 00:00:34.074
This is the second.

3
00:00:34.159 --> 00:00:35.743
This is the third
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('This is the first subtitle.'));
        expect(cues[1].text, equals('This is the second.'));
        expect(cues[2].text, equals('This is the third'));
      });

      // Source: https://www.w3.org/TR/webvtt1/#cue-settings (W3C cue positioning spec)
      test('parses cues with positioning and styling', () {
        const vtt = '''
WEBVTT

00:00:00.000 --> 00:00:04.000 position:10%,line-left align:left size:35%
Where did he go?

00:00:03.000 --> 00:00:06.500 position:90% align:right size:35%
I think he went down this lane.

00:00:04.000 --> 00:00:06.500 position:45%,line-right align:center size:35%
What are you waiting for?
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Where did he go?'));
        expect(cues[1].text, equals('I think he went down this lane.'));
        expect(cues[2].text, equals('What are you waiting for?'));
      });

      // Source: https://developer.mozilla.org/en-US/docs/Web/API/WebVTT_API#styling_webvtt_cues
      test('parses styled content with HTML-like tags', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
<b>Bold text</b> and <i>italic text</i>

00:00:06.000 --> 00:00:10.000
<u>Underlined</u> text here

00:00:11.000 --> 00:00:15.000
<c.yellow>Yellow colored text</c>
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Bold text and italic text'));
        expect(cues[1].text, equals('Underlined text here'));
        expect(cues[2].text, equals('Yellow colored text'));
      });

      // Source: https://www.w3.org/TR/webvtt1/#cue-text-parsing-rules (karaoke timing)
      test('parses karaoke-style cues with inline timestamps', () {
        const vtt = '''
WEBVTT

00:00:00.000 --> 00:00:12.000
<00:00:00.500>This<00:00:01.000> is<00:00:01.500> karaoke<00:00:02.000> style
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(1));
        // Inline timestamps should be stripped
        expect(cues[0].text, equals('This is karaoke style'));
      });

      // Source: Combined example from W3C spec showing STYLE, REGION, and NOTE blocks
      test('parses complete VTT with all sections', () {
        const vtt = '''
WEBVTT
Kind: captions
Language: en

STYLE
::cue {
  font-family: "Comic Sans MS", sans-serif;
  color: white;
  background-color: rgba(0, 0, 0, 0.8);
}

NOTE This is a comment that should be ignored

REGION
id:region-1
width:50%
lines:3
regionanchor:100%,100%
viewportanchor:90%,90%
scroll:up

intro
00:00:00.000 --> 00:00:04.000 region:region-1
Welcome to the show!

main
00:00:05.000 --> 00:00:10.000
<v Host>Today we're discussing subtitles.

NOTE Another comment here

outro
00:00:15.000 --> 00:00:20.000
Thanks for watching!
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Welcome to the show!'));
        expect(cues[1].text, equals("Today we're discussing subtitles."));
        expect(cues[2].text, equals('Thanks for watching!'));
      });

      // Source: Multi-line dialogue patterns from YouTube auto-captions
      test('parses multi-line cues with various formats', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
First line
Second line
Third line

00:00:06.000 --> 00:00:10.000
<v Speaker>Line one
<v Speaker>Line two

00:00:11.000 --> 00:00:15.000
- Dialogue line one
- Dialogue line two
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('First line\nSecond line\nThird line'));
        expect(cues[1].text, equals('Line one\nLine two'));
        expect(cues[2].text, equals('- Dialogue line one\n- Dialogue line two'));
      });

      // Source: International subtitle patterns from TED Talks translations
      test('parses international characters correctly', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Bonjour! Comment ça va?

00:00:06.000 --> 00:00:10.000
Guten Tag! Wie geht's?

00:00:11.000 --> 00:00:15.000
こんにちは！元気ですか？

00:00:16.000 --> 00:00:20.000
مرحبا! كيف حالك؟
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(4));
        expect(cues[0].text, equals('Bonjour! Comment ça va?'));
        expect(cues[1].text, equals("Guten Tag! Wie geht's?"));
        expect(cues[2].text, equals('こんにちは！元気ですか？'));
        expect(cues[3].text, equals('مرحبا! كيف حالك؟'));
      });

      // Source: Netflix SDH (Subtitles for Deaf and Hard of Hearing) guidelines
      test('parses accessibility captions with sound descriptions', () {
        const vtt = '''
WEBVTT

00:00:00.000 --> 00:00:03.000
[UPBEAT MUSIC PLAYING]

00:00:04.000 --> 00:00:07.000
[DOOR OPENS]

00:00:08.000 --> 00:00:12.000
<v JOHN>(nervously) Hello?

00:00:13.000 --> 00:00:17.000
[FOOTSTEPS APPROACHING]

00:00:18.000 --> 00:00:22.000
(whispering) Over here!
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(5));
        expect(cues[0].text, equals('[UPBEAT MUSIC PLAYING]'));
        expect(cues[1].text, equals('[DOOR OPENS]'));
        expect(cues[2].text, equals('(nervously) Hello?'));
        expect(cues[3].text, equals('[FOOTSTEPS APPROACHING]'));
        expect(cues[4].text, equals('(whispering) Over here!'));
      });
    });

    // Tests using external fixture files
    group('fixture files', () {
      // Source: https://github.com/mhdz0791/sampleWebVTT
      test('parses sample_mhdz.vtt basic WebVTT tutorial', () {
        final vtt = loadFixture('vtt/sample_mhdz.vtt');
        final cues = parser.parse(vtt);

        expect(cues, hasLength(12));
        expect(cues[0].text, equals('Welcome to the WebVTT tutorial.'));
        expect(cues[0].start, equals(Duration.zero));
        expect(cues[0].end, equals(const Duration(seconds: 5)));
        expect(cues.last.text, equals('Thank you for watching this tutorial!'));
      });

      // Source: https://github.com/1c7/vtt-test-file
      test('parses sample_with_index.vtt with cue identifiers', () {
        final vtt = loadFixture('vtt/sample_with_index.vtt');
        final cues = parser.parse(vtt);

        expect(cues, hasLength(92));
        expect(cues[0].text, contains('Hi, welcome to the specialization'));
        expect(cues[0].start, equals(const Duration(seconds: 10, milliseconds: 520)));
      });

      // Source: https://github.com/1c7/vtt-test-file
      test('parses sample_no_hour.vtt without hour component', () {
        final vtt = loadFixture('vtt/sample_no_hour.vtt');
        final cues = parser.parse(vtt);

        expect(cues, hasLength(7));
        expect(cues[0].text, equals('We are in New York City'));
        expect(cues[0].start, equals(const Duration(seconds: 11)));
        expect(cues[0].end, equals(const Duration(seconds: 13)));
      });

      // Source: https://github.com/1c7/vtt-test-file
      test('parses sample_position.vtt with positioning settings', () {
        final vtt = loadFixture('vtt/sample_position.vtt');
        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Where did he go?'));
        expect(cues[1].text, equals('I think he went down this lane.'));
        expect(cues[2].text, equals('What are you waiting for?'));
      });

      // Source: https://github.com/1c7/vtt-test-file
      test('parses sample_region.vtt with REGION blocks', () {
        final vtt = loadFixture('vtt/sample_region.vtt');
        final cues = parser.parse(vtt);

        expect(cues, hasLength(6));
        // Voice tags should be stripped
        expect(cues[0].text, equals('Hi, my name is Fred'));
        // File uses curly apostrophe (U+2019)
        expect(cues[1].text, contains('Bill'));
      });

      // Source: https://github.com/1c7/vtt-test-file
      test('parses sample_comment.vtt with NOTE blocks', () {
        final vtt = loadFixture('vtt/sample_comment.vtt');
        final cues = parser.parse(vtt);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('Never drink liquid nitrogen.'));
        expect(cues[1].text, contains('It will perforate your stomach'));
      });

      // Source: https://github.com/asticode/go-astisub (MIT License)
      // Tests STYLE blocks, REGION definitions, positioning, and inline comments
      test('parses sample_go_astisub.vtt with styles and regions', () {
        final vtt = loadFixture('vtt/sample_go_astisub.vtt');
        final cues = parser.parse(vtt);

        expect(cues, hasLength(6));

        // First cue - with region reference
        expect(cues[0].text, equals('(deep rumbling)'));
        expect(cues[0].start, equals(const Duration(minutes: 1, seconds: 39)));
        expect(cues[0].end, equals(const Duration(minutes: 1, seconds: 41, milliseconds: 40)));

        // Second cue - with positioning and region
        expect(cues[1].text, equals('MAN:\nHow did we end up here?'));
        expect(cues[1].start, equals(const Duration(minutes: 2, seconds: 4, milliseconds: 80)));
        expect(cues[1].end, equals(const Duration(minutes: 2, seconds: 7, milliseconds: 120)));

        // Third cue - missing index number (tests robustness)
        expect(cues[2].text, equals('This place is horrible.'));
        expect(cues[2].start, equals(const Duration(minutes: 2, seconds: 12, milliseconds: 160)));

        // Multi-line cue
        expect(cues[4].text, equals("We don't belong\nin this shithole."));

        // Last cue
        expect(cues[5].text, equals('(computer playing\nelectronic melody)'));
      });
    });

    group('comprehensive fixture validation', () {
      test('all VTT fixture files parse without errors', () {
        // Get all .vtt files from fixtures directory
        final fixtureDir = Directory('test/subtitle/fixtures/vtt');
        final vttFiles = fixtureDir.listSync().whereType<File>().where((file) => file.path.endsWith('.vtt')).toList()
          ..sort((a, b) => a.path.compareTo(b.path));

        expect(vttFiles.length, greaterThanOrEqualTo(20), reason: 'Should have at least 20 VTT test files');

        final results = <String, ParseResult>{};

        for (final file in vttFiles) {
          final fileName = file.path.split('/').last;
          final content = file.readAsStringSync();

          try {
            final cues = parser.parse(content);
            results[fileName] = ParseResult(success: true, cueCount: cues.length);
          } catch (e) {
            results[fileName] = ParseResult(success: false, cueCount: 0, error: e.toString());
          }
        }

        // Print summary using TestLogger
        TestLogger.header('VTT Parser Validation Results');
        TestLogger.log('Total files: ${vttFiles.length}');

        var successCount = 0;
        var totalCues = 0;

        for (final entry in results.entries) {
          if (entry.value.success) {
            successCount++;
            totalCues += entry.value.cueCount;
            TestLogger.success('${entry.key}: ${entry.value.cueCount} cues');
          } else {
            TestLogger.error('${entry.key}: ${entry.value.error}');
          }
        }

        TestLogger.summary('Summary: $successCount/${vttFiles.length} files parsed successfully');
        TestLogger.log('Total cues parsed: $totalCues');
        TestLogger.footer('========================================');

        // All files should parse successfully
        final failures = results.entries.where((e) => !e.value.success).toList();
        expect(
          failures,
          isEmpty,
          reason:
              'All VTT files should parse without errors. '
              'Failures: ${failures.map((e) => '${e.key}: ${e.value.error}').join(', ')}',
        );
      });
    });

    group('styled spans (rich text formatting)', () {
      test('parses bold tags into styledSpans', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Normal <b>bold</b> normal
''';

        final cues = parser.parse(vtt);

        expect(cues[0].text, equals('Normal bold normal'));
        expect(cues[0].hasStyledSpans, isTrue);

        final spans = cues[0].styledSpans!;
        expect(spans, hasLength(3));

        expect(spans[0].text, equals('Normal '));
        expect(spans[0].hasStyle, isFalse);

        expect(spans[1].text, equals('bold'));
        expect(spans[1].style!.isBold, isTrue);
        expect(spans[1].style!.isItalic, isFalse);

        expect(spans[2].text, equals(' normal'));
        expect(spans[2].hasStyle, isFalse);
      });

      test('parses italic tags into styledSpans', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Normal <i>italic</i> normal
''';

        final cues = parser.parse(vtt);

        final spans = cues[0].styledSpans!;
        expect(spans[0].text, equals('Normal '));
        expect(spans[0].hasStyle, isFalse);

        expect(spans[1].text, equals('italic'));
        expect(spans[1].style!.isItalic, isTrue);
        expect(spans[1].style!.isBold, isFalse);

        expect(spans[2].text, equals(' normal'));
        expect(spans[2].hasStyle, isFalse);
      });

      test('parses underline tags into styledSpans', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Normal <u>underlined</u> normal
''';

        final cues = parser.parse(vtt);

        final spans = cues[0].styledSpans!;
        expect(spans[1].text, equals('underlined'));
        expect(spans[1].style!.isUnderline, isTrue);
      });

      test('parses nested tags correctly', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
<b>Bold <i>bold+italic</i> just bold</b> normal
''';

        final cues = parser.parse(vtt);

        final spans = cues[0].styledSpans!;

        // "Bold "
        expect(spans[0].text, equals('Bold '));
        expect(spans[0].style!.isBold, isTrue);
        expect(spans[0].style!.isItalic, isFalse);

        // "bold+italic"
        expect(spans[1].text, equals('bold+italic'));
        expect(spans[1].style!.isBold, isTrue);
        expect(spans[1].style!.isItalic, isTrue);

        // " just bold"
        expect(spans[2].text, equals(' just bold'));
        expect(spans[2].style!.isBold, isTrue);
        expect(spans[2].style!.isItalic, isFalse);

        // " normal"
        expect(spans[3].text, equals(' normal'));
        expect(spans[3].hasStyle, isFalse);
      });

      test('parses multiple separate styled sections', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
<b>Bold</b> and <i>italic</i> and <u>underlined</u>
''';

        final cues = parser.parse(vtt);

        final spans = cues[0].styledSpans!;
        expect(spans, hasLength(5));

        expect(spans[0].text, equals('Bold'));
        expect(spans[0].style!.isBold, isTrue);

        expect(spans[1].text, equals(' and '));
        expect(spans[1].hasStyle, isFalse);

        expect(spans[2].text, equals('italic'));
        expect(spans[2].style!.isItalic, isTrue);

        expect(spans[3].text, equals(' and '));
        expect(spans[3].hasStyle, isFalse);

        expect(spans[4].text, equals('underlined'));
        expect(spans[4].style!.isUnderline, isTrue);
      });

      test('handles plain text without tags', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Plain text without any styling
''';

        final cues = parser.parse(vtt);

        expect(cues[0].hasStyledSpans, isTrue);
        final spans = cues[0].styledSpans!;

        expect(spans, hasLength(1));
        expect(spans[0].text, equals('Plain text without any styling'));
        expect(spans[0].hasStyle, isFalse);
      });

      test('strips non-styling tags like voice and class', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
<v Speaker><b>Bold speaker</b></v> and <b>bold text</b>
''';

        final cues = parser.parse(vtt);

        // Voice tags are stripped, but bold is preserved
        expect(cues[0].text, equals('Bold speaker and bold text'));

        final spans = cues[0].styledSpans!;

        // First span should be "Bold speaker" with bold styling
        expect(spans[0].text, equals('Bold speaker'));
        expect(spans[0].style!.isBold, isTrue);

        // Second span should be " and " without styling
        expect(spans[1].text, equals(' and '));
        expect(spans[1].hasStyle, isFalse);

        // Third span should be "bold text" with bold styling
        expect(spans[2].text, equals('bold text'));
        expect(spans[2].style!.isBold, isTrue);
      });

      test('handles malformed/unclosed tags gracefully', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
<b>Unclosed bold tag and <i>closed italic</i>
''';

        final cues = parser.parse(vtt);

        // Should still parse successfully
        expect(cues, hasLength(1));
        expect(cues[0].hasStyledSpans, isTrue);
      });

      test('handles complex real-world WebVTT with styling', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:03.000
<v John><b>JOHN:</b> Hello there!</v>

00:00:04.000 --> 00:00:06.000
<v Mary><i>Mary thinking:</i> What should I say?</v>

00:00:07.000 --> 00:00:09.000
<b><i>Bold and italic together</i></b>
''';

        final cues = parser.parse(vtt);

        expect(cues, hasLength(3));

        // First cue: bold "JOHN:"
        expect(cues[0].text, equals('JOHN: Hello there!'));
        final spans0 = cues[0].styledSpans!;
        expect(spans0[0].text, equals('JOHN:'));
        expect(spans0[0].style!.isBold, isTrue);

        // Second cue: italic "Mary thinking:"
        expect(cues[1].text, equals('Mary thinking: What should I say?'));
        final spans1 = cues[1].styledSpans!;
        expect(spans1[0].text, equals('Mary thinking:'));
        expect(spans1[0].style!.isItalic, isTrue);

        // Third cue: both bold and italic
        expect(cues[2].text, equals('Bold and italic together'));
        final spans2 = cues[2].styledSpans!;
        expect(spans2[0].text, equals('Bold and italic together'));
        expect(spans2[0].style!.isBold, isTrue);
        expect(spans2[0].style!.isItalic, isTrue);
      });

      test('handles multiple tags on same text', () {
        const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
<b><i><u>Triple styling</u></i></b>
''';

        final cues = parser.parse(vtt);

        final spans = cues[0].styledSpans!;
        expect(spans[0].text, equals('Triple styling'));
        expect(spans[0].style!.isBold, isTrue);
        expect(spans[0].style!.isItalic, isTrue);
        expect(spans[0].style!.isUnderline, isTrue);
      });
    });
  });
}
