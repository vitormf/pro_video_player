import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

void main() {
  group('VideoControlsUtils', () {
    group('getRepeatModeLabel', () {
      test('returns empty string for none', () {
        expect(VideoControlsUtils.getRepeatModeLabel(PlaylistRepeatMode.none), '');
      });

      test('returns " (All)" for all', () {
        expect(VideoControlsUtils.getRepeatModeLabel(PlaylistRepeatMode.all), ' (All)');
      });

      test('returns " (One)" for one', () {
        expect(VideoControlsUtils.getRepeatModeLabel(PlaylistRepeatMode.one), ' (One)');
      });
    });

    group('getNextRepeatMode', () {
      test('cycles from none to all', () {
        expect(VideoControlsUtils.getNextRepeatMode(PlaylistRepeatMode.none), PlaylistRepeatMode.all);
      });

      test('cycles from all to one', () {
        expect(VideoControlsUtils.getNextRepeatMode(PlaylistRepeatMode.all), PlaylistRepeatMode.one);
      });

      test('cycles from one back to none', () {
        expect(VideoControlsUtils.getNextRepeatMode(PlaylistRepeatMode.one), PlaylistRepeatMode.none);
      });
    });

    group('getSkipBackwardIcon', () {
      test('returns replay_5 for 5 seconds or less', () {
        expect(VideoControlsUtils.getSkipBackwardIcon(const Duration(seconds: 3)), Icons.replay_5);
        expect(VideoControlsUtils.getSkipBackwardIcon(const Duration(seconds: 5)), Icons.replay_5);
      });

      test('returns replay_10 for 6-10 seconds', () {
        expect(VideoControlsUtils.getSkipBackwardIcon(const Duration(seconds: 6)), Icons.replay_10);
        expect(VideoControlsUtils.getSkipBackwardIcon(const Duration(seconds: 10)), Icons.replay_10);
      });

      test('returns replay_30 for more than 10 seconds', () {
        expect(VideoControlsUtils.getSkipBackwardIcon(const Duration(seconds: 11)), Icons.replay_30);
        expect(VideoControlsUtils.getSkipBackwardIcon(const Duration(seconds: 30)), Icons.replay_30);
        expect(VideoControlsUtils.getSkipBackwardIcon(const Duration(seconds: 60)), Icons.replay_30);
      });
    });

    group('getSkipForwardIcon', () {
      test('returns forward_5 for 5 seconds or less', () {
        expect(VideoControlsUtils.getSkipForwardIcon(const Duration(seconds: 3)), Icons.forward_5);
        expect(VideoControlsUtils.getSkipForwardIcon(const Duration(seconds: 5)), Icons.forward_5);
      });

      test('returns forward_10 for 6-10 seconds', () {
        expect(VideoControlsUtils.getSkipForwardIcon(const Duration(seconds: 6)), Icons.forward_10);
        expect(VideoControlsUtils.getSkipForwardIcon(const Duration(seconds: 10)), Icons.forward_10);
      });

      test('returns forward_30 for more than 10 seconds', () {
        expect(VideoControlsUtils.getSkipForwardIcon(const Duration(seconds: 11)), Icons.forward_30);
        expect(VideoControlsUtils.getSkipForwardIcon(const Duration(seconds: 30)), Icons.forward_30);
        expect(VideoControlsUtils.getSkipForwardIcon(const Duration(seconds: 60)), Icons.forward_30);
      });
    });

    group('sortedQualityTracks', () {
      test('returns empty list for empty input', () {
        expect(VideoControlsUtils.sortedQualityTracks([]), isEmpty);
      });

      test('filters out auto tracks', () {
        final tracks = [
          VideoQualityTrack.auto,
          const VideoQualityTrack(id: '720p', label: '720p', height: 720, width: 1280, bitrate: 2500000),
        ];

        final result = VideoControlsUtils.sortedQualityTracks(tracks);
        expect(result.length, 1);
        expect(result[0].id, '720p');
      });

      test('sorts by height descending', () {
        final tracks = [
          const VideoQualityTrack(id: '480p', label: '480p', height: 480, width: 640, bitrate: 1000000),
          const VideoQualityTrack(id: '1080p', label: '1080p', height: 1080, width: 1920, bitrate: 5000000),
          const VideoQualityTrack(id: '720p', label: '720p', height: 720, width: 1280, bitrate: 2500000),
        ];

        final result = VideoControlsUtils.sortedQualityTracks(tracks);
        expect(result.length, 3);
        expect(result[0].id, '1080p'); // Highest first
        expect(result[1].id, '720p');
        expect(result[2].id, '480p'); // Lowest last
      });

      test('handles mix of auto and non-auto tracks', () {
        final tracks = [
          VideoQualityTrack.auto,
          const VideoQualityTrack(id: '480p', label: '480p', height: 480, width: 640, bitrate: 1000000),
          const VideoQualityTrack(id: '720p', label: '720p', height: 720, width: 1280, bitrate: 2500000),
        ];

        final result = VideoControlsUtils.sortedQualityTracks(tracks);
        expect(result.length, 2);
        expect(result[0].id, '720p');
        expect(result[1].id, '480p');
      });
    });

    group('getScalingModeLabel', () {
      test('returns correct label for fit', () {
        expect(VideoControlsUtils.getScalingModeLabel(VideoScalingMode.fit), 'Fit (Letterbox)');
      });

      test('returns correct label for fill', () {
        expect(VideoControlsUtils.getScalingModeLabel(VideoScalingMode.fill), 'Fill (Crop)');
      });

      test('returns correct label for stretch', () {
        expect(VideoControlsUtils.getScalingModeLabel(VideoScalingMode.stretch), 'Stretch');
      });
    });

    group('getScalingModeDescription', () {
      test('returns correct description for fit', () {
        expect(VideoControlsUtils.getScalingModeDescription(VideoScalingMode.fit), 'Show entire video with black bars');
      });

      test('returns correct description for fill', () {
        expect(VideoControlsUtils.getScalingModeDescription(VideoScalingMode.fill), 'Fill screen, may crop edges');
      });

      test('returns correct description for stretch', () {
        expect(VideoControlsUtils.getScalingModeDescription(VideoScalingMode.stretch), 'Stretch to fill screen');
      });
    });
  });
}
