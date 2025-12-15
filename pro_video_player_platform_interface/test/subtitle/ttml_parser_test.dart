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
  group('TtmlParser', () {
    late TtmlParser parser;

    setUp(() {
      parser = const TtmlParser();
    });

    test('parses simple TTML content', () {
      const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">Hello, world!</p>
      <p begin="00:00:06.000" end="00:00:10.500">This is a test.</p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(ttml);

      expect(cues, hasLength(2));

      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(cues[0].end, equals(const Duration(seconds: 5)));
      expect(cues[0].text, equals('Hello, world!'));

      expect(cues[1].start, equals(const Duration(seconds: 6)));
      expect(cues[1].end, equals(const Duration(seconds: 10, milliseconds: 500)));
      expect(cues[1].text, equals('This is a test.'));
    });

    test('parses TTML with dur attribute instead of end', () {
      const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" dur="00:00:04.000">With duration</p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(ttml);

      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(cues[0].end, equals(const Duration(seconds: 5)));
    });

    test('handles multi-line text with br elements', () {
      const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">Line one<br/>Line two<br/>Line three</p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(ttml);

      expect(cues[0].text, equals('Line one\nLine two\nLine three'));
    });

    test('handles nested span elements', () {
      const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000"><span>Text in </span><span>multiple spans</span></p>
    </div>
  </body>
</tt>
''';

      final cues = parser.parse(ttml);

      expect(cues[0].text, equals('Text in multiple spans'));
    });

    test('handles empty body', () {
      const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
  </body>
</tt>
''';

      final cues = parser.parse(ttml);

      expect(cues, isEmpty);
    });

    test('handles invalid XML gracefully', () {
      const ttml = 'not valid xml';

      final cues = parser.parse(ttml);

      expect(cues, isEmpty);
    });

    group('timestamp parsing', () {
      test('parses HH:MM:SS.mmm format', () {
        final duration = TtmlParser.parseTimestamp('01:23:45.678');
        expect(duration, equals(const Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678)));
      });

      test('parses seconds format', () {
        final duration = TtmlParser.parseTimestamp('90.5s');
        expect(duration, equals(const Duration(seconds: 90, milliseconds: 500)));
      });

      test('parses milliseconds format', () {
        final duration = TtmlParser.parseTimestamp('5500ms');
        expect(duration, equals(const Duration(milliseconds: 5500)));
      });

      test('parses frame format with default frame rate', () {
        // 12 frames at 25fps = 12/25 = 0.48s = 480ms
        final duration = TtmlParser.parseTimestamp('00:00:01:12');
        expect(duration, equals(const Duration(milliseconds: 1480)));
      });

      test('parses frame format with custom frame rate', () {
        // 12 frames at 30fps = 12/30 = 0.4s = 400ms
        final duration = TtmlParser.parseTimestamp('00:00:01:12', frameRate: 30);
        expect(duration, equals(const Duration(milliseconds: 1400)));
      });

      test('returns null for invalid timestamp', () {
        expect(TtmlParser.parseTimestamp('invalid'), isNull);
        expect(TtmlParser.parseTimestamp(''), isNull);
      });
    });

    // Real-world samples based on Netflix specs and W3C examples
    group('real-world samples', () {
      test('parses GitHub TTML example from anotherhale', () {
        // Based on https://gist.github.com/anotherhale/676a72edc84ca3a37c0c
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xml:lang="en" xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling">
  <head>
    <metadata>
      <title>Timed Text TTML Example</title>
      <desc>Sample TTML file</desc>
    </metadata>
    <styling>
      <style xml:id="s1" tts:color="white" tts:fontFamily="proportionalSansSerif" tts:fontSize="100%" tts:textAlign="center"/>
      <style xml:id="s2" style="s1" tts:color="yellow"/>
    </styling>
    <layout>
      <region xml:id="subtitleArea" style="s1" tts:origin="0px 0px" tts:extent="560px 62px" tts:displayAlign="after"/>
    </layout>
  </head>
  <body region="subtitleArea">
    <div>
      <p begin="0.76s" end="3.45s" style="s1">It seems a paradox, does it not,</p>
      <p begin="5.0s" end="10.0s" style="s1">that the image formed on the Retina should be inverted?</p>
      <p begin="10.0s" end="16.0s" style="s2">It is puzzling, why is it we do not see things upside-down?</p>
      <p begin="17.2s" end="23.0s" style="s1">You have never heard the Theory, then, that the Brain also is inverted?</p>
      <p begin="23.0s" end="27.0s" style="s2">No indeed! What a beautiful fact!</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(5));
        expect(cues[0].text, equals('It seems a paradox, does it not,'));
        expect(cues[0].start, equals(const Duration(milliseconds: 760)));
        expect(cues[0].end, equals(const Duration(milliseconds: 3450)));

        expect(cues[1].text, equals('that the image formed on the Retina should be inverted?'));
        expect(cues[2].text, equals('It is puzzling, why is it we do not see things upside-down?'));
        expect(cues[3].text, equals('You have never heard the Theory, then, that the Brain also is inverted?'));
        expect(cues[4].text, equals('No indeed! What a beautiful fact!'));
      });

      test('parses Netflix-style TTML format', () {
        // Based on Netflix Partner Help Center specifications
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml"
    xmlns:tts="http://www.w3.org/ns/ttml#styling"
    xmlns:ttm="http://www.w3.org/ns/ttml#metadata"
    xmlns:ttp="http://www.w3.org/ns/ttml#parameter"
    ttp:timeBase="media"
    xml:lang="en">
  <head>
    <styling>
      <style xml:id="default" tts:fontStyle="normal" tts:fontWeight="normal" tts:fontFamily="sansSerif" tts:fontSize="100%" tts:color="white" tts:backgroundColor="transparent" tts:textAlign="center"/>
    </styling>
    <layout>
      <region xml:id="top" tts:origin="10% 10%" tts:extent="80% 40%" tts:displayAlign="before"/>
      <region xml:id="bottom" tts:origin="10% 50%" tts:extent="80% 40%" tts:displayAlign="after"/>
    </layout>
  </head>
  <body>
    <div region="bottom">
      <p begin="00:00:01.000" end="00:00:04.000">Welcome to the show.</p>
      <p begin="00:00:05.500" end="00:00:09.000">Today we will be discussing subtitles.</p>
      <p begin="00:00:10.000" end="00:00:14.500">TTML is used by many streaming services.</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('Welcome to the show.'));
        expect(cues[0].start, equals(const Duration(seconds: 1)));
        expect(cues[0].end, equals(const Duration(seconds: 4)));

        expect(cues[1].text, equals('Today we will be discussing subtitles.'));
        expect(cues[2].text, equals('TTML is used by many streaming services.'));
      });

      test('parses TTML with duration attribute', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" dur="00:00:03.000">Three second duration</p>
      <p begin="00:00:05.000" dur="00:00:05.000">Five second duration</p>
      <p begin="00:00:11.000" dur="2.5s">Duration in seconds</p>
      <p begin="00:00:15.000" dur="1500ms">Duration in milliseconds</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(4));
        expect(cues[0].start, equals(const Duration(seconds: 1)));
        expect(cues[0].end, equals(const Duration(seconds: 4)));

        expect(cues[1].start, equals(const Duration(seconds: 5)));
        expect(cues[1].end, equals(const Duration(seconds: 10)));

        expect(cues[2].start, equals(const Duration(seconds: 11)));
        expect(cues[2].end, equals(const Duration(seconds: 13, milliseconds: 500)));

        expect(cues[3].start, equals(const Duration(seconds: 15)));
        expect(cues[3].end, equals(const Duration(seconds: 16, milliseconds: 500)));
      });

      test('parses EBU-TT format (European broadcast)', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml"
    xmlns:ttp="http://www.w3.org/ns/ttml#parameter"
    xmlns:tts="http://www.w3.org/ns/ttml#styling"
    xmlns:ebuttm="urn:ebu:tt:metadata"
    ttp:timeBase="media"
    xml:lang="en-GB"
    ttp:cellResolution="50 30">
  <head>
    <metadata>
      <ebuttm:documentMetadata>
        <ebuttm:documentEbuttVersion>v1.0</ebuttm:documentEbuttVersion>
      </ebuttm:documentMetadata>
    </metadata>
    <styling>
      <style xml:id="defaultStyle" tts:fontFamily="Verdana" tts:fontSize="160%" tts:lineHeight="125%"/>
    </styling>
    <layout>
      <region xml:id="bottom" tts:origin="10% 80%" tts:extent="80% 20%"/>
    </layout>
  </head>
  <body>
    <div region="bottom">
      <p begin="00:00:02.000" end="00:00:05.000">European broadcast subtitle</p>
      <p begin="00:00:06.000" end="00:00:10.000">Using EBU-TT format</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('European broadcast subtitle'));
        expect(cues[1].text, equals('Using EBU-TT format'));
      });

      test('parses TTML with frame-based timestamps', () {
        // SMPTE timecodes: HH:MM:SS:FF at 25fps
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml"
    xmlns:ttp="http://www.w3.org/ns/ttml#parameter"
    ttp:frameRate="25"
    ttp:timeBase="smpte">
  <body>
    <div>
      <p begin="00:00:01:00" end="00:00:05:00">Frame 0 at 25fps</p>
      <p begin="00:00:06:12" end="00:00:10:24">Frame 12 at 25fps</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(2));
        expect(cues[0].start, equals(const Duration(seconds: 1)));
        expect(cues[0].end, equals(const Duration(seconds: 5)));

        // Frame 12 at 25fps = 480ms
        expect(cues[1].start, equals(const Duration(seconds: 6, milliseconds: 480)));
        // Frame 24 at 25fps = 960ms
        expect(cues[1].end, equals(const Duration(seconds: 10, milliseconds: 960)));
      });

      test('parses TTML with styled spans', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling">
  <head>
    <styling>
      <style xml:id="normal" tts:color="white"/>
      <style xml:id="italic" tts:fontStyle="italic"/>
      <style xml:id="speaker" tts:color="yellow"/>
    </styling>
  </head>
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000"><span style="speaker">JOHN:</span> <span style="normal">Hello there!</span></p>
      <p begin="00:00:06.000" end="00:00:10.000"><span style="italic">He walked slowly</span> towards the door.</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('JOHN: Hello there!'));
        expect(cues[1].text, equals('He walked slowly towards the door.'));
      });

      test('parses TTML with line breaks', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">Line one<br/>Line two<br/>Line three</p>
      <p begin="00:00:06.000" end="00:00:10.000">Single<br></br>break</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('Line one\nLine two\nLine three'));
        expect(cues[1].text, equals('Single\nbreak'));
      });

      test('parses TTML with multiple divs', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div xml:lang="en">
      <p begin="00:00:01.000" end="00:00:05.000">English subtitle</p>
    </div>
    <div xml:lang="es">
      <p begin="00:00:01.000" end="00:00:05.000">Subtítulo en español</p>
    </div>
    <div xml:lang="ja">
      <p begin="00:00:01.000" end="00:00:05.000">日本語字幕</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(3));
        expect(cues[0].text, equals('English subtitle'));
        expect(cues[1].text, equals('Subtítulo en español'));
        expect(cues[2].text, equals('日本語字幕'));
      });

      test('parses IMSC1 format (Internet Media Subtitles)', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml"
    xmlns:tts="http://www.w3.org/ns/ttml#styling"
    xmlns:ttp="http://www.w3.org/ns/ttml#parameter"
    xmlns:ittp="http://www.w3.org/ns/ttml/profile/imsc1#parameter"
    ttp:profile="http://www.w3.org/ns/ttml/profile/imsc1/text"
    xml:lang="en">
  <head>
    <styling>
      <style xml:id="s0" tts:fontSize="100%" tts:textAlign="center"/>
    </styling>
    <layout>
      <region xml:id="r0" tts:origin="10% 80%" tts:extent="80% 20%"/>
    </layout>
  </head>
  <body>
    <div region="r0">
      <p begin="00:00:01.000" end="00:00:04.000" style="s0">IMSC1 compliant subtitle</p>
      <p begin="00:00:05.000" end="00:00:09.000" style="s0">Used for OTT streaming</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('IMSC1 compliant subtitle'));
        expect(cues[1].text, equals('Used for OTT streaming'));
      });

      test('parses TTML with accessibility features', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml" xmlns:tts="http://www.w3.org/ns/ttml#styling">
  <head>
    <styling>
      <style xml:id="speaker" tts:color="cyan"/>
      <style xml:id="sound" tts:color="white" tts:fontStyle="italic"/>
    </styling>
  </head>
  <body>
    <div>
      <p begin="00:00:00.000" end="00:00:03.000" style="sound">[MUSIC PLAYING]</p>
      <p begin="00:00:04.000" end="00:00:08.000"><span style="speaker">NARRATOR:</span> Once upon a time...</p>
      <p begin="00:00:09.000" end="00:00:12.000" style="sound">[DOOR CREAKS]</p>
      <p begin="00:00:13.000" end="00:00:17.000"><span style="speaker">CHILD:</span> (whispering) Hello?</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(4));
        expect(cues[0].text, equals('[MUSIC PLAYING]'));
        expect(cues[1].text, equals('NARRATOR: Once upon a time...'));
        expect(cues[2].text, equals('[DOOR CREAKS]'));
        expect(cues[3].text, equals('CHILD: (whispering) Hello?'));
      });

      test('parses long-form content with hour timestamps', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="01:30:45.500" end="01:30:50.000">At 1 hour 30 minutes</p>
      <p begin="02:00:00.000" end="02:00:05.000">At 2 hours exactly</p>
      <p begin="03:59:55.000" end="04:00:00.000">Almost at 4 hours</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(3));
        expect(cues[0].start, equals(const Duration(hours: 1, minutes: 30, seconds: 45, milliseconds: 500)));
        expect(cues[1].start, equals(const Duration(hours: 2)));
        expect(cues[2].start, equals(const Duration(hours: 3, minutes: 59, seconds: 55)));
      });
    });

    // Tests using external fixture files
    group('fixture files', () {
      // Content: Public domain text from "Alice's Adventures in Wonderland" by Lewis Carroll (1865)
      // TTML structure demonstrates styling, multi-line text with <br/>, and style references
      test('parses sample_ttml_example.xml with styling', () {
        final ttml = loadFixture('ttml/sample_ttml_example.xml');
        final cues = parser.parse(ttml);

        expect(cues, hasLength(5));
        expect(cues[0].text, equals('Would you tell me, please,'));
        expect(cues[0].start, equals(const Duration(milliseconds: 760)));
        expect(cues[0].end, equals(const Duration(milliseconds: 3450)));

        expect(cues[4].text, equals("Oh, you're sure to do that,\n\nif you only walk long enough."));
        expect(cues[4].end, equals(const Duration(seconds: 27)));
      });

      // Source: https://github.com/IRT-Open-Source/irt-ebu-tt-d-application-samples
      test('parses sample_ebu_tt_d.xml EBU-TT-D format', () {
        final ttml = loadFixture('ttml/sample_ebu_tt_d.xml');
        final cues = parser.parse(ttml);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('One line Subtitle.'));
        expect(cues[0].start, equals(const Duration(seconds: 10)));
        expect(cues[0].end, equals(const Duration(seconds: 20)));

        expect(cues[1].text, equals('One line Subtitle.'));
        expect(cues[1].start, equals(const Duration(seconds: 22)));
        expect(cues[1].end, equals(const Duration(seconds: 30)));
      });

      // Source: https://github.com/asticode/go-astisub (MIT License)
      // Tests TTML with metadata, regions, and styles
      test('parses sample_go_astisub.ttml with regions and styles', () {
        final ttml = loadFixture('ttml/sample_go_astisub.ttml');
        final cues = parser.parse(ttml);

        expect(cues, hasLength(6));

        // First cue
        expect(cues[0].text, equals('(deep rumbling)'));
        expect(cues[0].start, equals(const Duration(minutes: 1, seconds: 39)));
        expect(cues[0].end, equals(const Duration(minutes: 1, seconds: 41, milliseconds: 40)));

        // Second cue - multi-line with br
        expect(cues[1].text, equals('MAN:\n\nHow did we end up here?'));
        expect(cues[1].start, equals(const Duration(minutes: 2, seconds: 4, milliseconds: 80)));

        // Fourth cue
        expect(cues[3].text, equals('Smells like balls.'));

        // Multi-line cue
        expect(cues[4].text, contains("We don't belong"));

        // Last cue
        expect(cues[5].text, contains('(computer playing'));
      });
    });

    group('comprehensive fixture validation', () {
      test('all TTML fixture files parse without errors', () {
        // Get all .ttml files from fixtures directory
        final fixtureDir = Directory('test/subtitle/fixtures/ttml');
        final ttmlFiles = fixtureDir.listSync().whereType<File>().where((file) => file.path.endsWith('.ttml')).toList()
          ..sort((a, b) => a.path.compareTo(b.path));

        expect(ttmlFiles.length, greaterThanOrEqualTo(20), reason: 'Should have at least 20 TTML test files');

        final results = <String, ParseResult>{};

        for (final file in ttmlFiles) {
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
        TestLogger.header('TTML Parser Validation Results');
        TestLogger.log('Total files: ${ttmlFiles.length}');

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

        TestLogger.summary('Summary: $successCount/${ttmlFiles.length} files parsed successfully');
        TestLogger.log('Total cues parsed: $totalCues');
        TestLogger.footer('========================================');

        // All files should parse successfully
        final failures = results.entries.where((e) => !e.value.success).toList();
        expect(
          failures,
          isEmpty,
          reason:
              'All TTML files should parse without errors. '
              'Failures: ${failures.map((e) => '${e.key}: ${e.value.error}').join(', ')}',
        );
      });
    });

    group('styled spans (rich text formatting)', () {
      test('parses fontWeight bold attribute', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000"><span tts:fontWeight="bold">Bold text</span></p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues[0].text, equals('Bold text'));
        expect(cues[0].hasStyledSpans, isTrue);

        final spans = cues[0].styledSpans!;
        expect(spans, hasLength(1));

        expect(spans[0].text, equals('Bold text'));
        expect(spans[0].style!.isBold, isTrue);
      });

      test('parses fontStyle italic attribute', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">Normal <span tts:fontStyle="italic">italic</span> normal</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;
        expect(spans[1].text, equals('italic'));
        expect(spans[1].style!.isItalic, isTrue);
        expect(spans[1].style!.isBold, isFalse);
      });

      test('parses textDecoration underline attribute', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">Normal <span tts:textDecoration="underline">underlined</span> normal</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;
        expect(spans[1].text, equals('underlined'));
        expect(spans[1].style!.isUnderline, isTrue);
      });

      test('parses textDecoration lineThrough attribute', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">Normal <span tts:textDecoration="lineThrough">strikethrough</span> normal</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;
        expect(spans[1].text, equals('strikethrough'));
        expect(spans[1].style!.isStrikethrough, isTrue);
      });

      test('parses color hex attribute', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">
        <span tts:color="#FF0000">Red</span>
        <span tts:color="#00FF00">Green</span>
        <span tts:color="#0000FF">Blue</span>
      </p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;

        expect(spans[0].text, equals('Red'));
        expect(spans[0].style!.color, equals(const Color(0xFFFF0000)));

        expect(spans[1].text, equals('Green'));
        expect(spans[1].style!.color, equals(const Color(0xFF00FF00)));

        expect(spans[2].text, equals('Blue'));
        expect(spans[2].style!.color, equals(const Color(0xFF0000FF)));
      });

      test('parses color named values', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">
        <span tts:color="red">Red</span>
        <span tts:color="green">Green</span>
        <span tts:color="blue">Blue</span>
        <span tts:color="white">White</span>
      </p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;

        expect(spans[0].style!.color, equals(const Color(0xFFFF0000)));
        expect(spans[1].style!.color, equals(const Color(0xFF00FF00)));
        expect(spans[2].style!.color, equals(const Color(0xFF0000FF)));
        expect(spans[3].style!.color, equals(const Color(0xFFFFFFFF)));
      });

      test('parses fontSize attribute', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">
        <span tts:fontSize="48px">Large</span>
        <span tts:fontSize="24">Medium</span>
        <span tts:fontSize="12px">Small</span>
      </p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;

        expect(spans[0].text, equals('Large'));
        expect(spans[0].style!.fontSize, equals(48.0));

        expect(spans[1].text, equals('Medium'));
        expect(spans[1].style!.fontSize, equals(24.0));

        expect(spans[2].text, equals('Small'));
        expect(spans[2].style!.fontSize, equals(12.0));
      });

      test('parses multiple styling attributes on same span', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">
        <span tts:fontWeight="bold" tts:fontStyle="italic" tts:textDecoration="underline" tts:color="#FF0000">Styled text</span>
      </p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;

        expect(spans[0].text, equals('Styled text'));
        expect(spans[0].style!.isBold, isTrue);
        expect(spans[0].style!.isItalic, isTrue);
        expect(spans[0].style!.isUnderline, isTrue);
        expect(spans[0].style!.color, equals(const Color(0xFFFF0000)));
      });

      test('parses styling on <p> tag (applies to all content)', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000" tts:fontWeight="bold">All text is bold</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;

        expect(spans[0].text, equals('All text is bold'));
        expect(spans[0].style!.isBold, isTrue);
      });

      test('merges <p> styling with <span> styling', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000" tts:fontWeight="bold">
        <span tts:fontStyle="italic">Bold and italic</span>
      </p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues[0].text, equals('Bold and italic'));
        final spans = cues[0].styledSpans!;

        // Should merge <p> bold with <span> italic
        expect(spans[0].text, equals('Bold and italic'));
        expect(spans[0].style!.isBold, isTrue);
        expect(spans[0].style!.isItalic, isTrue);
      });

      test('handles plain text without styling', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">Plain text without styling</p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        // No styling attributes, so styledSpans should be null or empty
        // (or contain a single plain span, depending on implementation)
        expect(cues[0].text, equals('Plain text without styling'));
      });

      test('handles color with rgb() function', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">
        <span tts:color="rgb(255, 0, 0)">RGB red</span>
      </p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        final spans = cues[0].styledSpans!;
        expect(spans[0].text, equals('RGB red'));
        expect(spans[0].style!.color, equals(const Color(0xFFFF0000)));
      });

      test('handles complex real-world TTML with styling', () {
        const ttml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <head>
    <styling>
      <style xml:id="speaker" tts:color="cyan"/>
      <style xml:id="sound" tts:color="white" tts:fontStyle="italic"/>
    </styling>
  </head>
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:03.000">
        <span tts:fontWeight="bold" tts:color="#FFFF00">JOHN:</span>
      </p>
      <p begin="00:00:04.000" end="00:00:06.000">
        <span tts:fontStyle="italic">(thinking) What should I say?</span>
      </p>
      <p begin="00:00:07.000" end="00:00:09.000">
        <span tts:fontWeight="bold" tts:fontStyle="italic">Bold and italic together</span>
      </p>
    </div>
  </body>
</tt>
''';

        final cues = parser.parse(ttml);

        expect(cues, hasLength(3));

        // First cue: bold yellow "JOHN:"
        final spans0 = cues[0].styledSpans!;
        expect(spans0[0].text, equals('JOHN:'));
        expect(spans0[0].style!.isBold, isTrue);
        expect(spans0[0].style!.color, equals(const Color(0xFFFFFF00)));

        // Second cue: italic "(thinking) What should I say?"
        final spans1 = cues[1].styledSpans!;
        expect(spans1[0].text, equals('(thinking) What should I say?'));
        expect(spans1[0].style!.isItalic, isTrue);

        // Third cue: bold and italic
        final spans2 = cues[2].styledSpans!;
        expect(spans2[0].text, equals('Bold and italic together'));
        expect(spans2[0].style!.isBold, isTrue);
        expect(spans2[0].style!.isItalic, isTrue);
      });
    });
  });
}
