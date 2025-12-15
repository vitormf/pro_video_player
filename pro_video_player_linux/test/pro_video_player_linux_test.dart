import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_linux/pro_video_player_linux.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProVideoPlayerLinux', () {
    test('can be registered', () {
      ProVideoPlayerPlatform.instance = ProVideoPlayerLinux();
      expect(ProVideoPlayerPlatform.instance, isA<ProVideoPlayerLinux>());
    });
  });
}
