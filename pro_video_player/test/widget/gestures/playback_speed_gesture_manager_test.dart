import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/gestures/playback_speed_gesture_manager.dart';

// Mock callbacks
class MockDoubleGetter extends Mock {
  double call();
}

class MockSetPlaybackSpeed extends Mock {
  Future<void> call(double speed);
}

class MockDoubleSetter extends Mock {
  void call(double? value);
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(0.0);
  });

  group('PlaybackSpeedGestureManager', () {
    late PlaybackSpeedGestureManager manager;
    late MockDoubleGetter mockGetPlaybackSpeed;
    late MockSetPlaybackSpeed mockSetPlaybackSpeed;
    late MockDoubleSetter mockSetCurrentSpeed;

    setUp(() {
      mockGetPlaybackSpeed = MockDoubleGetter();
      mockSetPlaybackSpeed = MockSetPlaybackSpeed();
      mockSetCurrentSpeed = MockDoubleSetter();

      manager = PlaybackSpeedGestureManager(
        getPlaybackSpeed: mockGetPlaybackSpeed.call,
        setPlaybackSpeed: mockSetPlaybackSpeed.call,
        setCurrentSpeed: mockSetCurrentSpeed.call,
      );

      // Default mock responses
      when(() => mockSetPlaybackSpeed(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      manager.dispose();
    });

    group('Start Speed Gesture', () {
      test('dragStartSpeed stores initial speed', () {
        // Arrange
        const startSpeed = 1.5;

        // Act
        manager.dragStartSpeed = startSpeed;

        // Assert - No immediate side effects
        verifyNever(() => mockSetPlaybackSpeed(any()));
      });
    });

    group('Update Speed', () {
      setUp(() {
        manager.dragStartSpeed = 1; // Start at 1x
      });

      test('negative deltaY (swipe up) increases speed', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = -150.0; // Swipe up half the screen

        // Act
        manager.updateSpeed(deltaY, screenHeight);

        // Assert - Should increase from 1.0 by 0.5 (half screen) = 1.5
        verify(() => mockSetCurrentSpeed(1.5)).called(1);
        verify(() => mockSetPlaybackSpeed(1.5)).called(1);
      });

      test('positive deltaY (swipe down) decreases speed', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = 150.0; // Swipe down half the screen

        // Act
        manager.updateSpeed(deltaY, screenHeight);

        // Assert - Should decrease from 1.0 by 0.5 (half screen) = 0.5
        verify(() => mockSetCurrentSpeed(0.5)).called(1);
        verify(() => mockSetPlaybackSpeed(0.5)).called(1);
      });

      test('speed is clamped to 0.25 (lower bound)', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = 600.0; // Swipe down 2x screen height

        // Act
        manager.updateSpeed(deltaY, screenHeight);

        // Assert - Should be clamped to 0.25
        verify(() => mockSetCurrentSpeed(0.25)).called(1);
        verify(() => mockSetPlaybackSpeed(0.25)).called(1);
      });

      test('speed is clamped to 3.0 (upper bound)', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = -900.0; // Swipe up 3x screen height

        // Act
        manager.updateSpeed(deltaY, screenHeight);

        // Assert - Should be clamped to 3.0
        verify(() => mockSetCurrentSpeed(3)).called(1);
        verify(() => mockSetPlaybackSpeed(3)).called(1);
      });

      test('speed is rounded to 0.05 intervals', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = -10.0; // Small upward movement

        // Act
        manager.updateSpeed(deltaY, screenHeight);

        // Assert - Should round to nearest 0.05
        // 1.0 + (10/300) ≈ 1.033 → rounds to 1.05
        verify(() => mockSetCurrentSpeed(1.05)).called(1);
      });

      test('multiple updateSpeed calls update progressively', () {
        // Arrange
        const screenHeight = 300.0;

        // Act
        manager.updateSpeed(-30, screenHeight); // +0.1 → 1.1 → rounds to 1.1
        manager.updateSpeed(-60, screenHeight); // +0.2 total → 1.2
        manager.updateSpeed(-90, screenHeight); // +0.3 total → 1.3

        // Assert
        verify(() => mockSetCurrentSpeed(1.1)).called(1);
        verify(() => mockSetCurrentSpeed(1.2)).called(1);
        verify(() => mockSetCurrentSpeed(1.3)).called(1);
      });
    });

    group('End Speed Gesture', () {
      test('endSpeedGesture clears state', () {
        // Arrange
        manager.dragStartSpeed = 1;
        manager.updateSpeed(-100, 300);

        // Act
        manager.endSpeedGesture();

        // Assert
        verify(() => mockSetCurrentSpeed(null)).called(1);
      });

      test('endSpeedGesture can be called without startSpeedGesture', () {
        // Act
        manager.endSpeedGesture();

        // Assert - Should not crash
        verify(() => mockSetCurrentSpeed(null)).called(1);
      });
    });

    group('Edge Cases', () {
      test('updateSpeed before startSpeedGesture does nothing', () {
        // Act
        manager.updateSpeed(-100, 300);

        // Assert - Should not crash or call anything
        verifyNever(() => mockSetPlaybackSpeed(any()));
      });

      test('speed rounds correctly at boundaries', () {
        // Test various rounding scenarios
        manager.dragStartSpeed = 1;

        // 1.0 + 0.023 = 1.023 → should round to 1.0
        manager.updateSpeed(-6.9, 300);
        verify(() => mockSetCurrentSpeed(1)).called(1);

        // 1.0 + 0.026 = 1.026 → should round to 1.05
        manager.updateSpeed(-7.8, 300);
        verify(() => mockSetCurrentSpeed(1.05)).called(1);
      });
    });
  });
}
