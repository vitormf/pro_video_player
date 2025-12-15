import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('PlatformCapabilities', () {
    test('can be created with all required parameters', () {
      const capabilities = PlatformCapabilities(
        supportsPictureInPicture: true,
        supportsFullscreen: true,
        supportsBackgroundPlayback: true,
        supportsCasting: true,
        supportsAirPlay: true,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: true,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: true,
        supportsExternalSubtitles: true,
        supportsAudioTrackSelection: true,
        supportsChapters: true,
        supportsVideoMetadataExtraction: true,
        supportsNetworkMonitoring: true,
        supportsBandwidthEstimation: true,
        supportsAdaptiveBitrate: true,
        supportsHLS: true,
        supportsDASH: false,
        supportsDeviceVolumeControl: true,
        supportsScreenBrightnessControl: true,
        platformName: 'iOS',
        nativePlayerType: 'AVPlayer',
      );

      expect(capabilities.supportsPictureInPicture, isTrue);
      expect(capabilities.supportsFullscreen, isTrue);
      expect(capabilities.supportsBackgroundPlayback, isTrue);
      expect(capabilities.supportsCasting, isTrue);
      expect(capabilities.supportsAirPlay, isTrue);
      expect(capabilities.supportsChromecast, isFalse);
      expect(capabilities.supportsRemotePlayback, isFalse);
      expect(capabilities.supportsQualitySelection, isTrue);
      expect(capabilities.supportsPlaybackSpeedControl, isTrue);
      expect(capabilities.supportsSubtitles, isTrue);
      expect(capabilities.supportsExternalSubtitles, isTrue);
      expect(capabilities.supportsAudioTrackSelection, isTrue);
      expect(capabilities.supportsChapters, isTrue);
      expect(capabilities.supportsVideoMetadataExtraction, isTrue);
      expect(capabilities.supportsNetworkMonitoring, isTrue);
      expect(capabilities.supportsBandwidthEstimation, isTrue);
      expect(capabilities.supportsAdaptiveBitrate, isTrue);
      expect(capabilities.supportsHLS, isTrue);
      expect(capabilities.supportsDASH, isFalse);
      expect(capabilities.supportsDeviceVolumeControl, isTrue);
      expect(capabilities.supportsScreenBrightnessControl, isTrue);
      expect(capabilities.platformName, equals('iOS'));
      expect(capabilities.nativePlayerType, equals('AVPlayer'));
    });

    test('can be created with optional additionalInfo', () {
      const capabilities = PlatformCapabilities(
        supportsPictureInPicture: true,
        supportsFullscreen: true,
        supportsBackgroundPlayback: false,
        supportsCasting: false,
        supportsAirPlay: false,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: false,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: false,
        supportsExternalSubtitles: false,
        supportsAudioTrackSelection: false,
        supportsChapters: false,
        supportsVideoMetadataExtraction: false,
        supportsNetworkMonitoring: false,
        supportsBandwidthEstimation: false,
        supportsAdaptiveBitrate: false,
        supportsHLS: false,
        supportsDASH: false,
        supportsDeviceVolumeControl: false,
        supportsScreenBrightnessControl: false,
        platformName: 'Web',
        nativePlayerType: 'HTML5',
        additionalInfo: {'browser': 'Chrome', 'version': '120'},
      );

      expect(capabilities.additionalInfo, isNotNull);
      expect(capabilities.additionalInfo!['browser'], equals('Chrome'));
      expect(capabilities.additionalInfo!['version'], equals('120'));
    });

    test('toMap converts capabilities to map', () {
      const capabilities = PlatformCapabilities(
        supportsPictureInPicture: true,
        supportsFullscreen: false,
        supportsBackgroundPlayback: true,
        supportsCasting: true,
        supportsAirPlay: true,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: true,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: true,
        supportsExternalSubtitles: true,
        supportsAudioTrackSelection: true,
        supportsChapters: true,
        supportsVideoMetadataExtraction: true,
        supportsNetworkMonitoring: true,
        supportsBandwidthEstimation: true,
        supportsAdaptiveBitrate: true,
        supportsHLS: true,
        supportsDASH: false,
        supportsDeviceVolumeControl: true,
        supportsScreenBrightnessControl: true,
        platformName: 'iOS',
        nativePlayerType: 'AVPlayer',
      );

      final map = capabilities.toMap();

      expect(map['supportsPictureInPicture'], isTrue);
      expect(map['supportsFullscreen'], isFalse);
      expect(map['supportsBackgroundPlayback'], isTrue);
      expect(map['supportsCasting'], isTrue);
      expect(map['supportsAirPlay'], isTrue);
      expect(map['supportsChromecast'], isFalse);
      expect(map['platformName'], equals('iOS'));
      expect(map['nativePlayerType'], equals('AVPlayer'));
    });

    test('fromMap creates capabilities from map', () {
      final map = {
        'supportsPictureInPicture': true,
        'supportsFullscreen': true,
        'supportsBackgroundPlayback': false,
        'supportsCasting': true,
        'supportsAirPlay': false,
        'supportsChromecast': true,
        'supportsRemotePlayback': false,
        'supportsQualitySelection': true,
        'supportsPlaybackSpeedControl': true,
        'supportsSubtitles': true,
        'supportsExternalSubtitles': true,
        'supportsAudioTrackSelection': true,
        'supportsChapters': true,
        'supportsVideoMetadataExtraction': true,
        'supportsNetworkMonitoring': true,
        'supportsBandwidthEstimation': true,
        'supportsAdaptiveBitrate': true,
        'supportsHLS': true,
        'supportsDASH': true,
        'supportsDeviceVolumeControl': true,
        'supportsScreenBrightnessControl': false,
        'platformName': 'Android',
        'nativePlayerType': 'ExoPlayer',
        'additionalInfo': {'sdkVersion': 30},
      };

      final capabilities = PlatformCapabilities.fromMap(map);

      expect(capabilities.supportsPictureInPicture, isTrue);
      expect(capabilities.supportsFullscreen, isTrue);
      expect(capabilities.supportsBackgroundPlayback, isFalse);
      expect(capabilities.supportsCasting, isTrue);
      expect(capabilities.supportsAirPlay, isFalse);
      expect(capabilities.supportsChromecast, isTrue);
      expect(capabilities.supportsRemotePlayback, isFalse);
      expect(capabilities.supportsQualitySelection, isTrue);
      expect(capabilities.supportsPlaybackSpeedControl, isTrue);
      expect(capabilities.supportsSubtitles, isTrue);
      expect(capabilities.supportsExternalSubtitles, isTrue);
      expect(capabilities.supportsAudioTrackSelection, isTrue);
      expect(capabilities.supportsChapters, isTrue);
      expect(capabilities.supportsVideoMetadataExtraction, isTrue);
      expect(capabilities.supportsNetworkMonitoring, isTrue);
      expect(capabilities.supportsBandwidthEstimation, isTrue);
      expect(capabilities.supportsAdaptiveBitrate, isTrue);
      expect(capabilities.supportsHLS, isTrue);
      expect(capabilities.supportsDASH, isTrue);
      expect(capabilities.supportsDeviceVolumeControl, isTrue);
      expect(capabilities.supportsScreenBrightnessControl, isFalse);
      expect(capabilities.platformName, equals('Android'));
      expect(capabilities.nativePlayerType, equals('ExoPlayer'));
      expect(capabilities.additionalInfo, isNotNull);
    });

    test('fromMap defaults to false for missing boolean fields', () {
      final map = {'platformName': 'Unknown'};

      final capabilities = PlatformCapabilities.fromMap(map);

      expect(capabilities.supportsPictureInPicture, isFalse);
      expect(capabilities.supportsFullscreen, isFalse);
      expect(capabilities.supportsBackgroundPlayback, isFalse);
      expect(capabilities.supportsCasting, isFalse);
      expect(capabilities.platformName, equals('Unknown'));
    });

    test('copyWith creates new instance with updated fields', () {
      const capabilities = PlatformCapabilities(
        supportsPictureInPicture: true,
        supportsFullscreen: true,
        supportsBackgroundPlayback: true,
        supportsCasting: true,
        supportsAirPlay: true,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: true,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: true,
        supportsExternalSubtitles: true,
        supportsAudioTrackSelection: true,
        supportsChapters: true,
        supportsVideoMetadataExtraction: true,
        supportsNetworkMonitoring: true,
        supportsBandwidthEstimation: true,
        supportsAdaptiveBitrate: true,
        supportsHLS: true,
        supportsDASH: false,
        supportsDeviceVolumeControl: true,
        supportsScreenBrightnessControl: true,
        platformName: 'iOS',
        nativePlayerType: 'AVPlayer',
      );

      final updated = capabilities.copyWith(supportsPictureInPicture: false, platformName: 'macOS');

      expect(updated.supportsPictureInPicture, isFalse);
      expect(updated.platformName, equals('macOS'));
      expect(updated.supportsFullscreen, isTrue); // Unchanged
      expect(updated.nativePlayerType, equals('AVPlayer')); // Unchanged
    });

    test('equality works correctly', () {
      const capabilities1 = PlatformCapabilities(
        supportsPictureInPicture: true,
        supportsFullscreen: true,
        supportsBackgroundPlayback: true,
        supportsCasting: true,
        supportsAirPlay: true,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: true,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: true,
        supportsExternalSubtitles: true,
        supportsAudioTrackSelection: true,
        supportsChapters: true,
        supportsVideoMetadataExtraction: true,
        supportsNetworkMonitoring: true,
        supportsBandwidthEstimation: true,
        supportsAdaptiveBitrate: true,
        supportsHLS: true,
        supportsDASH: false,
        supportsDeviceVolumeControl: true,
        supportsScreenBrightnessControl: true,
        platformName: 'iOS',
        nativePlayerType: 'AVPlayer',
      );

      const capabilities2 = PlatformCapabilities(
        supportsPictureInPicture: true,
        supportsFullscreen: true,
        supportsBackgroundPlayback: true,
        supportsCasting: true,
        supportsAirPlay: true,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: true,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: true,
        supportsExternalSubtitles: true,
        supportsAudioTrackSelection: true,
        supportsChapters: true,
        supportsVideoMetadataExtraction: true,
        supportsNetworkMonitoring: true,
        supportsBandwidthEstimation: true,
        supportsAdaptiveBitrate: true,
        supportsHLS: true,
        supportsDASH: false,
        supportsDeviceVolumeControl: true,
        supportsScreenBrightnessControl: true,
        platformName: 'iOS',
        nativePlayerType: 'AVPlayer',
      );

      const capabilities3 = PlatformCapabilities(
        supportsPictureInPicture: false,
        supportsFullscreen: true,
        supportsBackgroundPlayback: true,
        supportsCasting: true,
        supportsAirPlay: true,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: true,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: true,
        supportsExternalSubtitles: true,
        supportsAudioTrackSelection: true,
        supportsChapters: true,
        supportsVideoMetadataExtraction: true,
        supportsNetworkMonitoring: true,
        supportsBandwidthEstimation: true,
        supportsAdaptiveBitrate: true,
        supportsHLS: true,
        supportsDASH: false,
        supportsDeviceVolumeControl: true,
        supportsScreenBrightnessControl: true,
        platformName: 'iOS',
        nativePlayerType: 'AVPlayer',
      );

      expect(capabilities1, equals(capabilities2));
      expect(capabilities1, isNot(equals(capabilities3)));
    });

    test('toString returns meaningful string representation', () {
      const capabilities = PlatformCapabilities(
        supportsPictureInPicture: true,
        supportsFullscreen: true,
        supportsBackgroundPlayback: false,
        supportsCasting: true,
        supportsAirPlay: true,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: true,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: true,
        supportsExternalSubtitles: true,
        supportsAudioTrackSelection: true,
        supportsChapters: true,
        supportsVideoMetadataExtraction: true,
        supportsNetworkMonitoring: true,
        supportsBandwidthEstimation: true,
        supportsAdaptiveBitrate: true,
        supportsHLS: true,
        supportsDASH: false,
        supportsDeviceVolumeControl: true,
        supportsScreenBrightnessControl: true,
        platformName: 'iOS',
        nativePlayerType: 'AVPlayer',
      );

      final string = capabilities.toString();

      expect(string, contains('iOS'));
      expect(string, contains('AVPlayer'));
      expect(string, contains('pip: true'));
      expect(string, contains('fullscreen: true'));
      expect(string, contains('background: false'));
      expect(string, contains('casting: true'));
      expect(string, contains('airplay: true'));
      expect(string, contains('chromecast: false'));
      expect(string, contains('HLS: true'));
      expect(string, contains('DASH: false'));
    });
  });
}
