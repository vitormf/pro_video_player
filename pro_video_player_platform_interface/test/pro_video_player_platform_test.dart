import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

/// Test subclass that exposes the base class default implementations.
class TestableProVideoPlayer extends ProVideoPlayerPlatform with MockPlatformInterfaceMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(const VideoSource.network('https://example.com'));
    registerFallbackValue(const VideoPlayerOptions());
    registerFallbackValue(const PipOptions());
    registerFallbackValue(const SubtitleTrack(id: 'test', label: 'Test'));
    registerFallbackValue(Duration.zero);
  });

  group('ProVideoPlayerPlatform', () {
    test('default instance is PigeonMethodChannelBase', () {
      expect(ProVideoPlayerPlatform.instance, isA<PigeonMethodChannelBase>());
    });

    test('can set custom instance', () {
      final mock = MockProVideoPlayerPlatform();
      final originalInstance = ProVideoPlayerPlatform.instance;
      ProVideoPlayerPlatform.instance = mock;

      expect(ProVideoPlayerPlatform.instance, equals(mock));

      // Reset to default
      ProVideoPlayerPlatform.instance = originalInstance;
    });

    group('default implementations throw UnimplementedError', () {
      late TestableProVideoPlayer platform;

      setUp(() {
        platform = TestableProVideoPlayer();
      });

      test('create throws UnimplementedError', () {
        expect(
          () => platform.create(source: const VideoSource.network('https://example.com/video.mp4')),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('create()'))),
        );
      });

      test('dispose throws UnimplementedError', () {
        expect(
          () => platform.dispose(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('dispose()'))),
        );
      });

      test('play throws UnimplementedError', () {
        expect(
          () => platform.play(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('play()'))),
        );
      });

      test('pause throws UnimplementedError', () {
        expect(
          () => platform.pause(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('pause()'))),
        );
      });

      test('stop throws UnimplementedError', () {
        expect(
          () => platform.stop(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('stop()'))),
        );
      });

      test('seekTo throws UnimplementedError', () {
        expect(
          () => platform.seekTo(1, const Duration(seconds: 10)),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('seekTo()'))),
        );
      });

      test('setPlaybackSpeed throws UnimplementedError', () {
        expect(
          () => platform.setPlaybackSpeed(1, 1.5),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('setPlaybackSpeed()'))),
        );
      });

      test('setVolume throws UnimplementedError', () {
        expect(
          () => platform.setVolume(1, 0.5),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('setVolume()'))),
        );
      });

      test('setLooping throws UnimplementedError', () {
        expect(
          () => platform.setLooping(1, true),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('setLooping()'))),
        );
      });

      test('setSubtitleTrack throws UnimplementedError', () {
        expect(
          () => platform.setSubtitleTrack(1, const SubtitleTrack(id: 'en', label: 'English')),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('setSubtitleTrack()'))),
        );
      });

      test('getPosition throws UnimplementedError', () {
        expect(
          () => platform.getPosition(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('getPosition()'))),
        );
      });

      test('getDuration throws UnimplementedError', () {
        expect(
          () => platform.getDuration(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('getDuration()'))),
        );
      });

      test('enterPip throws UnimplementedError', () {
        expect(
          () => platform.enterPip(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('enterPip()'))),
        );
      });

      test('exitPip throws UnimplementedError', () {
        expect(
          () => platform.exitPip(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('exitPip()'))),
        );
      });

      test('isPipSupported throws UnimplementedError', () {
        expect(
          () => platform.isPipSupported(),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('isPipSupported()'))),
        );
      });

      test('events throws UnimplementedError', () {
        expect(
          () => platform.events(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('events()'))),
        );
      });

      test('buildView throws UnimplementedError', () {
        expect(
          () => platform.buildView(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('buildView()'))),
        );
      });

      test('addExternalSubtitle throws UnimplementedError', () {
        expect(
          () => platform.addExternalSubtitle(
            1,
            const SubtitleSource.network('https://example.com/subtitles.srt', format: SubtitleFormat.srt),
          ),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('addExternalSubtitle()'))),
        );
      });

      test('removeExternalSubtitle throws UnimplementedError', () {
        expect(
          () => platform.removeExternalSubtitle(1, 'track_id'),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('removeExternalSubtitle()'))),
        );
      });

      test('getExternalSubtitles throws UnimplementedError', () {
        expect(
          () => platform.getExternalSubtitles(1),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('getExternalSubtitles()'))),
        );
      });

      test('getPlatformInfo throws UnimplementedError', () {
        expect(
          () => platform.getPlatformInfo(),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('getPlatformInfo()'))),
        );
      });

      test('supportsPictureInPicture throws UnimplementedError', () {
        expect(
          () => platform.supportsPictureInPicture(),
          throwsA(
            isA<UnimplementedError>().having((e) => e.message, 'message', contains('supportsPictureInPicture()')),
          ),
        );
      });
    });
  });
}
