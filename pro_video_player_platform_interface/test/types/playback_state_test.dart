import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('PlaybackState', () {
    test('has all expected values', () {
      expect(PlaybackState.values, hasLength(9));
      expect(PlaybackState.values, contains(PlaybackState.uninitialized));
      expect(PlaybackState.values, contains(PlaybackState.initializing));
      expect(PlaybackState.values, contains(PlaybackState.ready));
      expect(PlaybackState.values, contains(PlaybackState.playing));
      expect(PlaybackState.values, contains(PlaybackState.paused));
      expect(PlaybackState.values, contains(PlaybackState.completed));
      expect(PlaybackState.values, contains(PlaybackState.buffering));
      expect(PlaybackState.values, contains(PlaybackState.error));
      expect(PlaybackState.values, contains(PlaybackState.disposed));
    });

    test('uninitialized is the first state', () {
      expect(PlaybackState.values.first, equals(PlaybackState.uninitialized));
    });

    test('each state has a unique index', () {
      final indices = PlaybackState.values.map((s) => s.index).toSet();
      expect(indices.length, equals(PlaybackState.values.length));
    });

    test('name property returns readable string', () {
      expect(PlaybackState.playing.name, equals('playing'));
      expect(PlaybackState.paused.name, equals('paused'));
      expect(PlaybackState.buffering.name, equals('buffering'));
    });
  });
}
