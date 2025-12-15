import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoMetadata', () {
    test('creates with all fields', () {
      const metadata = VideoMetadata(
        videoCodec: 'h264',
        audioCodec: 'aac',
        width: 1920,
        height: 1080,
        videoBitrate: 5000000,
        audioBitrate: 128000,
        frameRate: 29.97,
        duration: Duration(minutes: 5, seconds: 30),
        containerFormat: 'mp4',
      );

      expect(metadata.videoCodec, 'h264');
      expect(metadata.audioCodec, 'aac');
      expect(metadata.width, 1920);
      expect(metadata.height, 1080);
      expect(metadata.videoBitrate, 5000000);
      expect(metadata.audioBitrate, 128000);
      expect(metadata.frameRate, 29.97);
      expect(metadata.duration, const Duration(minutes: 5, seconds: 30));
      expect(metadata.containerFormat, 'mp4');
    });

    test('creates with partial fields', () {
      const metadata = VideoMetadata(width: 1280, height: 720);

      expect(metadata.width, 1280);
      expect(metadata.height, 720);
      expect(metadata.videoCodec, isNull);
      expect(metadata.audioCodec, isNull);
      expect(metadata.videoBitrate, isNull);
      expect(metadata.audioBitrate, isNull);
      expect(metadata.frameRate, isNull);
      expect(metadata.duration, isNull);
      expect(metadata.containerFormat, isNull);
    });

    test('creates empty metadata', () {
      const metadata = VideoMetadata.empty;

      expect(metadata.videoCodec, isNull);
      expect(metadata.audioCodec, isNull);
      expect(metadata.width, isNull);
      expect(metadata.height, isNull);
      expect(metadata.videoBitrate, isNull);
      expect(metadata.audioBitrate, isNull);
      expect(metadata.frameRate, isNull);
      expect(metadata.duration, isNull);
      expect(metadata.containerFormat, isNull);
      expect(metadata.isEmpty, isTrue);
      expect(metadata.isNotEmpty, isFalse);
    });

    test('isEmpty returns false when any field is set', () {
      expect(const VideoMetadata(videoCodec: 'h264').isEmpty, isFalse);
      expect(const VideoMetadata(audioCodec: 'aac').isEmpty, isFalse);
      expect(const VideoMetadata(width: 1920).isEmpty, isFalse);
      expect(const VideoMetadata(height: 1080).isEmpty, isFalse);
      expect(const VideoMetadata(videoBitrate: 5000000).isEmpty, isFalse);
      expect(const VideoMetadata(audioBitrate: 128000).isEmpty, isFalse);
      expect(const VideoMetadata(frameRate: 30).isEmpty, isFalse);
      expect(const VideoMetadata(duration: Duration(seconds: 1)).isEmpty, isFalse);
      expect(const VideoMetadata(containerFormat: 'mp4').isEmpty, isFalse);
    });

    test('isNotEmpty returns true when any field is set', () {
      expect(const VideoMetadata(videoCodec: 'h264').isNotEmpty, isTrue);
      expect(const VideoMetadata(width: 1920, height: 1080).isNotEmpty, isTrue);
    });

    group('computed properties', () {
      test('totalBitrate returns sum of video and audio bitrate', () {
        const metadata = VideoMetadata(videoBitrate: 5000000, audioBitrate: 128000);

        expect(metadata.totalBitrate, 5128000);
      });

      test('totalBitrate returns null when bitrates are missing', () {
        expect(VideoMetadata.empty.totalBitrate, isNull);
        expect(const VideoMetadata(videoBitrate: 5000000).totalBitrate, isNull);
        expect(const VideoMetadata(audioBitrate: 128000).totalBitrate, isNull);
      });

      test('aspectRatio calculates correctly', () {
        const metadata = VideoMetadata(width: 1920, height: 1080);

        expect(metadata.aspectRatio, closeTo(1.778, 0.001)); // 16:9
      });

      test('aspectRatio returns null when dimensions are missing', () {
        expect(VideoMetadata.empty.aspectRatio, isNull);
        expect(const VideoMetadata(width: 1920).aspectRatio, isNull);
        expect(const VideoMetadata(height: 1080).aspectRatio, isNull);
      });

      test('aspectRatio returns null when height is zero', () {
        const metadata = VideoMetadata(width: 1920, height: 0);

        expect(metadata.aspectRatio, isNull);
      });

      test('resolution returns formatted string', () {
        const metadata = VideoMetadata(width: 1920, height: 1080);

        expect(metadata.resolution, '1920x1080');
      });

      test('resolution returns null when dimensions are missing', () {
        expect(VideoMetadata.empty.resolution, isNull);
        expect(const VideoMetadata(width: 1920).resolution, isNull);
        expect(const VideoMetadata(height: 1080).resolution, isNull);
      });

      test('isHD returns true for 720p or higher', () {
        expect(const VideoMetadata(height: 720).isHD, isTrue);
        expect(const VideoMetadata(height: 1080).isHD, isTrue);
        expect(const VideoMetadata(height: 2160).isHD, isTrue);
      });

      test('isHD returns false for less than 720p', () {
        expect(const VideoMetadata(height: 480).isHD, isFalse);
        expect(const VideoMetadata(height: 360).isHD, isFalse);
      });

      test('isHD returns false when height is null', () {
        expect(VideoMetadata.empty.isHD, isFalse);
      });

      test('is4K returns true for 2160p or higher', () {
        expect(const VideoMetadata(height: 2160).is4K, isTrue);
        expect(const VideoMetadata(height: 4320).is4K, isTrue);
      });

      test('is4K returns false for less than 2160p', () {
        expect(const VideoMetadata(height: 1080).is4K, isFalse);
        expect(const VideoMetadata(height: 1440).is4K, isFalse);
      });

      test('is4K returns false when height is null', () {
        expect(VideoMetadata.empty.is4K, isFalse);
      });

      test('videoBitrateInMbps converts correctly', () {
        const metadata = VideoMetadata(videoBitrate: 5000000);

        expect(metadata.videoBitrateInMbps, 5.0);
      });

      test('videoBitrateInMbps returns null when bitrate is null', () {
        expect(VideoMetadata.empty.videoBitrateInMbps, isNull);
      });

      test('audioBitrateInKbps converts correctly', () {
        const metadata = VideoMetadata(audioBitrate: 128000);

        expect(metadata.audioBitrateInKbps, 128.0);
      });

      test('audioBitrateInKbps returns null when bitrate is null', () {
        expect(VideoMetadata.empty.audioBitrateInKbps, isNull);
      });
    });

    test('copyWith creates a new instance with updated fields', () {
      const original = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080);

      final updated = original.copyWith(videoCodec: 'hevc', frameRate: 60);

      expect(updated.videoCodec, 'hevc');
      expect(updated.width, 1920);
      expect(updated.height, 1080);
      expect(updated.frameRate, 60.0);

      // Original should be unchanged
      expect(original.videoCodec, 'h264');
      expect(original.frameRate, isNull);
    });

    test('copyWith with no arguments preserves existing values', () {
      const original = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080);

      final updated = original.copyWith();

      expect(updated.videoCodec, 'h264');
      expect(updated.width, 1920);
      expect(updated.height, 1080);
    });

    test('toMap returns correct map representation', () {
      const metadata = VideoMetadata(
        videoCodec: 'h264',
        audioCodec: 'aac',
        width: 1920,
        height: 1080,
        videoBitrate: 5000000,
        audioBitrate: 128000,
        frameRate: 29.97,
        duration: Duration(minutes: 5, seconds: 30),
        containerFormat: 'mp4',
      );

      final map = metadata.toMap();

      expect(map['videoCodec'], 'h264');
      expect(map['audioCodec'], 'aac');
      expect(map['width'], 1920);
      expect(map['height'], 1080);
      expect(map['videoBitrate'], 5000000);
      expect(map['audioBitrate'], 128000);
      expect(map['frameRate'], 29.97);
      expect(map['durationMs'], 330000); // 5:30 in milliseconds
      expect(map['containerFormat'], 'mp4');
    });

    test('toMap excludes null values', () {
      const metadata = VideoMetadata(width: 1920, height: 1080);

      final map = metadata.toMap();

      expect(map['width'], 1920);
      expect(map['height'], 1080);
      expect(map.containsKey('videoCodec'), isFalse);
      expect(map.containsKey('audioCodec'), isFalse);
      expect(map.containsKey('videoBitrate'), isFalse);
      expect(map.containsKey('audioBitrate'), isFalse);
      expect(map.containsKey('frameRate'), isFalse);
      expect(map.containsKey('durationMs'), isFalse);
      expect(map.containsKey('containerFormat'), isFalse);
    });

    test('fromMap creates metadata from map', () {
      final map = {
        'videoCodec': 'h264',
        'audioCodec': 'aac',
        'width': 1920,
        'height': 1080,
        'videoBitrate': 5000000,
        'audioBitrate': 128000,
        'frameRate': 29.97,
        'durationMs': 330000,
        'containerFormat': 'mp4',
      };

      final metadata = VideoMetadata.fromMap(map);

      expect(metadata.videoCodec, 'h264');
      expect(metadata.audioCodec, 'aac');
      expect(metadata.width, 1920);
      expect(metadata.height, 1080);
      expect(metadata.videoBitrate, 5000000);
      expect(metadata.audioBitrate, 128000);
      expect(metadata.frameRate, 29.97);
      expect(metadata.duration, const Duration(minutes: 5, seconds: 30));
      expect(metadata.containerFormat, 'mp4');
    });

    test('fromMap handles missing fields', () {
      final map = {'width': 1920, 'height': 1080};

      final metadata = VideoMetadata.fromMap(map);

      expect(metadata.width, 1920);
      expect(metadata.height, 1080);
      expect(metadata.videoCodec, isNull);
      expect(metadata.audioCodec, isNull);
      expect(metadata.videoBitrate, isNull);
      expect(metadata.audioBitrate, isNull);
      expect(metadata.frameRate, isNull);
      expect(metadata.duration, isNull);
      expect(metadata.containerFormat, isNull);
    });

    test('fromMap handles empty map', () {
      final metadata = VideoMetadata.fromMap({});

      expect(metadata.isEmpty, isTrue);
    });

    test('fromMap handles integer frameRate', () {
      final map = {'frameRate': 30};

      final metadata = VideoMetadata.fromMap(map);

      expect(metadata.frameRate, 30.0);
    });

    test('equality works correctly', () {
      const metadata1 = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080);
      const metadata2 = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080);
      const metadata3 = VideoMetadata(videoCodec: 'hevc', width: 1920, height: 1080);

      expect(metadata1, equals(metadata2));
      expect(metadata1, isNot(equals(metadata3)));
    });

    test('hashCode is consistent with equality', () {
      const metadata1 = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080);
      const metadata2 = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080);

      expect(metadata1.hashCode, equals(metadata2.hashCode));
    });

    test('toString returns readable representation', () {
      const metadata = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080);

      final string = metadata.toString();

      expect(string, contains('VideoMetadata'));
      expect(string, contains('h264'));
      expect(string, contains('1920'));
      expect(string, contains('1080'));
    });

    group('empty constant', () {
      test('empty is an empty metadata instance', () {
        expect(VideoMetadata.empty.isEmpty, isTrue);
        expect(VideoMetadata.empty.videoCodec, isNull);
        expect(VideoMetadata.empty.audioCodec, isNull);
        expect(VideoMetadata.empty.width, isNull);
        expect(VideoMetadata.empty.height, isNull);
      });

      test('empty equals default constructor', () {
        expect(VideoMetadata.empty, equals(VideoMetadata.empty));
      });
    });
  });
}
