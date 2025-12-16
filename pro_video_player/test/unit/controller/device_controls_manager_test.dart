import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/controller/device_controls_manager.dart';

import '../../shared/mocks.dart';
import '../../shared/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late DeviceControlsManager manager;
  late bool isInitialized;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    isInitialized = true;

    manager = DeviceControlsManager(
      platform: mockPlatform,
      ensureInitialized: () {
        if (!isInitialized) {
          throw StateError('Controller not initialized');
        }
      },
    );
  });

  group('DeviceControlsManager', () {
    group('getDeviceVolume', () {
      test('calls platform getDeviceVolume', () async {
        when(() => mockPlatform.getDeviceVolume()).thenAnswer((_) async => 0.8);

        final volume = await manager.getDeviceVolume();

        expect(volume, equals(0.8));
        verify(() => mockPlatform.getDeviceVolume()).called(1);
      });

      test('returns platform value', () async {
        when(() => mockPlatform.getDeviceVolume()).thenAnswer((_) async => 0.5);

        final volume = await manager.getDeviceVolume();

        expect(volume, equals(0.5));
      });
    });

    group('setDeviceVolume', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.setDeviceVolume(any())).thenAnswer((_) async {});

        await manager.setDeviceVolume(0.7);

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.setDeviceVolume(0.7)).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.setDeviceVolume(0.7), throwsStateError);
      });

      test('calls platform setDeviceVolume with valid value', () async {
        when(() => mockPlatform.setDeviceVolume(any())).thenAnswer((_) async {});

        await manager.setDeviceVolume(0.6);

        verify(() => mockPlatform.setDeviceVolume(0.6)).called(1);
      });

      test('accepts minimum value 0.0', () async {
        when(() => mockPlatform.setDeviceVolume(any())).thenAnswer((_) async {});

        await manager.setDeviceVolume(0);

        verify(() => mockPlatform.setDeviceVolume(0)).called(1);
      });

      test('accepts maximum value 1.0', () async {
        when(() => mockPlatform.setDeviceVolume(any())).thenAnswer((_) async {});

        await manager.setDeviceVolume(1);

        verify(() => mockPlatform.setDeviceVolume(1)).called(1);
      });

      test('throws ArgumentError for negative volume', () async {
        expect(
          () => manager.setDeviceVolume(-0.1),
          throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('between 0.0 and 1.0'))),
        );
      });

      test('throws ArgumentError for volume > 1.0', () async {
        expect(
          () => manager.setDeviceVolume(1.1),
          throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('between 0.0 and 1.0'))),
        );
      });
    });

    group('getScreenBrightness', () {
      test('calls platform getScreenBrightness', () async {
        when(() => mockPlatform.getScreenBrightness()).thenAnswer((_) async => 0.9);

        final brightness = await manager.getScreenBrightness();

        expect(brightness, equals(0.9));
        verify(() => mockPlatform.getScreenBrightness()).called(1);
      });

      test('returns platform value', () async {
        when(() => mockPlatform.getScreenBrightness()).thenAnswer((_) async => 0.3);

        final brightness = await manager.getScreenBrightness();

        expect(brightness, equals(0.3));
      });
    });

    group('setScreenBrightness', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.setScreenBrightness(any())).thenAnswer((_) async {});

        await manager.setScreenBrightness(0.8);

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.setScreenBrightness(0.8)).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.setScreenBrightness(0.8), throwsStateError);
      });

      test('calls platform setScreenBrightness with valid value', () async {
        when(() => mockPlatform.setScreenBrightness(any())).thenAnswer((_) async {});

        await manager.setScreenBrightness(0.5);

        verify(() => mockPlatform.setScreenBrightness(0.5)).called(1);
      });

      test('accepts minimum value 0.0', () async {
        when(() => mockPlatform.setScreenBrightness(any())).thenAnswer((_) async {});

        await manager.setScreenBrightness(0);

        verify(() => mockPlatform.setScreenBrightness(0)).called(1);
      });

      test('accepts maximum value 1.0', () async {
        when(() => mockPlatform.setScreenBrightness(any())).thenAnswer((_) async {});

        await manager.setScreenBrightness(1);

        verify(() => mockPlatform.setScreenBrightness(1)).called(1);
      });

      test('throws ArgumentError for negative brightness', () async {
        expect(
          () => manager.setScreenBrightness(-0.1),
          throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('between 0.0 and 1.0'))),
        );
      });

      test('throws ArgumentError for brightness > 1.0', () async {
        expect(
          () => manager.setScreenBrightness(1.5),
          throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('between 0.0 and 1.0'))),
        );
      });
    });
  });
}
