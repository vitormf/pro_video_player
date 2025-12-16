import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/controller/fullscreen_manager.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../shared/mocks.dart';
import '../../shared/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late FullscreenManager manager;
  late VideoPlayerValue value;
  late int? playerId;
  late VideoPlayerOptions options;
  late bool isInitialized;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    playerId = 1;
    options = const VideoPlayerOptions();
    isInitialized = true;
    value = const VideoPlayerValue();

    manager = FullscreenManager(
      getValue: () => value,
      setValue: (v) => value = v,
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

  group('FullscreenManager', () {
    group('enterFullscreen', () {
      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.enterFullscreen(), throwsStateError);
      });

      test('updates state to fullscreen', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        await manager.enterFullscreen();

        expect(value.isFullscreen, isTrue);
      });

      test('calls platform enterFullscreen', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        await manager.enterFullscreen();

        verify(() => mockPlatform.enterFullscreen(1)).called(1);
      });

      test('returns platform result', () async {
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        final result = await manager.enterFullscreen();

        expect(result, isTrue);
      });

      test('uses fullscreenOrientation from options when not specified', () async {
        options = const VideoPlayerOptions(fullscreenOrientation: FullscreenOrientation.landscapeLeft);
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        await manager.enterFullscreen();

        // State should be updated
        expect(value.isFullscreen, isTrue);
      });

      test('uses provided orientation parameter', () async {
        options = const VideoPlayerOptions(fullscreenOrientation: FullscreenOrientation.landscapeLeft);
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        await manager.enterFullscreen(orientation: FullscreenOrientation.portraitUp);

        // State should be updated
        expect(value.isFullscreen, isTrue);
      });
    });

    group('exitFullscreen', () {
      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.exitFullscreen(), throwsStateError);
      });

      test('updates state to not fullscreen', () async {
        value = value.copyWith(isFullscreen: true);
        when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

        await manager.exitFullscreen();

        expect(value.isFullscreen, isFalse);
      });

      test('calls platform exitFullscreen', () async {
        when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

        await manager.exitFullscreen();

        verify(() => mockPlatform.exitFullscreen(1)).called(1);
      });
    });

    group('toggleFullscreen', () {
      test('enters fullscreen when not fullscreen', () async {
        value = value.copyWith(isFullscreen: false);
        when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);

        await manager.toggleFullscreen();

        expect(value.isFullscreen, isTrue);
        verify(() => mockPlatform.enterFullscreen(1)).called(1);
      });

      test('exits fullscreen when fullscreen', () async {
        value = value.copyWith(isFullscreen: true);
        when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});

        await manager.toggleFullscreen();

        expect(value.isFullscreen, isFalse);
        verify(() => mockPlatform.exitFullscreen(1)).called(1);
      });
    });

    group('setFlutterFullscreenState', () {
      test('updates state without calling platform', () {
        manager.setFlutterFullscreenState(isFullscreen: true);

        expect(value.isFullscreen, isTrue);
        verifyNever(() => mockPlatform.enterFullscreen(any()));
        verifyNever(() => mockPlatform.exitFullscreen(any()));
      });

      test('can set to false', () {
        value = value.copyWith(isFullscreen: true);

        manager.setFlutterFullscreenState(isFullscreen: false);

        expect(value.isFullscreen, isFalse);
      });

      test('can set to true', () {
        manager.setFlutterFullscreenState(isFullscreen: true);

        expect(value.isFullscreen, isTrue);
      });
    });

    group('lockOrientation', () {
      test('updates lockedOrientation state', () async {
        await manager.lockOrientation(FullscreenOrientation.landscapeLeft);

        expect(value.lockedOrientation, equals(FullscreenOrientation.landscapeLeft));
      });

      test('can lock to different orientations', () async {
        await manager.lockOrientation(FullscreenOrientation.portraitUp);
        expect(value.lockedOrientation, equals(FullscreenOrientation.portraitUp));

        await manager.lockOrientation(FullscreenOrientation.landscapeRight);
        expect(value.lockedOrientation, equals(FullscreenOrientation.landscapeRight));
      });
    });

    group('unlockOrientation', () {
      test('clears lockedOrientation when in fullscreen', () async {
        value = value.copyWith(isFullscreen: true, lockedOrientation: FullscreenOrientation.landscapeLeft);

        await manager.unlockOrientation();

        expect(value.lockedOrientation, isNull);
      });

      test('clears lockedOrientation when not in fullscreen', () async {
        value = value.copyWith(isFullscreen: false, lockedOrientation: FullscreenOrientation.landscapeLeft);

        await manager.unlockOrientation();

        expect(value.lockedOrientation, isNull);
      });
    });

    group('toggleOrientationLock', () {
      test('locks orientation when unlocked', () async {
        value = value.copyWith();

        await manager.toggleOrientationLock();

        expect(value.isOrientationLocked, isTrue);
        expect(value.lockedOrientation, equals(FullscreenOrientation.landscapeBoth));
      });

      test('unlocks orientation when locked', () async {
        value = value.copyWith(lockedOrientation: FullscreenOrientation.landscapeLeft);

        await manager.toggleOrientationLock();

        expect(value.isOrientationLocked, isFalse);
        expect(value.lockedOrientation, isNull);
      });
    });

    group('cycleOrientationLock', () {
      test('cycles from unlocked to landscapeBoth', () async {
        value = value.copyWith();

        await manager.cycleOrientationLock();

        expect(value.lockedOrientation, equals(FullscreenOrientation.landscapeBoth));
      });

      test('cycles from landscapeBoth to landscapeLeft', () async {
        value = value.copyWith(lockedOrientation: FullscreenOrientation.landscapeBoth);

        await manager.cycleOrientationLock();

        expect(value.lockedOrientation, equals(FullscreenOrientation.landscapeLeft));
      });

      test('cycles from landscapeLeft to landscapeRight', () async {
        value = value.copyWith(lockedOrientation: FullscreenOrientation.landscapeLeft);

        await manager.cycleOrientationLock();

        expect(value.lockedOrientation, equals(FullscreenOrientation.landscapeRight));
      });

      test('cycles from landscapeRight to unlocked', () async {
        value = value.copyWith(lockedOrientation: FullscreenOrientation.landscapeRight);

        await manager.cycleOrientationLock();

        expect(value.lockedOrientation, isNull);
      });

      test('cycles from portraitUp to unlocked', () async {
        value = value.copyWith(lockedOrientation: FullscreenOrientation.portraitUp);

        await manager.cycleOrientationLock();

        expect(value.lockedOrientation, isNull);
      });

      test('cycles from portraitDown to unlocked', () async {
        value = value.copyWith(lockedOrientation: FullscreenOrientation.portraitDown);

        await manager.cycleOrientationLock();

        expect(value.lockedOrientation, isNull);
      });

      test('cycles from portraitBoth to unlocked', () async {
        value = value.copyWith(lockedOrientation: FullscreenOrientation.portraitBoth);

        await manager.cycleOrientationLock();

        expect(value.lockedOrientation, isNull);
      });

      test('cycles from all to unlocked', () async {
        value = value.copyWith(lockedOrientation: FullscreenOrientation.all);

        await manager.cycleOrientationLock();

        expect(value.lockedOrientation, isNull);
      });
    });
  });
}
