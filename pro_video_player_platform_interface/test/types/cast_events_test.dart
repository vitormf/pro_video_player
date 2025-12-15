import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('CastStateChangedEvent', () {
    test('creates event with all properties', () {
      const device = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      const event = CastStateChangedEvent(state: CastState.connected, device: device);

      expect(event.state, equals(CastState.connected));
      expect(event.device, equals(device));
    });

    test('creates event with null device', () {
      const event = CastStateChangedEvent(state: CastState.notConnected);

      expect(event.state, equals(CastState.notConnected));
      expect(event.device, isNull);
    });

    test('toString includes state and device', () {
      const device = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay);

      const event = CastStateChangedEvent(state: CastState.connected, device: device);

      final string = event.toString();
      expect(string, contains('connected'));
      expect(string, contains('device-123'));
    });
  });

  group('CastDevicesChangedEvent', () {
    test('creates event with empty device list', () {
      const event = CastDevicesChangedEvent([]);

      expect(event.devices, isEmpty);
    });

    test('creates event with multiple devices', () {
      const devices = [
        CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay),
        CastDevice(id: 'device-456', name: 'Bedroom Chromecast', type: CastDeviceType.chromecast),
      ];

      const event = CastDevicesChangedEvent(devices);

      expect(event.devices, hasLength(2));
      expect(event.devices, equals(devices));
    });

    test('toString includes device count', () {
      const devices = [
        CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.airPlay),
        CastDevice(id: 'device-456', name: 'Bedroom Chromecast', type: CastDeviceType.chromecast),
      ];

      const event = CastDevicesChangedEvent(devices);

      final string = event.toString();
      expect(string, contains('2'));
      expect(string, contains('devices'));
    });
  });
}
