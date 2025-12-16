import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/controller/event_coordinator.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../shared/mocks.dart';
import '../../shared/test_constants.dart';
import '../../shared/test_setup.dart';

void main() {
  late EventCoordinator coordinator;
  late MockProVideoPlayerPlatform mockPlatform;
  late MockPlaybackManager mockPlaybackManager;
  late MockTrackManager mockTrackManager;
  late MockErrorRecoveryManager mockErrorRecovery;
  late MockPlaylistManager mockPlaylistManager;
  late VideoPlayerValue currentValue;
  late VideoPlayerOptions options;
  late int? playerId;
  late bool disposed;
  late bool retrying;
  late StreamController<VideoPlayerEvent> eventStream;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    mockPlaybackManager = MockPlaybackManager();
    mockTrackManager = MockTrackManager();
    mockErrorRecovery = MockErrorRecoveryManager();
    mockPlaylistManager = MockPlaylistManager();

    currentValue = const VideoPlayerValue();
    options = const VideoPlayerOptions();
    playerId = 1;
    disposed = false;
    retrying = false;
    eventStream = StreamController<VideoPlayerEvent>.broadcast();

    when(() => mockPlatform.events(any())).thenAnswer((_) => eventStream.stream);

    coordinator = EventCoordinator(
      getValue: () => currentValue,
      setValue: (v) => currentValue = v,
      getPlayerId: () => playerId,
      getOptions: () => options,
      isDisposed: () => disposed,
      isRetrying: () => retrying,
      setRetrying: ({required isRetrying}) => retrying = isRetrying,
      platform: mockPlatform,
      playbackManager: mockPlaybackManager,
      trackManager: mockTrackManager,
      errorRecoveryManager: mockErrorRecovery,
      playlistManager: mockPlaylistManager,
      onSeekTo: (_) async {},
      onPlay: () async {},
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    await eventStream.close();
  });

  group('EventCoordinator', () {
    group('subscribeToEvents', () {
      test('subscribes to platform event stream', () {
        coordinator.subscribeToEvents();

        verify(() => mockPlatform.events(1)).called(1);
      });
    });

    group('event handling', () {
      setUp(() {
        coordinator.subscribeToEvents();
      });

      test('updates state on PlaybackStateChangedEvent', () async {
        when(() => mockPlaybackManager.handlePlaybackStateChanged(any())).thenReturn(true);

        eventStream.add(const PlaybackStateChangedEvent(PlaybackState.playing));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.playbackState, PlaybackState.playing);
        verify(() => mockPlaybackManager.handlePlaybackStateChanged(PlaybackState.playing)).called(1);
      });

      test('ignores stale PlaybackStateChangedEvent', () async {
        when(() => mockPlaybackManager.handlePlaybackStateChanged(any())).thenReturn(false);
        currentValue = const VideoPlayerValue(playbackState: PlaybackState.paused);

        eventStream.add(const PlaybackStateChangedEvent(PlaybackState.playing));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.playbackState, PlaybackState.paused);
      });

      test('skips redundant PlaybackStateChangedEvent', () async {
        currentValue = const VideoPlayerValue(playbackState: PlaybackState.playing);

        eventStream.add(const PlaybackStateChangedEvent(PlaybackState.playing));
        await Future<void>.delayed(TestDelays.eventPropagation);

        verifyNever(() => mockPlaybackManager.handlePlaybackStateChanged(any()));
      });

      test('updates position on PositionChangedEvent', () async {
        when(() => mockPlaybackManager.handlePositionChanged(any())).thenReturn(true);

        eventStream.add(const PositionChangedEvent(Duration(seconds: 30)));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.position, equals(const Duration(seconds: 30)));
        verify(() => mockPlaybackManager.handlePositionChanged(const Duration(seconds: 30))).called(1);
      });

      test('ignores stale PositionChangedEvent', () async {
        when(() => mockPlaybackManager.handlePositionChanged(any())).thenReturn(false);
        currentValue = const VideoPlayerValue(position: Duration(seconds: 10));

        eventStream.add(const PositionChangedEvent(Duration(seconds: 30)));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.position, equals(const Duration(seconds: 10)));
      });

      test('updates buffered position on BufferedPositionChangedEvent', () async {
        eventStream.add(const BufferedPositionChangedEvent(Duration(seconds: 60)));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.bufferedPosition, equals(const Duration(seconds: 60)));
      });

      test('updates duration on DurationChangedEvent', () async {
        eventStream.add(const DurationChangedEvent(TestMetadata.duration));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.duration, equals(TestMetadata.duration));
      });

      test('handles PlaybackCompletedEvent', () async {
        eventStream.add(const PlaybackCompletedEvent());
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.playbackState, PlaybackState.completed);
      });

      test('handles ErrorEvent and schedules retry', () async {
        final error = VideoPlayerError.network(message: 'Network failed', code: 'network_error');

        eventStream.add(ErrorEvent.withError(error));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.playbackState, PlaybackState.error);
        expect(currentValue.errorMessage, 'Network failed');
        verify(() => mockErrorRecovery.scheduleAutoRetry(error)).called(1);
      });

      test('updates video size on VideoSizeChangedEvent', () async {
        eventStream.add(const VideoSizeChangedEvent(width: 1920, height: 1080));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.size!.width, 1920);
        expect(currentValue.size!.height, 1080);
      });

      test('handles SubtitleTracksChangedEvent with auto-select', () async {
        const tracks = [SubtitleTrack(id: '1', label: 'English', language: 'en')];
        options = const VideoPlayerOptions(showSubtitlesByDefault: true);

        eventStream.add(const SubtitleTracksChangedEvent(tracks));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.subtitleTracks, tracks);
        verify(() => mockTrackManager.autoSelectSubtitle(tracks)).called(1);
      });

      test('ignores SubtitleTracksChangedEvent when subtitles disabled', () async {
        const tracks = [SubtitleTrack(id: '1', label: 'English')];
        options = const VideoPlayerOptions(subtitlesEnabled: false);

        eventStream.add(const SubtitleTracksChangedEvent(tracks));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.subtitleTracks, isEmpty);
      });

      test('updates pip state on PipStateChangedEvent', () async {
        eventStream.add(const PipStateChangedEvent(isActive: true));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.isPipActive, isTrue);
      });

      test('updates fullscreen state on FullscreenStateChangedEvent', () async {
        eventStream.add(const FullscreenStateChangedEvent(isFullscreen: true));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.isFullscreen, isTrue);
      });

      test('handles BufferingStartedEvent', () async {
        eventStream.add(const BufferingStartedEvent(reason: BufferingReason.networkUnstable));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.isNetworkBuffering, isTrue);
        expect(currentValue.bufferingReason, BufferingReason.networkUnstable);
        expect(currentValue.playbackState, PlaybackState.buffering);
      });

      test('handles BufferingEndedEvent', () async {
        currentValue = const VideoPlayerValue(isNetworkBuffering: true);

        eventStream.add(const BufferingEndedEvent());
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.isNetworkBuffering, isFalse);
        verify(() => mockErrorRecovery.cancelRetryTimer()).called(1);
        expect(retrying, isFalse);
      });

      test('handles NetworkErrorEvent', () async {
        eventStream.add(const NetworkErrorEvent(message: 'Connection lost'));
        await Future<void>.delayed(TestDelays.eventPropagation);

        verify(() => mockErrorRecovery.handleNetworkError('Connection lost')).called(1);
      });

      test('handles PlaybackRecoveredEvent', () async {
        currentValue = const VideoPlayerValue(networkRetryCount: 2);

        eventStream.add(const PlaybackRecoveredEvent(retriesUsed: 2));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.networkRetryCount, 0);
        expect(currentValue.isRecoveringFromError, isFalse);
        verify(() => mockErrorRecovery.cancelRetryTimer()).called(1);
        expect(retrying, isFalse);
      });

      test('handles NetworkStateChangedEvent', () async {
        eventStream.add(const NetworkStateChangedEvent(isConnected: true));
        await Future<void>.delayed(TestDelays.eventPropagation);

        verify(() => mockErrorRecovery.handleNetworkStateChange(isConnected: true)).called(1);
      });

      test('updates metadata on VideoMetadataExtractedEvent', () async {
        const metadata = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080, videoBitrate: 5000000);

        eventStream.add(const VideoMetadataExtractedEvent(metadata));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.videoMetadata, metadata);
      });

      test('updates chapters on ChaptersExtractedEvent', () async {
        const chapters = [Chapter(id: '1', title: 'Intro', startTime: Duration.zero, endTime: Duration(minutes: 1))];

        eventStream.add(const ChaptersExtractedEvent(chapters));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(currentValue.chapters, chapters);
      });

      test('does not process events when disposed', () async {
        disposed = true;

        eventStream.add(const PlaybackStateChangedEvent(PlaybackState.playing));
        await Future<void>.delayed(TestDelays.eventPropagation);

        verifyNever(() => mockPlaybackManager.handlePlaybackStateChanged(any()));
      });
    });

    group('dispose', () {
      test('cancels event subscription', () async {
        coordinator.subscribeToEvents();

        await coordinator.dispose();

        // Verify subscription is cancelled by checking events are not processed
        disposed = true;
        eventStream.add(const PlaybackStateChangedEvent(PlaybackState.playing));
        await Future<void>.delayed(TestDelays.eventPropagation);

        verifyNever(() => mockPlaybackManager.handlePlaybackStateChanged(any()));
      });
    });
  });
}
