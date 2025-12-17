import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/gestures/tap_gesture_manager.dart';

import '../../shared/test_constants.dart';

// Mock callbacks
class MockVoidCallback extends Mock {
  void call();
}

class MockOffsetCallback extends Mock {
  void call(Offset offset);
}

class MockBoolGetter extends Mock {
  bool call();
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Offset.zero);
  });

  group('TapGestureManager', () {
    late TapGestureManager manager;
    late MockVoidCallback mockOnSingleTap;
    late MockOffsetCallback mockOnDoubleTapLeft;
    late MockOffsetCallback mockOnDoubleTapCenter;
    late MockOffsetCallback mockOnDoubleTapRight;
    late MockBoolGetter mockGetControlsVisible;
    late MockVoidCallback mockSetControlsVisibleTrue;
    late MockVoidCallback mockSetControlsVisibleFalse;
    late MockBoolGetter mockGetIsPlaying;
    late BuildContext mockContext;

    setUp(() {
      mockOnSingleTap = MockVoidCallback();
      mockOnDoubleTapLeft = MockOffsetCallback();
      mockOnDoubleTapCenter = MockOffsetCallback();
      mockOnDoubleTapRight = MockOffsetCallback();
      mockGetControlsVisible = MockBoolGetter();
      mockSetControlsVisibleTrue = MockVoidCallback();
      mockSetControlsVisibleFalse = MockVoidCallback();
      mockGetIsPlaying = MockBoolGetter();

      // Create a mock context with a render box
      mockContext = _buildMockContext();

      manager = TapGestureManager(
        onSingleTap: mockOnSingleTap.call,
        onDoubleTapLeft: mockOnDoubleTapLeft.call,
        onDoubleTapCenter: mockOnDoubleTapCenter.call,
        onDoubleTapRight: mockOnDoubleTapRight.call,
        getControlsVisible: mockGetControlsVisible.call,
        setControlsVisible: ({required visible}) {
          if (visible) {
            mockSetControlsVisibleTrue.call();
          } else {
            mockSetControlsVisibleFalse.call();
          }
        },
        getIsPlaying: mockGetIsPlaying.call,
        autoHideEnabled: true,
        autoHideDelay: TestDelays.autoHideControls,
        doubleTapEnabled: true,
        context: mockContext,
      );

      // Default mock responses
      when(() => mockGetControlsVisible()).thenReturn(false);
      when(() => mockGetIsPlaying()).thenReturn(false);
    });

    tearDown(() {
      manager.dispose();
    });

    group('Single Tap Detection', () {
      test('single tap triggers callback after double-tap timeout', () async {
        // Arrange
        when(() => mockGetControlsVisible()).thenReturn(false);

        // Act
        manager.handleTap(const Offset(200, 150)); // Center tap
        await Future<void>.delayed(TestDelays.doubleTap); // Wait for double-tap timeout

        // Assert
        verify(() => mockOnSingleTap()).called(1);
        verifyNever(() => mockOnDoubleTapLeft(any()));
        verifyNever(() => mockOnDoubleTapCenter(any()));
        verifyNever(() => mockOnDoubleTapRight(any()));
      });

      test('single tap shows controls when hidden', () async {
        // Arrange
        when(() => mockGetControlsVisible()).thenReturn(false);

        // Act
        manager.handleTap(const Offset(200, 150));
        await Future<void>.delayed(TestDelays.doubleTap);

        // Assert
        verify(() => mockSetControlsVisibleTrue()).called(1);
      });

      test('single tap toggles controls when visible', () async {
        // Arrange
        when(() => mockGetControlsVisible()).thenReturn(true);

        // Act
        manager.handleTap(const Offset(200, 150));
        await Future<void>.delayed(TestDelays.doubleTap);

        // Assert
        verify(() => mockOnSingleTap()).called(1);
      });
    });

    group('Double Tap Detection', () {
      test('double tap within timeout triggers double tap callback', () async {
        // Arrange
        const leftPosition = Offset(50, 150); // Left 30%

        // Act
        manager.handleTap(leftPosition); // First tap
        await Future<void>.delayed(TestDelays.stateUpdate); // 100ms < 300ms
        manager.handleTap(leftPosition); // Second tap
        await Future<void>.delayed(TestDelays.singleFrame);

        // Assert
        verify(() => mockOnDoubleTapLeft(leftPosition)).called(1);
        verifyNever(() => mockOnSingleTap());
      });

      test('double tap cancels single tap timer', () async {
        // Arrange
        const centerPosition = Offset(200, 150);

        // Act
        manager.handleTap(centerPosition); // First tap
        await Future<void>.delayed(TestDelays.stateUpdate); // 100ms
        manager.handleTap(centerPosition); // Second tap (cancels timer)
        await Future<void>.delayed(TestDelays.doubleTap); // Wait full timeout

        // Assert
        verify(() => mockOnDoubleTapCenter(centerPosition)).called(1);
        verifyNever(() => mockOnSingleTap()); // Single tap should NOT fire
      });
    });

    group('Double Tap Zone Classification', () {
      test('double tap on left side (<=30%) triggers seek backward', () async {
        // Arrange
        const leftPosition = Offset(100, 150); // ~25% of 400px width

        // Act
        manager.handleTap(leftPosition);
        await Future<void>.delayed(TestDelays.stateUpdate);
        manager.handleTap(leftPosition);
        await Future<void>.delayed(TestDelays.singleFrame);

        // Assert
        verify(() => mockOnDoubleTapLeft(leftPosition)).called(1);
        verifyNever(() => mockOnDoubleTapCenter(any()));
        verifyNever(() => mockOnDoubleTapRight(any()));
      });

      test('double tap on center (30-70%) triggers play/pause', () async {
        // Arrange
        const centerPosition = Offset(200, 150); // 50% of 400px width

        // Act
        manager.handleTap(centerPosition);
        await Future<void>.delayed(TestDelays.stateUpdate);
        manager.handleTap(centerPosition);
        await Future<void>.delayed(TestDelays.singleFrame);

        // Assert
        verify(() => mockOnDoubleTapCenter(centerPosition)).called(1);
        verifyNever(() => mockOnDoubleTapLeft(any()));
        verifyNever(() => mockOnDoubleTapRight(any()));
      });

      test('double tap on right side (>=70%) triggers seek forward', () async {
        // Arrange
        const rightPosition = Offset(300, 150); // 75% of 400px width

        // Act
        manager.handleTap(rightPosition);
        await Future<void>.delayed(TestDelays.stateUpdate);
        manager.handleTap(rightPosition);
        await Future<void>.delayed(TestDelays.singleFrame);

        // Assert
        verify(() => mockOnDoubleTapRight(rightPosition)).called(1);
        verifyNever(() => mockOnDoubleTapLeft(any()));
        verifyNever(() => mockOnDoubleTapCenter(any()));
      });

      test('double tap at left boundary (30%) triggers center action', () async {
        // Arrange
        const boundaryPosition = Offset(120, 150); // Exactly 30% of 400px

        // Act
        manager.handleTap(boundaryPosition);
        await Future<void>.delayed(TestDelays.stateUpdate);
        manager.handleTap(boundaryPosition);
        await Future<void>.delayed(TestDelays.singleFrame);

        // Assert - Should be treated as center (>30%)
        verify(() => mockOnDoubleTapCenter(boundaryPosition)).called(1);
      });

      test('double tap at right boundary (70%) triggers center action', () async {
        // Arrange
        const boundaryPosition = Offset(280, 150); // Exactly 70% of 400px

        // Act
        manager.handleTap(boundaryPosition);
        await Future<void>.delayed(TestDelays.stateUpdate);
        manager.handleTap(boundaryPosition);
        await Future<void>.delayed(TestDelays.singleFrame);

        // Assert - Should be treated as center (<70%)
        verify(() => mockOnDoubleTapCenter(boundaryPosition)).called(1);
      });
    });

    group('Auto-hide Timer', () {
      test('auto-hide timer hides controls after delay when playing', () async {
        // Arrange
        when(() => mockGetControlsVisible()).thenReturn(true);
        when(() => mockGetIsPlaying()).thenReturn(true);

        // Act
        manager.resetHideTimer();
        await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));

        // Assert
        verify(() => mockSetControlsVisibleFalse()).called(1);
      });

      test('auto-hide timer does not hide when paused', () async {
        // Arrange
        when(() => mockGetControlsVisible()).thenReturn(true);
        when(() => mockGetIsPlaying()).thenReturn(false); // Paused

        // Act
        manager.resetHideTimer();
        await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));

        // Assert
        verifyNever(() => mockSetControlsVisibleFalse());
      });

      test('auto-hide timer does not hide when controls are hidden', () async {
        // Arrange
        when(() => mockGetControlsVisible()).thenReturn(false);
        when(() => mockGetIsPlaying()).thenReturn(true);

        // Act
        manager.resetHideTimer();
        await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));

        // Assert
        verifyNever(() => mockSetControlsVisibleFalse());
      });

      test('reset hide timer cancels previous timer', () async {
        // Arrange
        when(() => mockGetControlsVisible()).thenReturn(true);
        when(() => mockGetIsPlaying()).thenReturn(true);

        // Act
        manager.resetHideTimer();
        await Future<void>.delayed(const Duration(seconds: 1));
        manager.resetHideTimer(); // Reset timer after 1 second
        await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 500));

        // Assert - Should NOT have hidden yet (timer was reset)
        verifyNever(() => mockSetControlsVisibleFalse());

        // Wait for the reset timer to complete
        await Future<void>.delayed(const Duration(milliseconds: 600));
        verify(() => mockSetControlsVisibleFalse()).called(1);
      });
    });

    group('Disabled Double Tap', () {
      setUp(() {
        manager.dispose();
        manager = TapGestureManager(
          onSingleTap: mockOnSingleTap.call,
          onDoubleTapLeft: mockOnDoubleTapLeft.call,
          onDoubleTapCenter: mockOnDoubleTapCenter.call,
          onDoubleTapRight: mockOnDoubleTapRight.call,
          getControlsVisible: mockGetControlsVisible.call,
          setControlsVisible: ({required visible}) {
            if (visible) {
              mockSetControlsVisibleTrue.call();
            } else {
              mockSetControlsVisibleFalse.call();
            }
          },
          getIsPlaying: mockGetIsPlaying.call,
          autoHideEnabled: true,
          autoHideDelay: TestDelays.autoHideControls,
          doubleTapEnabled: false, // DISABLED
          context: mockContext,
        );
      });

      test('double tap does nothing when disabled', () async {
        // Arrange
        const centerPosition = Offset(200, 150);

        // Act
        manager.handleTap(centerPosition);
        await Future<void>.delayed(TestDelays.stateUpdate);
        manager.handleTap(centerPosition);
        await Future<void>.delayed(TestDelays.singleFrame);

        // Assert
        verifyNever(() => mockOnDoubleTapCenter(any()));
        verifyNever(() => mockOnDoubleTapLeft(any()));
        verifyNever(() => mockOnDoubleTapRight(any()));
      });
    });

    group('Disposal', () {
      test('dispose cancels hide timer', () async {
        // Arrange
        when(() => mockGetControlsVisible()).thenReturn(true);
        when(() => mockGetIsPlaying()).thenReturn(true);

        // Act
        manager.resetHideTimer();
        await Future<void>.delayed(const Duration(seconds: 1));
        manager.dispose(); // Dispose after 1 second
        await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

        // Assert - Timer was cancelled, should not fire
        verifyNever(() => mockSetControlsVisibleFalse());
      });

      test('dispose cancels double-tap timer', () async {
        // Arrange
        const position = Offset(200, 150);

        // Act
        manager.handleTap(position); // Start single tap timer
        await Future<void>.delayed(TestDelays.stateUpdate);
        manager.dispose(); // Dispose before timer completes
        await Future<void>.delayed(TestDelays.doubleTap);

        // Assert - Timer was cancelled, should not fire
        verifyNever(() => mockOnSingleTap());
      });
    });
  });
}

/// Creates a mock BuildContext with a RenderBox for position calculations.
BuildContext _buildMockContext() {
  TestWidgetsFlutterBinding.ensureInitialized();
  return _MockBuildContext();
}

class _MockBuildContext extends Mock implements BuildContext {
  @override
  RenderObject? findRenderObject() => _MockRenderBox();
}

class _MockRenderBox extends Mock implements RenderBox {
  @override
  Size get size => const Size(400, 300);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => 'MockRenderBox';
}
