import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Mock HTTP client for testing network requests.
class MockHttpClient extends Mock implements http.Client {}

/// Fake Uri for mocktail fallback value.
class FakeUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeUri());
  });

  group('SubtitleLoader', () {
    late SubtitleLoader loader;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      loader = SubtitleLoader(client: mockClient);
    });

    group('loadSubtitles', () {
      test('loads and parses SRT from network source', () async {
        const srtContent = '''
1
00:00:01,000 --> 00:00:05,000
Hello, world!

2
00:00:06,000 --> 00:00:10,000
This is a test.
''';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(srtContent, 200));

        const source = SubtitleSource.network('https://example.com/subtitle.srt', format: SubtitleFormat.srt);

        final cues = await loader.loadSubtitles(source);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('Hello, world!'));
        expect(cues[0].start, equals(const Duration(seconds: 1)));
        expect(cues[0].end, equals(const Duration(seconds: 5)));
        expect(cues[1].text, equals('This is a test.'));

        verify(() => mockClient.get(Uri.parse('https://example.com/subtitle.srt'))).called(1);
      });

      test('loads and parses VTT from network source', () async {
        const vttContent = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Hello from VTT!

00:00:06.000 --> 00:00:10.000
WebVTT subtitle.
''';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(vttContent, 200));

        const source = SubtitleSource.network('https://example.com/subtitle.vtt', format: SubtitleFormat.vtt);

        final cues = await loader.loadSubtitles(source);

        expect(cues, hasLength(2));
        expect(cues[0].text, equals('Hello from VTT!'));
        expect(cues[1].text, equals('WebVTT subtitle.'));
      });

      test('loads and parses SSA from network source', () async {
        const ssaContent = '''
[Script Info]
Title: Test

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,SSA subtitle
''';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(ssaContent, 200));

        const source = SubtitleSource.network('https://example.com/subtitle.ssa', format: SubtitleFormat.ssa);

        final cues = await loader.loadSubtitles(source);

        expect(cues, hasLength(1));
        expect(cues[0].text, equals('SSA subtitle'));
      });

      test('loads and parses TTML from network source', () async {
        const ttmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">TTML subtitle</p>
    </div>
  </body>
</tt>
''';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(ttmlContent, 200));

        const source = SubtitleSource.network('https://example.com/subtitle.ttml', format: SubtitleFormat.ttml);

        final cues = await loader.loadSubtitles(source);

        expect(cues, hasLength(1));
        expect(cues[0].text, equals('TTML subtitle'));
      });

      test('throws exception when network request fails', () async {
        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response('Not Found', 404));

        const source = SubtitleSource.network('https://example.com/not-found.srt', format: SubtitleFormat.srt);

        expect(
          () => loader.loadSubtitles(source),
          throwsA(
            isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to download subtitle: HTTP 404')),
          ),
        );
      });

      test('throws exception when network throws error', () async {
        when(() => mockClient.get(any())).thenThrow(const SocketException('Network error'));

        const source = SubtitleSource.network('https://example.com/subtitle.srt', format: SubtitleFormat.srt);

        expect(
          () => loader.loadSubtitles(source),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to download subtitle'))),
        );
      });

      test('throws ArgumentError when format is null', () async {
        const srtContent = '1\n00:00:01,000 --> 00:00:05,000\nTest';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(srtContent, 200));

        const source = SubtitleSource.network(
          'https://example.com/subtitle.unknown',
          // No format specified and .unknown extension won't be detected
        );

        expect(() => loader.loadSubtitles(source), throwsA(isA<ArgumentError>()));
      });
    });

    group('loadAndConvertToWebVTT', () {
      test('returns original content for VTT format', () async {
        const vttContent = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
Already VTT!
''';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(vttContent, 200));

        const source = SubtitleSource.network('https://example.com/subtitle.vtt', format: SubtitleFormat.vtt);

        final result = await loader.loadAndConvertToWebVTT(source);

        expect(result, equals(vttContent));
      });

      test('converts SRT to WebVTT format', () async {
        const srtContent = '''
1
00:00:01,000 --> 00:00:05,000
SRT subtitle

2
00:00:06,000 --> 00:00:10,000
Second subtitle
''';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(srtContent, 200));

        const source = SubtitleSource.network('https://example.com/subtitle.srt', format: SubtitleFormat.srt);

        final result = await loader.loadAndConvertToWebVTT(source);

        expect(result, startsWith('WEBVTT\n\n'));
        expect(result, contains('00:00:01.000 --> 00:00:05.000'));
        expect(result, contains('SRT subtitle'));
        expect(result, contains('00:00:06.000 --> 00:00:10.000'));
        expect(result, contains('Second subtitle'));
      });

      test('converts SSA to WebVTT format', () async {
        const ssaContent = '''
[Script Info]
Title: Test

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,SSA to WebVTT
''';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(ssaContent, 200));

        const source = SubtitleSource.network('https://example.com/subtitle.ssa', format: SubtitleFormat.ssa);

        final result = await loader.loadAndConvertToWebVTT(source);

        expect(result, startsWith('WEBVTT\n\n'));
        expect(result, contains('00:00:01.000 --> 00:00:05.000'));
        expect(result, contains('SSA to WebVTT'));
      });

      test('converts TTML to WebVTT format', () async {
        const ttmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">TTML to WebVTT</p>
    </div>
  </body>
</tt>
''';

        when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(ttmlContent, 200));

        const source = SubtitleSource.network('https://example.com/subtitle.ttml', format: SubtitleFormat.ttml);

        final result = await loader.loadAndConvertToWebVTT(source);

        expect(result, startsWith('WEBVTT\n\n'));
        expect(result, contains('00:00:01.000 --> 00:00:05.000'));
        expect(result, contains('TTML to WebVTT'));
      });
    });

    group('file source support', () {
      test('throws exception for non-existent file', () async {
        const source = SubtitleSource.file('/non/existent/path/subtitle.srt', format: SubtitleFormat.srt);

        expect(
          () => loader.loadSubtitles(source),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to read subtitle file'))),
        );
      });
    });

    group('asset source support', () {
      test('throws exception for non-existent asset', () async {
        const source = SubtitleSource.asset('assets/non_existent.srt', format: SubtitleFormat.srt);

        expect(
          () => loader.loadSubtitles(source),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to load subtitle asset'))),
        );
      });
    });
  });
}
