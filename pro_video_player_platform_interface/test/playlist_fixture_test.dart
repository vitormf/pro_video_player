import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('Playlist Fixture Tests', () {
    const fixturesPath = 'test/fixtures/playlists';

    group('M3U/M3U8 Fixtures', () {
      final m3uFiles = [
        'sethdeckard_master.m3u8',
        'sethdeckard_with_codecs.m3u8',
        'sethdeckard_iframes.m3u8',
        'sethdeckard_session_data.m3u8',
        'sethdeckard_variant_codecs.m3u8',
        'grafov_master.m3u8',
        'grafov_media.m3u8',
        'grafov_widevine.m3u8',
        'javaplaylistparser_test.m3u',
        'playlistsnet_ext.m3u',
        'playlistsnet_ext_hls.m3u',
        'playlistsnet_ext_hls_master.m3u',
        'playlistsnet_not_ext.m3u',
      ];

      for (final filename in m3uFiles) {
        test('parses $filename without errors', () async {
          final file = File('$fixturesPath/m3u/$filename');
          expect(file.existsSync(), isTrue, reason: 'Fixture file $filename not found');

          final content = await file.readAsString();
          expect(content.isNotEmpty, isTrue, reason: 'File $filename is empty');

          final parser = M3UPlaylistParser();
          final result = await parser.parse(content, 'https://example.com/');

          expect(result, isNotNull, reason: 'Parser returned null for $filename');
          expect(result.items, isNotNull, reason: 'Items list is null for $filename');
        });
      }
    });

    group('PLS Fixtures', () {
      final plsFiles = [
        'nickdesaulniers_example.pls',
        'javaplaylistparser_test.pls',
        'javaplaylistparser_test2.pls',
        'playlistsnet_playlist.pls',
        'playlistsnet_playlist2.pls',
      ];

      for (final filename in plsFiles) {
        test('parses $filename without errors', () async {
          final file = File('$fixturesPath/pls/$filename');
          expect(file.existsSync(), isTrue, reason: 'Fixture file $filename not found');

          final content = await file.readAsString();
          expect(content.isNotEmpty, isTrue, reason: 'File $filename is empty');

          final parser = PLSPlaylistParser();
          final result = await parser.parse(content, 'https://example.com/');

          expect(result, isNotNull, reason: 'Parser returned null for $filename');
          expect(result.items, isNotNull, reason: 'Items list is null for $filename');
        });
      }
    });

    group('XSPF Fixtures', () {
      final xspfFiles = [
        'totem_decrypted_amazon_track.xspf',
        'totem_new_lastfm_output.xspf',
        'totem_old_lastfm_output.xspf',
        'totem_playlist.xspf',
        'totem_xml_base.xspf',
        'radio_playlist_parser_template.xspf',
        'javaplaylistparser_test.xspf',
        'javaplaylistparser_test2.xspf',
      ];

      for (final filename in xspfFiles) {
        test('parses $filename without errors', () async {
          final file = File('$fixturesPath/xspf/$filename');
          expect(file.existsSync(), isTrue, reason: 'Fixture file $filename not found');

          final content = await file.readAsString();
          expect(content.isNotEmpty, isTrue, reason: 'File $filename is empty');

          final parser = XSPFPlaylistParser();
          final result = await parser.parse(content, 'https://example.com/');

          expect(result, isNotNull, reason: 'Parser returned null for $filename');
          expect(result.items, isNotNull, reason: 'Items list is null for $filename');
        });
      }
    });

    group('JSPF Fixtures', () {
      final jspfFiles = [
        'xspf_spec_minimal.jspf',
        'xspf_spec_basic.jspf',
        'xspf_spec_comprehensive.jspf',
        'xspf_spec_empty.jspf',
        'xspf_spec_multiple_locations.jspf',
        'xspf_spec_with_images.jspf',
        'xspf_spec_podcast.jspf',
        'xspf_spec_radio.jspf',
        'xspf_spec_album.jspf',
        'xspf_spec_identifiers.jspf',
        'xspf_spec_long_playlist.jspf',
        'xspf_spec_license.jspf',
      ];

      for (final filename in jspfFiles) {
        test('parses $filename without errors', () async {
          final file = File('$fixturesPath/jspf/$filename');
          expect(file.existsSync(), isTrue, reason: 'Fixture file $filename not found');

          final content = await file.readAsString();
          expect(content.isNotEmpty, isTrue, reason: 'File $filename is empty');

          final parser = JSPFPlaylistParser();
          final result = await parser.parse(content, 'https://example.com/');

          expect(result, isNotNull, reason: 'Parser returned null for $filename');
          expect(result.items, isNotNull, reason: 'Items list is null for $filename');
        });
      }
    });

    group('ASX Fixtures', () {
      final asxFiles = [
        'nickdesaulniers_example.asx',
        'nickdesaulniers_malformed.asx',
        'nickdesaulniers_malformed_no_attributes.asx',
        'nickdesaulniers_malformed_wrong_case.asx',
        'javaplaylistparser_test.asx',
      ];

      for (final filename in asxFiles) {
        test('parses $filename without errors', () async {
          final file = File('$fixturesPath/asx/$filename');
          expect(file.existsSync(), isTrue, reason: 'Fixture file $filename not found');

          final content = await file.readAsString();
          expect(content.isNotEmpty, isTrue, reason: 'File $filename is empty');

          final parser = ASXPlaylistParser();
          final result = await parser.parse(content, 'https://example.com/');

          expect(result, isNotNull, reason: 'Parser returned null for $filename');
          expect(result.items, isNotNull, reason: 'Items list is null for $filename');
        });
      }
    });

    group('WPL Fixtures', () {
      final wplFiles = [
        'playlistsnet_2seq.wpl',
        'playlistsnet_2seqoutput.wpl',
        'playlistsnet_2seqoutputTest.wpl',
        'playlistsnet_empty.wpl',
        'playlistsnet_playlist.wpl',
        'playlistsnet_playlist2.wpl',
        'playlistsnet_playlist3.wpl',
        'playlistsnet_smart.wpl',
        'playlistsnet_playlist3b.wpl',
        'javaplaylistparser_test.wpl',
      ];

      for (final filename in wplFiles) {
        test('parses $filename without errors', () async {
          final file = File('$fixturesPath/wpl/$filename');
          expect(file.existsSync(), isTrue, reason: 'Fixture file $filename not found');

          final content = await file.readAsString();
          expect(content.isNotEmpty, isTrue, reason: 'File $filename is empty');

          final parser = WPLPlaylistParser();
          final result = await parser.parse(content, 'https://example.com/');

          expect(result, isNotNull, reason: 'Parser returned null for $filename');
          expect(result.items, isNotNull, reason: 'Items list is null for $filename');
        });
      }
    });

    group('CUE Sheet Fixtures', () {
      final cueFiles = [
        'libcue_99_tracks.cue',
        'libcue_issue10.cue',
        'libcue_standard.cue',
        'libcue_multiple_files.cue',
        'libcue_multiple_files_pregap.cue',
        'libcue_noncompliant.cue',
        'libcue_single_idx_00.cue',
      ];

      for (final filename in cueFiles) {
        test('parses $filename without errors', () async {
          final file = File('$fixturesPath/cue/$filename');
          expect(file.existsSync(), isTrue, reason: 'Fixture file $filename not found');

          final content = await file.readAsString();
          expect(content.isNotEmpty, isTrue, reason: 'File $filename is empty');

          final parser = CUEPlaylistParser();
          final result = await parser.parse(content, 'https://example.com/');

          expect(result, isNotNull, reason: 'Parser returned null for $filename');
          expect(result.items, isNotNull, reason: 'Items list is null for $filename');
        });
      }
    });

    group('DASH/MPD Fixtures', () {
      final dashFiles = [
        'shaka_angel_one.mpd',
        'shaka_angel_one_clearkey.mpd',
        'shaka_sintel.mpd',
        'shaka_sintel_basic.mpd',
        'shaka_sintel_trickplay.mpd',
        'shaka_sintel_webm_only.mpd',
        'shaka_sintel_mp4_only.mpd',
        'shaka_sintel_widevine.mpd',
        'shaka_sintel_mp4_wvtt.mpd',
        'shaka_heliocentrism.mpd',
      ];

      for (final filename in dashFiles) {
        test('parses $filename without errors', () async {
          final file = File('$fixturesPath/dash/$filename');
          expect(file.existsSync(), isTrue, reason: 'Fixture file $filename not found');

          final content = await file.readAsString();
          expect(content.isNotEmpty, isTrue, reason: 'File $filename is empty');

          final parser = DASHPlaylistParser();
          final result = await parser.parse(content, 'https://example.com/');

          expect(result, isNotNull, reason: 'Parser returned null for $filename');
          expect(result.items, isNotNull, reason: 'Items list is null for $filename');
        });
      }
    });

    group('Format Detection', () {
      test('detects M3U format (HLS master)', () async {
        final file = File('$fixturesPath/m3u/sethdeckard_master.m3u8');
        final content = await file.readAsString();

        final parser = M3UPlaylistParser();
        final type = parser.detectType(content);
        expect(type, equals(PlaylistType.hlsMaster));
      });

      test('detects PLS format', () async {
        final file = File('$fixturesPath/pls/nickdesaulniers_example.pls');
        final content = await file.readAsString();

        final parser = PLSPlaylistParser();
        final type = parser.detectType(content);
        expect(type, equals(PlaylistType.pls));
      });

      test('detects XSPF format', () async {
        final file = File('$fixturesPath/xspf/totem_playlist.xspf');
        final content = await file.readAsString();

        final parser = XSPFPlaylistParser();
        final type = parser.detectType(content);
        expect(type, equals(PlaylistType.xspf));
      });

      test('detects JSPF format', () async {
        final file = File('$fixturesPath/jspf/xspf_spec_basic.jspf');
        final content = await file.readAsString();

        final parser = JSPFPlaylistParser();
        final type = parser.detectType(content);
        expect(type, equals(PlaylistType.jspf));
      });

      test('detects ASX format', () async {
        final file = File('$fixturesPath/asx/nickdesaulniers_example.asx');
        final content = await file.readAsString();

        final parser = ASXPlaylistParser();
        final type = parser.detectType(content);
        expect(type, equals(PlaylistType.asx));
      });

      test('detects WPL format', () async {
        final file = File('$fixturesPath/wpl/playlistsnet_playlist.wpl');
        final content = await file.readAsString();

        final parser = WPLPlaylistParser();
        final type = parser.detectType(content);
        expect(type, equals(PlaylistType.wpl));
      });

      test('detects CUE format', () async {
        final file = File('$fixturesPath/cue/libcue_standard.cue');
        final content = await file.readAsString();

        final parser = CUEPlaylistParser();
        final type = parser.detectType(content);
        expect(type, equals(PlaylistType.cue));
      });

      test('detects DASH/MPD format', () async {
        final file = File('$fixturesPath/dash/shaka_angel_one.mpd');
        final content = await file.readAsString();

        final parser = DASHPlaylistParser();
        final type = parser.detectType(content);
        expect(type, equals(PlaylistType.dash));
      });
    });
  });
}
