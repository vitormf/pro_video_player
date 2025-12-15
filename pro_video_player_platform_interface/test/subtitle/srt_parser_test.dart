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
  group('SrtParser', () {
    late SrtParser parser;

    setUp(() {
      parser = const SrtParser();
    });

    test('parses simple SRT content', () {
      const srt = '''
1
00:00:01,000 --> 00:00:05,000
Hello, world!

2
00:00:06,000 --> 00:00:10,500
This is a test.
''';

      final cues = parser.parse(srt);

      expect(cues, hasLength(2));

      expect(cues[0].index, equals(1));
      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(cues[0].end, equals(const Duration(seconds: 5)));
      expect(cues[0].text, equals('Hello, world!'));

      expect(cues[1].index, equals(2));
      expect(cues[1].start, equals(const Duration(seconds: 6)));
      expect(cues[1].end, equals(const Duration(seconds: 10, milliseconds: 500)));
      expect(cues[1].text, equals('This is a test.'));
    });

    test('parses multi-line subtitles', () {
      const srt = '''
1
00:00:01,000 --> 00:00:05,000
Line one
Line two
Line three
''';

      final cues = parser.parse(srt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Line one\nLine two\nLine three'));
    });

    test('handles Windows line endings (CRLF)', () {
      const srt = '1\r\n00:00:01,000 --> 00:00:05,000\r\nHello\r\n\r\n';

      final cues = parser.parse(srt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Hello'));
    });

    test('handles milliseconds with comma separator', () {
      const srt = '''
1
00:01:30,500 --> 00:01:35,750
Test
''';

      final cues = parser.parse(srt);

      expect(cues[0].start, equals(const Duration(minutes: 1, seconds: 30, milliseconds: 500)));
      expect(cues[0].end, equals(const Duration(minutes: 1, seconds: 35, milliseconds: 750)));
    });

    test('handles milliseconds with dot separator', () {
      const srt = '''
1
00:01:30.500 --> 00:01:35.750
Test
''';

      final cues = parser.parse(srt);

      expect(cues[0].start, equals(const Duration(minutes: 1, seconds: 30, milliseconds: 500)));
      expect(cues[0].end, equals(const Duration(minutes: 1, seconds: 35, milliseconds: 750)));
    });

    test('handles hours in timestamp', () {
      const srt = '''
1
01:30:45,123 --> 02:00:00,000
Long video
''';

      final cues = parser.parse(srt);

      expect(cues[0].start, equals(const Duration(hours: 1, minutes: 30, seconds: 45, milliseconds: 123)));
      expect(cues[0].end, equals(const Duration(hours: 2)));
    });

    test('strips HTML tags from text', () {
      const srt = '''
1
00:00:01,000 --> 00:00:05,000
<b>Bold</b> and <i>italic</i> text
''';

      final cues = parser.parse(srt);

      expect(cues[0].text, equals('Bold and italic text'));
    });

    test('strips font tags', () {
      const srt = '''
1
00:00:01,000 --> 00:00:05,000
<font color="#FFFFFF">Colored text</font>
''';

      final cues = parser.parse(srt);

      expect(cues[0].text, equals('Colored text'));
    });

    test('handles empty content', () {
      const srt = '';

      final cues = parser.parse(srt);

      expect(cues, isEmpty);
    });

    test('handles whitespace-only content', () {
      const srt = '   \n\n   \n';

      final cues = parser.parse(srt);

      expect(cues, isEmpty);
    });

    test('skips malformed entries', () {
      const srt = '''
1
00:00:01,000 --> 00:00:05,000
Valid entry

not a number
broken timestamp
Invalid entry

3
00:00:10,000 --> 00:00:15,000
Another valid entry
''';

      final cues = parser.parse(srt);

      expect(cues, hasLength(2));
      expect(cues[0].index, equals(1));
      expect(cues[1].index, equals(3));
    });

    test('handles entries without blank line separator at end', () {
      const srt = '''
1
00:00:01,000 --> 00:00:05,000
First

2
00:00:06,000 --> 00:00:10,000
Second''';

      final cues = parser.parse(srt);

      expect(cues, hasLength(2));
    });

    test('ignores position metadata in timestamp line', () {
      const srt = '''
1
00:00:01,000 --> 00:00:05,000 X1:0 X2:100 Y1:0 Y2:50
Positioned subtitle
''';

      final cues = parser.parse(srt);

      expect(cues, hasLength(1));
      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(cues[0].end, equals(const Duration(seconds: 5)));
    });

    test('handles BOM (Byte Order Mark)', () {
      const srt = '\uFEFF1\n00:00:01,000 --> 00:00:05,000\nWith BOM\n';

      final cues = parser.parse(srt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('With BOM'));
    });

    group('timestamp parsing', () {
      test('parses HH:MM:SS,mmm format', () {
        final duration = SrtParser.parseTimestamp('01:23:45,678');
        expect(duration, equals(const Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678)));
      });

      test('parses HH:MM:SS.mmm format', () {
        final duration = SrtParser.parseTimestamp('01:23:45.678');
        expect(duration, equals(const Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678)));
      });

      test('parses zero timestamp', () {
        final duration = SrtParser.parseTimestamp('00:00:00,000');
        expect(duration, equals(Duration.zero));
      });

      test('returns null for invalid timestamp', () {
        expect(SrtParser.parseTimestamp('invalid'), isNull);
        expect(SrtParser.parseTimestamp('1:2:3'), isNull);
        expect(SrtParser.parseTimestamp(''), isNull);
      });
    });

    // Real-world samples based on files from GitHub and SubtitleWise
    group('real-world samples', () {
      // Source: https://github.com/andreyvit/subtitle-tools/blob/master/sample.srt
      test('parses sample from github.com/andreyvit/subtitle-tools', () {
        const srt = '''
1
00:00:00,000 --> 00:00:01,500
For www.forom.com

2
00:00:01,500 --> 00:00:02,500
<i>Tonight's the night.</i>

3
00:00:03,000 --> 00:00:15,000
<i>And it's going to happen
again and again --</i>
''';

        final cues = parser.parse(srt);

        expect(cues, hasLength(3));

        expect(cues[0].index, equals(1));
        expect(cues[0].start, equals(Duration.zero));
        expect(cues[0].end, equals(const Duration(seconds: 1, milliseconds: 500)));
        expect(cues[0].text, equals('For www.forom.com'));

        expect(cues[1].index, equals(2));
        expect(cues[1].start, equals(const Duration(seconds: 1, milliseconds: 500)));
        expect(cues[1].end, equals(const Duration(seconds: 2, milliseconds: 500)));
        expect(cues[1].text, equals("Tonight's the night."));

        expect(cues[2].index, equals(3));
        expect(cues[2].start, equals(const Duration(seconds: 3)));
        expect(cues[2].end, equals(const Duration(seconds: 15)));
        expect(cues[2].text, equals("And it's going to happen\nagain and again --"));
      });

      // Source: https://gist.github.com/matibzurovski/d690d5c14acbaa399e7f0829f9d6888e
      test('parses sample from gist.github.com/matibzurovski', () {
        const srt = '''
1
00:00:00,000 --> 00:00:02,500
Welcome to the Example Subtitle File!

2
00:00:03,000 --> 00:00:07,000
This is a demonstration of SRT subtitles.

3
00:00:08,000 --> 00:00:12,000
Each subtitle entry requires:
- A sequential number

4
00:00:12,500 --> 00:00:17,000
- A timecode in the format:
HH:MM:SS,mmm

5
00:00:17,500 --> 00:00:22,000
- The text to be displayed
(one or more lines)

6
00:00:22,500 --> 00:00:28,000
Notice how each entry is separated
by a blank line.
''';

        final cues = parser.parse(srt);

        expect(cues, hasLength(6));

        expect(cues[0].text, equals('Welcome to the Example Subtitle File!'));
        expect(cues[1].text, equals('This is a demonstration of SRT subtitles.'));
        expect(cues[2].text, equals('Each subtitle entry requires:\n- A sequential number'));
        expect(cues[3].text, contains('HH:MM:SS,mmm'));
        expect(cues[4].text, contains('one or more lines'));
        expect(cues[5].text, equals('Notice how each entry is separated\nby a blank line.'));
      });

      // Source: Common pattern in movie subtitles from OpenSubtitles.org
      test('parses movie-style dialogue with dashes', () {
        const srt = '''
1
00:01:15,200 --> 00:01:17,800
- Hello, how are you?
- I'm fine, thanks.

2
00:01:18,000 --> 00:01:20,500
- And you?
- Great!
''';

        final cues = parser.parse(srt);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals("- Hello, how are you?\n- I'm fine, thanks."));
        expect(cues[1].text, equals('- And you?\n- Great!'));
      });

      // Source: Based on long-form content patterns (movies, TV series)
      test('parses long-running video with hour timestamps', () {
        const srt = '''
1
01:30:45,123 --> 01:30:50,456
This is at 1 hour 30 minutes.

2
02:45:00,000 --> 02:45:05,000
This is near the end.

3
03:00:00,000 --> 03:00:02,500
The End
''';

        final cues = parser.parse(srt);

        expect(cues, hasLength(3));
        expect(cues[0].start, equals(const Duration(hours: 1, minutes: 30, seconds: 45, milliseconds: 123)));
        expect(cues[1].start, equals(const Duration(hours: 2, minutes: 45)));
        expect(cues[2].start, equals(const Duration(hours: 3)));
      });

      // Source: International subtitle examples from Subscene.com patterns
      test('parses content with special characters and Unicode', () {
        const srt = '''
1
00:00:01,000 --> 00:00:05,000
¡Hola! ¿Cómo estás?

2
00:00:06,000 --> 00:00:10,000
日本語テスト

3
00:00:11,000 --> 00:00:15,000
Привет мир!

4
00:00:16,000 --> 00:00:20,000
🎬 Emojis work too! 🎉
''';

        final cues = parser.parse(srt);

        expect(cues, hasLength(4));
        expect(cues[0].text, equals('¡Hola! ¿Cómo estás?'));
        expect(cues[1].text, equals('日本語テスト'));
        expect(cues[2].text, equals('Привет мир!'));
        expect(cues[3].text, equals('🎬 Emojis work too! 🎉'));
      });

      // Source: SDH (Subtitles for the Deaf and Hard of Hearing) patterns from Netflix
      test('parses hearing-impaired subtitles with annotations', () {
        const srt = '''
1
00:00:01,000 --> 00:00:05,000
[MUSIC PLAYING]

2
00:00:06,000 --> 00:00:10,000
[DOOR SLAMS]

3
00:00:11,000 --> 00:00:15,000
JOHN: Hello there!

4
00:00:16,000 --> 00:00:20,000
(whispering) Be quiet...

5
00:00:21,000 --> 00:00:25,000
♪ La la la ♪
''';

        final cues = parser.parse(srt);

        expect(cues, hasLength(5));
        expect(cues[0].text, equals('[MUSIC PLAYING]'));
        expect(cues[1].text, equals('[DOOR SLAMS]'));
        expect(cues[2].text, equals('JOHN: Hello there!'));
        expect(cues[3].text, equals('(whispering) Be quiet...'));
        expect(cues[4].text, equals('♪ La la la ♪'));
      });

      // Source: Error handling test based on common issues in user-generated subtitles
      test('handles malformed entries mixed with valid ones', () {
        const srt = '''
1
00:00:01,000 --> 00:00:05,000
Valid first entry

This line has no number
00:00:06,000 --> 00:00:10,000
Invalid - missing index

3
bad timestamp format
Missing proper timing

4
00:00:11,000 --> 00:00:15,000
Valid fourth entry

5
00:00:16,000
Missing end timestamp
Also invalid

6
00:00:20,000 --> 00:00:25,000
Valid sixth entry
''';

        final cues = parser.parse(srt);

        // Should only parse entries 1, 4, and 6
        expect(cues.length, greaterThanOrEqualTo(2));
        expect(cues.first.text, equals('Valid first entry'));
        expect(cues.any((c) => c.text == 'Valid sixth entry'), isTrue);
      });

      // Source: Fast-paced dialogue patterns common in action/comedy films
      test('parses rapid-fire subtitles with overlapping times', () {
        const srt = '''
1
00:00:01,000 --> 00:00:01,500
Fast!

2
00:00:01,400 --> 00:00:01,900
Very fast!

3
00:00:01,800 --> 00:00:02,300
Super fast!
''';

        final cues = parser.parse(srt);

        expect(cues, hasLength(3));
        // Overlapping times should still parse correctly
        expect(cues[0].end.inMilliseconds, equals(1500));
        expect(cues[1].start.inMilliseconds, equals(1400));
      });
    });

    // Tests using external fixture files
    // Source: https://github.com/andreyvit/subtitle-tools/blob/master/sample.srt
    group('fixture files', () {
      test('parses sample_andreyvit.srt from andreyvit/subtitle-tools', () {
        final srt = loadFixture('srt/sample_andreyvit.srt');
        final cues = parser.parse(srt);

        expect(cues, hasLength(3));

        expect(cues[0].index, equals(1));
        expect(cues[0].start, equals(Duration.zero));
        expect(cues[0].end, equals(const Duration(seconds: 1, milliseconds: 500)));
        expect(cues[0].text, equals('For www.forom.com'));

        expect(cues[1].index, equals(2));
        expect(cues[1].start, equals(const Duration(seconds: 1, milliseconds: 500)));
        expect(cues[1].end, equals(const Duration(seconds: 2, milliseconds: 500)));
        expect(cues[1].text, equals("Tonight's the night."));

        expect(cues[2].index, equals(3));
        expect(cues[2].start, equals(const Duration(seconds: 3)));
        expect(cues[2].end, equals(const Duration(seconds: 15)));
        expect(cues[2].text, equals("And it's going to happen\nagain and again --"));
      });

      // SRT with HTML formatting tags (bold, italic, underline, font color)
      test('parses sample_html_formatting.srt and strips HTML tags', () {
        final srt = loadFixture('srt/sample_html_formatting.srt');
        final cues = parser.parse(srt);

        expect(cues, hasLength(8));
        // HTML tags should be stripped
        expect(cues[0].text, equals('This is bold text'));
        expect(cues[1].text, equals('This is italic text'));
        expect(cues[2].text, equals('This is underlined text'));
        expect(cues[3].text, equals('Red text'));
        expect(cues[4].text, equals('Yellow text'));
        expect(cues[5].text, equals('Mixed: bold, italic, and underlined'));
        expect(cues[6].text, equals('Bold green text'));
        expect(cues[7].text, equals('Nested bold italic formatting'));
      });

      // SRT with extended positioning (X1, X2, Y1, Y2 coordinates)
      test('parses sample_positioning.srt and ignores position metadata', () {
        final srt = loadFixture('srt/sample_positioning.srt');
        final cues = parser.parse(srt);

        expect(cues, hasLength(4));
        expect(cues[0].text, equals('Top positioned subtitle'));
        expect(cues[1].text, equals('Bottom positioned subtitle'));
        expect(cues[2].text, equals('Right side subtitle'));
        expect(cues[3].text, equals('Normal subtitle without positioning'));
        // Timing should still be correct despite position metadata
        expect(cues[0].start, equals(const Duration(seconds: 1)));
        expect(cues[0].end, equals(const Duration(seconds: 4)));
      });

      // SRT with ASS-style override tags ({\an8}, {\pos}, etc.)
      test('parses sample_ass_tags.srt and strips ASS-style tags', () {
        final srt = loadFixture('srt/sample_ass_tags.srt');
        final cues = parser.parse(srt);

        expect(cues, hasLength(8));
        // ASS-style tags should be stripped
        expect(cues[0].text, equals('Top center aligned'));
        expect(cues[1].text, equals('Bottom center (default position)'));
        expect(cues[2].text, equals('Top left aligned'));
        expect(cues[3].text, equals('Top right aligned'));
        expect(cues[4].text, equals('Custom position'));
        expect(cues[5].text, equals('Fade in and out effect'));
        expect(cues[6].text, equals('Blue colored text'));
        expect(cues[7].text, equals('Larger font size text'));
      });

      // SRT with period (.) as millisecond separator instead of comma (,)
      test('parses sample_dot_separator.srt with period timestamps', () {
        final srt = loadFixture('srt/sample_dot_separator.srt');
        final cues = parser.parse(srt);

        expect(cues, hasLength(4));
        expect(cues[0].text, equals('Using period as millisecond separator'));
        expect(cues[0].start, equals(const Duration(seconds: 1, milliseconds: 500)));
        expect(cues[0].end, equals(const Duration(seconds: 4)));

        expect(cues[1].start, equals(const Duration(seconds: 5, milliseconds: 250)));
        expect(cues[1].end, equals(const Duration(seconds: 8, milliseconds: 750)));

        expect(cues[2].start, equals(const Duration(seconds: 9, milliseconds: 123)));
        expect(cues[2].end, equals(const Duration(seconds: 12, milliseconds: 456)));
      });

      // Source: https://github.com/asticode/go-astisub (MIT License)
      // Tests mixed timestamp separators (both comma and dot), positioning metadata, BOM
      test('parses sample_go_astisub.srt with mixed separators and positioning', () {
        final srt = loadFixture('srt/sample_go_astisub.srt');
        final cues = parser.parse(srt);

        expect(cues, hasLength(6));

        // First cue - comma separator, no decimal places
        expect(cues[0].index, equals(1));
        expect(cues[0].start, equals(const Duration(minutes: 1, seconds: 39)));
        expect(cues[0].end, equals(const Duration(minutes: 1, seconds: 41, milliseconds: 40)));
        expect(cues[0].text, equals('(deep rumbling)'));

        // Second cue - comma separator with positioning metadata (should be ignored)
        expect(cues[1].index, equals(2));
        expect(cues[1].start, equals(const Duration(minutes: 2, seconds: 4, milliseconds: 80)));
        expect(cues[1].end, equals(const Duration(minutes: 2, seconds: 7, milliseconds: 120)));
        expect(cues[1].text, equals('MAN:\nHow did we end up here?'));

        // Third cue - dot separator
        expect(cues[2].index, equals(3));
        expect(cues[2].start, equals(const Duration(minutes: 2, seconds: 12, milliseconds: 160)));
        expect(cues[2].end, equals(const Duration(minutes: 2, seconds: 15, milliseconds: 200)));
        expect(cues[2].text, equals('This place is horrible.'));

        // Multi-line cue
        expect(cues[4].text, equals("We don't belong\nin this shithole."));

        // Last cue - multi-line
        expect(cues[5].text, equals('(computer playing\nelectronic melody)'));
      });
    });

    group('comprehensive fixture validation', () {
      test('all SRT fixture files parse without errors', () {
        // Get all .srt files from fixtures directory
        final fixtureDir = Directory('test/subtitle/fixtures/srt');
        final srtFiles = fixtureDir.listSync().whereType<File>().where((file) => file.path.endsWith('.srt')).toList()
          ..sort((a, b) => a.path.compareTo(b.path));

        expect(srtFiles.length, greaterThanOrEqualTo(20), reason: 'Should have at least 20 SRT test files');

        final results = <String, ParseResult>{};

        for (final file in srtFiles) {
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
        TestLogger.header('SRT Parser Validation Results');
        TestLogger.log('Total files: ${srtFiles.length}');

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

        TestLogger.summary('Summary: $successCount/${srtFiles.length} files parsed successfully');
        TestLogger.log('Total cues parsed: $totalCues');
        TestLogger.footer('========================================');

        // All files should parse successfully
        final failures = results.entries.where((e) => !e.value.success).toList();
        expect(
          failures,
          isEmpty,
          reason:
              'All SRT files should parse without errors. '
              'Failures: ${failures.map((e) => '${e.key}: ${e.value.error}').join(', ')}',
        );
      });
    });
  });
}
