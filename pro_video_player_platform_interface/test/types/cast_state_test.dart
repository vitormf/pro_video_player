import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('CastState', () {
    test('has all expected values', () {
      expect(CastState.values, hasLength(4));
      expect(CastState.values, contains(CastState.notConnected));
      expect(CastState.values, contains(CastState.connecting));
      expect(CastState.values, contains(CastState.connected));
      expect(CastState.values, contains(CastState.disconnecting));
    });
  });
}
