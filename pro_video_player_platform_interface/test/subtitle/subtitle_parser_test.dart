import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('SubtitleParser', () {
    test('parses SRT format', () {
      const content = '''
1
00:00:01,000 --> 00:00:05,000
Hello SRT
''';

      final cues = SubtitleParser.parse(content, SubtitleFormat.srt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Hello SRT'));
    });

    test('parses VTT format', () {
      const content = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Hello VTT
''';

      final cues = SubtitleParser.parse(content, SubtitleFormat.vtt);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Hello VTT'));
    });

    test('parses SSA format', () {
      const content = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Hello SSA
''';

      final cues = SubtitleParser.parse(content, SubtitleFormat.ssa);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Hello SSA'));
    });

    test('parses ASS format (uses SSA parser)', () {
      const content = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Hello ASS
''';

      final cues = SubtitleParser.parse(content, SubtitleFormat.ass);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Hello ASS'));
    });

    test('parses TTML format', () {
      const content = '''
<?xml version="1.0"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body><div><p begin="00:00:01.000" end="00:00:05.000">Hello TTML</p></div></body>
</tt>
''';

      final cues = SubtitleParser.parse(content, SubtitleFormat.ttml);

      expect(cues, hasLength(1));
      expect(cues[0].text, equals('Hello TTML'));
    });

    group('detectFormat', () {
      test('detects SRT format', () {
        const content = '''
1
00:00:01,000 --> 00:00:05,000
Test
''';

        expect(SubtitleParser.detectFormat(content), equals(SubtitleFormat.srt));
      });

      test('detects VTT format from header', () {
        const content = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Test
''';

        expect(SubtitleParser.detectFormat(content), equals(SubtitleFormat.vtt));
      });

      test('detects VTT format from header with BOM', () {
        const content = '\uFEFFWEBVTT\n\n00:00:01.000 --> 00:00:05.000\nTest';

        expect(SubtitleParser.detectFormat(content), equals(SubtitleFormat.vtt));
      });

      test('detects SSA format', () {
        const content = '''
[Script Info]
Title: Test

[Events]
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Test
''';

        expect(SubtitleParser.detectFormat(content), equals(SubtitleFormat.ssa));
      });

      test('detects ASS format from script type', () {
        const content = '''
[Script Info]
ScriptType: v4.00+

[Events]
''';

        expect(SubtitleParser.detectFormat(content), equals(SubtitleFormat.ass));
      });

      test('detects TTML format from XML', () {
        const content = '''
<?xml version="1.0"?>
<tt xmlns="http://www.w3.org/ns/ttml">
</tt>
''';

        expect(SubtitleParser.detectFormat(content), equals(SubtitleFormat.ttml));
      });

      test('detects TTML format from tt element', () {
        const content = '<tt xmlns="http://www.w3.org/ns/ttml"></tt>';

        expect(SubtitleParser.detectFormat(content), equals(SubtitleFormat.ttml));
      });

      test('returns null for unrecognized format', () {
        const content = 'just some random text';

        expect(SubtitleParser.detectFormat(content), isNull);
      });
    });

    group('parseWithAutoDetect', () {
      test('auto-detects and parses SRT', () {
        const content = '''
1
00:00:01,000 --> 00:00:05,000
Auto SRT
''';

        final cues = SubtitleParser.parseWithAutoDetect(content);

        expect(cues, hasLength(1));
        expect(cues[0].text, equals('Auto SRT'));
      });

      test('auto-detects and parses VTT', () {
        const content = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Auto VTT
''';

        final cues = SubtitleParser.parseWithAutoDetect(content);

        expect(cues, hasLength(1));
        expect(cues[0].text, equals('Auto VTT'));
      });

      test('returns empty list for unrecognized format', () {
        const content = 'random content';

        final cues = SubtitleParser.parseWithAutoDetect(content);

        expect(cues, isEmpty);
      });
    });

    group('getParser', () {
      test('returns SrtParser for srt format', () {
        expect(SubtitleParser.getParser(SubtitleFormat.srt), isA<SrtParser>());
      });

      test('returns VttParser for vtt format', () {
        expect(SubtitleParser.getParser(SubtitleFormat.vtt), isA<VttParser>());
      });

      test('returns SsaParser for ssa format', () {
        expect(SubtitleParser.getParser(SubtitleFormat.ssa), isA<SsaParser>());
      });

      test('returns SsaParser for ass format', () {
        expect(SubtitleParser.getParser(SubtitleFormat.ass), isA<SsaParser>());
      });

      test('returns TtmlParser for ttml format', () {
        expect(SubtitleParser.getParser(SubtitleFormat.ttml), isA<TtmlParser>());
      });
    });
  });
}
