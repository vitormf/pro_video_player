import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/gestures/brightness_gesture_manager.dart';
import 'package:pro_video_player/src/gestures/gesture_coordinator.dart';
import 'package:pro_video_player/src/gestures/playback_speed_gesture_manager.dart';
import 'package:pro_video_player/src/gestures/seek_gesture_manager.dart';
import 'package:pro_video_player/src/gestures/tap_gesture_manager.dart';
import 'package:pro_video_player/src/gestures/volume_gesture_manager.dart';

// Mock managers
class MockTapGestureManager extends Mock implements TapGestureManager {}

class MockSeekGestureManager extends Mock implements SeekGestureManager {}

class MockVolumeGestureManager extends Mock implements VolumeGestureManager {}

class MockBrightnessGestureManager extends Mock implements BrightnessGestureManager {}

class MockPlaybackSpeedGestureManager extends Mock implements PlaybackSpeedGestureManager {}

// Mock callbacks for gesture coordinator
class MockGestureCallbacks extends Mock implements GestureCoordinatorCallbacks {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Offset.zero);
    registerFallbackValue(Duration.zero);
  });

  group('GestureCoordinator', () {
    late GestureCoordinator coordinator;
    late MockTapGestureManager mockTapManager;
    late MockSeekGestureManager mockSeekManager;
    late MockVolumeGestureManager mockVolumeManager;
    late MockBrightnessGestureManager mockBrightnessManager;
    late MockPlaybackSpeedGestureManager mockSpeedManager;
    late MockGestureCallbacks mockCallbacks;

    setUp(() {
      mockTapManager = MockTapGestureManager();
      mockSeekManager = MockSeekGestureManager();
      mockVolumeManager = MockVolumeGestureManager();
      mockBrightnessManager = MockBrightnessGestureManager();
      mockSpeedManager = MockPlaybackSpeedGestureManager();
      mockCallbacks = MockGestureCallbacks();

      // Default mock responses
      when(() => mockCallbacks.enableSeekGesture).thenReturn(true);
      when(() => mockCallbacks.enableVolumeGesture).thenReturn(true);
      when(() => mockCallbacks.enableBrightnessGesture).thenReturn(true);
      when(() => mockCallbacks.enablePlaybackSpeedGesture).thenReturn(true);
      when(() => mockCallbacks.sideGestureAreaFraction).thenReturn(0.25);
      when(() => mockCallbacks.bottomGestureExclusionHeight).thenReturn(80);
      when(() => mockCallbacks.verticalGestureThreshold).thenReturn(30);
      when(() => mockCallbacks.getControlsVisible()).thenReturn(true);
      when(() => mockCallbacks.setControlsVisible(visible: any(named: 'visible'))).thenReturn(null);

      when(() => mockVolumeManager.startVolumeGesture()).thenAnswer((_) async {});
      when(() => mockBrightnessManager.startBrightnessGesture()).thenAnswer((_) async {});

      // Mock getter methods used by coordinator (these are function fields, not methods)
      when(() => mockSeekManager.getCurrentPosition).thenReturn(() => const Duration(seconds: 10));
      when(() => mockSeekManager.getIsPlaying).thenReturn(() => true);
      when(() => mockSpeedManager.getPlaybackSpeed).thenReturn(() => 1.0);

      // Stub start methods
      when(() => mockSeekManager.startSeek(any(), isPlaying: any(named: 'isPlaying'))).thenReturn(null);

      // Stub tap manager methods
      when(() => mockTapManager.cancelDoubleTapTimer()).thenReturn(null);

      // Stub void/async methods to prevent null errors
      when(() => mockSeekManager.endSeek()).thenAnswer((_) async {});
      when(() => mockVolumeManager.endVolumeGesture()).thenReturn(null);
      when(() => mockBrightnessManager.endBrightnessGesture()).thenReturn(null);
      when(() => mockSpeedManager.endSpeedGesture()).thenReturn(null);

      coordinator = GestureCoordinator(
        tapManager: mockTapManager,
        seekManager: mockSeekManager,
        volumeManager: mockVolumeManager,
        brightnessManager: mockBrightnessManager,
        speedManager: mockSpeedManager,
        callbacks: mockCallbacks,
      );
    });

    tearDown(() {
      coordinator.dispose();
    });

    group('Pointer Tracking', () {
      test('tracks single pointer down and up', () {
        // Act
        coordinator.onPointerDown();
        expect(coordinator.pointerCount, 1);

        coordinator.onPointerUp();
        expect(coordinator.pointerCount, 0);
      });

      test('tracks multiple pointers', () {
        // Act
        coordinator.onPointerDown(); // 1
        coordinator.onPointerDown(); // 2
        expect(coordinator.pointerCount, 2);

        coordinator.onPointerUp(); // 1
        expect(coordinator.pointerCount, 1);

        coordinator.onPointerUp(); // 0
        expect(coordinator.pointerCount, 0);
      });

      test('pointer count never goes negative', () {
        // Act
        coordinator.onPointerUp(); // Should stay at 0
        expect(coordinator.pointerCount, 0);

        coordinator.onPointerUp(); // Should stay at 0
        expect(coordinator.pointerCount, 0);
      });
    });

    group('Gesture Start', () {
      test('stores start position on gesture start', () {
        // Arrange
        const position = Offset(100, 100);
        const screenSize = Size(400, 800);

        // Act
        coordinator.onGestureStart(position, screenSize);

        // Assert - start position stored (verified by subsequent movement)
        expect(coordinator.startPosition, position);
      });

      test('prepares for two-finger speed gesture', () {
        // Arrange
        coordinator.onPointerDown();
        coordinator.onPointerDown(); // 2 pointers

        // Act
        coordinator.onGestureStart(const Offset(200, 400), const Size(400, 800));

        // Assert - Speed gesture should be prepared (verified by movement)
        expect(coordinator.pointerCount, 2);
      });
    });

    group('Gesture Locking', () {
      test('locks to seek on horizontal movement', () {
        // Arrange
        const startPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Horizontal movement (deltaX > deltaY)
        coordinator.onGestureUpdate(const Offset(250, 400), screenSize);

        // Assert
        verify(() => mockSeekManager.startSeek(any(), isPlaying: any(named: 'isPlaying'))).called(1);
      });

      test('locks to volume on right-side vertical movement', () {
        // Arrange - Right side position (x > 75% of width)
        const startPos = Offset(350, 400); // 350/400 = 87.5% (right side)
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Vertical movement (deltaY > deltaX)
        coordinator.onGestureUpdate(const Offset(350, 350), screenSize);

        // Assert
        verify(() => mockVolumeManager.startVolumeGesture()).called(1);
        verify(() => mockVolumeManager.updateVolume(any(), any())).called(1);
      });

      test('locks to brightness on left-side vertical movement', () {
        // Arrange - Left side position (x < 25% of width)
        const startPos = Offset(50, 400); // 50/400 = 12.5% (left side)
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Vertical movement (deltaY > deltaX)
        coordinator.onGestureUpdate(const Offset(50, 350), screenSize);

        // Assert
        verify(() => mockBrightnessManager.startBrightnessGesture()).called(1);
        verify(() => mockBrightnessManager.updateBrightness(any(), any())).called(1);
      });

      test('locks to playback speed on two-finger vertical movement', () {
        // Arrange
        coordinator.onPointerDown();
        coordinator.onPointerDown(); // 2 pointers
        const startPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Vertical movement with 2 fingers
        coordinator.onGestureUpdate(const Offset(200, 350), screenSize);

        // Assert
        verify(() => mockSpeedManager.dragStartSpeed = any()).called(1);
        verify(() => mockSpeedManager.updateSpeed(any(), any())).called(1);
      });

      test('stays locked to first detected gesture', () {
        // Arrange - Start with horizontal movement (seek)
        const startPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);
        coordinator.onGestureUpdate(const Offset(250, 400), screenSize); // Lock to seek

        // Act - Try vertical movement (should stay locked to seek)
        coordinator.onGestureUpdate(const Offset(250, 350), screenSize);

        // Assert - Seek continues, no volume/brightness started
        verify(() => mockSeekManager.updateSeek(any(), any())).called(greaterThan(1));
        verifyNever(() => mockVolumeManager.startVolumeGesture());
        verifyNever(() => mockBrightnessManager.startBrightnessGesture());
      });
    });

    group('Threshold Enforcement', () {
      test('requires vertical threshold before activating volume gesture', () {
        // Arrange - Right side position
        const startPos = Offset(350, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Small vertical movement (below threshold)
        coordinator.onGestureUpdate(const Offset(350, 390), screenSize); // 10px

        // Assert - No gesture activated yet
        verifyNever(() => mockVolumeManager.startVolumeGesture());
      });

      test('activates volume gesture after exceeding threshold', () {
        // Arrange - Right side position
        const startPos = Offset(350, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Large vertical movement (above threshold of 30px)
        coordinator.onGestureUpdate(const Offset(350, 360), screenSize); // 40px

        // Assert
        verify(() => mockVolumeManager.startVolumeGesture()).called(1);
      });

      test('requires horizontal threshold before activating seek gesture', () {
        // Arrange - Center position
        const startPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Small horizontal movement (below 10px threshold)
        coordinator.onGestureUpdate(const Offset(205, 400), screenSize); // 5px

        // Assert - No seek started yet
        verifyNever(() => mockSeekManager.startSeek(any(), isPlaying: any(named: 'isPlaying')));
      });
    });

    group('Tap Detection', () {
      test('detects tap when no movement occurs', () {
        // Arrange
        const tapPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(tapPos, screenSize);

        // Act - End without movement
        coordinator.onGestureEnd();

        // Assert
        verify(() => mockTapManager.handleTap(tapPos)).called(1);
      });

      test('does not detect tap when gesture is locked', () {
        // Arrange - Lock to seek
        const startPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);
        coordinator.onGestureUpdate(const Offset(250, 400), screenSize); // Lock to seek

        // Act - End gesture
        coordinator.onGestureEnd();

        // Assert - Tap not detected, seek ended
        verifyNever(() => mockTapManager.handleTap(any()));
        verify(() => mockSeekManager.endSeek()).called(1);
      });
    });

    group('Gesture End', () {
      test('ends seek gesture', () {
        // Arrange - Lock to seek
        const startPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);
        coordinator.onGestureUpdate(const Offset(250, 400), screenSize);

        // Act
        coordinator.onGestureEnd();

        // Assert
        verify(() => mockSeekManager.endSeek()).called(1);
      });

      test('ends volume gesture', () {
        // Arrange - Lock to volume
        const startPos = Offset(350, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);
        coordinator.onGestureUpdate(const Offset(350, 350), screenSize);

        // Act
        coordinator.onGestureEnd();

        // Assert
        verify(() => mockVolumeManager.endVolumeGesture()).called(1);
      });

      test('ends brightness gesture', () {
        // Arrange - Lock to brightness
        const startPos = Offset(50, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);
        coordinator.onGestureUpdate(const Offset(50, 350), screenSize);

        // Act
        coordinator.onGestureEnd();

        // Assert
        verify(() => mockBrightnessManager.endBrightnessGesture()).called(1);
      });

      test('ends speed gesture', () {
        // Arrange - Lock to speed
        coordinator.onPointerDown();
        coordinator.onPointerDown();
        const startPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onGestureStart(startPos, screenSize);
        coordinator.onGestureUpdate(const Offset(200, 350), screenSize);

        // Act
        coordinator.onGestureEnd();

        // Assert
        verify(() => mockSpeedManager.endSpeedGesture()).called(1);
      });

      test('resets lock after gesture ends', () {
        // Arrange - Complete a seek gesture
        const startPos = Offset(200, 400);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);
        coordinator.onGestureUpdate(const Offset(250, 400), screenSize);
        coordinator.onGestureEnd();
        coordinator.onPointerUp(); // Reset pointer count

        // Act - Start new gesture (should be able to lock to different type)
        coordinator.onPointerDown();
        coordinator.onGestureStart(const Offset(350, 400), screenSize);
        coordinator.onGestureUpdate(const Offset(350, 350), screenSize);

        // Assert - Volume gesture activated (not seek)
        verify(() => mockVolumeManager.startVolumeGesture()).called(1);
      });
    });

    group('Bottom Exclusion Zone', () {
      test('does not activate seek gesture in bottom exclusion zone', () {
        // Arrange - Position in bottom 80 pixels (progress bar area)
        // screenSize = 800, exclusion = 80, so bottom zone starts at y = 720
        const startPos = Offset(200, 750); // In bottom exclusion zone
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Horizontal movement that would normally trigger seek
        coordinator.onGestureUpdate(const Offset(250, 750), screenSize);

        // Assert - Seek should NOT be started (let progress bar handle it)
        verifyNever(() => mockSeekManager.startSeek(any(), isPlaying: any(named: 'isPlaying')));
      });

      test('activates seek gesture above bottom exclusion zone', () {
        // Arrange - Position above bottom exclusion zone
        // screenSize = 800, exclusion = 80, so bottom zone starts at y = 720
        const startPos = Offset(200, 700); // Just above exclusion zone
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Horizontal movement
        coordinator.onGestureUpdate(const Offset(250, 700), screenSize);

        // Assert - Seek should be started normally
        verify(() => mockSeekManager.startSeek(any(), isPlaying: any(named: 'isPlaying'))).called(1);
      });

      test('does not activate volume gesture in bottom exclusion zone', () {
        // Arrange - Right side position in bottom exclusion zone
        const startPos = Offset(350, 750);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Vertical movement that would normally trigger volume
        coordinator.onGestureUpdate(const Offset(350, 700), screenSize);

        // Assert - Volume should NOT be started
        verifyNever(() => mockVolumeManager.startVolumeGesture());
      });

      test('does not activate brightness gesture in bottom exclusion zone', () {
        // Arrange - Left side position in bottom exclusion zone
        const startPos = Offset(50, 750);
        const screenSize = Size(400, 800);
        coordinator.onPointerDown();
        coordinator.onGestureStart(startPos, screenSize);

        // Act - Vertical movement that would normally trigger brightness
        coordinator.onGestureUpdate(const Offset(50, 700), screenSize);

        // Assert - Brightness should NOT be started
        verifyNever(() => mockBrightnessManager.startBrightnessGesture());
      });
    });

    group('Dispose', () {
      test('disposes all managers', () {
        // Act
        coordinator.dispose();

        // Assert
        verify(() => mockTapManager.dispose()).called(1);
        verify(() => mockSeekManager.dispose()).called(1);
        verify(() => mockVolumeManager.dispose()).called(1);
        verify(() => mockBrightnessManager.dispose()).called(1);
        verify(() => mockSpeedManager.dispose()).called(1);
      });
    });
  });
}
