import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('PlaylistParseResult', () {
    test('isAdaptiveStream returns true for HLS master', () {
      const result = PlaylistParseResult(type: PlaylistType.hlsMaster, items: []);

      expect(result.isAdaptiveStream, true);
    });

    test('isAdaptiveStream returns true for HLS media', () {
      const result = PlaylistParseResult(type: PlaylistType.hlsMedia, items: []);

      expect(result.isAdaptiveStream, true);
    });

    test('isAdaptiveStream returns true for DASH', () {
      const result = PlaylistParseResult(type: PlaylistType.dash, items: []);

      expect(result.isAdaptiveStream, true);
    });

    test('isAdaptiveStream returns false for simple M3U', () {
      const result = PlaylistParseResult(
        type: PlaylistType.m3uSimple,
        items: [
          NetworkVideoSource('https://example.com/video1.mp4'),
          NetworkVideoSource('https://example.com/video2.mp4'),
        ],
      );

      expect(result.isAdaptiveStream, false);
    });

    test('isAdaptiveStream returns false for PLS', () {
      const result = PlaylistParseResult(
        type: PlaylistType.pls,
        items: [NetworkVideoSource('https://example.com/video.mp4')],
      );

      expect(result.isAdaptiveStream, false);
    });

    test('isAdaptiveStream returns false for XSPF', () {
      const result = PlaylistParseResult(
        type: PlaylistType.xspf,
        items: [NetworkVideoSource('https://example.com/video.mp4')],
      );

      expect(result.isAdaptiveStream, false);
    });

    test('isMultiVideo returns true when items has multiple entries', () {
      const result = PlaylistParseResult(
        type: PlaylistType.m3uSimple,
        items: [
          NetworkVideoSource('https://example.com/video1.mp4'),
          NetworkVideoSource('https://example.com/video2.mp4'),
          NetworkVideoSource('https://example.com/video3.mp4'),
        ],
      );

      expect(result.isMultiVideo, true);
    });

    test('isMultiVideo returns false when items has one entry', () {
      const result = PlaylistParseResult(
        type: PlaylistType.m3uSimple,
        items: [NetworkVideoSource('https://example.com/video.mp4')],
      );

      expect(result.isMultiVideo, false);
    });

    test('isMultiVideo returns false when items is empty', () {
      const result = PlaylistParseResult(type: PlaylistType.hlsMaster, items: []);

      expect(result.isMultiVideo, false);
    });

    test('stores title correctly', () {
      const result = PlaylistParseResult(type: PlaylistType.m3uSimple, items: [], title: 'My Playlist');

      expect(result.title, 'My Playlist');
    });

    test('stores metadata correctly', () {
      const result = PlaylistParseResult(
        type: PlaylistType.pls,
        items: [],
        metadata: {
          'titles': {1: 'Video 1', 2: 'Video 2'},
          'duration': 300,
        },
      );

      expect(result.metadata['titles'], {1: 'Video 1', 2: 'Video 2'});
      expect(result.metadata['duration'], 300);
    });

    test('metadata defaults to empty map when not provided', () {
      const result = PlaylistParseResult(type: PlaylistType.xspf, items: []);

      expect(result.metadata, isEmpty);
    });

    test('title is null when not provided', () {
      const result = PlaylistParseResult(type: PlaylistType.m3uSimple, items: []);

      expect(result.title, isNull);
    });
  });

  group('PlaylistType', () {
    test('enum has all expected values', () {
      expect(PlaylistType.values, [
        PlaylistType.hlsMaster,
        PlaylistType.hlsMedia,
        PlaylistType.dash,
        PlaylistType.m3uSimple,
        PlaylistType.pls,
        PlaylistType.xspf,
        PlaylistType.jspf,
        PlaylistType.asx,
        PlaylistType.wpl,
        PlaylistType.cue,
        PlaylistType.unknown,
      ]);
    });

    test('toString returns expected values', () {
      expect(PlaylistType.hlsMaster.toString(), 'PlaylistType.hlsMaster');
      expect(PlaylistType.hlsMedia.toString(), 'PlaylistType.hlsMedia');
      expect(PlaylistType.dash.toString(), 'PlaylistType.dash');
      expect(PlaylistType.m3uSimple.toString(), 'PlaylistType.m3uSimple');
      expect(PlaylistType.pls.toString(), 'PlaylistType.pls');
      expect(PlaylistType.xspf.toString(), 'PlaylistType.xspf');
      expect(PlaylistType.jspf.toString(), 'PlaylistType.jspf');
      expect(PlaylistType.asx.toString(), 'PlaylistType.asx');
      expect(PlaylistType.wpl.toString(), 'PlaylistType.wpl');
      expect(PlaylistType.cue.toString(), 'PlaylistType.cue');
      expect(PlaylistType.unknown.toString(), 'PlaylistType.unknown');
    });
  });
}
