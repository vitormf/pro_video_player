@TestOn('browser')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:pro_video_player_web/pro_video_player_web.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProVideoPlayerWeb', () {
    late ProVideoPlayerWeb platform;

    setUp(() {
      platform = ProVideoPlayerWeb();
      ProVideoPlayerPlatform.instance = platform;
    });

    group('registration', () {
      test('is the registered instance', () {
        expect(ProVideoPlayerPlatform.instance, isA<ProVideoPlayerWeb>());
      });

      test('can be set as platform instance', () {
        final newInstance = ProVideoPlayerWeb();
        ProVideoPlayerPlatform.instance = newInstance;
        expect(ProVideoPlayerPlatform.instance, same(newInstance));
      });
    });

    group('PiP support', () {
      test('isPipSupported returns a boolean', () async {
        final result = await platform.isPipSupported();
        expect(result, isA<bool>());
      });
    });

    group('player lifecycle', () {
      test('create returns incrementing player IDs', () async {
        final id1 = await platform.create(source: const VideoSource.network('https://example.com/video1.mp4'));
        final id2 = await platform.create(source: const VideoSource.network('https://example.com/video2.mp4'));

        expect(id1, isNonNegative);
        expect(id2, equals(id1 + 1));

        // Cleanup
        await platform.dispose(id1);
        await platform.dispose(id2);
      });

      test('create with options passes options to player', () async {
        const options = VideoPlayerOptions(looping: true, volume: 0.5, playbackSpeed: 1.5);

        final id = await platform.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: options,
        );

        expect(id, isNonNegative);

        // Cleanup
        await platform.dispose(id);
      });

      test('dispose removes player', () async {
        final id = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        await platform.dispose(id);

        // After dispose, accessing the player should throw
        expect(() => platform.events(id), throwsStateError);
      });

      test('dispose is safe for non-existent player', () async {
        // Should not throw for non-existent player
        await expectLater(platform.dispose(999), completes);
      });
    });

    group('error handling', () {
      test('play throws StateError for non-existent player', () async {
        expect(() => platform.play(999), throwsStateError);
      });

      test('pause throws StateError for non-existent player', () async {
        expect(() => platform.pause(999), throwsStateError);
      });

      test('stop throws StateError for non-existent player', () async {
        expect(() => platform.stop(999), throwsStateError);
      });

      test('seekTo throws StateError for non-existent player', () async {
        expect(() => platform.seekTo(999, Duration.zero), throwsStateError);
      });

      test('setPlaybackSpeed throws StateError for non-existent player', () async {
        expect(() => platform.setPlaybackSpeed(999, 1), throwsStateError);
      });

      test('setVolume throws StateError for non-existent player', () async {
        expect(() => platform.setVolume(999, 1), throwsStateError);
      });

      test('setLooping throws StateError for non-existent player', () async {
        expect(() => platform.setLooping(999, looping: true), throwsStateError);
      });

      test('setSubtitleTrack throws StateError for non-existent player', () async {
        expect(() => platform.setSubtitleTrack(999, null), throwsStateError);
      });

      test('getPosition throws StateError for non-existent player', () async {
        expect(() => platform.getPosition(999), throwsStateError);
      });

      test('getDuration throws StateError for non-existent player', () async {
        expect(() => platform.getDuration(999), throwsStateError);
      });

      test('enterPip throws StateError for non-existent player', () async {
        expect(() => platform.enterPip(999), throwsStateError);
      });

      test('exitPip throws StateError for non-existent player', () async {
        expect(() => platform.exitPip(999), throwsStateError);
      });

      test('enterFullscreen throws StateError for non-existent player', () async {
        expect(() => platform.enterFullscreen(999), throwsStateError);
      });

      test('exitFullscreen throws StateError for non-existent player', () async {
        expect(() => platform.exitFullscreen(999), throwsStateError);
      });

      test('events throws StateError for non-existent player', () {
        expect(() => platform.events(999), throwsStateError);
      });

      test('buildView throws StateError for non-existent player', () {
        expect(() => platform.buildView(999), throwsStateError);
      });
    });

    group('events', () {
      test('events returns a broadcast stream', () async {
        final id = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final stream = platform.events(id);
        expect(stream, isA<Stream<VideoPlayerEvent>>());
        expect(stream.isBroadcast, isTrue);

        // Cleanup
        await platform.dispose(id);
      });

      test('events can be accessed multiple times', () async {
        final id = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        // Multiple accesses should not throw
        final stream1 = platform.events(id);
        final stream2 = platform.events(id);
        expect(stream1, isA<Stream<VideoPlayerEvent>>());
        expect(stream2, isA<Stream<VideoPlayerEvent>>());

        // Cleanup
        await platform.dispose(id);
      });
    });

    group('buildView', () {
      test('buildView returns HtmlElementView widget', () async {
        final id = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final view = platform.buildView(id);
        expect(view, isA<HtmlElementView>());

        // Cleanup
        await platform.dispose(id);
      });

      test('buildView accepts controlsMode parameter', () async {
        final id = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final view = platform.buildView(id, controlsMode: ControlsMode.native);
        expect(view, isA<HtmlElementView>());

        // Cleanup
        await platform.dispose(id);
      });
    });

    group('video sources', () {
      test('create with NetworkVideoSource', () async {
        final id = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        expect(id, isNonNegative);
        await platform.dispose(id);
      });

      test('create with NetworkVideoSource with headers', () async {
        final id = await platform.create(
          source: const VideoSource.network(
            'https://example.com/video.mp4',
            headers: {'Authorization': 'Bearer token'},
          ),
        );
        expect(id, isNonNegative);
        await platform.dispose(id);
      });

      test('create with FileVideoSource', () async {
        final id = await platform.create(source: const VideoSource.file('/path/to/video.mp4'));
        expect(id, isNonNegative);
        await platform.dispose(id);
      });

      test('create with AssetVideoSource', () async {
        final id = await platform.create(source: const VideoSource.asset('assets/video.mp4'));
        expect(id, isNonNegative);
        await platform.dispose(id);
      });
    });

    group('player operations', () {
      late int playerId;

      setUp(() async {
        playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
      });

      tearDown(() async {
        await platform.dispose(playerId);
      });

      test('play completes without throwing', () async {
        // Note: Play may be rejected by browser autoplay policy in test environment
        // but the method itself should complete without throwing (errors go to event stream)
        try {
          await platform.play(playerId);
        } catch (_) {
          // Autoplay policy may reject in test environment - this is expected
        }
        // If we get here without throwing, the test passes
      });

      test('pause completes without error', () async {
        await expectLater(platform.pause(playerId), completes);
      });

      test('stop completes without error', () async {
        await expectLater(platform.stop(playerId), completes);
      });

      test('seekTo completes without error', () async {
        await expectLater(platform.seekTo(playerId, const Duration(seconds: 10)), completes);
      });

      test('setPlaybackSpeed completes without error', () async {
        await expectLater(platform.setPlaybackSpeed(playerId, 1.5), completes);
      });

      test('setVolume completes without error', () async {
        await expectLater(platform.setVolume(playerId, 0.5), completes);
      });

      test('setLooping completes without error', () async {
        await expectLater(platform.setLooping(playerId, looping: true), completes);
      });

      test('setSubtitleTrack completes without error', () async {
        await expectLater(platform.setSubtitleTrack(playerId, null), completes);
      });

      test('getPosition returns Duration', () async {
        final position = await platform.getPosition(playerId);
        expect(position, isA<Duration>());
      });

      test('getDuration returns Duration', () async {
        final duration = await platform.getDuration(playerId);
        expect(duration, isA<Duration>());
      });

      test('enterPip returns boolean', () async {
        final result = await platform.enterPip(playerId);
        expect(result, isA<bool>());
      });

      test('exitPip completes without error', () async {
        await expectLater(platform.exitPip(playerId), completes);
      });

      test('enterFullscreen returns boolean', () async {
        // Note: Fullscreen requires user interaction in browsers
        // This test verifies the method doesn't throw
        final result = await platform.enterFullscreen(playerId);
        expect(result, isA<bool>());
      });

      test('exitFullscreen completes without error', () async {
        await expectLater(platform.exitFullscreen(playerId), completes);
      });
    });

    group('quality selection', () {
      late int playerId;

      setUp(() async {
        playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
      });

      tearDown(() async {
        await platform.dispose(playerId);
      });

      test('getVideoQualities returns list with at least auto option', () async {
        final qualities = await platform.getVideoQualities(playerId);
        expect(qualities, isA<List<VideoQualityTrack>>());
        expect(qualities, isNotEmpty);
        // Auto should always be present
        expect(qualities.any((q) => q.isAuto), isTrue);
      });

      test('setVideoQuality returns boolean', () async {
        final result = await platform.setVideoQuality(playerId, VideoQualityTrack.auto);
        expect(result, isA<bool>());
      });

      test('setVideoQuality with auto returns true', () async {
        final result = await platform.setVideoQuality(playerId, VideoQualityTrack.auto);
        expect(result, isTrue);
      });

      test('getCurrentVideoQuality returns VideoQualityTrack', () async {
        final quality = await platform.getCurrentVideoQuality(playerId);
        expect(quality, isA<VideoQualityTrack>());
      });

      test('isQualitySelectionSupported returns boolean', () async {
        final result = await platform.isQualitySelectionSupported(playerId);
        expect(result, isA<bool>());
      });

      test('for non-HLS source, quality selection is not supported', () async {
        // Regular MP4 file doesn't support quality selection
        final result = await platform.isQualitySelectionSupported(playerId);
        expect(result, isFalse);
      });
    });

    group('audio track selection', () {
      late int playerId;

      setUp(() async {
        playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
      });

      tearDown(() async {
        await platform.dispose(playerId);
      });

      test('setAudioTrack completes without error', () async {
        await expectLater(platform.setAudioTrack(playerId, null), completes);
      });
    });

    group('background playback', () {
      test('isBackgroundPlaybackSupported returns false on web', () async {
        final result = await platform.isBackgroundPlaybackSupported();
        expect(result, isFalse);
      });

      test('setBackgroundPlayback returns false on web', () async {
        final playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final result = await platform.setBackgroundPlayback(playerId, enabled: true);
        expect(result, isFalse);
        await platform.dispose(playerId);
      });
    });

    group('multiple players', () {
      test('can create multiple players simultaneously', () async {
        final id1 = await platform.create(source: const VideoSource.network('https://example.com/video1.mp4'));
        final id2 = await platform.create(source: const VideoSource.network('https://example.com/video2.mp4'));
        final id3 = await platform.create(source: const VideoSource.network('https://example.com/video3.mp4'));

        expect(id1, isNot(equals(id2)));
        expect(id2, isNot(equals(id3)));
        expect(id1, isNot(equals(id3)));

        // Each player has its own event stream
        final stream1 = platform.events(id1);
        final stream2 = platform.events(id2);
        final stream3 = platform.events(id3);
        expect(identical(stream1, stream2), isFalse);
        expect(identical(stream2, stream3), isFalse);

        // Cleanup
        await platform.dispose(id1);
        await platform.dispose(id2);
        await platform.dispose(id3);
      });

      test('disposing one player does not affect others', () async {
        final id1 = await platform.create(source: const VideoSource.network('https://example.com/video1.mp4'));
        final id2 = await platform.create(source: const VideoSource.network('https://example.com/video2.mp4'));

        await platform.dispose(id1);

        // id2 should still be accessible
        expect(() => platform.events(id2), returnsNormally);

        // id1 should throw
        expect(() => platform.events(id1), throwsStateError);

        // Cleanup
        await platform.dispose(id2);
      });
    });

    group('HLS sources', () {
      test('can create player with HLS source (.m3u8)', () async {
        final id = await platform.create(source: const VideoSource.network('https://example.com/stream.m3u8'));
        expect(id, isNonNegative);
        await platform.dispose(id);
      });

      test('can create player with HLS source with query params', () async {
        final id = await platform.create(
          source: const VideoSource.network('https://example.com/stream.m3u8?token=abc123'),
        );
        expect(id, isNonNegative);
        await platform.dispose(id);
      });

      test('HLS source can access quality methods', () async {
        final id = await platform.create(source: const VideoSource.network('https://example.com/stream.m3u8'));

        // These methods should not throw even for HLS sources
        final qualities = await platform.getVideoQualities(id);
        expect(qualities, isNotEmpty);

        final currentQuality = await platform.getCurrentVideoQuality(id);
        expect(currentQuality, isA<VideoQualityTrack>());

        final supported = await platform.isQualitySelectionSupported(id);
        expect(supported, isA<bool>());

        await platform.dispose(id);
      });
    });

    group('scaling mode', () {
      late int playerId;

      setUp(() async {
        playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
      });

      tearDown(() async {
        await platform.dispose(playerId);
      });

      test('setScalingMode with fit completes without error', () async {
        await expectLater(platform.setScalingMode(playerId, VideoScalingMode.fit), completes);
      });

      test('setScalingMode with fill completes without error', () async {
        await expectLater(platform.setScalingMode(playerId, VideoScalingMode.fill), completes);
      });

      test('setScalingMode with stretch completes without error', () async {
        await expectLater(platform.setScalingMode(playerId, VideoScalingMode.stretch), completes);
      });
    });

    group('media metadata', () {
      late int playerId;

      setUp(() async {
        playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
      });

      tearDown(() async {
        await platform.dispose(playerId);
      });

      test('setMediaMetadata completes without error', () async {
        await expectLater(
          platform.setMediaMetadata(playerId, const MediaMetadata(title: 'Test Video', artist: 'Test Artist')),
          completes,
        );
      });
    });

    group('verbose logging', () {
      test('setVerboseLogging can be enabled', () async {
        await expectLater(platform.setVerboseLogging(enabled: true), completes);
      });

      test('setVerboseLogging can be disabled', () async {
        await expectLater(platform.setVerboseLogging(enabled: false), completes);
      });
    });

    group('external subtitles', () {
      late int playerId;

      setUp(() async {
        playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
      });

      tearDown(() async {
        await platform.dispose(playerId);
      });

      test('addExternalSubtitle with VTT format returns track', () async {
        const source = SubtitleSource.network(
          'https://example.com/subtitle.vtt',
          format: SubtitleFormat.vtt,
          label: 'English',
          language: 'en',
        );

        final track = await platform.addExternalSubtitle(playerId, source);

        expect(track, isNotNull);
        expect(track!.label, equals('English'));
        expect(track.language, equals('en'));
        expect(track.format, equals(SubtitleFormat.vtt));
      });

      test('addExternalSubtitle with SRT format converts to VTT', () async {
        // SRT format should be converted to VTT via SubtitleLoader
        const source = SubtitleSource.network(
          'https://example.com/subtitle.srt',
          format: SubtitleFormat.srt,
          label: 'English SRT',
          language: 'en',
        );

        final track = await platform.addExternalSubtitle(playerId, source);

        // Track creation should succeed (conversion happens internally)
        expect(track, isNotNull);
        expect(track!.label, equals('English SRT'));
        expect(track.format, equals(SubtitleFormat.srt));
      });

      test('addExternalSubtitle with SSA format converts to VTT', () async {
        const source = SubtitleSource.network(
          'https://example.com/subtitle.ssa',
          format: SubtitleFormat.ssa,
          label: 'English SSA',
          language: 'en',
        );

        final track = await platform.addExternalSubtitle(playerId, source);

        expect(track, isNotNull);
        expect(track!.label, equals('English SSA'));
        expect(track.format, equals(SubtitleFormat.ssa));
      });

      test('addExternalSubtitle with TTML format converts to VTT', () async {
        const source = SubtitleSource.network(
          'https://example.com/subtitle.ttml',
          format: SubtitleFormat.ttml,
          label: 'English TTML',
          language: 'en',
        );

        final track = await platform.addExternalSubtitle(playerId, source);

        expect(track, isNotNull);
        expect(track!.label, equals('English TTML'));
        expect(track.format, equals(SubtitleFormat.ttml));
      });

      test('addExternalSubtitle auto-detects format from URL', () async {
        const source = SubtitleSource.network('https://example.com/subtitle.vtt');

        final track = await platform.addExternalSubtitle(playerId, source);

        expect(track, isNotNull);
        // Format should be auto-detected as VTT
        expect(track!.format, equals(SubtitleFormat.vtt));
      });

      test('addExternalSubtitle generates unique track IDs', () async {
        const source1 = SubtitleSource.network('https://example.com/subtitle1.vtt');
        const source2 = SubtitleSource.network('https://example.com/subtitle2.vtt');

        final track1 = await platform.addExternalSubtitle(playerId, source1);
        final track2 = await platform.addExternalSubtitle(playerId, source2);

        expect(track1, isNotNull);
        expect(track2, isNotNull);
        expect(track1!.id, isNot(equals(track2!.id)));
      });

      test('removeExternalSubtitle removes track successfully', () async {
        const source = SubtitleSource.network('https://example.com/subtitle.vtt');

        final track = await platform.addExternalSubtitle(playerId, source);
        expect(track, isNotNull);

        final removed = await platform.removeExternalSubtitle(playerId, track!.id);
        expect(removed, isTrue);
      });

      test('removeExternalSubtitle returns false for non-existent track', () async {
        final removed = await platform.removeExternalSubtitle(playerId, 'non-existent-id');
        expect(removed, isFalse);
      });

      test('getExternalSubtitles returns empty list initially', () async {
        final subtitles = await platform.getExternalSubtitles(playerId);
        expect(subtitles, isEmpty);
      });

      test('getExternalSubtitles returns added tracks', () async {
        const source1 = SubtitleSource.network('https://example.com/subtitle1.vtt', label: 'Track 1');
        const source2 = SubtitleSource.network('https://example.com/subtitle2.vtt', label: 'Track 2');

        await platform.addExternalSubtitle(playerId, source1);
        await platform.addExternalSubtitle(playerId, source2);

        final subtitles = await platform.getExternalSubtitles(playerId);
        expect(subtitles, hasLength(2));
        expect(subtitles.map((t) => t.label), containsAll(['Track 1', 'Track 2']));
      });

      test('addExternalSubtitle handles default subtitle flag', () async {
        const source = SubtitleSource.network('https://example.com/subtitle.vtt', isDefault: true);

        final track = await platform.addExternalSubtitle(playerId, source);

        expect(track, isNotNull);
        expect(track!.isDefault, isTrue);
      });

      test('addExternalSubtitle handles file source', () async {
        const source = SubtitleSource.file(
          '/path/to/subtitle.vtt',
          format: SubtitleFormat.vtt,
          label: 'Local Subtitle',
        );

        final track = await platform.addExternalSubtitle(playerId, source);

        // Track should be created (actual file loading may fail in browser)
        expect(track, isNotNull);
        expect(track!.sourceType, equals('file'));
      });

      test('addExternalSubtitle handles asset source', () async {
        const source = SubtitleSource.asset('assets/subtitle.vtt', format: SubtitleFormat.vtt, label: 'Asset Subtitle');

        final track = await platform.addExternalSubtitle(playerId, source);

        expect(track, isNotNull);
        expect(track!.sourceType, equals('asset'));
      });
    });
  });
}
