import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_macos/pro_video_player_macos.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProVideoPlayerMacOS', () {
    late ProVideoPlayerMacOS platform;
    final log = <MethodCall>[];

    setUp(() {
      platform = ProVideoPlayerMacOS();
      ProVideoPlayerPlatform.instance = platform;

      // Mock method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.example.pro_video_player_macos/methods'),
        (methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'create':
              return 1; // Return player ID
            case 'isPipSupported':
              return true;
            case 'enterPip':
              return true;
            case 'enterFullscreen':
              return true;
            case 'getPosition':
              return 0;
            case 'getDuration':
              return 10000;
            default:
              return null;
          }
        },
      );
    });

    tearDown(log.clear);

    test('is the registered instance', () {
      expect(ProVideoPlayerPlatform.instance, isA<ProVideoPlayerMacOS>());
    });

    test('create returns a player ID', () async {
      final playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
      expect(playerId, 1);
      expect(log, hasLength(1));
      expect(log.first.method, 'create');
    });

    test('dispose calls native dispose', () async {
      await platform.dispose(1);
      expect(log.last.method, 'dispose');
      expect(log.last.arguments, {'playerId': 1});
    });

    test('play calls native play', () async {
      await platform.play(1);
      expect(log.last.method, 'play');
      expect(log.last.arguments, {'playerId': 1});
    });

    test('pause calls native pause', () async {
      await platform.pause(1);
      expect(log.last.method, 'pause');
      expect(log.last.arguments, {'playerId': 1});
    });

    test('seekTo calls native seekTo with milliseconds', () async {
      await platform.seekTo(1, const Duration(seconds: 5));
      expect(log.last.method, 'seekTo');
      expect(log.last.arguments, {'playerId': 1, 'position': 5000});
    });

    test('setVolume calls native setVolume', () async {
      await platform.setVolume(1, 0.8);
      expect(log.last.method, 'setVolume');
      expect(log.last.arguments, {'playerId': 1, 'volume': 0.8});
    });

    test('setPlaybackSpeed calls native setPlaybackSpeed', () async {
      await platform.setPlaybackSpeed(1, 1.5);
      expect(log.last.method, 'setPlaybackSpeed');
      expect(log.last.arguments, {'playerId': 1, 'speed': 1.5});
    });

    test('setLooping calls native setLooping', () async {
      await platform.setLooping(1, looping: true);
      expect(log.last.method, 'setLooping');
      expect(log.last.arguments, {'playerId': 1, 'looping': true});
    });

    test('isPipSupported returns native result', () async {
      final result = await platform.isPipSupported();
      expect(result, true);
      expect(log.last.method, 'isPipSupported');
    });

    test('enterPip calls native enterPip', () async {
      final result = await platform.enterPip(1);
      expect(result, true);
      expect(log.last.method, 'enterPip');
    });

    test('enterFullscreen calls native enterFullscreen', () async {
      final result = await platform.enterFullscreen(1);
      expect(result, true);
      expect(log.last.method, 'enterFullscreen');
    });

    test('getPosition returns duration from native', () async {
      final position = await platform.getPosition(1);
      expect(position, Duration.zero);
      expect(log.last.method, 'getPosition');
    });

    test('getDuration returns duration from native', () async {
      final duration = await platform.getDuration(1);
      expect(duration, const Duration(milliseconds: 10000));
      expect(log.last.method, 'getDuration');
    });

    test('registerWith sets platform instance', () {
      ProVideoPlayerMacOS.registerWith();
      expect(ProVideoPlayerPlatform.instance, isA<ProVideoPlayerMacOS>());
    });

    testWidgets('buildView returns AppKitView widget', (tester) async {
      final view = platform.buildView(1);
      expect(view, isA<AppKitView>());
    });

    testWidgets('buildView passes playerId and controlsMode', (tester) async {
      final view = platform.buildView(1, controlsMode: ControlsMode.native) as AppKitView;
      expect(view.viewType, 'com.example.pro_video_player_macos/video_view');
      expect(view.creationParams, {'playerId': 1, 'controlsMode': 'native'});
    });

    testWidgets('buildView defaults to none controlsMode', (tester) async {
      final view = platform.buildView(1) as AppKitView;
      expect(view.creationParams, {'playerId': 1, 'controlsMode': 'none'});
    });
  });
}
