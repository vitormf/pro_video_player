import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/gestures/seek_gesture_manager.dart';

// Mock callbacks
class MockDurationGetter extends Mock {
  Duration call();
}

class MockBoolGetter extends Mock {
  bool call();
}

class MockDurationSetter extends Mock {
  void call(Duration? duration);
}

class MockSeekTo extends Mock {
  Future<void> call(Duration position);
}

class MockAsyncVoidCallback extends Mock {
  Future<void> call();
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Duration.zero);
  });

  group('SeekGestureManager', () {
    late SeekGestureManager manager;
    late MockDurationGetter mockGetCurrentPosition;
    late MockDurationGetter mockGetDuration;
    late MockBoolGetter mockGetIsPlaying;
    late MockDurationSetter mockSetSeekTarget;
    late MockDurationSetter mockOnSeekGestureUpdate;
    late MockSeekTo mockSeekTo;
    late MockAsyncVoidCallback mockPause;
    late MockAsyncVoidCallback mockPlay;

    const defaultSeekSecondsPerInch = 20.0;

    setUp(() {
      mockGetCurrentPosition = MockDurationGetter();
      mockGetDuration = MockDurationGetter();
      mockGetIsPlaying = MockBoolGetter();
      mockSetSeekTarget = MockDurationSetter();
      mockOnSeekGestureUpdate = MockDurationSetter();
      mockSeekTo = MockSeekTo();
      mockPause = MockAsyncVoidCallback();
      mockPlay = MockAsyncVoidCallback();

      manager = SeekGestureManager(
        getCurrentPosition: mockGetCurrentPosition.call,
        getDuration: mockGetDuration.call,
        getIsPlaying: mockGetIsPlaying.call,
        seekSecondsPerInch: defaultSeekSecondsPerInch,
        setSeekTarget: mockSetSeekTarget.call,
        seekTo: mockSeekTo.call,
        pause: mockPause.call,
        play: mockPlay.call,
        onSeekGestureUpdate: mockOnSeekGestureUpdate.call,
      );

      // Default mock responses
      when(() => mockGetDuration()).thenReturn(const Duration(seconds: 100));
      when(() => mockSeekTo(any())).thenAnswer((_) async {});
      when(() => mockPause()).thenAnswer((_) async {});
      when(() => mockPlay()).thenAnswer((_) async {});
    });

    tearDown(() {
      manager.dispose();
    });

    group('Start Seek', () {
      test('startSeek pauses video if playing', () async {
        // Arrange
        const startPosition = Duration(seconds: 50);
        const isPlaying = true;

        // Act
        manager.startSeek(startPosition, isPlaying: isPlaying);
        await Future<void>.delayed(Duration.zero); // Allow async operations

        // Assert
        verify(() => mockPause()).called(1);
      });

      test('startSeek does not pause if already paused', () async {
        // Arrange
        const startPosition = Duration(seconds: 50);
        const isPlaying = false;

        // Act
        manager.startSeek(startPosition, isPlaying: isPlaying);
        await Future<void>.delayed(Duration.zero);

        // Assert
        verifyNever(() => mockPause());
      });
    });

    group('Update Seek', () {
      setUp(() {
        // Start a seek gesture at 50 seconds
        manager.startSeek(const Duration(seconds: 50), isPlaying: false);
      });

      test('positive horizontal delta seeks forward', () {
        // Arrange
        const screenWidth = 400.0;
        // 160px = 1 inch, 20 seconds/inch
        // 160px delta = 1 inch = 20 seconds forward
        const deltaX = 160.0;

        // Act
        manager.updateSeek(deltaX, screenWidth);

        // Assert
        verify(() => mockSetSeekTarget(const Duration(seconds: 70))).called(1);
        verify(() => mockOnSeekGestureUpdate(const Duration(seconds: 70))).called(1);
      });

      test('negative horizontal delta seeks backward', () {
        // Arrange
        const screenWidth = 400.0;
        // -160px = -1 inch = -20 seconds backward
        const deltaX = -160.0;

        // Act
        manager.updateSeek(deltaX, screenWidth);

        // Assert
        verify(() => mockSetSeekTarget(const Duration(seconds: 30))).called(1);
        verify(() => mockOnSeekGestureUpdate(const Duration(seconds: 30))).called(1);
      });

      test('seek is clamped to zero (lower bound)', () {
        // Arrange
        const screenWidth = 400.0;
        // -800px = -5 inches = -100 seconds (would go to -50, clamped to 0)
        const deltaX = -800.0;

        // Act
        manager.updateSeek(deltaX, screenWidth);

        // Assert
        verify(() => mockSetSeekTarget(Duration.zero)).called(1);
      });

      test('seek is clamped to duration (upper bound)', () {
        // Arrange
        const screenWidth = 400.0;
        // +800px = +5 inches = +100 seconds (would go to 150, clamped to 100)
        const deltaX = 800.0;

        // Act
        manager.updateSeek(deltaX, screenWidth);

        // Assert
        verify(() => mockSetSeekTarget(const Duration(seconds: 100))).called(1);
      });

      test('custom seekSecondsPerInch changes sensitivity', () {
        // Arrange
        manager.dispose();
        manager = SeekGestureManager(
          getCurrentPosition: mockGetCurrentPosition.call,
          getDuration: mockGetDuration.call,
          getIsPlaying: mockGetIsPlaying.call,
          seekSecondsPerInch: 10, // Half the default sensitivity
          setSeekTarget: mockSetSeekTarget.call,
          seekTo: mockSeekTo.call,
          pause: mockPause.call,
          play: mockPlay.call,
          onSeekGestureUpdate: mockOnSeekGestureUpdate.call,
        );
        manager.startSeek(const Duration(seconds: 50), isPlaying: false);

        const screenWidth = 400.0;
        const deltaX = 160.0; // 1 inch

        // Act
        manager.updateSeek(deltaX, screenWidth);

        // Assert - Should be 10 seconds instead of 20
        verify(() => mockSetSeekTarget(const Duration(seconds: 60))).called(1);
      });

      test('multiple updateSeek calls update target progressively', () {
        // Arrange
        const screenWidth = 400.0;

        // Act - Drag in increments
        manager.updateSeek(80, screenWidth); // +0.5 inch = +10 sec → 60
        manager.updateSeek(160, screenWidth); // +1 inch total = +20 sec → 70
        manager.updateSeek(240, screenWidth); // +1.5 inches total = +30 sec → 80

        // Assert - Each call updates the target
        verify(() => mockSetSeekTarget(const Duration(seconds: 60))).called(1);
        verify(() => mockSetSeekTarget(const Duration(seconds: 70))).called(1);
        verify(() => mockSetSeekTarget(const Duration(seconds: 80))).called(1);
      });
    });

    group('End Seek', () {
      test('endSeek commits seek to target position', () async {
        // Arrange
        manager.startSeek(const Duration(seconds: 50), isPlaying: false);
        manager.updateSeek(160, 400); // Seek to 70 seconds

        // Act
        await manager.endSeek();
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockSeekTo(const Duration(seconds: 70))).called(1);
      });

      test('endSeek resumes playback if was playing before', () async {
        // Arrange
        manager.startSeek(const Duration(seconds: 50), isPlaying: true); // Was playing
        manager.updateSeek(160, 400);

        // Act
        await manager.endSeek();
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockSeekTo(any())).called(1);
        verify(() => mockPlay()).called(1);
      });

      test('endSeek does not resume if was paused before', () async {
        // Arrange
        manager.startSeek(const Duration(seconds: 50), isPlaying: false); // Was paused
        manager.updateSeek(160, 400);

        // Act
        await manager.endSeek();
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockSeekTo(any())).called(1);
        verifyNever(() => mockPlay());
      });

      test('endSeek clears seek target state', () async {
        // Arrange
        manager.startSeek(const Duration(seconds: 50), isPlaying: false);
        manager.updateSeek(160, 400);

        // Act
        await manager.endSeek();

        // Assert
        verify(() => mockSetSeekTarget(null)).called(1);
        verify(() => mockOnSeekGestureUpdate(null)).called(1);
      });

      test('endSeek without updateSeek seeks to start position', () async {
        // Arrange
        manager.startSeek(const Duration(seconds: 50), isPlaying: false);
        // No updateSeek called

        // Act
        await manager.endSeek();
        await Future<void>.delayed(Duration.zero);

        // Assert - Should seek to original position (no change)
        verify(() => mockSeekTo(const Duration(seconds: 50))).called(1);
      });
    });

    group('Cancel Seek', () {
      test('cancelSeek clears state without seeking', () {
        // Arrange
        manager.startSeek(const Duration(seconds: 50), isPlaying: true);
        manager.updateSeek(160, 400);

        // Act
        manager.cancelSeek();

        // Assert
        verify(() => mockSetSeekTarget(null)).called(1);
        verify(() => mockOnSeekGestureUpdate(null)).called(1);
        verifyNever(() => mockSeekTo(any()));
      });

      test('cancelSeek resumes playback if was playing', () async {
        // Arrange
        manager.startSeek(const Duration(seconds: 50), isPlaying: true);
        manager.updateSeek(160, 400);

        // Act
        manager.cancelSeek();
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockPlay()).called(1);
        verifyNever(() => mockSeekTo(any()));
      });

      test('cancelSeek does not resume if was paused', () async {
        // Arrange
        manager.startSeek(const Duration(seconds: 50), isPlaying: false);
        manager.updateSeek(160, 400);

        // Act
        manager.cancelSeek();
        await Future<void>.delayed(Duration.zero);

        // Assert
        verifyNever(() => mockPlay());
      });
    });

    group('Edge Cases', () {
      test('updateSeek before startSeek does nothing', () {
        // Act
        manager.updateSeek(160, 400);

        // Assert - Should not crash or call anything
        verifyNever(() => mockSetSeekTarget(any()));
      });

      test('endSeek before startSeek does nothing', () async {
        // Act
        await manager.endSeek();

        // Assert - Should not crash or call anything
        verifyNever(() => mockSeekTo(any()));
      });

      test('cancelSeek before startSeek does nothing', () {
        // Act
        manager.cancelSeek();

        // Assert - Should not crash or call anything
        verifyNever(() => mockSetSeekTarget(any()));
      });
    });
  });
}
