import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:pro_video_player_windows/pro_video_player_windows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProVideoPlayerWindows', () {
    late ProVideoPlayerWindows platform;

    setUp(() {
      platform = ProVideoPlayerWindows();
      ProVideoPlayerPlatform.instance = platform;
    });

    test('can be registered', () {
      expect(ProVideoPlayerPlatform.instance, isA<ProVideoPlayerWindows>());
    });

    test('registerWith sets platform instance', () {
      ProVideoPlayerWindows.registerWith();
      expect(ProVideoPlayerPlatform.instance, isA<ProVideoPlayerWindows>());
    });

    test('isPipSupported returns false', () async {
      final result = await platform.isPipSupported();
      expect(result, false);
    });

    test('enterPip returns false', () async {
      final result = await platform.enterPip(1);
      expect(result, false);
    });

    test('exitPip completes without error', () async {
      await platform.exitPip(1);
      // Should complete without throwing
    });

    testWidgets('buildView returns Text widget', (tester) async {
      final view = platform.buildView(1);
      expect(view, isA<Text>());
      expect((view as Text).data, 'Windows video view placeholder');
    });

    testWidgets('buildView accepts controlsMode parameter', (tester) async {
      final view = platform.buildView(1, controlsMode: ControlsMode.native);
      expect(view, isA<Text>());
    });
  });
}
