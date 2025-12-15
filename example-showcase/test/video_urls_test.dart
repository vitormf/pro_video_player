import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_example/constants/video_constants.dart';

/// Tests that all video and subtitle URLs used in the example app are accessible.
///
/// This test should be run periodically to catch broken links early.
/// Run with: `cd example && fvm flutter test test/video_urls_test.dart`
void main() {
  final httpClient = HttpClient();

  setUpAll(() {
    httpClient.connectionTimeout = const Duration(seconds: 10);
  });

  tearDownAll(httpClient.close);

  Future<int> checkUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final request = await httpClient.headUrl(uri);
      final response = await request.close();
      return response.statusCode;
    } catch (e) {
      return -1; // Connection error
    }
  }

  group('VideoUrls', () {
    group('Google Cloud Storage MP4 videos', () {
      test('bigBuckBunny is accessible', () async {
        final status = await checkUrl(VideoUrls.bigBuckBunny);
        expect(status, equals(200), reason: 'BigBuckBunny.mp4 should be accessible');
      });

      test('elephantsDream is accessible', () async {
        final status = await checkUrl(VideoUrls.elephantsDream);
        expect(status, equals(200), reason: 'ElephantsDream.mp4 should be accessible');
      });

      test('forBiggerBlazes is accessible', () async {
        final status = await checkUrl(VideoUrls.forBiggerBlazes);
        expect(status, equals(200), reason: 'ForBiggerBlazes.mp4 should be accessible');
      });

      test('forBiggerEscapes is accessible', () async {
        final status = await checkUrl(VideoUrls.forBiggerEscapes);
        expect(status, equals(200), reason: 'ForBiggerEscapes.mp4 should be accessible');
      });

      test('forBiggerFun is accessible', () async {
        final status = await checkUrl(VideoUrls.forBiggerFun);
        expect(status, equals(200), reason: 'ForBiggerFun.mp4 should be accessible');
      });
    });

    group('HLS streaming URLs', () {
      test('appleHlsBipbop is accessible', () async {
        final status = await checkUrl(VideoUrls.appleHlsBipbop);
        expect(status, equals(200), reason: 'Apple HLS bipbop should be accessible');
      });

      test('shakaAngelOneHls is accessible', () async {
        final status = await checkUrl(VideoUrls.shakaAngelOneHls);
        expect(status, equals(200), reason: 'Shaka Angel One HLS should be accessible');
      });

      test('bitmovinSintelHls is accessible', () async {
        final status = await checkUrl(VideoUrls.bitmovinSintelHls);
        expect(status, equals(200), reason: 'Bitmovin Sintel HLS should be accessible');
      });

      test('awsBipbopHls is accessible', () async {
        final status = await checkUrl(VideoUrls.awsBipbopHls);
        expect(status, equals(200), reason: 'AWS bipbop HLS should be accessible');
      });
    });

    group('DASH streaming URLs', () {
      test('shakaSintelDash is accessible', () async {
        final status = await checkUrl(VideoUrls.shakaSintelDash);
        expect(status, equals(200), reason: 'Shaka Sintel DASH should be accessible');
      });

      test('bitmovinSintelDash is accessible', () async {
        final status = await checkUrl(VideoUrls.bitmovinSintelDash);
        expect(status, equals(200), reason: 'Bitmovin Sintel DASH should be accessible');
      });

      test('shakaAngelOneDash is accessible', () async {
        final status = await checkUrl(VideoUrls.shakaAngelOneDash);
        expect(status, equals(200), reason: 'Shaka Angel One DASH should be accessible');
      });
    });

    group('Videos with embedded subtitles', () {
      test('bitmovinSintelWithSubsHls is accessible', () async {
        final status = await checkUrl(VideoUrls.bitmovinSintelWithSubsHls);
        expect(status, equals(200), reason: 'Bitmovin Sintel with subs HLS should be accessible');
      });

      test('bitmovinSintelWithSubsDash is accessible', () async {
        final status = await checkUrl(VideoUrls.bitmovinSintelWithSubsDash);
        expect(status, equals(200), reason: 'Bitmovin Sintel with subs DASH should be accessible');
      });

      test('shakaAngelOneWithSubsHls is accessible', () async {
        final status = await checkUrl(VideoUrls.shakaAngelOneWithSubsHls);
        expect(status, equals(200), reason: 'Shaka Angel One with subs HLS should be accessible');
      });

      test('shakaAngelOneWithSubsDash is accessible', () async {
        final status = await checkUrl(VideoUrls.shakaAngelOneWithSubsDash);
        expect(status, equals(200), reason: 'Shaka Angel One with subs DASH should be accessible');
      });
    });
  });

  group('SubtitleUrls', () {
    group('Sintel subtitles (Bitmovin)', () {
      test('sintelEnglishVtt is accessible', () async {
        final status = await checkUrl(SubtitleUrls.sintelEnglishVtt);
        expect(status, equals(200), reason: 'Sintel English VTT should be accessible');
      });

      test('sintelSpanishVtt is accessible', () async {
        final status = await checkUrl(SubtitleUrls.sintelSpanishVtt);
        expect(status, equals(200), reason: 'Sintel Spanish VTT should be accessible');
      });

      test('sintelGermanVtt is accessible', () async {
        final status = await checkUrl(SubtitleUrls.sintelGermanVtt);
        expect(status, equals(200), reason: 'Sintel German VTT should be accessible');
      });

      test('sintelFrenchVtt is accessible', () async {
        final status = await checkUrl(SubtitleUrls.sintelFrenchVtt);
        expect(status, equals(200), reason: 'Sintel French VTT should be accessible');
      });
    });

    group('Sample subtitle formats (mantas-done)', () {
      test('sampleSrt is accessible', () async {
        final status = await checkUrl(SubtitleUrls.sampleSrt);
        expect(status, equals(200), reason: 'Sample SRT should be accessible');
      });

      test('sampleAss is accessible', () async {
        final status = await checkUrl(SubtitleUrls.sampleAss);
        expect(status, equals(200), reason: 'Sample ASS should be accessible');
      });

      test('sampleTtml is accessible', () async {
        final status = await checkUrl(SubtitleUrls.sampleTtml);
        expect(status, equals(200), reason: 'Sample TTML should be accessible');
      });

      test('sampleVtt is accessible', () async {
        final status = await checkUrl(SubtitleUrls.sampleVtt);
        expect(status, equals(200), reason: 'Sample VTT should be accessible');
      });
    });
  });
}
