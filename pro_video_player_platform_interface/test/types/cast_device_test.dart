import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('CastDeviceType', () {
    test('has all expected values', () {
      expect(CastDeviceType.values, hasLength(4));
      expect(CastDeviceType.values, contains(CastDeviceType.airPlay));
      expect(CastDeviceType.values, contains(CastDeviceType.chromecast));
      expect(CastDeviceType.values, contains(CastDeviceType.webRemotePlayback));
      expect(CastDeviceType.values, contains(CastDeviceType.unknown));
    });
  });

  group('CastDevice', () {
    test('creates device with all properties', () {
      const device = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      expect(device.id, equals('device-123'));
      expect(device.name, equals('Living Room TV'));
      expect(device.type, equals(CastDeviceType.airPlay));
    });

    test('copyWith creates a copy with modified fields', () {
      const original = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      final modified = original.copyWith(name: 'Bedroom TV', type: CastDeviceType.chromecast);

      expect(modified.id, equals('device-123'));
      expect(modified.name, equals('Bedroom TV'));
      expect(modified.type, equals(CastDeviceType.chromecast));
    });

    test('copyWith preserves original fields when not specified', () {
      const original = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      final modified = original.copyWith(name: 'Bedroom TV');

      expect(modified.id, equals('device-123'));
      expect(modified.name, equals('Bedroom TV'));
      expect(modified.type, equals(CastDeviceType.airPlay));
    });

    test('equality works correctly', () {
      const device1 = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      const device2 = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      const device3 = CastDevice(id: 'device-456', name: 'Living Room TV', type: CastDeviceType.airPlay);

      expect(device1, equals(device2));
      expect(device1, isNot(equals(device3)));
    });

    test('hashCode works correctly', () {
      const device1 = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      const device2 = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      expect(device1.hashCode, equals(device2.hashCode));
    });

    test('toString includes all properties', () {
      const device = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      final string = device.toString();
      expect(string, contains('device-123'));
      expect(string, contains('Living Room TV'));
      expect(string, contains('airPlay'));
    });
  });
}
