import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/gestures/brightness_gesture_manager.dart';

// Mock callbacks
class MockGetScreenBrightness extends Mock {
  Future<double> call();
}

class MockSetScreenBrightness extends Mock {
  Future<void> call(double brightness);
}

class MockDoubleSetter extends Mock {
  void call(double? value);
}

class MockDoubleCallback extends Mock {
  void call(double value);
}

class MockBoolGetter extends Mock {
  bool call();
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(0.0);
  });

  group('BrightnessGestureManager', () {
    late BrightnessGestureManager manager;
    late MockGetScreenBrightness mockGetScreenBrightness;
    late MockSetScreenBrightness mockSetScreenBrightness;
    late MockDoubleSetter mockSetCurrentBrightness;
    late MockDoubleCallback mockOnBrightnessChanged;
    late MockBoolGetter mockIsBrightnessSupported;

    setUp(() {
      mockGetScreenBrightness = MockGetScreenBrightness();
      mockSetScreenBrightness = MockSetScreenBrightness();
      mockSetCurrentBrightness = MockDoubleSetter();
      mockOnBrightnessChanged = MockDoubleCallback();
      mockIsBrightnessSupported = MockBoolGetter();

      manager = BrightnessGestureManager(
        getScreenBrightness: mockGetScreenBrightness.call,
        setScreenBrightness: mockSetScreenBrightness.call,
        setCurrentBrightness: mockSetCurrentBrightness.call,
        onBrightnessChanged: mockOnBrightnessChanged.call,
        isBrightnessSupported: mockIsBrightnessSupported.call,
      );

      // Default mock responses
      when(() => mockGetScreenBrightness()).thenAnswer((_) async => 0.5);
      when(() => mockSetScreenBrightness(any())).thenAnswer((_) async {});
      when(() => mockIsBrightnessSupported()).thenReturn(true);
    });

    tearDown(() {
      manager.dispose();
    });

    group('Start Brightness Gesture', () {
      test('startBrightnessGesture fetches screen brightness asynchronously', () async {
        // Arrange
        when(() => mockGetScreenBrightness()).thenAnswer((_) async => 0.7);

        // Act
        await manager.startBrightnessGesture();
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockGetScreenBrightness()).called(1);
      });

      test('startBrightnessGesture uses default 0.5 while fetching', () async {
        // Arrange
        final completer = Completer<double>();
        when(() => mockGetScreenBrightness()).thenAnswer((_) => completer.future);

        // Act
        await manager.startBrightnessGesture();

        // Update brightness before fetch completes
        manager.updateBrightness(-100, 300); // Swipe up

        // Assert - Should use 0.5 as starting point
        verify(() => mockSetCurrentBrightness(any(that: greaterThan(0.5)))).called(greaterThan(0));

        // Complete the future
        completer.complete(0.7);
      });
    });

    group('Update Brightness', () {
      setUp(() async {
        await manager.startBrightnessGesture();
      });

      test('negative deltaY (swipe up) increases brightness', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = -150.0; // Swipe up half the screen

        // Act
        manager.updateBrightness(deltaY, screenHeight);

        // Assert - Should increase from 0.5 by 0.5 (half screen) = 1.0
        verify(() => mockSetCurrentBrightness(1)).called(1);
        verify(() => mockSetScreenBrightness(1)).called(1);
        verify(() => mockOnBrightnessChanged(1)).called(1);
      });

      test('positive deltaY (swipe down) decreases brightness', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = 150.0; // Swipe down half the screen

        // Act
        manager.updateBrightness(deltaY, screenHeight);

        // Assert - Should decrease from 0.5 by 0.5 (half screen) = 0.0
        verify(() => mockSetCurrentBrightness(0)).called(1);
        verify(() => mockSetScreenBrightness(0)).called(1);
        verify(() => mockOnBrightnessChanged(0)).called(1);
      });

      test('brightness is clamped to 0.0 (lower bound)', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = 600.0; // Swipe down 2x screen height

        // Act
        manager.updateBrightness(deltaY, screenHeight);

        // Assert - Should be clamped to 0.0
        verify(() => mockSetCurrentBrightness(0)).called(1);
        verify(() => mockSetScreenBrightness(0)).called(1);
      });

      test('brightness is clamped to 1.0 (upper bound)', () {
        // Arrange
        const screenHeight = 300.0;
        const deltaY = -600.0; // Swipe up 2x screen height

        // Act
        manager.updateBrightness(deltaY, screenHeight);

        // Assert - Should be clamped to 1.0
        verify(() => mockSetCurrentBrightness(1)).called(1);
        verify(() => mockSetScreenBrightness(1)).called(1);
      });

      test('multiple updateBrightness calls update progressively', () {
        // Arrange
        const screenHeight = 300.0;

        // Act
        manager.updateBrightness(-30, screenHeight); // +0.1 → 0.6
        manager.updateBrightness(-60, screenHeight); // +0.2 total → 0.7
        manager.updateBrightness(-90, screenHeight); // +0.3 total → 0.8

        // Assert
        verify(() => mockSetCurrentBrightness(0.6)).called(1);
        verify(() => mockSetCurrentBrightness(0.7)).called(1);
        verify(() => mockSetCurrentBrightness(0.8)).called(1);
      });
    });

    group('End Brightness Gesture', () {
      test('endBrightnessGesture clears state', () async {
        // Arrange
        await manager.startBrightnessGesture();
        manager.updateBrightness(-100, 300);

        // Act
        manager.endBrightnessGesture();

        // Assert
        verify(() => mockSetCurrentBrightness(null)).called(1);
      });

      test('endBrightnessGesture can be called without startBrightnessGesture', () {
        // Act
        manager.endBrightnessGesture();

        // Assert - Should not crash
        verify(() => mockSetCurrentBrightness(null)).called(1);
      });
    });

    group('Edge Cases', () {
      test('updateBrightness before startBrightnessGesture does nothing', () {
        // Act
        manager.updateBrightness(-100, 300);

        // Assert - Should not crash or call anything
        verifyNever(() => mockSetScreenBrightness(any()));
      });
    });
  });
}
