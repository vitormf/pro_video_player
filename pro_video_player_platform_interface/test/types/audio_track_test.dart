import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('AudioTrack', () {
    test('creates with required parameters', () {
      const track = AudioTrack(id: 'en-1', label: 'English');

      expect(track.id, equals('en-1'));
      expect(track.label, equals('English'));
      expect(track.language, isNull);
      expect(track.isDefault, isFalse);
    });

    test('creates with all parameters', () {
      const track = AudioTrack(id: 'en-1', label: 'English (Stereo)', language: 'en', isDefault: true);

      expect(track.id, equals('en-1'));
      expect(track.label, equals('English (Stereo)'));
      expect(track.language, equals('en'));
      expect(track.isDefault, isTrue);
    });

    group('equality', () {
      test('equal tracks are equal', () {
        const track1 = AudioTrack(id: 'en-1', label: 'English', language: 'en', isDefault: true);
        const track2 = AudioTrack(id: 'en-1', label: 'English', language: 'en', isDefault: true);

        expect(track1, equals(track2));
      });

      test('tracks with different id are not equal', () {
        const track1 = AudioTrack(id: 'en-1', label: 'English');
        const track2 = AudioTrack(id: 'en-2', label: 'English');

        expect(track1, isNot(equals(track2)));
      });

      test('tracks with different label are not equal', () {
        const track1 = AudioTrack(id: 'en-1', label: 'English');
        const track2 = AudioTrack(id: 'en-1', label: 'English (5.1)');

        expect(track1, isNot(equals(track2)));
      });

      test('tracks with different language are not equal', () {
        const track1 = AudioTrack(id: 'en-1', label: 'English', language: 'en');
        const track2 = AudioTrack(id: 'en-1', label: 'English', language: 'es');

        expect(track1, isNot(equals(track2)));
      });

      test('tracks with different isDefault are not equal', () {
        const track1 = AudioTrack(id: 'en-1', label: 'English', isDefault: true);
        const track2 = AudioTrack(id: 'en-1', label: 'English');

        expect(track1, isNot(equals(track2)));
      });
    });

    test('hashCode is consistent with equality', () {
      const track1 = AudioTrack(id: 'en-1', label: 'English', language: 'en');
      const track2 = AudioTrack(id: 'en-1', label: 'English', language: 'en');

      expect(track1.hashCode, equals(track2.hashCode));
    });

    test('toString returns readable representation', () {
      const track = AudioTrack(id: 'en-1', label: 'English', language: 'en', isDefault: true);

      final str = track.toString();
      expect(str, contains('AudioTrack'));
      expect(str, contains('en-1'));
      expect(str, contains('English'));
      expect(str, contains('en'));
      expect(str, contains('true'));
    });
  });
}
