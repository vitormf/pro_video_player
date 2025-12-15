import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/controller/casting_manager.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late CastingManager manager;
  late int? playerId;
  late VideoPlayerOptions options;
  late bool isInitialized;

  setUpAll(registerFallbackValues);

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    playerId = 1;
    options = const VideoPlayerOptions();
    isInitialized = true;

    manager = CastingManager(
      getPlayerId: () => playerId,
      getOptions: () => options,
      platform: mockPlatform,
      ensureInitialized: () {
        if (!isInitialized) {
          throw StateError('Controller not initialized');
        }
      },
    );
  });

  group('CastingManager', () {
    group('isCastingSupported', () {
      test('returns false when allowCasting is false', () async {
        options = const VideoPlayerOptions(allowCasting: false);

        final supported = await manager.isCastingSupported();

        expect(supported, isFalse);
        verifyNever(() => mockPlatform.isCastingSupported());
      });

      test('returns platform value when allowCasting is true', () async {
        options = const VideoPlayerOptions();
        when(() => mockPlatform.isCastingSupported()).thenAnswer((_) async => true);

        final supported = await manager.isCastingSupported();

        expect(supported, isTrue);
        verify(() => mockPlatform.isCastingSupported()).called(1);
      });

      test('returns false from platform when not supported', () async {
        options = const VideoPlayerOptions();
        when(() => mockPlatform.isCastingSupported()).thenAnswer((_) async => false);

        final supported = await manager.isCastingSupported();

        expect(supported, isFalse);
      });

      test('uses default allowCasting value (true)', () async {
        options = const VideoPlayerOptions(); // Default allowCasting is true
        when(() => mockPlatform.isCastingSupported()).thenAnswer((_) async => true);

        final supported = await manager.isCastingSupported();

        expect(supported, isTrue);
        verify(() => mockPlatform.isCastingSupported()).called(1);
      });
    });

    group('startCasting', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.startCasting(any(), device: any(named: 'device'))).thenAnswer((_) async => true);

        await manager.startCasting();

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.startCasting(1)).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.startCasting(), throwsStateError);
      });

      test('returns false when allowCasting is false', () async {
        options = const VideoPlayerOptions(allowCasting: false);

        final started = await manager.startCasting();

        expect(started, isFalse);
        verifyNever(() => mockPlatform.startCasting(any(), device: any(named: 'device')));
      });

      test('calls platform startCasting with playerId when allowed', () async {
        when(() => mockPlatform.startCasting(any(), device: any(named: 'device'))).thenAnswer((_) async => true);

        final started = await manager.startCasting();

        expect(started, isTrue);
        verify(() => mockPlatform.startCasting(1)).called(1);
      });

      test('passes device parameter to platform', () async {
        const device = CastDevice(id: 'device-123', name: 'Living Room TV', type: CastDeviceType.chromecast);
        when(() => mockPlatform.startCasting(any(), device: any(named: 'device'))).thenAnswer((_) async => true);

        final started = await manager.startCasting(device: device);

        expect(started, isTrue);
        verify(() => mockPlatform.startCasting(1, device: device)).called(1);
      });

      test('passes null device for device picker', () async {
        when(() => mockPlatform.startCasting(any())).thenAnswer((_) async => true);

        await manager.startCasting();

        verify(() => mockPlatform.startCasting(1)).called(1);
      });

      test('returns false when platform returns false', () async {
        when(() => mockPlatform.startCasting(any(), device: any(named: 'device'))).thenAnswer((_) async => false);

        final started = await manager.startCasting();

        expect(started, isFalse);
      });
    });

    group('stopCasting', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.stopCasting(any())).thenAnswer((_) async => true);

        await manager.stopCasting();

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.stopCasting(1)).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.stopCasting(), throwsStateError);
      });

      test('calls platform stopCasting with playerId', () async {
        when(() => mockPlatform.stopCasting(any())).thenAnswer((_) async => true);

        final stopped = await manager.stopCasting();

        expect(stopped, isTrue);
        verify(() => mockPlatform.stopCasting(1)).called(1);
      });

      test('returns false when platform returns false', () async {
        when(() => mockPlatform.stopCasting(any())).thenAnswer((_) async => false);

        final stopped = await manager.stopCasting();

        expect(stopped, isFalse);
      });

      test('returns platform value', () async {
        when(() => mockPlatform.stopCasting(any())).thenAnswer((_) async => true);

        final stopped = await manager.stopCasting();

        expect(stopped, isTrue);
      });
    });
  });
}
