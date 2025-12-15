import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('PlaylistLoader.loadPlaylist', () {
    test('loads and parses M3U playlist', () async {
      const playlistUrl = 'https://example.com/playlist.m3u';
      const playlistContent = '''
#EXTM3U
#EXTINF:123,Video 1
https://example.com/video1.mp4
#EXTINF:456,Video 2
https://example.com/video2.mp4
''';

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), playlistUrl);
        return http.Response(playlistContent, 200);
      });

      final loader = PlaylistLoader(client: mockClient);
      final result = await loader.loadPlaylist(playlistUrl);

      expect(result.type, PlaylistType.m3uSimple);
      expect(result.items.length, 2);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/video2.mp4');
    });

    test('loads and parses PLS playlist', () async {
      const playlistUrl = 'https://example.com/playlist.pls';
      const playlistContent = '''
[playlist]
File1=https://example.com/video1.mp4
File2=https://example.com/video2.mp4
NumberOfEntries=2
''';

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), playlistUrl);
        return http.Response(playlistContent, 200);
      });

      final loader = PlaylistLoader(client: mockClient);
      final result = await loader.loadPlaylist(playlistUrl);

      expect(result.type, PlaylistType.pls);
      expect(result.items.length, 2);
    });

    test('loads and parses XSPF playlist', () async {
      const playlistUrl = 'https://example.com/playlist.xspf';
      const playlistContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <track>
    <location>https://example.com/video1.mp4</location>
  </track>
  <track>
    <location>https://example.com/video2.mp4</location>
  </track>
</playlist>
''';

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), playlistUrl);
        return http.Response(playlistContent, 200);
      });

      final loader = PlaylistLoader(client: mockClient);
      final result = await loader.loadPlaylist(playlistUrl);

      expect(result.type, PlaylistType.xspf);
      expect(result.items.length, 2);
    });

    test('detects HLS master playlist', () async {
      const playlistUrl = 'https://example.com/master.m3u8';
      const playlistContent = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=854x480
stream1.m3u8
''';

      final mockClient = MockClient((request) async => http.Response(playlistContent, 200));

      final loader = PlaylistLoader(client: mockClient);
      final result = await loader.loadPlaylist(playlistUrl);

      expect(result.type, PlaylistType.hlsMaster);
      expect(result.isAdaptiveStream, true);
      expect(result.items, isEmpty);
    });

    test('detects HLS media playlist', () async {
      const playlistUrl = 'https://example.com/stream.m3u8';
      const playlistContent = '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:10.0,
segment1.ts
''';

      final mockClient = MockClient((request) async => http.Response(playlistContent, 200));

      final loader = PlaylistLoader(client: mockClient);
      final result = await loader.loadPlaylist(playlistUrl);

      expect(result.type, PlaylistType.hlsMedia);
      expect(result.isAdaptiveStream, true);
      expect(result.items, isEmpty);
    });

    test('includes custom headers in request', () async {
      const playlistUrl = 'https://example.com/playlist.m3u';
      final headers = {'Authorization': 'Bearer token123', 'Custom': 'value'};

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token123');
        expect(request.headers['Custom'], 'value');
        return http.Response('#EXTM3U\n', 200);
      });

      final loader = PlaylistLoader(client: mockClient);
      await loader.loadPlaylist(playlistUrl, headers: headers);
    });

    test('throws exception on HTTP error', () async {
      const playlistUrl = 'https://example.com/playlist.m3u';

      final mockClient = MockClient((request) async => http.Response('Not Found', 404));

      final loader = PlaylistLoader(client: mockClient);

      expect(() => loader.loadPlaylist(playlistUrl), throwsA(isA<Exception>()));
    });

    test('throws exception on network error', () async {
      const playlistUrl = 'https://example.com/playlist.m3u';

      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final loader = PlaylistLoader(client: mockClient);

      expect(() => loader.loadPlaylist(playlistUrl), throwsException);
    });
  });

  group('PlaylistLoader.toPlaylist', () {
    late PlaylistLoader loader;

    setUp(() {
      loader = PlaylistLoader(client: MockClient((request) async => http.Response('', 200)));
    });

    test('converts simple M3U result to Playlist', () {
      const parseResult = PlaylistParseResult(
        type: PlaylistType.m3uSimple,
        items: [
          NetworkVideoSource('https://example.com/video1.mp4'),
          NetworkVideoSource('https://example.com/video2.mp4'),
          NetworkVideoSource('https://example.com/video3.mp4'),
        ],
        title: 'My Playlist',
      );

      final playlist = loader.toPlaylist(parseResult);

      expect(playlist, isNotNull);
      expect(playlist!.items.length, 3);
      expect(playlist.items[0], parseResult.items[0]);
      expect(playlist.items[1], parseResult.items[1]);
      expect(playlist.items[2], parseResult.items[2]);
    });

    test('converts PLS result to Playlist', () {
      const parseResult = PlaylistParseResult(
        type: PlaylistType.pls,
        items: [
          NetworkVideoSource('https://example.com/video1.mp4'),
          NetworkVideoSource('https://example.com/video2.mp4'),
        ],
      );

      final playlist = loader.toPlaylist(parseResult);

      expect(playlist, isNotNull);
      expect(playlist!.items.length, 2);
    });

    test('converts XSPF result to Playlist', () {
      const parseResult = PlaylistParseResult(
        type: PlaylistType.xspf,
        items: [NetworkVideoSource('https://example.com/video1.mp4')],
      );

      final playlist = loader.toPlaylist(parseResult);

      expect(playlist, isNotNull);
      expect(playlist!.items.length, 1);
    });

    test('returns null for HLS master playlist', () {
      const parseResult = PlaylistParseResult(type: PlaylistType.hlsMaster, items: []);

      final playlist = loader.toPlaylist(parseResult);

      expect(playlist, isNull);
    });

    test('returns null for HLS media playlist', () {
      const parseResult = PlaylistParseResult(type: PlaylistType.hlsMedia, items: []);

      final playlist = loader.toPlaylist(parseResult);

      expect(playlist, isNull);
    });

    test('returns null for empty items', () {
      const parseResult = PlaylistParseResult(type: PlaylistType.m3uSimple, items: []);

      final playlist = loader.toPlaylist(parseResult);

      expect(playlist, isNull);
    });
  });

  group('PlaylistLoader.loadAndConvert', () {
    test('returns Playlist for simple M3U', () async {
      const playlistUrl = 'https://example.com/playlist.m3u';
      const playlistContent = '''
#EXTM3U
#EXTINF:123,Video 1
https://example.com/video1.mp4
#EXTINF:456,Video 2
https://example.com/video2.mp4
''';

      final mockClient = MockClient((request) async => http.Response(playlistContent, 200));

      final loader = PlaylistLoader(client: mockClient);
      const source = PlaylistVideoSource(playlistUrl);
      final result = await loader.loadAndConvert(source);

      expect(result, isA<Playlist>());
      final playlist = result as Playlist;
      expect(playlist.items.length, 2);
    });

    test('returns VideoSource for HLS master playlist', () async {
      const playlistUrl = 'https://example.com/master.m3u8';
      const playlistContent = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1280000
stream.m3u8
''';

      final mockClient = MockClient((request) async => http.Response(playlistContent, 200));

      final loader = PlaylistLoader(client: mockClient);
      const source = PlaylistVideoSource(playlistUrl);
      final result = await loader.loadAndConvert(source);

      expect(result, isA<VideoSource>());
      expect(result, isA<NetworkVideoSource>());
      final videoSource = result as NetworkVideoSource;
      expect(videoSource.url, playlistUrl);
    });

    test('returns VideoSource for HLS media playlist', () async {
      const playlistUrl = 'https://example.com/stream.m3u8';
      const playlistContent = '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:10.0,
segment.ts
''';

      final mockClient = MockClient((request) async => http.Response(playlistContent, 200));

      final loader = PlaylistLoader(client: mockClient);
      const source = PlaylistVideoSource(playlistUrl);
      final result = await loader.loadAndConvert(source);

      expect(result, isA<VideoSource>());
      expect(result, isA<NetworkVideoSource>());
    });

    test('includes headers in returned VideoSource for HLS', () async {
      const playlistUrl = 'https://example.com/master.m3u8';
      const playlistContent = '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1280000\nstream.m3u8';
      final headers = {'Authorization': 'Bearer token123'};

      final mockClient = MockClient((request) async => http.Response(playlistContent, 200));

      final loader = PlaylistLoader(client: mockClient);
      final source = PlaylistVideoSource(playlistUrl, headers: headers);
      final result = await loader.loadAndConvert(source);

      expect(result, isA<NetworkVideoSource>());
      final videoSource = result as NetworkVideoSource;
      expect(videoSource.headers, headers);
    });
  });
}
