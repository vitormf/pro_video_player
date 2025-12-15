import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('M3UPlaylistParser', () {
    late M3UPlaylistParser parser;

    setUp(() {
      parser = M3UPlaylistParser();
    });

    test('detectType identifies HLS master playlist', () {
      const content = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=854x480
stream1.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2560000,RESOLUTION=1280x720
stream2.m3u8
''';

      expect(parser.detectType(content), PlaylistType.hlsMaster);
    });

    test('detectType identifies HLS media playlist', () {
      const content = '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:9.9,
segment1.ts
#EXTINF:10.0,
segment2.ts
''';

      expect(parser.detectType(content), PlaylistType.hlsMedia);
    });

    test('detectType identifies simple M3U playlist', () {
      const content = '''
#EXTM3U
#EXTINF:123,Video 1
https://example.com/video1.mp4
#EXTINF:456,Video 2
https://example.com/video2.mp4
''';

      expect(parser.detectType(content), PlaylistType.m3uSimple);
    });

    test('parse returns empty items for HLS master playlist', () async {
      const content = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1280000
stream.m3u8
''';
      const baseUrl = 'https://example.com/playlist.m3u8';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.hlsMaster);
      expect(result.items, isEmpty);
      expect(result.isAdaptiveStream, true);
    });

    test('parse returns empty items for HLS media playlist', () async {
      const content = '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:10.0,
segment.ts
''';
      const baseUrl = 'https://example.com/stream.m3u8';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.hlsMedia);
      expect(result.items, isEmpty);
      expect(result.isAdaptiveStream, true);
    });

    test('parse extracts video URLs from simple M3U playlist', () async {
      const content = '''
#EXTM3U
#EXTINF:123,Video 1
https://example.com/video1.mp4
#EXTINF:456,Video 2
https://example.com/video2.mp4
#EXTINF:789,Video 3
https://example.com/video3.mp4
''';
      const baseUrl = 'https://example.com/playlist.m3u';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.m3uSimple);
      expect(result.items.length, 3);
      expect(result.isAdaptiveStream, false);
      expect(result.isMultiVideo, true);

      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/video2.mp4');
      expect((result.items[2] as NetworkVideoSource).url, 'https://example.com/video3.mp4');
    });

    test('parse resolves relative URLs correctly', () async {
      const content = '''
#EXTM3U
#EXTINF:123,Video 1
video1.mp4
#EXTINF:456,Video 2
../videos/video2.mp4
#EXTINF:789,Video 3
/absolute/video3.mp4
''';
      const baseUrl = 'https://example.com/playlists/list.m3u';

      final result = await parser.parse(content, baseUrl);

      expect(result.items.length, 3);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/playlists/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/playlists/../videos/video2.mp4');
      expect((result.items[2] as NetworkVideoSource).url, 'https://example.com/absolute/video3.mp4');
    });

    test('parse extracts playlist title', () async {
      const content = '''
#EXTM3U
#PLAYLIST:My Awesome Playlist
#EXTINF:123,Video 1
https://example.com/video1.mp4
''';
      const baseUrl = 'https://example.com/playlist.m3u';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'My Awesome Playlist');
    });

    test('parse handles empty lines and comments', () async {
      const content = '''
#EXTM3U

#EXTINF:123,Video 1
https://example.com/video1.mp4

# This is a comment
#EXTINF:456,Video 2
https://example.com/video2.mp4

''';
      const baseUrl = 'https://example.com/playlist.m3u';

      final result = await parser.parse(content, baseUrl);

      expect(result.items.length, 2);
    });
  });

  group('PLSPlaylistParser', () {
    late PLSPlaylistParser parser;

    setUp(() {
      parser = PLSPlaylistParser();
    });

    test('detectType returns pls', () {
      const content = '[playlist]';
      expect(parser.detectType(content), PlaylistType.pls);
    });

    test('parse extracts video URLs', () async {
      const content = '''
[playlist]
File1=https://example.com/video1.mp4
File2=https://example.com/video2.mp4
File3=https://example.com/video3.mp4
NumberOfEntries=3
''';
      const baseUrl = 'https://example.com/playlist.pls';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.pls);
      expect(result.items.length, 3);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/video2.mp4');
      expect((result.items[2] as NetworkVideoSource).url, 'https://example.com/video3.mp4');
    });

    test('parse extracts playlist title', () async {
      const content = '''
[playlist]
Title=My PLS Playlist
File1=https://example.com/video1.mp4
NumberOfEntries=1
''';
      const baseUrl = 'https://example.com/playlist.pls';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'My PLS Playlist');
    });

    test('parse handles track titles', () async {
      const content = '''
[playlist]
File1=https://example.com/video1.mp4
Title1=First Video
File2=https://example.com/video2.mp4
Title2=Second Video
NumberOfEntries=2
''';
      const baseUrl = 'https://example.com/playlist.pls';

      final result = await parser.parse(content, baseUrl);

      expect(result.metadata['titles'], {1: 'First Video', 2: 'Second Video'});
    });

    test('parse resolves relative URLs', () async {
      const content = '''
[playlist]
File1=video1.mp4
File2=/absolute/video2.mp4
NumberOfEntries=2
''';
      const baseUrl = 'https://example.com/playlists/list.pls';

      final result = await parser.parse(content, baseUrl);

      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/playlists/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/absolute/video2.mp4');
    });
  });

  group('XSPFPlaylistParser', () {
    late XSPFPlaylistParser parser;

    setUp(() {
      parser = XSPFPlaylistParser();
    });

    test('detectType returns xspf', () {
      const content = '<playlist xmlns="http://xspf.org/ns/0/">';
      expect(parser.detectType(content), PlaylistType.xspf);
    });

    test('parse extracts video URLs', () async {
      const content = '''
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <track>
    <location>https://example.com/video1.mp4</location>
  </track>
  <track>
    <location>https://example.com/video2.mp4</location>
  </track>
  <track>
    <location>https://example.com/video3.mp4</location>
  </track>
</playlist>
''';
      const baseUrl = 'https://example.com/playlist.xspf';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.xspf);
      expect(result.items.length, 3);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/video2.mp4');
      expect((result.items[2] as NetworkVideoSource).url, 'https://example.com/video3.mp4');
    });

    test('parse extracts playlist title', () async {
      const content = '''
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>My XSPF Playlist</title>
  <track>
    <location>https://example.com/video1.mp4</location>
  </track>
</playlist>
''';
      const baseUrl = 'https://example.com/playlist.xspf';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'My XSPF Playlist');
    });

    test('parse handles XML entities', () async {
      const content = '''
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>Playlist &amp; More</title>
  <track>
    <location>https://example.com/video.mp4?param=1&amp;other=2</location>
  </track>
</playlist>
''';
      const baseUrl = 'https://example.com/playlist.xspf';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'Playlist & More');
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video.mp4?param=1&other=2');
    });

    test('parse resolves relative URLs', () async {
      const content = '''
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <track>
    <location>video1.mp4</location>
  </track>
  <track>
    <location>/absolute/video2.mp4</location>
  </track>
</playlist>
''';
      const baseUrl = 'https://example.com/playlists/list.xspf';

      final result = await parser.parse(content, baseUrl);

      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/playlists/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/absolute/video2.mp4');
    });
  });

  group('JSPFPlaylistParser', () {
    late JSPFPlaylistParser parser;

    setUp(() {
      parser = JSPFPlaylistParser();
    });

    test('detectType returns jspf', () {
      const content = '{"playlist":{}}';
      expect(parser.detectType(content), PlaylistType.jspf);
    });

    test('parse extracts video URLs', () async {
      const content = '''
{
  "playlist": {
    "track": [
      {"location": "https://example.com/video1.mp4"},
      {"location": "https://example.com/video2.mp4"},
      {"location": "https://example.com/video3.mp4"}
    ]
  }
}
''';
      const baseUrl = 'https://example.com/playlist.jspf';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.jspf);
      expect(result.items.length, 3);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/video2.mp4');
      expect((result.items[2] as NetworkVideoSource).url, 'https://example.com/video3.mp4');
    });

    test('parse extracts playlist title', () async {
      const content = '''
{
  "playlist": {
    "title": "My JSPF Playlist",
    "track": [
      {"location": "https://example.com/video1.mp4"}
    ]
  }
}
''';
      const baseUrl = 'https://example.com/playlist.jspf';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'My JSPF Playlist');
    });

    test('parse resolves relative URLs', () async {
      const content = '''
{
  "playlist": {
    "track": [
      {"location": "video1.mp4"},
      {"location": "/absolute/video2.mp4"}
    ]
  }
}
''';
      const baseUrl = 'https://example.com/playlists/list.jspf';

      final result = await parser.parse(content, baseUrl);

      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/playlists/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/absolute/video2.mp4');
    });

    test('parse handles invalid JSON gracefully', () async {
      const content = 'not valid json';
      const baseUrl = 'https://example.com/playlist.jspf';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.jspf);
      expect(result.items, isEmpty);
    });

    test('parse handles missing playlist key', () async {
      const content = '{"other": "data"}';
      const baseUrl = 'https://example.com/playlist.jspf';

      final result = await parser.parse(content, baseUrl);

      expect(result.items, isEmpty);
    });

    test('parse extracts track titles in metadata', () async {
      const content = '''
{
  "playlist": {
    "track": [
      {"location": "https://example.com/video1.mp4", "title": "First Video"},
      {"location": "https://example.com/video2.mp4", "title": "Second Video"}
    ]
  }
}
''';
      const baseUrl = 'https://example.com/playlist.jspf';

      final result = await parser.parse(content, baseUrl);

      expect(result.metadata['titles'], {0: 'First Video', 1: 'Second Video'});
    });
  });

  group('ASXPlaylistParser', () {
    late ASXPlaylistParser parser;

    setUp(() {
      parser = ASXPlaylistParser();
    });

    test('detectType returns asx', () {
      const content = '<asx version="3.0">';
      expect(parser.detectType(content), PlaylistType.asx);
    });

    test('parse extracts video URLs', () async {
      const content = '''
<asx version="3.0">
  <entry>
    <ref href="https://example.com/video1.wmv"/>
  </entry>
  <entry>
    <ref href="https://example.com/video2.wmv"/>
  </entry>
  <entry>
    <ref href="https://example.com/video3.wmv"/>
  </entry>
</asx>
''';
      const baseUrl = 'https://example.com/playlist.asx';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.asx);
      expect(result.items.length, 3);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video1.wmv');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/video2.wmv');
      expect((result.items[2] as NetworkVideoSource).url, 'https://example.com/video3.wmv');
    });

    test('parse extracts playlist title', () async {
      const content = '''
<asx version="3.0">
  <title>My ASX Playlist</title>
  <entry>
    <ref href="https://example.com/video1.wmv"/>
  </entry>
</asx>
''';
      const baseUrl = 'https://example.com/playlist.asx';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'My ASX Playlist');
    });

    test('parse resolves relative URLs', () async {
      const content = '''
<asx version="3.0">
  <entry>
    <ref href="video1.wmv"/>
  </entry>
  <entry>
    <ref href="/absolute/video2.wmv"/>
  </entry>
</asx>
''';
      const baseUrl = 'https://example.com/playlists/list.asx';

      final result = await parser.parse(content, baseUrl);

      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/playlists/video1.wmv');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/absolute/video2.wmv');
    });

    test('parse handles XML entities', () async {
      const content = '''
<asx version="3.0">
  <title>Playlist &amp; More</title>
  <entry>
    <ref href="https://example.com/video.wmv?param=1&amp;other=2"/>
  </entry>
</asx>
''';
      const baseUrl = 'https://example.com/playlist.asx';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'Playlist & More');
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video.wmv?param=1&other=2');
    });

    test('parse is case insensitive', () async {
      const content = '''
<ASX VERSION="3.0">
  <ENTRY>
    <REF HREF="https://example.com/video.wmv"/>
  </ENTRY>
</ASX>
''';
      const baseUrl = 'https://example.com/playlist.asx';

      final result = await parser.parse(content, baseUrl);

      expect(result.items.length, 1);
    });
  });

  group('WPLPlaylistParser', () {
    late WPLPlaylistParser parser;

    setUp(() {
      parser = WPLPlaylistParser();
    });

    test('detectType returns wpl', () {
      const content = '<?wpl version="1.0"?>';
      expect(parser.detectType(content), PlaylistType.wpl);
    });

    test('parse extracts video URLs', () async {
      const content = '''
<?wpl version="1.0"?>
<smil>
  <head>
    <title>My WPL Playlist</title>
  </head>
  <body>
    <seq>
      <media src="https://example.com/video1.wmv"/>
      <media src="https://example.com/video2.wmv"/>
      <media src="https://example.com/video3.wmv"/>
    </seq>
  </body>
</smil>
''';
      const baseUrl = 'https://example.com/playlist.wpl';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.wpl);
      expect(result.items.length, 3);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video1.wmv');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/video2.wmv');
      expect((result.items[2] as NetworkVideoSource).url, 'https://example.com/video3.wmv');
    });

    test('parse extracts playlist title', () async {
      const content = '''
<?wpl version="1.0"?>
<smil>
  <head>
    <title>My WPL Playlist</title>
  </head>
  <body>
    <seq>
      <media src="https://example.com/video1.wmv"/>
    </seq>
  </body>
</smil>
''';
      const baseUrl = 'https://example.com/playlist.wpl';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'My WPL Playlist');
    });

    test('parse resolves relative URLs', () async {
      const content = '''
<?wpl version="1.0"?>
<smil>
  <body>
    <seq>
      <media src="video1.wmv"/>
      <media src="/absolute/video2.wmv"/>
    </seq>
  </body>
</smil>
''';
      const baseUrl = 'https://example.com/playlists/list.wpl';

      final result = await parser.parse(content, baseUrl);

      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/playlists/video1.wmv');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/absolute/video2.wmv');
    });

    test('parse handles XML entities', () async {
      const content = '''
<?wpl version="1.0"?>
<smil>
  <head>
    <title>Playlist &amp; More</title>
  </head>
  <body>
    <seq>
      <media src="https://example.com/video.wmv?param=1&amp;other=2"/>
    </seq>
  </body>
</smil>
''';
      const baseUrl = 'https://example.com/playlist.wpl';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'Playlist & More');
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video.wmv?param=1&other=2');
    });
  });

  group('CUEPlaylistParser', () {
    late CUEPlaylistParser parser;

    setUp(() {
      parser = CUEPlaylistParser();
    });

    test('detectType returns cue', () {
      const content = 'FILE "video.mp4" MP4\nTRACK 01 AUDIO';
      expect(parser.detectType(content), PlaylistType.cue);
    });

    test('parse extracts file URLs', () async {
      const content = '''
TITLE "My Album"
FILE "video.mp4" MP4
  TRACK 01 VIDEO
    INDEX 01 00:00:00
  TRACK 02 VIDEO
    INDEX 01 05:30:00
''';
      const baseUrl = 'https://example.com/playlist.cue';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.cue);
      expect(result.items.length, 1);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video.mp4');
    });

    test('parse extracts playlist title', () async {
      const content = '''
TITLE "My Video Collection"
FILE "video.mp4" MP4
  TRACK 01 VIDEO
    INDEX 01 00:00:00
''';
      const baseUrl = 'https://example.com/playlist.cue';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'My Video Collection');
    });

    test('parse handles multiple files', () async {
      const content = '''
TITLE "Multi-File Collection"
FILE "video1.mp4" MP4
  TRACK 01 VIDEO
    INDEX 01 00:00:00
FILE "video2.mp4" MP4
  TRACK 02 VIDEO
    INDEX 01 00:00:00
''';
      const baseUrl = 'https://example.com/playlist.cue';

      final result = await parser.parse(content, baseUrl);

      expect(result.items.length, 2);
      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/video1.mp4');
      expect((result.items[1] as NetworkVideoSource).url, 'https://example.com/video2.mp4');
    });

    test('parse stores track metadata with timestamps', () async {
      const content = '''
TITLE "Album"
FILE "video.mp4" MP4
  TRACK 01 VIDEO
    TITLE "Chapter 1"
    INDEX 01 00:00:00
  TRACK 02 VIDEO
    TITLE "Chapter 2"
    INDEX 01 05:30:45
''';
      const baseUrl = 'https://example.com/playlist.cue';

      final result = await parser.parse(content, baseUrl);

      expect(result.metadata['tracks'], isNotNull);
      final tracks = result.metadata['tracks'] as Map<int, Map<String, dynamic>>;
      expect(tracks[1]?['title'], 'Chapter 1');
      expect(tracks[1]?['startMs'], 0);
      expect(tracks[2]?['title'], 'Chapter 2');
      // 5 minutes + 30 seconds + 45 frames (at 75fps)
      expect(tracks[2]?['startMs'], 5 * 60 * 1000 + 30 * 1000 + 45 * 1000 ~/ 75);
    });

    test('parse resolves relative file paths', () async {
      const content = '''
FILE "videos/video.mp4" MP4
  TRACK 01 VIDEO
    INDEX 01 00:00:00
''';
      const baseUrl = 'https://example.com/playlists/list.cue';

      final result = await parser.parse(content, baseUrl);

      expect((result.items[0] as NetworkVideoSource).url, 'https://example.com/playlists/videos/video.mp4');
    });

    test('parse handles PERFORMER metadata', () async {
      const content = '''
PERFORMER "Artist Name"
TITLE "Album Title"
FILE "video.mp4" MP4
  TRACK 01 VIDEO
    INDEX 01 00:00:00
''';
      const baseUrl = 'https://example.com/playlist.cue';

      final result = await parser.parse(content, baseUrl);

      expect(result.metadata['performer'], 'Artist Name');
    });
  });

  group('DASHPlaylistParser', () {
    late DASHPlaylistParser parser;

    setUp(() {
      parser = DASHPlaylistParser();
    });

    test('detectType returns dash', () {
      const content = '<?xml version="1.0"?><MPD></MPD>';
      expect(parser.detectType(content), PlaylistType.dash);
    });

    test('parse returns PlaylistType.dash', () async {
      const content = '''
<?xml version="1.0"?>
<MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
  <Period>
    <AdaptationSet mimeType="video/mp4">
      <Representation bandwidth="1000000" width="1920" height="1080"/>
    </AdaptationSet>
  </Period>
</MPD>''';
      const baseUrl = 'https://example.com/manifest.mpd';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.dash);
      expect(result.items, isEmpty);
      expect(result.metadata['originalUrl'], baseUrl);
    });

    test('parse extracts title from MPD', () async {
      const content = '''
<?xml version="1.0"?>
<MPD xmlns="urn:mpeg:dash:schema:mpd:2011">
  <ProgramInformation>
    <Title>Sintel DASH Stream</Title>
  </ProgramInformation>
</MPD>''';
      const baseUrl = 'https://example.com/manifest.mpd';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'Sintel DASH Stream');
    });

    test('parse handles title with XML entities', () async {
      const content = '''
<?xml version="1.0"?>
<MPD xmlns="urn:mpeg:dash:schema:mpd:2011">
  <ProgramInformation>
    <Title>Rock &amp; Roll &lt;Live&gt;</Title>
  </ProgramInformation>
</MPD>''';
      const baseUrl = 'https://example.com/manifest.mpd';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, 'Rock & Roll <Live>');
    });

    test('parse returns null title when not present', () async {
      const content = '''
<?xml version="1.0"?>
<MPD xmlns="urn:mpeg:dash:schema:mpd:2011">
  <Period>
    <AdaptationSet mimeType="video/mp4"/>
  </Period>
</MPD>''';
      const baseUrl = 'https://example.com/manifest.mpd';

      final result = await parser.parse(content, baseUrl);

      expect(result.title, isNull);
    });

    test('parse handles minimal MPD', () async {
      const content = '<MPD></MPD>';
      const baseUrl = 'https://example.com/manifest.mpd';

      final result = await parser.parse(content, baseUrl);

      expect(result.type, PlaylistType.dash);
      expect(result.items, isEmpty);
    });
  });

  group('createPlaylistParser', () {
    test('creates M3U parser for .m3u URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/playlist.m3u');
      expect(parser, isA<M3UPlaylistParser>());
    });

    test('creates M3U parser for .m3u8 URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/playlist.m3u8');
      expect(parser, isA<M3UPlaylistParser>());
    });

    test('creates PLS parser for .pls URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/playlist.pls');
      expect(parser, isA<PLSPlaylistParser>());
    });

    test('creates XSPF parser for .xspf URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/playlist.xspf');
      expect(parser, isA<XSPFPlaylistParser>());
    });

    test('creates JSPF parser for .jspf URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/playlist.jspf');
      expect(parser, isA<JSPFPlaylistParser>());
    });

    test('creates ASX parser for .asx URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/playlist.asx');
      expect(parser, isA<ASXPlaylistParser>());
    });

    test('creates WPL parser for .wpl URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/playlist.wpl');
      expect(parser, isA<WPLPlaylistParser>());
    });

    test('creates CUE parser for .cue URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/playlist.cue');
      expect(parser, isA<CUEPlaylistParser>());
    });

    test('creates M3U parser based on content with #EXTM3U', () {
      const content = '#EXTM3U\n#EXTINF:123,Video\nhttps://example.com/video.mp4';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<M3UPlaylistParser>());
    });

    test('creates PLS parser based on content with [playlist]', () {
      const content = '[playlist]\nFile1=https://example.com/video.mp4';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<PLSPlaylistParser>());
    });

    test('creates XSPF parser based on XML content', () {
      const content = '<?xml version="1.0"?>\n<playlist xmlns="http://xspf.org/ns/0/">';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<XSPFPlaylistParser>());
    });

    test('creates JSPF parser based on JSON content', () {
      const content = '{"playlist": {"track": []}}';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<JSPFPlaylistParser>());
    });

    test('creates ASX parser based on content', () {
      const content = '<asx version="3.0"><entry><ref href="video.wmv"/></entry></asx>';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<ASXPlaylistParser>());
    });

    test('creates WPL parser based on content', () {
      const content = '<?wpl version="1.0"?><smil><body><seq><media src="video.wmv"/></seq></body></smil>';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<WPLPlaylistParser>());
    });

    test('creates CUE parser based on content', () {
      const content = 'FILE "video.mp4" MP4\nTRACK 01 VIDEO\nINDEX 01 00:00:00';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<CUEPlaylistParser>());
    });

    test('creates DASH parser for .mpd URL', () {
      final parser = createPlaylistParser(url: 'https://example.com/manifest.mpd');
      expect(parser, isA<DASHPlaylistParser>());
    });

    test('creates DASH parser for .mpd URL with query params', () {
      final parser = createPlaylistParser(url: 'https://example.com/manifest.mpd?token=abc123');
      expect(parser, isA<DASHPlaylistParser>());
    });

    test('creates DASH parser based on content with <MPD>', () {
      const content = '<?xml version="1.0"?><MPD xmlns="urn:mpeg:dash:schema:mpd:2011"></MPD>';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<DASHPlaylistParser>());
    });

    test('creates DASH parser based on content with <mpd> lowercase', () {
      const content = '<?xml version="1.0"?><mpd xmlns="urn:mpeg:dash:schema:mpd:2011"></mpd>';
      final parser = createPlaylistParser(content: content);
      expect(parser, isA<DASHPlaylistParser>());
    });

    test('defaults to M3U parser when unknown', () {
      final parser = createPlaylistParser(url: 'https://example.com/unknown.txt');
      expect(parser, isA<M3UPlaylistParser>());
    });
  });

  group('PlaylistParser URL resolution', () {
    late M3UPlaylistParser parser;

    setUp(() {
      parser = M3UPlaylistParser();
    });

    test('resolveUrl returns absolute URLs unchanged', () {
      const url = 'https://example.com/video.mp4';
      const baseUrl = 'https://other.com/playlist.m3u';

      expect(parser.resolveUrl(url, baseUrl), url);
    });

    test('resolveUrl resolves URLs starting with /', () {
      const url = '/videos/video.mp4';
      const baseUrl = 'https://example.com/playlists/list.m3u';

      expect(parser.resolveUrl(url, baseUrl), 'https://example.com/videos/video.mp4');
    });

    test('resolveUrl resolves relative URLs', () {
      const url = 'video.mp4';
      const baseUrl = 'https://example.com/playlists/list.m3u';

      expect(parser.resolveUrl(url, baseUrl), 'https://example.com/playlists/video.mp4');
    });

    test('resolveUrl handles relative paths with ../', () {
      const url = '../videos/video.mp4';
      const baseUrl = 'https://example.com/playlists/subfolder/list.m3u';

      expect(parser.resolveUrl(url, baseUrl), 'https://example.com/playlists/subfolder/../videos/video.mp4');
    });

    test('resolveUrl preserves http:// URLs', () {
      const url = 'http://example.com/video.mp4';
      const baseUrl = 'https://other.com/playlist.m3u';

      expect(parser.resolveUrl(url, baseUrl), url);
    });

    test('resolveUrl preserves file:// URLs', () {
      const url = 'file:///path/to/video.mp4';
      const baseUrl = 'https://example.com/playlist.m3u';

      expect(parser.resolveUrl(url, baseUrl), url);
    });
  });

  group('Fixture file tests', () {
    late String fixturesPath;

    setUpAll(() {
      // Get the path to the fixtures directory relative to the test file
      fixturesPath = '${Directory.current.path}/test/fixtures/playlists';
      if (!Directory(fixturesPath).existsSync()) {
        // Try alternative path when running from package root
        fixturesPath = 'test/fixtures/playlists';
      }
    });

    String loadFixture(String filename) {
      final file = File('$fixturesPath/$filename');
      if (!file.existsSync()) {
        fail('Fixture file not found: $fixturesPath/$filename');
      }
      return file.readAsStringSync();
    }

    test('parses real M3U file', () async {
      final content = loadFixture('sample.m3u');
      final parser = M3UPlaylistParser();
      final result = await parser.parse(content, 'file://$fixturesPath/sample.m3u');

      expect(result.type, PlaylistType.m3uSimple);
      expect(result.title, 'Sample M3U Playlist');
      expect(result.items.length, 3);
      expect(
        (result.items[0] as NetworkVideoSource).url,
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      );
    });

    test('parses real PLS file', () async {
      final content = loadFixture('sample.pls');
      final parser = PLSPlaylistParser();
      final result = await parser.parse(content, 'file://$fixturesPath/sample.pls');

      expect(result.type, PlaylistType.pls);
      expect(result.title, 'Sample PLS Playlist');
      expect(result.items.length, 3);
      expect(result.metadata['titles'], {1: 'Big Buck Bunny', 2: 'Elephants Dream', 3: 'For Bigger Blazes'});
    });

    test('parses real XSPF file', () async {
      final content = loadFixture('sample.xspf');
      final parser = XSPFPlaylistParser();
      final result = await parser.parse(content, 'file://$fixturesPath/sample.xspf');

      expect(result.type, PlaylistType.xspf);
      expect(result.title, 'Sample XSPF Playlist');
      expect(result.items.length, 3);
    });

    test('parses real JSPF file', () async {
      final content = loadFixture('sample.jspf');
      final parser = JSPFPlaylistParser();
      final result = await parser.parse(content, 'file://$fixturesPath/sample.jspf');

      expect(result.type, PlaylistType.jspf);
      expect(result.title, 'Sample JSPF Playlist');
      expect(result.items.length, 3);
      expect(result.metadata['titles'], {0: 'Big Buck Bunny', 1: 'Elephants Dream', 2: 'For Bigger Blazes'});
    });

    test('parses real ASX file', () async {
      final content = loadFixture('sample.asx');
      final parser = ASXPlaylistParser();
      final result = await parser.parse(content, 'file://$fixturesPath/sample.asx');

      expect(result.type, PlaylistType.asx);
      expect(result.title, 'Sample ASX Playlist');
      expect(result.items.length, 3);
      expect(
        (result.items[0] as NetworkVideoSource).url,
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      );
    });

    test('parses real WPL file', () async {
      final content = loadFixture('sample.wpl');
      final parser = WPLPlaylistParser();
      final result = await parser.parse(content, 'file://$fixturesPath/sample.wpl');

      expect(result.type, PlaylistType.wpl);
      expect(result.title, 'Sample WPL Playlist');
      expect(result.items.length, 3);
    });

    test('parses real CUE file', () async {
      final content = loadFixture('sample.cue');
      final parser = CUEPlaylistParser();
      final result = await parser.parse(content, 'file://$fixturesPath/sample.cue');

      expect(result.type, PlaylistType.cue);
      expect(result.title, 'Big Buck Bunny - Chapters');
      expect(result.metadata['performer'], 'Blender Foundation');
      expect(result.items.length, 1);
      expect((result.items[0] as NetworkVideoSource).url, 'file://$fixturesPath/BigBuckBunny.mp4');

      // Verify track metadata
      final tracks = result.metadata['tracks'] as Map<int, Map<String, dynamic>>;
      expect(tracks.length, 7);
      expect(tracks[1]?['title'], 'Opening Credits');
      expect(tracks[1]?['startMs'], 0);
      expect(tracks[2]?['title'], 'The Butterfly');
      // 00:42:50 = 42 seconds + 50 frames (at 75fps) = 42000 + 666 = 42666ms
      expect(tracks[2]?['startMs'], 42 * 1000 + 50 * 1000 ~/ 75);
    });

    test('createPlaylistParser auto-detects format from file content', () {
      final m3uContent = loadFixture('sample.m3u');
      final plsContent = loadFixture('sample.pls');
      final xspfContent = loadFixture('sample.xspf');
      final jspfContent = loadFixture('sample.jspf');
      final asxContent = loadFixture('sample.asx');
      final wplContent = loadFixture('sample.wpl');
      final cueContent = loadFixture('sample.cue');

      expect(createPlaylistParser(content: m3uContent), isA<M3UPlaylistParser>());
      expect(createPlaylistParser(content: plsContent), isA<PLSPlaylistParser>());
      expect(createPlaylistParser(content: xspfContent), isA<XSPFPlaylistParser>());
      expect(createPlaylistParser(content: jspfContent), isA<JSPFPlaylistParser>());
      expect(createPlaylistParser(content: asxContent), isA<ASXPlaylistParser>());
      expect(createPlaylistParser(content: wplContent), isA<WPLPlaylistParser>());
      expect(createPlaylistParser(content: cueContent), isA<CUEPlaylistParser>());
    });
  });
}
