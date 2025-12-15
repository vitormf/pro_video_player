import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoPlayerValue', () {
    test('has correct default values', () {
      const value = VideoPlayerValue();

      expect(value.playbackState, equals(PlaybackState.uninitialized));
      expect(value.position, equals(Duration.zero));
      expect(value.duration, equals(Duration.zero));
      expect(value.bufferedPosition, equals(Duration.zero));
      expect(value.playbackSpeed, equals(1.0));
      expect(value.volume, equals(1.0));
      expect(value.isLooping, isFalse);
      expect(value.isPipActive, isFalse);
      expect(value.size, isNull);
      expect(value.subtitleTracks, isEmpty);
      expect(value.selectedSubtitleTrack, isNull);
      expect(value.audioTracks, isEmpty);
      expect(value.selectedAudioTrack, isNull);
      expect(value.errorMessage, isNull);
    });

    group('convenience getters', () {
      test('isPlaying returns true when playing', () {
        const value = VideoPlayerValue(playbackState: PlaybackState.playing);
        expect(value.isPlaying, isTrue);
      });

      test('isPlaying returns false when not playing', () {
        const value = VideoPlayerValue(playbackState: PlaybackState.paused);
        expect(value.isPlaying, isFalse);
      });

      test('isInitialized returns true for initialized states', () {
        const readyValue = VideoPlayerValue(playbackState: PlaybackState.ready);
        const playingValue = VideoPlayerValue(playbackState: PlaybackState.playing);
        const pausedValue = VideoPlayerValue(playbackState: PlaybackState.paused);

        expect(readyValue.isInitialized, isTrue);
        expect(playingValue.isInitialized, isTrue);
        expect(pausedValue.isInitialized, isTrue);
      });

      test('isInitialized returns false for uninitialized states', () {
        const uninitializedValue = VideoPlayerValue();
        const initializingValue = VideoPlayerValue(playbackState: PlaybackState.initializing);
        const disposedValue = VideoPlayerValue(playbackState: PlaybackState.disposed);

        expect(uninitializedValue.isInitialized, isFalse);
        expect(initializingValue.isInitialized, isFalse);
        expect(disposedValue.isInitialized, isFalse);
      });

      test('isCompleted returns true when completed', () {
        const value = VideoPlayerValue(playbackState: PlaybackState.completed);
        expect(value.isCompleted, isTrue);
      });

      test('isBuffering returns true when buffering', () {
        const value = VideoPlayerValue(playbackState: PlaybackState.buffering);
        expect(value.isBuffering, isTrue);
      });

      test('hasError returns true when in error state', () {
        const value = VideoPlayerValue(playbackState: PlaybackState.error);
        expect(value.hasError, isTrue);
      });

      test('aspectRatio returns null when size is null', () {
        const value = VideoPlayerValue();
        expect(value.aspectRatio, isNull);
      });

      test('aspectRatio returns null when height is 0', () {
        const value = VideoPlayerValue(size: (width: 1920, height: 0));
        expect(value.aspectRatio, isNull);
      });

      test('aspectRatio returns correct value', () {
        const value = VideoPlayerValue(size: (width: 1920, height: 1080));
        expect(value.aspectRatio, closeTo(16 / 9, 0.01));
      });
    });

    group('copyWith', () {
      test('copies with new playback state', () {
        const original = VideoPlayerValue(playbackState: PlaybackState.ready);
        final copied = original.copyWith(playbackState: PlaybackState.playing);

        expect(copied.playbackState, equals(PlaybackState.playing));
        expect(original.playbackState, equals(PlaybackState.ready));
      });

      test('copies with new position', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(position: const Duration(seconds: 30));

        expect(copied.position, equals(const Duration(seconds: 30)));
        expect(original.position, equals(Duration.zero));
      });

      test('copies with new duration', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(duration: const Duration(minutes: 5));

        expect(copied.duration, equals(const Duration(minutes: 5)));
      });

      test('copies with new bufferedPosition', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(bufferedPosition: const Duration(seconds: 60));

        expect(copied.bufferedPosition, equals(const Duration(seconds: 60)));
      });

      test('copies with new playbackSpeed', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(playbackSpeed: 1.5);

        expect(copied.playbackSpeed, equals(1.5));
      });

      test('copies with new volume', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(volume: 0.5);

        expect(copied.volume, equals(0.5));
      });

      test('copies with new isLooping', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(isLooping: true);

        expect(copied.isLooping, isTrue);
      });

      test('copies with new isPipActive', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(isPipActive: true);

        expect(copied.isPipActive, isTrue);
      });

      test('copies with new size', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(size: (width: 1920, height: 1080));

        expect(copied.size, equals((width: 1920, height: 1080)));
      });

      test('copies with new subtitleTracks', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(
          subtitleTracks: const [SubtitleTrack(id: '1', label: 'English')],
        );

        expect(copied.subtitleTracks, hasLength(1));
        expect(copied.subtitleTracks.first.label, equals('English'));
      });

      test('copies with new selectedSubtitleTrack', () {
        const original = VideoPlayerValue();
        const track = SubtitleTrack(id: '1', label: 'English');
        final copied = original.copyWith(selectedSubtitleTrack: track);

        expect(copied.selectedSubtitleTrack, equals(track));
      });

      test('copies with new audioTracks', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(
          audioTracks: const [AudioTrack(id: '1', label: 'English')],
        );

        expect(copied.audioTracks, hasLength(1));
        expect(copied.audioTracks.first.label, equals('English'));
      });

      test('copies with new selectedAudioTrack', () {
        const original = VideoPlayerValue();
        const track = AudioTrack(id: '1', label: 'English');
        final copied = original.copyWith(selectedAudioTrack: track);

        expect(copied.selectedAudioTrack, equals(track));
      });

      test('copies with new errorMessage', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(errorMessage: 'Network error');

        expect(copied.errorMessage, equals('Network error'));
      });

      test('preserves unchanged values', () {
        const original = VideoPlayerValue(
          playbackState: PlaybackState.playing,
          position: Duration(seconds: 10),
          volume: 0.5,
        );
        final copied = original.copyWith(position: const Duration(seconds: 20));

        expect(copied.playbackState, equals(PlaybackState.playing));
        expect(copied.volume, equals(0.5));
      });

      test('clearError removes error message', () {
        const original = VideoPlayerValue(errorMessage: 'Some error');
        final copied = original.copyWith(clearError: true);

        expect(copied.errorMessage, isNull);
      });

      test('clearSelectedSubtitle removes selected subtitle', () {
        const track = SubtitleTrack(id: '1', label: 'English');
        const original = VideoPlayerValue(selectedSubtitleTrack: track);
        final copied = original.copyWith(clearSelectedSubtitle: true);

        expect(copied.selectedSubtitleTrack, isNull);
      });

      test('clearSelectedAudio removes selected audio track', () {
        const track = AudioTrack(id: '1', label: 'English');
        const original = VideoPlayerValue(selectedAudioTrack: track);
        final copied = original.copyWith(clearSelectedAudio: true);

        expect(copied.selectedAudioTrack, isNull);
      });

      test('clearSize removes size', () {
        const original = VideoPlayerValue(size: (width: 1920, height: 1080));
        final copied = original.copyWith(clearSize: true);

        expect(copied.size, isNull);
      });
    });

    group('equality', () {
      test('equal values are equal', () {
        const value1 = VideoPlayerValue(playbackState: PlaybackState.playing, position: Duration(seconds: 10));
        const value2 = VideoPlayerValue(playbackState: PlaybackState.playing, position: Duration(seconds: 10));

        expect(value1, equals(value2));
      });

      test('different values are not equal', () {
        const value1 = VideoPlayerValue(position: Duration(seconds: 10));
        const value2 = VideoPlayerValue(position: Duration(seconds: 20));

        expect(value1, isNot(equals(value2)));
      });

      test('identical values are equal', () {
        const value = VideoPlayerValue(position: Duration(seconds: 10));

        expect(value == value, isTrue);
      });

      test('different type is not equal', () {
        const value = VideoPlayerValue(position: Duration(seconds: 10));
        const Object other = 'not a VideoPlayerValue';

        expect(value == other, isFalse);
      });

      test('values with different subtitleTracks are not equal', () {
        const value1 = VideoPlayerValue(
          subtitleTracks: [SubtitleTrack(id: '1', label: 'English')],
        );
        const value2 = VideoPlayerValue(
          subtitleTracks: [SubtitleTrack(id: '2', label: 'Spanish')],
        );

        expect(value1, isNot(equals(value2)));
      });

      test('values with same subtitleTracks are equal', () {
        const value1 = VideoPlayerValue(
          subtitleTracks: [SubtitleTrack(id: '1', label: 'English')],
        );
        const value2 = VideoPlayerValue(
          subtitleTracks: [SubtitleTrack(id: '1', label: 'English')],
        );

        expect(value1, equals(value2));
      });

      test('values with different length subtitleTracks are not equal', () {
        const value1 = VideoPlayerValue(
          subtitleTracks: [
            SubtitleTrack(id: '1', label: 'English'),
            SubtitleTrack(id: '2', label: 'Spanish'),
          ],
        );
        const value2 = VideoPlayerValue(
          subtitleTracks: [SubtitleTrack(id: '1', label: 'English')],
        );

        expect(value1, isNot(equals(value2)));
      });

      test('values with different audioTracks are not equal', () {
        const value1 = VideoPlayerValue(
          audioTracks: [AudioTrack(id: '1', label: 'English')],
        );
        const value2 = VideoPlayerValue(
          audioTracks: [AudioTrack(id: '2', label: 'Spanish')],
        );

        expect(value1, isNot(equals(value2)));
      });

      test('values with same audioTracks are equal', () {
        const value1 = VideoPlayerValue(
          audioTracks: [AudioTrack(id: '1', label: 'English')],
        );
        const value2 = VideoPlayerValue(
          audioTracks: [AudioTrack(id: '1', label: 'English')],
        );

        expect(value1, equals(value2));
      });

      test('values with different length audioTracks are not equal', () {
        const value1 = VideoPlayerValue(
          audioTracks: [
            AudioTrack(id: '1', label: 'English'),
            AudioTrack(id: '2', label: 'Spanish'),
          ],
        );
        const value2 = VideoPlayerValue(
          audioTracks: [AudioTrack(id: '1', label: 'English')],
        );

        expect(value1, isNot(equals(value2)));
      });

      test('hashCode is consistent with equality', () {
        const value1 = VideoPlayerValue(playbackState: PlaybackState.playing, position: Duration(seconds: 10));
        const value2 = VideoPlayerValue(playbackState: PlaybackState.playing, position: Duration(seconds: 10));

        expect(value1.hashCode, equals(value2.hashCode));
      });
    });

    test('toString returns readable representation', () {
      const value = VideoPlayerValue(playbackState: PlaybackState.playing, position: Duration(seconds: 10));

      expect(value.toString(), contains('VideoPlayerValue'));
      expect(value.toString(), contains('playing'));
    });

    // Network Resilience Tests
    group('network resilience fields', () {
      test('has correct default network resilience values', () {
        const value = VideoPlayerValue();

        expect(value.isNetworkBuffering, isFalse);
        expect(value.bufferingReason, isNull);
        expect(value.networkRetryCount, equals(0));
        expect(value.isRecoveringFromError, isFalse);
      });

      test('copyWith updates network buffering state', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(isNetworkBuffering: true, bufferingReason: BufferingReason.networkUnstable);

        expect(copied.isNetworkBuffering, isTrue);
        expect(copied.bufferingReason, equals(BufferingReason.networkUnstable));
      });

      test('copyWith updates network retry count', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(networkRetryCount: 2);

        expect(copied.networkRetryCount, equals(2));
      });

      test('copyWith updates recovering from error state', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(isRecoveringFromError: true);

        expect(copied.isRecoveringFromError, isTrue);
      });

      test('clearBufferingReason clears buffering reason', () {
        const original = VideoPlayerValue(bufferingReason: BufferingReason.insufficientBandwidth);
        final copied = original.copyWith(clearBufferingReason: true);

        expect(copied.bufferingReason, isNull);
      });

      test('equality includes network resilience fields', () {
        const value1 = VideoPlayerValue(
          isNetworkBuffering: true,
          bufferingReason: BufferingReason.networkUnstable,
          networkRetryCount: 1,
          isRecoveringFromError: true,
        );
        const value2 = VideoPlayerValue(
          isNetworkBuffering: true,
          bufferingReason: BufferingReason.networkUnstable,
          networkRetryCount: 1,
          isRecoveringFromError: true,
        );

        expect(value1, equals(value2));
      });

      test('values with different network resilience fields are not equal', () {
        const value1 = VideoPlayerValue(isNetworkBuffering: true);
        const value2 = VideoPlayerValue();

        expect(value1, isNot(equals(value2)));
      });

      test('hashCode includes network resilience fields', () {
        const value1 = VideoPlayerValue(isNetworkBuffering: true, networkRetryCount: 1);
        const value2 = VideoPlayerValue(isNetworkBuffering: true, networkRetryCount: 1);

        expect(value1.hashCode, equals(value2.hashCode));
      });

      test('toString includes network resilience fields', () {
        const value = VideoPlayerValue(
          isNetworkBuffering: true,
          bufferingReason: BufferingReason.networkUnstable,
          networkRetryCount: 2,
          isRecoveringFromError: true,
        );

        final str = value.toString();
        expect(str, contains('isNetworkBuffering: true'));
        expect(str, contains('bufferingReason'));
        expect(str, contains('networkRetryCount: 2'));
        expect(str, contains('isRecoveringFromError: true'));
      });
    });

    // Bandwidth Estimation Tests
    group('bandwidth estimation', () {
      test('has correct default estimatedBandwidth value', () {
        const value = VideoPlayerValue();

        expect(value.estimatedBandwidth, isNull);
      });

      test('copyWith updates estimatedBandwidth', () {
        const original = VideoPlayerValue();
        final copied = original.copyWith(estimatedBandwidth: 5000000);

        expect(copied.estimatedBandwidth, equals(5000000));
      });

      test('copyWith preserves estimatedBandwidth when not specified', () {
        const original = VideoPlayerValue(estimatedBandwidth: 10000000);
        final copied = original.copyWith(playbackState: PlaybackState.playing);

        expect(copied.estimatedBandwidth, equals(10000000));
      });

      test('equality includes estimatedBandwidth', () {
        const value1 = VideoPlayerValue(estimatedBandwidth: 5000000);
        const value2 = VideoPlayerValue(estimatedBandwidth: 5000000);

        expect(value1, equals(value2));
      });

      test('values with different estimatedBandwidth are not equal', () {
        const value1 = VideoPlayerValue(estimatedBandwidth: 5000000);
        const value2 = VideoPlayerValue(estimatedBandwidth: 10000000);

        expect(value1, isNot(equals(value2)));
      });

      test('value with estimatedBandwidth not equal to value without', () {
        const value1 = VideoPlayerValue(estimatedBandwidth: 5000000);
        const value2 = VideoPlayerValue();

        expect(value1, isNot(equals(value2)));
      });

      test('hashCode includes estimatedBandwidth', () {
        const value1 = VideoPlayerValue(estimatedBandwidth: 5000000);
        const value2 = VideoPlayerValue(estimatedBandwidth: 5000000);

        expect(value1.hashCode, equals(value2.hashCode));
      });

      test('toString includes estimatedBandwidth', () {
        const value = VideoPlayerValue(estimatedBandwidth: 5000000);

        final str = value.toString();
        expect(str, contains('estimatedBandwidth: 5000000'));
      });

      test('toString shows null when estimatedBandwidth is not set', () {
        const value = VideoPlayerValue();

        final str = value.toString();
        expect(str, contains('estimatedBandwidth: null'));
      });
    });

    // Embedded Subtitle Cue Tests
    group('embedded subtitle cue', () {
      test('has correct default currentEmbeddedCue value', () {
        const value = VideoPlayerValue();

        expect(value.currentEmbeddedCue, isNull);
      });

      test('copyWith updates currentEmbeddedCue', () {
        const original = VideoPlayerValue();
        const cue = SubtitleCue(text: 'Hello world', start: Duration(seconds: 1), end: Duration(seconds: 3));
        final copied = original.copyWith(currentEmbeddedCue: cue);

        expect(copied.currentEmbeddedCue, equals(cue));
        expect(copied.currentEmbeddedCue?.text, equals('Hello world'));
      });

      test('copyWith preserves currentEmbeddedCue when not specified', () {
        const cue = SubtitleCue(text: 'Test subtitle', start: Duration.zero, end: Duration(seconds: 2));
        const original = VideoPlayerValue(currentEmbeddedCue: cue);
        final copied = original.copyWith(playbackState: PlaybackState.playing);

        expect(copied.currentEmbeddedCue, equals(cue));
      });

      test('clearCurrentEmbeddedCue clears the cue', () {
        const cue = SubtitleCue(text: 'Will be cleared', start: Duration.zero, end: Duration(seconds: 1));
        const original = VideoPlayerValue(currentEmbeddedCue: cue);
        final copied = original.copyWith(clearCurrentEmbeddedCue: true);

        expect(copied.currentEmbeddedCue, isNull);
      });

      test('equality includes currentEmbeddedCue', () {
        const cue = SubtitleCue(text: 'Same cue', start: Duration(seconds: 5), end: Duration(seconds: 8));
        const value1 = VideoPlayerValue(currentEmbeddedCue: cue);
        const value2 = VideoPlayerValue(currentEmbeddedCue: cue);

        expect(value1, equals(value2));
      });

      test('values with different currentEmbeddedCue are not equal', () {
        const cue1 = SubtitleCue(text: 'First cue', start: Duration.zero, end: Duration(seconds: 1));
        const cue2 = SubtitleCue(text: 'Second cue', start: Duration.zero, end: Duration(seconds: 1));
        const value1 = VideoPlayerValue(currentEmbeddedCue: cue1);
        const value2 = VideoPlayerValue(currentEmbeddedCue: cue2);

        expect(value1, isNot(equals(value2)));
      });

      test('value with currentEmbeddedCue not equal to value without', () {
        const cue = SubtitleCue(text: 'Has cue', start: Duration.zero, end: Duration(seconds: 1));
        const value1 = VideoPlayerValue(currentEmbeddedCue: cue);
        const value2 = VideoPlayerValue();

        expect(value1, isNot(equals(value2)));
      });

      test('hashCode includes currentEmbeddedCue', () {
        const cue = SubtitleCue(text: 'Test', start: Duration.zero, end: Duration(seconds: 1));
        const value1 = VideoPlayerValue(currentEmbeddedCue: cue);
        const value2 = VideoPlayerValue(currentEmbeddedCue: cue);

        expect(value1.hashCode, equals(value2.hashCode));
      });

      test('toString includes currentEmbeddedCue', () {
        const cue = SubtitleCue(text: 'Subtitle text here', start: Duration.zero, end: Duration(seconds: 2));
        const value = VideoPlayerValue(currentEmbeddedCue: cue);

        final str = value.toString();
        expect(str, contains('currentEmbeddedCue:'));
      });

      test('toString shows null when currentEmbeddedCue is not set', () {
        const value = VideoPlayerValue();

        final str = value.toString();
        // The toString truncates text to 30 chars using take(), so null shows differently
        expect(str, contains('currentEmbeddedCue: null'));
      });
    });
  });
}
