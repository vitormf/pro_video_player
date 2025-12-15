import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('ControlsMode', () {
    test('has all expected values', () {
      expect(ControlsMode.values, hasLength(3));
      expect(ControlsMode.values, contains(ControlsMode.none));
      expect(ControlsMode.values, contains(ControlsMode.flutter));
      expect(ControlsMode.values, contains(ControlsMode.native));
    });

    test('none is the first value', () {
      expect(ControlsMode.values.first, equals(ControlsMode.none));
    });

    test('each mode has a unique index', () {
      final indices = ControlsMode.values.map((m) => m.index).toSet();
      expect(indices.length, equals(ControlsMode.values.length));
    });

    test('name property returns readable string', () {
      expect(ControlsMode.none.name, equals('none'));
      expect(ControlsMode.flutter.name, equals('flutter'));
      expect(ControlsMode.native.name, equals('native'));
    });

    group('toJson', () {
      test('serializes none to string', () {
        expect(ControlsMode.none.toJson(), equals('none'));
      });

      test('serializes flutter to string', () {
        expect(ControlsMode.flutter.toJson(), equals('flutter'));
      });

      test('serializes native to string', () {
        expect(ControlsMode.native.toJson(), equals('native'));
      });
    });

    group('fromJson', () {
      test('deserializes none from string', () {
        expect(ControlsModeExtension.fromJson('none'), equals(ControlsMode.none));
      });

      test('deserializes flutter from string', () {
        expect(ControlsModeExtension.fromJson('flutter'), equals(ControlsMode.flutter));
      });

      test('deserializes native from string', () {
        expect(ControlsModeExtension.fromJson('native'), equals(ControlsMode.native));
      });

      test('defaults to none for unknown value', () {
        expect(ControlsModeExtension.fromJson('unknown'), equals(ControlsMode.none));
      });

      test('defaults to none for null', () {
        expect(ControlsModeExtension.fromJson(null), equals(ControlsMode.none));
      });
    });
  });
}
