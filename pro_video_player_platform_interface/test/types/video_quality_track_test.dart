import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoQualityTrack', () {
    test('creates with required parameters', () {
      const track = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);

      expect(track.id, '0:1');
      expect(track.bitrate, 5000000);
      expect(track.width, 1920);
      expect(track.height, 1080);
      expect(track.frameRate, isNull);
      expect(track.label, '');
      expect(track.isDefault, isFalse);
    });

    test('creates with all parameters', () {
      const track = VideoQualityTrack(
        id: '0:2',
        bitrate: 8000000,
        width: 3840,
        height: 2160,
        frameRate: 60,
        label: '4K 60fps',
        isDefault: true,
      );

      expect(track.id, '0:2');
      expect(track.bitrate, 8000000);
      expect(track.width, 3840);
      expect(track.height, 2160);
      expect(track.frameRate, 60.0);
      expect(track.label, '4K 60fps');
      expect(track.isDefault, isTrue);
    });

    group('displayLabel', () {
      test('uses custom label when provided', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 5000000, width: 1920, height: 1080, label: 'Custom Label');

        expect(track.displayLabel, 'Custom Label');
      });

      test('generates label from height and bitrate when no label', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 5000000, width: 1920, height: 1080);

        expect(track.displayLabel, '1080p (5.0 Mbps)');
      });

      test('generates label for 720p', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 2500000, width: 1280, height: 720);

        expect(track.displayLabel, '720p (2.5 Mbps)');
      });

      test('generates label for 4K', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 15000000, width: 3840, height: 2160);

        expect(track.displayLabel, '2160p (15.0 Mbps)');
      });

      test('generates label with frame rate when provided', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 5000000, width: 1920, height: 1080, frameRate: 60);

        expect(track.displayLabel, '1080p60 (5.0 Mbps)');
      });
    });

    group('bitrateInMbps', () {
      test('converts bitrate to Mbps', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 5000000, width: 1920, height: 1080);

        expect(track.bitrateInMbps, 5.0);
      });

      test('handles fractional Mbps', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 2500000, width: 1280, height: 720);

        expect(track.bitrateInMbps, 2.5);
      });
    });

    group('resolution', () {
      test('returns formatted resolution string', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 5000000, width: 1920, height: 1080);

        expect(track.resolution, '1920x1080');
      });
    });

    group('isHD', () {
      test('returns true for 720p and above', () {
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 1280, height: 720).isHD, isTrue);
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 1920, height: 1080).isHD, isTrue);
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 3840, height: 2160).isHD, isTrue);
      });

      test('returns false for below 720p', () {
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 854, height: 480).isHD, isFalse);
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 640, height: 360).isHD, isFalse);
      });
    });

    group('is4K', () {
      test('returns true for 2160p and above', () {
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 3840, height: 2160).is4K, isTrue);
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 4096, height: 2160).is4K, isTrue);
      });

      test('returns false for below 4K', () {
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 1920, height: 1080).is4K, isFalse);
        expect(const VideoQualityTrack(id: '0:0', bitrate: 1000000, width: 2560, height: 1440).is4K, isFalse);
      });
    });

    group('auto quality constant', () {
      test('auto represents automatic quality selection', () {
        expect(VideoQualityTrack.auto.id, 'auto');
        expect(VideoQualityTrack.auto.bitrate, 0);
        expect(VideoQualityTrack.auto.width, 0);
        expect(VideoQualityTrack.auto.height, 0);
        expect(VideoQualityTrack.auto.label, 'Auto');
        expect(VideoQualityTrack.auto.isAuto, isTrue);
      });

      test('regular track isAuto returns false', () {
        const track = VideoQualityTrack(id: '0:0', bitrate: 5000000, width: 1920, height: 1080);

        expect(track.isAuto, isFalse);
      });
    });

    group('equality', () {
      test('equal tracks are equal', () {
        const track1 = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);
        const track2 = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);

        expect(track1, equals(track2));
      });

      test('tracks with different id are not equal', () {
        const track1 = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);
        const track2 = VideoQualityTrack(id: '0:2', bitrate: 5000000, width: 1920, height: 1080);

        expect(track1, isNot(equals(track2)));
      });

      test('tracks with different bitrate are not equal', () {
        const track1 = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);
        const track2 = VideoQualityTrack(id: '0:1', bitrate: 8000000, width: 1920, height: 1080);

        expect(track1, isNot(equals(track2)));
      });

      test('hashCode is consistent with equality', () {
        const track1 = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);
        const track2 = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);

        expect(track1.hashCode, equals(track2.hashCode));
      });
    });

    group('fromMap', () {
      test('creates from map with all fields', () {
        final map = {
          'id': '0:1',
          'bitrate': 5000000,
          'width': 1920,
          'height': 1080,
          'frameRate': 30.0,
          'label': 'HD',
          'isDefault': true,
        };

        final track = VideoQualityTrack.fromMap(map);

        expect(track.id, '0:1');
        expect(track.bitrate, 5000000);
        expect(track.width, 1920);
        expect(track.height, 1080);
        expect(track.frameRate, 30.0);
        expect(track.label, 'HD');
        expect(track.isDefault, isTrue);
      });

      test('creates from map with required fields only', () {
        final map = {'id': '0:1', 'bitrate': 5000000, 'width': 1920, 'height': 1080};

        final track = VideoQualityTrack.fromMap(map);

        expect(track.id, '0:1');
        expect(track.bitrate, 5000000);
        expect(track.width, 1920);
        expect(track.height, 1080);
        expect(track.frameRate, isNull);
        expect(track.label, '');
        expect(track.isDefault, isFalse);
      });
    });

    group('toMap', () {
      test('converts to map with all fields', () {
        const track = VideoQualityTrack(
          id: '0:1',
          bitrate: 5000000,
          width: 1920,
          height: 1080,
          frameRate: 30,
          label: 'HD',
          isDefault: true,
        );

        final map = track.toMap();

        expect(map['id'], '0:1');
        expect(map['bitrate'], 5000000);
        expect(map['width'], 1920);
        expect(map['height'], 1080);
        expect(map['frameRate'], 30.0);
        expect(map['label'], 'HD');
        expect(map['isDefault'], true);
      });
    });

    test('toString returns readable representation', () {
      const track = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);

      final string = track.toString();

      expect(string, contains('VideoQualityTrack'));
      expect(string, contains('0:1'));
      expect(string, contains('1920'));
      expect(string, contains('1080'));
    });
  });
}
