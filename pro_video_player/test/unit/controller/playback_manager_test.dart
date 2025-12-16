import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/controller/playback_manager.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../shared/mocks.dart';
import '../../shared/test_constants.dart';
import '../../shared/test_setup.dart';

void main() {
  late PlaybackManager manager;
  late MockProVideoPlayerPlatform mockPlatform;
  late VideoPlayerValue currentValue;
  late int? playerId;
  late bool ensureInitializedCalled;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    currentValue = const VideoPlayerValue();
    playerId = 1;
    ensureInitializedCalled = false;

    manager = PlaybackManager(
      getValue: () => currentValue,
      setValue: (v) => currentValue = v,
      getPlayerId: () => playerId,
      platform: mockPlatform,
      ensureInitialized: () => ensureInitializedCalled = true,
    );
  });

  tearDown(() {
    manager.dispose();
  });

  group('PlaybackManager', () {
    group('play', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        await manager.play();

        expect(ensureInitializedCalled, isTrue);
      });

      test('calls platform play', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        await manager.play();

        verify(() => mockPlatform.play(1)).called(1);
      });

      test('sets isStartingPlayback flag', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        await manager.play();

        expect(manager.isStartingPlayback, isTrue);
      });

      test('updates state to playing optimistically', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});
        currentValue = const VideoPlayerValue(playbackState: PlaybackState.paused);

        await manager.play();

        expect(currentValue.playbackState, PlaybackState.playing);
      });

      test('clears isStartingPlayback after timeout', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});

        await manager.play();
        expect(manager.isStartingPlayback, isTrue);

        // Wait for timeout
        await Future<void>.delayed(TestDelays.playbackManagerTimer);

        expect(manager.isStartingPlayback, isFalse);
      });
    });

    group('pause', () {
      test('calls platform pause', () async {
        when(() => mockPlatform.pause(any())).thenAnswer((_) async {});

        await manager.pause();

        verify(() => mockPlatform.pause(1)).called(1);
      });

      test('updates state to paused optimistically', () async {
        when(() => mockPlatform.pause(any())).thenAnswer((_) async {});
        currentValue = const VideoPlayerValue(playbackState: PlaybackState.playing);

        await manager.pause();

        expect(currentValue.playbackState, PlaybackState.paused);
      });

      test('clears isStartingPlayback flag', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});
        when(() => mockPlatform.pause(any())).thenAnswer((_) async {});

        await manager.play();
        expect(manager.isStartingPlayback, isTrue);

        await manager.pause();
        expect(manager.isStartingPlayback, isFalse);
      });
    });

    group('seekTo', () {
      test('calls platform seekTo', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        await manager.seekTo(const Duration(seconds: 30));

        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 30))).called(1);
      });

      test('sets isSeeking flag', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        await manager.seekTo(const Duration(seconds: 30));

        expect(manager.isSeeking, isTrue);
        expect(manager.seekTargetPosition, equals(const Duration(seconds: 30)));
      });

      test('updates position optimistically', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});

        await manager.seekTo(const Duration(seconds: 30));

        expect(currentValue.position, equals(const Duration(seconds: 30)));
      });
    });

    group('seekForward', () {
      test('seeks forward by duration', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
        currentValue = const VideoPlayerValue(position: Duration(seconds: 10), duration: TestMetadata.duration);

        await manager.seekForward(const Duration(seconds: 5));

        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 15))).called(1);
      });

      test('clamps to duration', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
        currentValue = const VideoPlayerValue(position: Duration(seconds: 290), duration: TestMetadata.duration);

        await manager.seekForward(const Duration(seconds: 20));

        verify(() => mockPlatform.seekTo(1, TestMetadata.duration)).called(1);
      });
    });

    group('seekBackward', () {
      test('seeks backward by duration', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
        currentValue = const VideoPlayerValue(position: Duration(seconds: 30));

        await manager.seekBackward(const Duration(seconds: 5));

        verify(() => mockPlatform.seekTo(1, const Duration(seconds: 25))).called(1);
      });

      test('clamps to zero', () async {
        when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
        currentValue = const VideoPlayerValue(position: Duration(seconds: 3));

        await manager.seekBackward(const Duration(seconds: 5));

        verify(() => mockPlatform.seekTo(1, Duration.zero)).called(1);
      });
    });

    group('togglePlayPause', () {
      test('pauses when playing', () async {
        when(() => mockPlatform.pause(any())).thenAnswer((_) async {});
        currentValue = const VideoPlayerValue(playbackState: PlaybackState.playing);

        await manager.togglePlayPause();

        verify(() => mockPlatform.pause(1)).called(1);
      });

      test('plays when paused', () async {
        when(() => mockPlatform.play(any())).thenAnswer((_) async {});
        currentValue = const VideoPlayerValue(playbackState: PlaybackState.paused);

        await manager.togglePlayPause();

        verify(() => mockPlatform.play(1)).called(1);
      });
    });

    group('setPlaybackSpeed', () {
      test('calls platform and updates value', () async {
        when(() => mockPlatform.setPlaybackSpeed(any(), any())).thenAnswer((_) async {});

        await manager.setPlaybackSpeed(1.5);

        verify(() => mockPlatform.setPlaybackSpeed(1, 1.5)).called(1);
        expect(currentValue.playbackSpeed, equals(1.5));
      });

      test('throws for invalid speed', () async {
        expect(() => manager.setPlaybackSpeed(0), throwsA(isA<ArgumentError>()));
        expect(() => manager.setPlaybackSpeed(-1), throwsA(isA<ArgumentError>()));
      });
    });

    group('setVolume', () {
      test('calls platform and updates value', () async {
        when(() => mockPlatform.setVolume(any(), any())).thenAnswer((_) async {});

        await manager.setVolume(0.5);

        verify(() => mockPlatform.setVolume(1, 0.5)).called(1);
        expect(currentValue.volume, equals(0.5));
      });

      test('throws for invalid volume', () async {
        expect(() => manager.setVolume(-0.1), throwsA(isA<ArgumentError>()));
        expect(() => manager.setVolume(1.1), throwsA(isA<ArgumentError>()));
      });
    });

    group('state synchronization', () {
      group('handlePlaybackStateChanged', () {
        test('ignores stale paused event when starting playback', () async {
          when(() => mockPlatform.play(any())).thenAnswer((_) async {});
          await manager.play();

          final shouldProcess = manager.handlePlaybackStateChanged(PlaybackState.paused);

          expect(shouldProcess, isFalse);
        });

        test('ignores stale ready event when starting playback', () async {
          when(() => mockPlatform.play(any())).thenAnswer((_) async {});
          await manager.play();

          final shouldProcess = manager.handlePlaybackStateChanged(PlaybackState.ready);

          expect(shouldProcess, isFalse);
        });

        test('processes playing event and clears starting flag', () async {
          when(() => mockPlatform.play(any())).thenAnswer((_) async {});
          await manager.play();
          expect(manager.isStartingPlayback, isTrue);

          final shouldProcess = manager.handlePlaybackStateChanged(PlaybackState.playing);

          expect(shouldProcess, isTrue);
          expect(manager.isStartingPlayback, isFalse);
        });

        test('processes non-stale state changes', () {
          final shouldProcess = manager.handlePlaybackStateChanged(PlaybackState.buffering);

          expect(shouldProcess, isTrue);
        });
      });

      group('handlePositionChanged', () {
        test('ignores stale position when seeking', () async {
          when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
          await manager.seekTo(const Duration(seconds: 60));

          final shouldUpdate = manager.handlePositionChanged(const Duration(seconds: 30));

          expect(shouldUpdate, isFalse);
        });

        test('clears seeking flag when close to target', () async {
          when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
          await manager.seekTo(const Duration(seconds: 60));
          expect(manager.isSeeking, isTrue);

          manager.handlePositionChanged(const Duration(seconds: 60, milliseconds: 200));

          expect(manager.isSeeking, isFalse);
          expect(manager.seekTargetPosition, isNull);
        });

        test('processes position when not seeking', () {
          final shouldUpdate = manager.handlePositionChanged(const Duration(seconds: 30));

          expect(shouldUpdate, isTrue);
        });

        test('detects state mismatch after 3 position updates', () {
          currentValue = const VideoPlayerValue(playbackState: PlaybackState.paused);

          // First position update - not detected yet
          manager.handlePositionChanged(const Duration(seconds: 1));
          expect(currentValue.playbackState, PlaybackState.paused);

          // Second position update - not detected yet
          manager.handlePositionChanged(const Duration(seconds: 2));
          expect(currentValue.playbackState, PlaybackState.paused);

          // Third position update - mismatch detected and corrected
          manager.handlePositionChanged(const Duration(seconds: 3));
          expect(currentValue.playbackState, PlaybackState.playing);
        });
      });
    });
  });
}
