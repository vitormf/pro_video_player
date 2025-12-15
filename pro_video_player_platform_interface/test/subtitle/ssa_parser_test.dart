import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'test_logger.dart';

/// Loads a fixture file from the test/subtitle/fixtures directory.
String loadFixture(String path) {
  final file = File('test/subtitle/fixtures/$path');
  return file.readAsStringSync();
}

void main() {
  group('SsaParser', () {
    late SsaParser parser;

    setUp(() {
      parser = const SsaParser();
    });

    test('parses simple SSA content', () {
      const ssa = '''
[Script Info]
Title: Test

[V4+ Styles]
Format: Name, Fontname, Fontsize
Style: Default,Arial,20

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Hello, world!
Dialogue: 0,0:00:06.00,0:00:10.50,Default,,0,0,0,,This is a test.
''';

      final cues = parser.parse(ssa);

      expect(cues, hasLength(2));

      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(cues[0].end, equals(const Duration(seconds: 5)));
      expect(cues[0].text, equals('Hello, world!'));

      expect(cues[1].start, equals(const Duration(seconds: 6)));
      expect(cues[1].end, equals(const Duration(seconds: 10, milliseconds: 500)));
      expect(cues[1].text, equals('This is a test.'));
    });

    test('parses ASS format (same as SSA)', () {
      const ass = '''
[Script Info]
ScriptType: v4.00+

[V4+ Styles]
Style: Default,Arial,20

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,ASS subtitle
''';

      final cues = parser.parse(ass);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('ASS subtitle'));
    });

    test(r'handles multi-line text with \N', () {
      const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Line one\NLine two\NLine three
''';

      final cues = parser.parse(ssa);

      expect(cues[0].text, equals('Line one\nLine two\nLine three'));
    });

    test(r'handles multi-line text with \n (lowercase)', () {
      const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Line one\nLine two
''';

      final cues = parser.parse(ssa);

      expect(cues[0].text, equals('Line one\nLine two'));
    });

    test('strips override tags', () {
      const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\b1}Bold{\b0} and {\i1}italic{\i0}
''';

      final cues = parser.parse(ssa);

      expect(cues[0].text, equals('Bold and italic'));
    });

    test('strips color and font tags', () {
      const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\c&HFFFFFF&}White{\c} {\fn Arial}text{\fn}
''';

      final cues = parser.parse(ssa);

      expect(cues[0].text, equals('White text'));
    });

    test('strips position and animation tags', () {
      const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\pos(100,200)\fad(100,200)}Positioned
''';

      final cues = parser.parse(ssa);

      expect(cues[0].text, equals('Positioned'));
    });

    test('handles timestamps with hours', () {
      const ssa = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,1:30:45.12,2:00:00.00,Default,,0,0,0,,Long video
''';

      final cues = parser.parse(ssa);

      expect(cues[0].start, equals(const Duration(hours: 1, minutes: 30, seconds: 45, milliseconds: 120)));
      expect(cues[0].end, equals(const Duration(hours: 2)));
    });

    test('handles Comment lines (ignored)', () {
      const ssa = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Visible
Comment: 0,0:00:06.00,0:00:10.00,Default,,0,0,0,,Hidden comment
''';

      final cues = parser.parse(ssa);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Visible'));
    });

    test('handles empty [Events] section', () {
      const ssa = '''
[Script Info]
Title: Empty

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
''';

      final cues = parser.parse(ssa);

      expect(cues, isEmpty);
    });

    test('handles content without section headers', () {
      // Minimal SSA with just dialogue
      const ssa = '''
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Minimal
''';

      final cues = parser.parse(ssa);

      expect(cues, hasLength(1));
    });

    test('handles Windows line endings', () {
      const ssa =
          '[Events]\r\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\r\nDialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Test\r\n';

      final cues = parser.parse(ssa);

      expect(cues, hasLength(1));
    });

    test('handles BOM', () {
      const ssa =
          '\uFEFF[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\nDialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,With BOM\n';

      final cues = parser.parse(ssa);

      expect(cues, hasLength(1));
    });

    test('handles text with commas', () {
      const ssa = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Hello, world, with, many, commas
''';

      final cues = parser.parse(ssa);

      expect(cues[0].text, equals('Hello, world, with, many, commas'));
    });

    group('timestamp parsing', () {
      test('parses H:MM:SS.cc format', () {
        final duration = SsaParser.parseTimestamp('1:23:45.67');
        expect(duration, equals(const Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 670)));
      });

      test('parses 0:MM:SS.cc format', () {
        final duration = SsaParser.parseTimestamp('0:01:30.50');
        expect(duration, equals(const Duration(minutes: 1, seconds: 30, milliseconds: 500)));
      });

      test('parses zero timestamp', () {
        final duration = SsaParser.parseTimestamp('0:00:00.00');
        expect(duration, equals(Duration.zero));
      });

      test('returns null for invalid timestamp', () {
        expect(SsaParser.parseTimestamp('invalid'), isNull);
        expect(SsaParser.parseTimestamp(''), isNull);
      });
    });

    // Real-world samples based on MultimediaWiki and anime fansub examples
    group('real-world samples', () {
      test('parses ASS v4+ format from MultimediaWiki', () {
        // Based on https://wiki.multimedia.cx/index.php/SubStation_Alpha
        const ass = '''
[Script Info]
; Script generated by Aegisub
Title: Sample ASS File
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,48,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,2,1,2,10,10,10,1
Style: Italics,Arial,48,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,-1,0,0,100,100,0,0,1,2,1,2,10,10,10,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Welcome to the demonstration.
Dialogue: 0,0:00:06.00,0:00:10.00,Italics,,0,0,0,,This line uses italic style.
Dialogue: 0,0:00:11.00,0:00:15.00,Default,,0,0,0,,Back to default style.
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Welcome to the demonstration.'));
        expect(cues[1].text, equals('This line uses italic style.'));
        expect(cues[2].text, equals('Back to default style.'));
      });

      test('parses typical anime fansub styling', () {
        const ass = r'''
[Script Info]
Title: Anime Episode 01
ScriptType: v4.00+
Collisions: Normal

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Open Sans Semibold,72,&H00FFFFFF,&H000000FF,&H00000000,&H96000000,0,0,0,0,100,100,0,0,1,3.6,0,2,225,225,50,1
Style: Signs,Impact,50,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,2,2,10,10,10,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:05.23,0:00:08.56,Default,,0,0,0,,{\fad(200,200)}Are you ready?
Dialogue: 0,0:00:09.12,0:00:12.45,Default,,0,0,0,,{\pos(960,800)}Let's go!
Dialogue: 0,0:00:15.00,0:00:18.00,Signs,,0,0,0,,{\an8\pos(960,100)\c&H0000FF&}TOKYO STATION
Dialogue: 0,0:00:20.00,0:00:25.00,Default,,0,0,0,,{\b1}Bold{\b0} and {\i1}italic{\i0} text
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(4));
        expect(cues[0].text, equals('Are you ready?'));
        expect(cues[1].text, equals("Let's go!"));
        expect(cues[2].text, equals('TOKYO STATION'));
        expect(cues[3].text, equals('Bold and italic text'));
      });

      test('parses karaoke styling', () {
        const ass = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,0:00:05.00,Default,,0,0,0,,{\k50}La {\k50}la {\k50}la {\k100}laaa
Dialogue: 0,0:00:05.00,0:00:10.00,Default,,0,0,0,,{\kf50}Fade {\kf50}effect
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('La la la laaa'));
        expect(cues[1].text, equals('Fade effect'));
      });

      test('parses SSA v4 format (older version)', () {
        // Based on older SSA format
        const ssa = '''
[Script Info]
; This is a Sub Station Alpha v4 script.
ScriptType: v4.00
Collisions: Normal
PlayResY: 600

[V4 Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, TertiaryColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, AlphaLevel, Encoding
Style: Default,Tahoma,24,16777215,65535,65535,-2147483640,-1,0,1,2,3,2,20,20,20,0,0

[Events]
Format: Marked, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: Marked=0,0:00:01.00,0:00:05.00,Default,,0000,0000,0000,,Old SSA format
Dialogue: Marked=0,0:00:06.00,0:00:10.00,Default,,0000,0000,0000,,Still works!
''';

        final cues = parser.parse(ssa);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('Old SSA format'));
        expect(cues[1].text, equals('Still works!'));
      });

      test('parses complex override tags', () {
        const ass = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\fs48\c&HFFFFFF&\3c&H000000&\bord3\shad2}Styled text
Dialogue: 0,0:00:06.00,0:00:10.00,Default,,0,0,0,,{\an5\pos(640,360)\blur3}Centered and blurred
Dialogue: 0,0:00:11.00,0:00:15.00,Default,,0,0,0,,{\fscx150\fscy75}Stretched text
Dialogue: 0,0:00:16.00,0:00:20.00,Default,,0,0,0,,{\move(100,100,500,500,0,1000)}Moving text
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(4));
        expect(cues[0].text, equals('Styled text'));
        expect(cues[1].text, equals('Centered and blurred'));
        expect(cues[2].text, equals('Stretched text'));
        expect(cues[3].text, equals('Moving text'));
      });

      test('parses drawing commands (stripped)', () {
        const ass = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Normal text before
Dialogue: 0,0:00:06.00,0:00:10.00,Default,,0,0,0,,{\p1}m 0 0 l 100 0 100 100 0 100{\p0}
Dialogue: 0,0:00:11.00,0:00:15.00,Default,,0,0,0,,Normal text after
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Normal text before'));
        // Drawing commands get stripped, leaving the path coordinates
        expect(cues[2].text, equals('Normal text after'));
      });

      test('parses multi-line dialogue with newlines', () {
        const ass = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Line one\NLine two\NLine three
Dialogue: 0,0:00:06.00,0:00:10.00,Default,,0,0,0,,{\an8}Top line\N{\an2}Bottom line
Dialogue: 0,0:00:11.00,0:00:15.00,Default,,0,0,0,,Mixed \n newlines \N work
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Line one\nLine two\nLine three'));
        expect(cues[1].text, equals('Top line\nBottom line'));
        expect(cues[2].text, equals('Mixed \n newlines \n work'));
      });

      test('parses dialogue with speaker names', () {
        const ass = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,John,0,0,0,,Hello there!
Dialogue: 0,0:00:06.00,0:00:10.00,Default,Mary,0,0,0,,Hi John!
Dialogue: 0,0:00:11.00,0:00:15.00,Default,Narrator,0,0,0,,They greeted each other warmly.
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(3));
        // Speaker names are in the Name field, not the Text
        expect(cues[0].text, equals('Hello there!'));
        expect(cues[1].text, equals('Hi John!'));
        expect(cues[2].text, equals('They greeted each other warmly.'));
      });

      test('parses long video timestamps correctly', () {
        const ass = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,1:30:45.50,1:30:50.00,Default,,0,0,0,,At 1 hour 30 minutes
Dialogue: 0,2:00:00.00,2:00:05.00,Default,,0,0,0,,At 2 hours
Dialogue: 0,9:59:59.99,10:00:00.00,Default,,0,0,0,,Almost 10 hours
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(3));
        expect(cues[0].start, equals(const Duration(hours: 1, minutes: 30, seconds: 45, milliseconds: 500)));
        expect(cues[1].start, equals(const Duration(hours: 2)));
        expect(cues[2].start, equals(const Duration(hours: 9, minutes: 59, seconds: 59, milliseconds: 990)));
      });

      test('handles various special characters in text', () {
        const ass = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Hello, world! How's it going?
Dialogue: 0,0:00:06.00,0:00:10.00,Default,,0,0,0,,Price: $100 (50% off!)
Dialogue: 0,0:00:11.00,0:00:15.00,Default,,0,0,0,,Math: 1+1=2, 5*5=25
Dialogue: 0,0:00:16.00,0:00:20.00,Default,,0,0,0,,Japanese: こんにちは
Dialogue: 0,0:00:21.00,0:00:25.00,Default,,0,0,0,,Emoji: 😀👍🎬
''';

        final cues = parser.parse(ass);

        expect(cues, hasLength(5));
        expect(cues[0].text, equals("Hello, world! How's it going?"));
        expect(cues[1].text, equals(r'Price: $100 (50% off!)'));
        expect(cues[2].text, equals('Math: 1+1=2, 5*5=25'));
        expect(cues[3].text, equals('Japanese: こんにちは'));
        expect(cues[4].text, equals('Emoji: 😀👍🎬'));
      });
    });

    group('comprehensive fixture validation', () {
      test('all SSA/ASS fixture files parse without errors', () {
        // Get all .ssa and .ass files from fixtures directory
        final fixtureDir = Directory('test/subtitle/fixtures/ssa');
        final ssaFiles =
            fixtureDir
                .listSync()
                .whereType<File>()
                .where((file) => file.path.endsWith('.ssa') || file.path.endsWith('.ass'))
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path));

        expect(ssaFiles.length, greaterThanOrEqualTo(20), reason: 'Should have at least 20 SSA/ASS test files');

        final results = <String, ParseResult>{};

        for (final file in ssaFiles) {
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
        TestLogger.header('SSA/ASS Parser Validation Results');
        TestLogger.log('Total files: ${ssaFiles.length}');

        var successCount = 0;
        var totalCues = 0;

        for (final entry in results.entries) {
          final fileName = entry.key;
          final result = entry.value;

          if (result.success) {
            successCount++;
            totalCues += result.cueCount;
            TestLogger.success('$fileName: ${result.cueCount} cues');
          } else {
            TestLogger.error('$fileName: ${result.error}');
          }
        }

        TestLogger.summary('Summary: $successCount/${ssaFiles.length} files parsed successfully');
        TestLogger.log('Total cues parsed: $totalCues');
        TestLogger.footer('========================================');

        // All files should parse successfully
        final failures = results.entries.where((e) => !e.value.success).toList();
        expect(
          failures,
          isEmpty,
          reason:
              'All SSA/ASS files should parse without errors. '
              'Failures: ${failures.map((e) => '${e.key}: ${e.value.error}').join(', ')}',
        );
      });
    });

    // Tests using external fixture files
    group('fixture files', () {
      // Source: https://github.com/chireiden/python-ass/blob/master/tests/test.ass
      test('parses sample_python_ass.ass with override tags', () {
        final ass = loadFixture('ssa/sample_python_ass.ass');
        final cues = parser.parse(ass);

        expect(cues, hasLength(5));
        // First cue has color override tags that should be stripped
        expect(cues[0].text, contains('this is a test'));
        // Check timing
        expect(cues[0].start, equals(Duration.zero));
        expect(cues[0].end, equals(const Duration(seconds: 5)));
      });

      // Source: https://github.com/meew0/samaku/blob/master/test_files/multiple_styles.ass
      test('parses sample_multiple_styles.ass with colored styles', () {
        final ass = loadFixture('ssa/sample_multiple_styles.ass');
        final cues = parser.parse(ass);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Red'));
        expect(cues[1].text, equals('Green'));
        expect(cues[2].text, equals('Blue'));

        // Check timing intervals
        expect(cues[0].start, equals(Duration.zero));
        expect(cues[0].end, equals(const Duration(seconds: 5)));
        expect(cues[1].start, equals(const Duration(seconds: 5)));
        expect(cues[2].start, equals(const Duration(seconds: 10)));
      });

      // Source: https://github.com/meew0/samaku/blob/master/test_files/style_colours.ass
      test('parses sample_style_colours.ass with custom colors', () {
        final ass = loadFixture('ssa/sample_style_colours.ass');
        final cues = parser.parse(ass);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('Default style'));
        expect(cues[1].text, equals('Alternate style'));
      });

      // Source: https://github.com/meew0/samaku/blob/master/test_files/border_styles.ass
      test('parses sample_border_styles.ass with position tags', () {
        final ass = loadFixture('ssa/sample_border_styles.ass');
        final cues = parser.parse(ass);

        expect(cues, hasLength(5));
        // All cues have position tags that should be stripped
        expect(cues[0].text, equals('Border style 0'));
        expect(cues[1].text, equals('Border style 1'));
        expect(cues[2].text, equals('Border style 2'));
        expect(cues[3].text, equals('Border style 3'));
        expect(cues[4].text, equals('Border style 4'));
      });

      // Source: https://github.com/asticode/go-astisub (MIT License)
      // Tests SSA with script metadata, styles, and dialogue entries
      test('parses sample_go_astisub.ssa with styles and metadata', () {
        final ssa = loadFixture('ssa/sample_go_astisub.ssa');
        final cues = parser.parse(ssa);

        expect(cues, hasLength(6));

        // First dialogue entry
        expect(cues[0].text, equals('(deep rumbling)'));
        expect(cues[0].start, equals(const Duration(minutes: 1, seconds: 39)));
        expect(cues[0].end, equals(const Duration(minutes: 1, seconds: 41, milliseconds: 40)));

        // Second entry - with multi-line text (\n converted to newline)
        expect(cues[1].text, equals('MAN:\nHow did we end up here?'));
        expect(cues[1].start, equals(const Duration(minutes: 2, seconds: 4, milliseconds: 80)));

        // Fourth entry
        expect(cues[3].text, equals('Smells like balls.'));

        // Multi-line entry with \N (converted to newline)
        expect(cues[4].text, equals("We don't belong\nin this shithole."));

        // Last entry - \n converted to newline
        expect(cues[5].text, equals('(computer playing\nelectronic melody)'));
      });
    });

    group('styled spans (rich text formatting)', () {
      test('parses bold tags into styledSpans', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\b1}Bold{\b0} and {\b1}more bold{\b0}
''';

        final cues = parser.parse(ssa);

        expect(cues, hasLength(1));
        expect(cues[0].text, equals('Bold and more bold'));
        expect(cues[0].hasStyledSpans, isTrue);

        final spans = cues[0].styledSpans!;
        expect(spans, hasLength(3));

        // First span: "Bold" with bold=true
        expect(spans[0].text, equals('Bold'));
        expect(spans[0].hasStyle, isTrue);
        expect(spans[0].style!.isBold, isTrue);

        // Second span: " and " with no styling
        expect(spans[1].text, equals(' and '));
        expect(spans[1].hasStyle, isFalse);

        // Third span: "more bold" with bold=true
        expect(spans[2].text, equals('more bold'));
        expect(spans[2].hasStyle, isTrue);
        expect(spans[2].style!.isBold, isTrue);
      });

      test('parses italic tags into styledSpans', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Normal {\i1}italic{\i0} normal
''';

        final cues = parser.parse(ssa);

        expect(cues[0].hasStyledSpans, isTrue);
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
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\u1}Underlined{\u0} text
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;
        expect(spans[0].text, equals('Underlined'));
        expect(spans[0].style!.isUnderline, isTrue);

        expect(spans[1].text, equals(' text'));
        expect(spans[1].hasStyle, isFalse);
      });

      test('parses strikethrough tags into styledSpans', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\s1}Strikethrough{\s0} text
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;
        expect(spans[0].text, equals('Strikethrough'));
        expect(spans[0].style!.isStrikethrough, isTrue);

        expect(spans[1].text, equals(' text'));
        expect(spans[1].hasStyle, isFalse);
      });

      test('parses color tags into styledSpans (BGR format)', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\c&HFF0000&}Blue{\c&H00FF00&} Green {\c&H0000FF&}Red
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;

        // Blue text (BGR: FF0000 = ARGB: 0xFF0000FF)
        expect(spans[0].text, equals('Blue'));
        expect(spans[0].style!.color, equals(const Color(0xFF0000FF)));

        // Green text (BGR: 00FF00 = ARGB: 0xFF00FF00)
        expect(spans[1].text, equals(' Green '));
        expect(spans[1].style!.color, equals(const Color(0xFF00FF00)));

        // Red text (BGR: 0000FF = ARGB: 0xFFFF0000)
        expect(spans[2].text, equals('Red'));
        expect(spans[2].style!.color, equals(const Color(0xFFFF0000)));
      });

      test('parses color tags with alpha (AABBGGRR format)', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\c&H80FF0000&}Semi-transparent blue
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;

        // SSA alpha is inverted: 0x80 (128) -> 255-128 = 127 (0x7F)
        // AABBGGRR: 80FF0000 (alpha=128, blue=255, green=0, red=0)
        // ARGB: 0x7F0000FF (alpha=127, red=0, green=0, blue=255)
        expect(spans[0].text, equals('Semi-transparent blue'));
        expect(spans[0].style!.color, equals(const Color(0x7F0000FF)));
      });

      test('parses font size tags into styledSpans', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\fs48}Large{\fs24} Medium {\fs12}Small
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;

        expect(spans[0].text, equals('Large'));
        expect(spans[0].style!.fontSize, equals(48.0));

        expect(spans[1].text, equals(' Medium '));
        expect(spans[1].style!.fontSize, equals(24.0));

        expect(spans[2].text, equals('Small'));
        expect(spans[2].style!.fontSize, equals(12.0));
      });

      test('parses font family tags into styledSpans', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\fnArial}Arial{\fnTimes New Roman} Times
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;

        expect(spans[0].text, equals('Arial'));
        expect(spans[0].style!.fontFamily, equals('Arial'));

        expect(spans[1].text, equals(' Times'));
        expect(spans[1].style!.fontFamily, equals('Times New Roman'));
      });

      test('parses multiple tags in one block', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\b1\i1\u1}Bold italic underlined{\b0\i0\u0} normal
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;

        expect(spans[0].text, equals('Bold italic underlined'));
        expect(spans[0].style!.isBold, isTrue);
        expect(spans[0].style!.isItalic, isTrue);
        expect(spans[0].style!.isUnderline, isTrue);

        expect(spans[1].text, equals(' normal'));
        expect(spans[1].hasStyle, isFalse);
      });

      test('parses complex tag combinations', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\b1\c&HFF0000&\fs48}Big Bold Blue{\b0\c&H0000FF&\fs24} Small Red
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;

        // First span: bold, blue (0xFF0000 BGR), font size 48
        expect(spans[0].text, equals('Big Bold Blue'));
        expect(spans[0].style!.isBold, isTrue);
        expect(spans[0].style!.color, equals(const Color(0xFF0000FF)));
        expect(spans[0].style!.fontSize, equals(48.0));

        // Second span: not bold, red (0x0000FF BGR), font size 24
        expect(spans[1].text, equals(' Small Red'));
        expect(spans[1].style!.isBold, isFalse);
        expect(spans[1].style!.color, equals(const Color(0xFFFF0000)));
        expect(spans[1].style!.fontSize, equals(24.0));
      });

      test('handles state persistence across tags', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\b1}Bold {\i1}bold+italic{\b0} just italic{\i0} normal
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;

        // "Bold " - bold only
        expect(spans[0].text, equals('Bold '));
        expect(spans[0].style!.isBold, isTrue);
        expect(spans[0].style!.isItalic, isFalse);

        // "bold+italic" - both bold and italic
        expect(spans[1].text, equals('bold+italic'));
        expect(spans[1].style!.isBold, isTrue);
        expect(spans[1].style!.isItalic, isTrue);

        // " just italic" - italic only (bold turned off)
        expect(spans[2].text, equals(' just italic'));
        expect(spans[2].style!.isBold, isFalse);
        expect(spans[2].style!.isItalic, isTrue);

        // " normal" - no styling
        expect(spans[3].text, equals(' normal'));
        expect(spans[3].hasStyle, isFalse);
      });

      test('handles empty styledSpans for plain text', () {
        const ssa = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Plain text with no tags
''';

        final cues = parser.parse(ssa);

        expect(cues[0].hasStyledSpans, isTrue);
        final spans = cues[0].styledSpans!;

        // Should have one plain span
        expect(spans, hasLength(1));
        expect(spans[0].text, equals('Plain text with no tags'));
        expect(spans[0].hasStyle, isFalse);
      });

      test('parses alternative color tag format (1c)', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\1c&HFF0000&}Blue text
''';

        final cues = parser.parse(ssa);

        final spans = cues[0].styledSpans!;
        expect(spans[0].style!.color, equals(const Color(0xFF0000FF)));
      });

      test('ignores malformed color tags', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\c&HINVALID&}Text with invalid color
''';

        final cues = parser.parse(ssa);

        // Should still parse, but color should be null
        final spans = cues[0].styledSpans!;
        expect(spans[0].text, equals('Text with invalid color'));
        // Color parsing failed, so previous state is maintained
      });

      test('handles newlines with styled text', () {
        const ssa = r'''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\b1}Line one\NLine two{\b0}
''';

        final cues = parser.parse(ssa);

        expect(cues[0].text, equals('Line one\nLine two'));
        final spans = cues[0].styledSpans!;

        // Newlines are included in the text
        expect(spans[0].text, equals('Line one\nLine two'));
        expect(spans[0].style!.isBold, isTrue);
      });
    });
  });
}
