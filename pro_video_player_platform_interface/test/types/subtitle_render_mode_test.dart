import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('SubtitleRenderMode', () {
    test('has three modes', () {
      expect(SubtitleRenderMode.values.length, 3);
      expect(SubtitleRenderMode.values, contains(SubtitleRenderMode.native));
      expect(SubtitleRenderMode.values, contains(SubtitleRenderMode.flutter));
      expect(SubtitleRenderMode.values, contains(SubtitleRenderMode.auto));
    });

    test('serializes to JSON correctly', () {
      expect(SubtitleRenderMode.native.toJson(), 'native');
      expect(SubtitleRenderMode.flutter.toJson(), 'flutter');
      expect(SubtitleRenderMode.auto.toJson(), 'auto');
    });

    test('deserializes from JSON correctly', () {
      expect(SubtitleRenderModeExtension.fromJson('native'), SubtitleRenderMode.native);
      expect(SubtitleRenderModeExtension.fromJson('flutter'), SubtitleRenderMode.flutter);
      expect(SubtitleRenderModeExtension.fromJson('auto'), SubtitleRenderMode.auto);
    });

    test('deserializes null to auto', () {
      expect(SubtitleRenderModeExtension.fromJson(null), SubtitleRenderMode.auto);
    });

    test('deserializes unknown value to auto', () {
      expect(SubtitleRenderModeExtension.fromJson('invalid'), SubtitleRenderMode.auto);
      expect(SubtitleRenderModeExtension.fromJson(''), SubtitleRenderMode.auto);
    });

    test('round-trips through JSON', () {
      for (final mode in SubtitleRenderMode.values) {
        final json = mode.toJson();
        final deserialized = SubtitleRenderModeExtension.fromJson(json);
        expect(deserialized, mode);
      }
    });
  });
}
