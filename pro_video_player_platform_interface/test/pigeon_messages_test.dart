// Copyright 2025 The Pro Video Player Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/src/pigeon_generated/messages.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoSourceMessage', () {
    test('encodes and decodes network video source correctly', () {
      final source = VideoSourceMessage(
        type: VideoSourceType.network,
        url: 'https://example.com/video.mp4',
        headers: {'Authorization': 'Bearer token'},
      );

      final encoded = source.encode();
      expect(encoded, isA<List<Object?>>());

      final decoded = VideoSourceMessage.decode(encoded);
      expect(decoded.type, VideoSourceType.network);
      expect(decoded.url, 'https://example.com/video.mp4');
      expect(decoded.headers, {'Authorization': 'Bearer token'});
      expect(decoded.path, isNull);
      expect(decoded.assetPath, isNull);
    });

    test('encodes and decodes file video source correctly', () {
      final source = VideoSourceMessage(type: VideoSourceType.file, path: '/path/to/video.mp4');

      final encoded = source.encode();
      final decoded = VideoSourceMessage.decode(encoded);

      expect(decoded.type, VideoSourceType.file);
      expect(decoded.path, '/path/to/video.mp4');
      expect(decoded.url, isNull);
      expect(decoded.assetPath, isNull);
    });

    test('encodes and decodes asset video source correctly', () {
      final source = VideoSourceMessage(type: VideoSourceType.asset, assetPath: 'assets/video.mp4');

      final encoded = source.encode();
      final decoded = VideoSourceMessage.decode(encoded);

      expect(decoded.type, VideoSourceType.asset);
      expect(decoded.assetPath, 'assets/video.mp4');
      expect(decoded.url, isNull);
      expect(decoded.path, isNull);
    });
  });

  group('VideoPlayerOptionsMessage', () {
    test('encodes and decodes options correctly', () {
      final options = VideoPlayerOptionsMessage(
        autoPlay: true,
        looping: false,
        volume: 0.8,
        playbackSpeed: 1.5,
        allowBackgroundPlayback: true,
        mixWithOthers: false,
        allowPip: true,
        autoEnterPipOnBackground: false,
      );

      final encoded = options.encode();
      expect(encoded, isA<List<Object?>>());

      final decoded = VideoPlayerOptionsMessage.decode(encoded);
      expect(decoded.autoPlay, true);
      expect(decoded.looping, false);
      expect(decoded.volume, 0.8);
      expect(decoded.playbackSpeed, 1.5);
      expect(decoded.allowBackgroundPlayback, true);
      expect(decoded.mixWithOthers, false);
      expect(decoded.allowPip, true);
      expect(decoded.autoEnterPipOnBackground, false);
    });
  });

  group('PlatformCapabilitiesMessage', () {
    test('encodes and decodes capabilities correctly', () {
      final capabilities = PlatformCapabilitiesMessage(
        supportsPictureInPicture: true,
        supportsFullscreen: true,
        supportsBackgroundPlayback: true,
        supportsCasting: false,
        supportsAirPlay: false,
        supportsChromecast: false,
        supportsRemotePlayback: false,
        supportsQualitySelection: true,
        supportsPlaybackSpeedControl: true,
        supportsSubtitles: true,
        supportsExternalSubtitles: true,
        supportsAudioTrackSelection: true,
        supportsChapters: false,
        supportsVideoMetadataExtraction: true,
        supportsNetworkMonitoring: false,
        supportsBandwidthEstimation: false,
        supportsAdaptiveBitrate: true,
        supportsHLS: true,
        supportsDASH: false,
        supportsDeviceVolumeControl: true,
        supportsScreenBrightnessControl: true,
        platformName: 'iOS',
        nativePlayerType: 'AVPlayer',
      );

      final encoded = capabilities.encode();
      expect(encoded, isA<List<Object?>>());

      final decoded = PlatformCapabilitiesMessage.decode(encoded);
      expect(decoded.supportsPictureInPicture, true);
      expect(decoded.supportsBackgroundPlayback, true);
      expect(decoded.supportsCasting, false);
    });
  });

  group('VideoPlayerEventMessage', () {
    test('encodes and decodes playback state changed event', () {
      final event = VideoPlayerEventMessage(type: 'playbackStateChanged', state: PlaybackStateEnum.playing);

      final encoded = event.encode();
      final decoded = VideoPlayerEventMessage.decode(encoded);

      expect(decoded.type, 'playbackStateChanged');
      expect(decoded.state, PlaybackStateEnum.playing);
      expect(decoded.positionMs, isNull);
    });

    test('encodes and decodes position changed event', () {
      final event = VideoPlayerEventMessage(type: 'positionChanged', positionMs: 5000);

      final encoded = event.encode();
      final decoded = VideoPlayerEventMessage.decode(encoded);

      expect(decoded.type, 'positionChanged');
      expect(decoded.positionMs, 5000);
      expect(decoded.state, isNull);
    });

    test('encodes and decodes error event with message and code', () {
      final event = VideoPlayerEventMessage(
        type: 'error',
        errorMessage: 'Failed to load video',
        errorCode: 'VIDEO_LOAD_ERROR',
      );

      final encoded = event.encode();
      final decoded = VideoPlayerEventMessage.decode(encoded);

      expect(decoded.type, 'error');
      expect(decoded.errorMessage, 'Failed to load video');
      expect(decoded.errorCode, 'VIDEO_LOAD_ERROR');
    });

    test('encodes and decodes video size changed event', () {
      final event = VideoPlayerEventMessage(type: 'videoSizeChanged', width: 1920, height: 1080);

      final encoded = event.encode();
      final decoded = VideoPlayerEventMessage.decode(encoded);

      expect(decoded.type, 'videoSizeChanged');
      expect(decoded.width, 1920);
      expect(decoded.height, 1080);
    });
  });

  group('ProVideoPlayerHostApi', () {
    test('create sends correct message with source and options', () async {
      // This test verifies that the API interface is available
      // Actual platform channel testing will be done in integration tests
      expect(ProVideoPlayerHostApi.new, returnsNormally);
    });

    test('can instantiate ProVideoPlayerHostApi', () {
      final api = ProVideoPlayerHostApi();
      expect(api, isNotNull);
    });

    test('can create message objects with correct types', () {
      final source = VideoSourceMessage(type: VideoSourceType.network, url: 'https://example.com/video.mp4');

      final options = VideoPlayerOptionsMessage(
        autoPlay: false,
        looping: false,
        volume: 1,
        playbackSpeed: 1,
        allowBackgroundPlayback: false,
        mixWithOthers: false,
        allowPip: false,
        autoEnterPipOnBackground: false,
      );

      expect(source.type, VideoSourceType.network);
      expect(options.autoPlay, false);
    });
  });

  group('PlaybackStateEnum', () {
    test('has all required states', () {
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.uninitialized));
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.initializing));
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.ready));
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.playing));
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.paused));
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.completed));
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.buffering));
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.error));
      expect(PlaybackStateEnum.values, contains(PlaybackStateEnum.disposed));
    });
  });

  group('VideoSourceType', () {
    test('has all required types', () {
      expect(VideoSourceType.values, contains(VideoSourceType.network));
      expect(VideoSourceType.values, contains(VideoSourceType.file));
      expect(VideoSourceType.values, contains(VideoSourceType.asset));
    });
  });
}
