import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/gestures/volume_gesture_manager.dart';

// Mock callbacks
class MockGetDeviceVolume extends Mock {
  Future<double> call();
}

class MockSetDeviceVolume extends Mock {
  Future<void> call(double volume);
}

class MockDoubleSetter extends Mock {
  void call(double? value);
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(0.0);
  });

  group('VolumeGestureManager', () {
    late VolumeGestureManager manager;
    late MockGetDeviceVolume mockGetDeviceVolume;
    late MockSetDeviceVolume mockSetDeviceVolume;
    late MockDoubleSetter mockSetCurrentVolume;

    setUp(() {
      mockGetDeviceVolume = MockGetDeviceVolume();
      mockSetDeviceVolume = MockSetDeviceVolume();
      mockSetCurrentVolume = MockDoubleSetter();

      manager = VolumeGestureManager(
        getDeviceVolume: mockGetDeviceVolume.call,
        setDeviceVolume: mockSetDeviceVolume.call,
        setCurrentVolume: mockSetCurrentVolume.call,
      );

      // Default mock responses
      when(() => mockGetDeviceVolume()).thenAnswer((_) async => 0.5);
      when(() => mockSetDeviceVolume(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      manager.dispose();
    });

    group('Start Volume Gesture', () {
      test('startVolumeGesture fetches device volume asynchronously', () async {
        // Arrange
        when(() => mockGetDeviceVolume()).thenAnswer((_) async => 0.7);

        // Act
        await manager.startVolumeGesture();
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockGetDeviceVolume()).called(1);
      });

      test('startVolumeGesture uses default 0.5 while fetching', () async {
        // Arrange
        final completer = Completer<double>();
        when(() => mockGetDeviceVolume()).thenAnswer((_) => completer.future);

        // Act
        await manager.startVolumeGesture();
        // Don't complete the future yet - should use default

        // Update volume before fetch completes
        manager.updateVolume(-100, 300); // Swipe up

        // Assert - Should use 0.5 as starting point
        verify(() => mockSetCurrentVolume(any(that: greaterThan(0.5)))).called(greaterThan(0));

        // Complete the future
        completer.complete(0.7);
      });
    });

    group('Update Volume', () {
      setUp(() async {
        await manager.startVolumeGesture();
      });

      test('negative deltaY (swipe up) increases volume', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = -150.0; // Swipe up half the screen

        // Act
        manager.updateVolume(deltaY, screenHeight);

        // Assert - Should increase from 0.5 by 0.5 (half screen) = 1.0
        verify(() => mockSetCurrentVolume(1)).called(1);
        verify(() => mockSetDeviceVolume(1)).called(1);
      });

      test('positive deltaY (swipe down) decreases volume', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = 150.0; // Swipe down half the screen

        // Act
        manager.updateVolume(deltaY, screenHeight);

        // Assert - Should decrease from 0.5 by 0.5 (half screen) = 0.0
        verify(() => mockSetCurrentVolume(0)).called(1);
        verify(() => mockSetDeviceVolume(0)).called(1);
      });

      test('volume is clamped to 0.0 (lower bound)', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = 600.0; // Swipe down 2x screen height

        // Act
        manager.updateVolume(deltaY, screenHeight);

        // Assert - Should be clamped to 0.0
        verify(() => mockSetCurrentVolume(0)).called(1);
        verify(() => mockSetDeviceVolume(0)).called(1);
      });

      test('volume is clamped to 1.0 (upper bound)', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = -600.0; // Swipe up 2x screen height

        // Act
        manager.updateVolume(deltaY, screenHeight);

        // Assert - Should be clamped to 1.0
        verify(() => mockSetCurrentVolume(1)).called(1);
        verify(() => mockSetDeviceVolume(1)).called(1);
      });

      test('multiple updateVolume calls update progressively', () {
        // Arrange
        const screenHeight = 300.0;

        // Act
        manager.updateVolume(-30, screenHeight); // +0.1 → 0.6
        manager.updateVolume(-60, screenHeight); // +0.2 total → 0.7
        manager.updateVolume(-90, screenHeight); // +0.3 total → 0.8

        // Assert
        verify(() => mockSetCurrentVolume(0.6)).called(1);
        verify(() => mockSetCurrentVolume(0.7)).called(1);
        verify(() => mockSetCurrentVolume(0.8)).called(1);
      });
    });

    group('End Volume Gesture', () {
      test('endVolumeGesture clears state', () async {
        // Arrange
        await manager.startVolumeGesture();
        manager.updateVolume(-100, 300);

        // Act
        manager.endVolumeGesture();

        // Assert
        verify(() => mockSetCurrentVolume(null)).called(1);
      });

      test('endVolumeGesture can be called without startVolumeGesture', () {
        // Act
        manager.endVolumeGesture();

        // Assert - Should not crash
        verify(() => mockSetCurrentVolume(null)).called(1);
      });
    });

    group('Edge Cases', () {
      test('updateVolume before startVolumeGesture does nothing', () {
        // Act
        manager.updateVolume(-100, 300);

        // Assert - Should not crash or call anything
        verifyNever(() => mockSetDeviceVolume(any()));
      });
    });
  });
}
