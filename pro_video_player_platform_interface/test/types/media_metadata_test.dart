import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('MediaMetadata', () {
    test('creates with all fields', () {
      const metadata = MediaMetadata(
        title: 'Video Title',
        artist: 'Artist Name',
        album: 'Album Name',
        artworkUrl: 'https://example.com/artwork.jpg',
      );

      expect(metadata.title, 'Video Title');
      expect(metadata.artist, 'Artist Name');
      expect(metadata.album, 'Album Name');
      expect(metadata.artworkUrl, 'https://example.com/artwork.jpg');
    });

    test('creates with only title', () {
      const metadata = MediaMetadata(title: 'Video Title');

      expect(metadata.title, 'Video Title');
      expect(metadata.artist, isNull);
      expect(metadata.album, isNull);
      expect(metadata.artworkUrl, isNull);
    });

    test('creates empty metadata', () {
      const metadata = MediaMetadata.empty;

      expect(metadata.title, isNull);
      expect(metadata.artist, isNull);
      expect(metadata.album, isNull);
      expect(metadata.artworkUrl, isNull);
      expect(metadata.isEmpty, isTrue);
      expect(metadata.isNotEmpty, isFalse);
    });

    test('isEmpty returns false when any field is set', () {
      expect(const MediaMetadata(title: 'Title').isEmpty, isFalse);
      expect(const MediaMetadata(artist: 'Artist').isEmpty, isFalse);
      expect(const MediaMetadata(album: 'Album').isEmpty, isFalse);
      expect(const MediaMetadata(artworkUrl: 'https://example.com').isEmpty, isFalse);
    });

    test('isNotEmpty returns true when any field is set', () {
      expect(const MediaMetadata(title: 'Title').isNotEmpty, isTrue);
      expect(const MediaMetadata(artist: 'Artist').isNotEmpty, isTrue);
      expect(const MediaMetadata(album: 'Album').isNotEmpty, isTrue);
      expect(const MediaMetadata(artworkUrl: 'https://example.com').isNotEmpty, isTrue);
    });

    test('copyWith creates a new instance with updated fields', () {
      const original = MediaMetadata(title: 'Original Title', artist: 'Original Artist');

      final updated = original.copyWith(title: 'Updated Title', album: 'New Album');

      expect(updated.title, 'Updated Title');
      expect(updated.artist, 'Original Artist');
      expect(updated.album, 'New Album');
      expect(updated.artworkUrl, isNull);

      // Original should be unchanged
      expect(original.title, 'Original Title');
      expect(original.album, isNull);
    });

    test('copyWith with null values preserves existing values', () {
      const original = MediaMetadata(title: 'Title', artist: 'Artist');

      final updated = original.copyWith();

      expect(updated.title, 'Title');
      expect(updated.artist, 'Artist');
    });

    test('toMap returns correct map representation', () {
      const metadata = MediaMetadata(
        title: 'Video Title',
        artist: 'Artist Name',
        album: 'Album Name',
        artworkUrl: 'https://example.com/artwork.jpg',
      );

      final map = metadata.toMap();

      expect(map['title'], 'Video Title');
      expect(map['artist'], 'Artist Name');
      expect(map['album'], 'Album Name');
      expect(map['artworkUrl'], 'https://example.com/artwork.jpg');
    });

    test('toMap excludes null values', () {
      const metadata = MediaMetadata(title: 'Video Title');

      final map = metadata.toMap();

      expect(map['title'], 'Video Title');
      expect(map.containsKey('artist'), isFalse);
      expect(map.containsKey('album'), isFalse);
      expect(map.containsKey('artworkUrl'), isFalse);
    });

    test('fromMap creates metadata from map', () {
      final map = {
        'title': 'Video Title',
        'artist': 'Artist Name',
        'album': 'Album Name',
        'artworkUrl': 'https://example.com/artwork.jpg',
      };

      final metadata = MediaMetadata.fromMap(map);

      expect(metadata.title, 'Video Title');
      expect(metadata.artist, 'Artist Name');
      expect(metadata.album, 'Album Name');
      expect(metadata.artworkUrl, 'https://example.com/artwork.jpg');
    });

    test('fromMap handles missing fields', () {
      final map = {'title': 'Video Title'};

      final metadata = MediaMetadata.fromMap(map);

      expect(metadata.title, 'Video Title');
      expect(metadata.artist, isNull);
      expect(metadata.album, isNull);
      expect(metadata.artworkUrl, isNull);
    });

    test('fromMap handles empty map', () {
      final metadata = MediaMetadata.fromMap({});

      expect(metadata.isEmpty, isTrue);
    });

    test('equality works correctly', () {
      const metadata1 = MediaMetadata(title: 'Title', artist: 'Artist');
      const metadata2 = MediaMetadata(title: 'Title', artist: 'Artist');
      const metadata3 = MediaMetadata(title: 'Different Title', artist: 'Artist');

      expect(metadata1, equals(metadata2));
      expect(metadata1, isNot(equals(metadata3)));
    });

    test('hashCode is consistent with equality', () {
      const metadata1 = MediaMetadata(title: 'Title', artist: 'Artist');
      const metadata2 = MediaMetadata(title: 'Title', artist: 'Artist');

      expect(metadata1.hashCode, equals(metadata2.hashCode));
    });

    test('toString returns readable representation', () {
      const metadata = MediaMetadata(title: 'Video Title', artist: 'Artist Name');

      final string = metadata.toString();

      expect(string, contains('MediaMetadata'));
      expect(string, contains('Video Title'));
      expect(string, contains('Artist Name'));
    });

    group('empty constant', () {
      test('empty is an empty metadata instance', () {
        expect(MediaMetadata.empty.isEmpty, isTrue);
        expect(MediaMetadata.empty.title, isNull);
        expect(MediaMetadata.empty.artist, isNull);
        expect(MediaMetadata.empty.album, isNull);
        expect(MediaMetadata.empty.artworkUrl, isNull);
      });

      test('empty is the same as default constructor', () {
        // Both should be equal and represent empty metadata
        expect(MediaMetadata.empty.isEmpty, isTrue);
      });
    });
  });
}
