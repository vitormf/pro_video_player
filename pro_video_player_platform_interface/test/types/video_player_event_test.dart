import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoPlayerEvent', () {
    group('PlaybackStateChangedEvent', () {
      test('creates with state', () {
        const event = PlaybackStateChangedEvent(PlaybackState.playing);

        expect(event.state, equals(PlaybackState.playing));
      });

      test('toString returns readable representation', () {
        const event = PlaybackStateChangedEvent(PlaybackState.playing);

        expect(event.toString(), contains('PlaybackStateChangedEvent'));
        expect(event.toString(), contains('playing'));
      });
    });

    group('PositionChangedEvent', () {
      test('creates with position', () {
        const event = PositionChangedEvent(Duration(seconds: 30));

        expect(event.position, equals(const Duration(seconds: 30)));
      });

      test('toString returns readable representation', () {
        const event = PositionChangedEvent(Duration(seconds: 30));

        expect(event.toString(), contains('PositionChangedEvent'));
      });
    });

    group('BufferedPositionChangedEvent', () {
      test('creates with buffered position', () {
        const event = BufferedPositionChangedEvent(Duration(seconds: 60));

        expect(event.bufferedPosition, equals(const Duration(seconds: 60)));
      });

      test('toString returns readable representation', () {
        const event = BufferedPositionChangedEvent(Duration(seconds: 60));

        expect(event.toString(), contains('BufferedPositionChangedEvent'));
      });
    });

    group('DurationChangedEvent', () {
      test('creates with duration', () {
        const event = DurationChangedEvent(Duration(minutes: 5));

        expect(event.duration, equals(const Duration(minutes: 5)));
      });

      test('toString returns readable representation', () {
        const event = DurationChangedEvent(Duration(minutes: 5));

        expect(event.toString(), contains('DurationChangedEvent'));
      });
    });

    group('PlaybackCompletedEvent', () {
      test('creates', () {
        const event = PlaybackCompletedEvent();

        expect(event, isA<PlaybackCompletedEvent>());
      });

      test('toString returns readable representation', () {
        const event = PlaybackCompletedEvent();

        expect(event.toString(), contains('PlaybackCompletedEvent'));
      });
    });

    group('ErrorEvent', () {
      test('creates with message only', () {
        final event = ErrorEvent('Playback error');

        expect(event.message, equals('Playback error'));
        expect(event.code, isNull);
        expect(event.error, isNotNull);
        expect(event.error.message, equals('Playback error'));
      });

      test('creates with message and code', () {
        final event = ErrorEvent('Playback error', code: 'PLAYBACK_ERROR');

        expect(event.message, equals('Playback error'));
        expect(event.code, equals('PLAYBACK_ERROR'));
        expect(event.error.code, equals('PLAYBACK_ERROR'));
      });

      test('creates with VideoPlayerError', () {
        final error = VideoPlayerError.network(message: 'Connection timeout');
        final event = ErrorEvent.withError(error);

        expect(event.message, equals('Connection timeout'));
        expect(event.error, same(error));
        expect(event.error.category, equals(VideoPlayerErrorCategory.network));
        expect(event.error.severity, equals(VideoPlayerErrorSeverity.recoverable));
      });

      test('toString returns readable representation', () {
        final event = ErrorEvent('Playback error', code: 'PLAYBACK_ERROR');

        final str = event.toString();
        expect(str, contains('ErrorEvent'));
        expect(str, contains('Playback error'));
        expect(str, contains('PLAYBACK_ERROR'));
      });

      test('error classification works correctly', () {
        final networkError = ErrorEvent('Network connection failed', code: 'NETWORK_ERROR');
        expect(networkError.error.category, equals(VideoPlayerErrorCategory.network));
        expect(networkError.error.severity, equals(VideoPlayerErrorSeverity.recoverable));

        final sourceError = ErrorEvent('Invalid video source', code: 'INVALID_SOURCE');
        expect(sourceError.error.category, equals(VideoPlayerErrorCategory.source));
        expect(sourceError.error.severity, equals(VideoPlayerErrorSeverity.fatal));
      });
    });

    group('VideoSizeChangedEvent', () {
      test('creates with width and height', () {
        const event = VideoSizeChangedEvent(width: 1920, height: 1080);

        expect(event.width, equals(1920));
        expect(event.height, equals(1080));
      });

      test('toString returns readable representation', () {
        const event = VideoSizeChangedEvent(width: 1920, height: 1080);

        final str = event.toString();
        expect(str, contains('VideoSizeChangedEvent'));
        expect(str, contains('1920'));
        expect(str, contains('1080'));
      });
    });

    group('SubtitleTracksChangedEvent', () {
      test('creates with empty tracks', () {
        const event = SubtitleTracksChangedEvent([]);

        expect(event.tracks, isEmpty);
      });

      test('creates with tracks', () {
        const tracks = [SubtitleTrack(id: 'en', label: 'English'), SubtitleTrack(id: 'es', label: 'Spanish')];
        const event = SubtitleTracksChangedEvent(tracks);

        expect(event.tracks, hasLength(2));
        expect(event.tracks[0].id, equals('en'));
        expect(event.tracks[1].id, equals('es'));
      });

      test('toString returns readable representation', () {
        const event = SubtitleTracksChangedEvent([]);

        expect(event.toString(), contains('SubtitleTracksChangedEvent'));
      });
    });

    group('SelectedSubtitleChangedEvent', () {
      test('creates with track', () {
        const track = SubtitleTrack(id: 'en', label: 'English');
        const event = SelectedSubtitleChangedEvent(track);

        expect(event.track, equals(track));
      });

      test('creates with null track (disabled)', () {
        const event = SelectedSubtitleChangedEvent(null);

        expect(event.track, isNull);
      });

      test('toString returns readable representation', () {
        const event = SelectedSubtitleChangedEvent(null);

        expect(event.toString(), contains('SelectedSubtitleChangedEvent'));
      });
    });

    group('AudioTracksChangedEvent', () {
      test('creates with empty tracks', () {
        const event = AudioTracksChangedEvent([]);

        expect(event.tracks, isEmpty);
      });

      test('creates with tracks', () {
        const tracks = [AudioTrack(id: 'en', label: 'English'), AudioTrack(id: 'es', label: 'Spanish')];
        const event = AudioTracksChangedEvent(tracks);

        expect(event.tracks, hasLength(2));
        expect(event.tracks[0].id, equals('en'));
        expect(event.tracks[1].id, equals('es'));
      });

      test('toString returns readable representation', () {
        const event = AudioTracksChangedEvent([]);

        expect(event.toString(), contains('AudioTracksChangedEvent'));
      });
    });

    group('SelectedAudioChangedEvent', () {
      test('creates with track', () {
        const track = AudioTrack(id: 'en', label: 'English');
        const event = SelectedAudioChangedEvent(track);

        expect(event.track, equals(track));
      });

      test('creates with null track', () {
        const event = SelectedAudioChangedEvent(null);

        expect(event.track, isNull);
      });

      test('toString returns readable representation', () {
        const event = SelectedAudioChangedEvent(null);

        expect(event.toString(), contains('SelectedAudioChangedEvent'));
      });
    });

    group('VideoQualityTracksChangedEvent', () {
      test('creates with empty tracks', () {
        const event = VideoQualityTracksChangedEvent([]);

        expect(event.tracks, isEmpty);
      });

      test('creates with tracks', () {
        const tracks = [
          VideoQualityTrack.auto,
          VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080),
          VideoQualityTrack(id: '0:2', bitrate: 2500000, width: 1280, height: 720),
        ];
        const event = VideoQualityTracksChangedEvent(tracks);

        expect(event.tracks, hasLength(3));
        expect(event.tracks[0].isAuto, isTrue);
        expect(event.tracks[1].height, equals(1080));
        expect(event.tracks[2].height, equals(720));
      });

      test('toString returns readable representation', () {
        const tracks = [
          VideoQualityTrack.auto,
          VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080),
        ];
        const event = VideoQualityTracksChangedEvent(tracks);

        final str = event.toString();
        expect(str, contains('VideoQualityTracksChangedEvent'));
        expect(str, contains('2 available'));
      });
    });

    group('SelectedQualityChangedEvent', () {
      test('creates with track and defaults to manual switch', () {
        const track = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);
        const event = SelectedQualityChangedEvent(track);

        expect(event.track, equals(track));
        expect(event.isAutoSwitch, isFalse);
      });

      test('creates with auto track', () {
        const event = SelectedQualityChangedEvent(VideoQualityTrack.auto);

        expect(event.track.isAuto, isTrue);
        expect(event.isAutoSwitch, isFalse);
      });

      test('creates with auto switch flag', () {
        const track = VideoQualityTrack(id: '0:2', bitrate: 2500000, width: 1280, height: 720);
        const event = SelectedQualityChangedEvent(track, isAutoSwitch: true);

        expect(event.track, equals(track));
        expect(event.isAutoSwitch, isTrue);
      });

      test('toString returns readable representation for manual selection', () {
        const track = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);
        const event = SelectedQualityChangedEvent(track);

        final str = event.toString();
        expect(str, contains('SelectedQualityChangedEvent'));
        expect(str, contains('isAutoSwitch: false'));
      });

      test('toString returns readable representation for auto switch', () {
        const track = VideoQualityTrack(id: '0:1', bitrate: 5000000, width: 1920, height: 1080);
        const event = SelectedQualityChangedEvent(track, isAutoSwitch: true);

        final str = event.toString();
        expect(str, contains('SelectedQualityChangedEvent'));
        expect(str, contains('isAutoSwitch: true'));
      });
    });

    group('PipStateChangedEvent', () {
      test('creates with isActive true', () {
        const event = PipStateChangedEvent(isActive: true);

        expect(event.isActive, isTrue);
      });

      test('creates with isActive false', () {
        const event = PipStateChangedEvent(isActive: false);

        expect(event.isActive, isFalse);
      });

      test('toString returns readable representation', () {
        const event = PipStateChangedEvent(isActive: true);

        final str = event.toString();
        expect(str, contains('PipStateChangedEvent'));
        expect(str, contains('true'));
      });
    });

    group('FullscreenStateChangedEvent', () {
      test('creates with isFullscreen true', () {
        const event = FullscreenStateChangedEvent(isFullscreen: true);

        expect(event.isFullscreen, isTrue);
      });

      test('creates with isFullscreen false', () {
        const event = FullscreenStateChangedEvent(isFullscreen: false);

        expect(event.isFullscreen, isFalse);
      });

      test('toString returns readable representation', () {
        const event = FullscreenStateChangedEvent(isFullscreen: true);

        final str = event.toString();
        expect(str, contains('FullscreenStateChangedEvent'));
        expect(str, contains('true'));
      });
    });

    group('PlaybackSpeedChangedEvent', () {
      test('creates with speed', () {
        const event = PlaybackSpeedChangedEvent(1.5);

        expect(event.speed, equals(1.5));
      });

      test('toString returns readable representation', () {
        const event = PlaybackSpeedChangedEvent(1.5);

        final str = event.toString();
        expect(str, contains('PlaybackSpeedChangedEvent'));
        expect(str, contains('1.5'));
      });
    });

    group('VolumeChangedEvent', () {
      test('creates with volume', () {
        const event = VolumeChangedEvent(0.5);

        expect(event.volume, equals(0.5));
      });

      test('toString returns readable representation', () {
        const event = VolumeChangedEvent(0.5);

        final str = event.toString();
        expect(str, contains('VolumeChangedEvent'));
        expect(str, contains('0.5'));
      });
    });

    // Network Resilience Events
    group('BufferingStartedEvent', () {
      test('creates with default reason', () {
        const event = BufferingStartedEvent();

        expect(event.reason, equals(BufferingReason.unknown));
      });

      test('creates with specific reason', () {
        const event = BufferingStartedEvent(reason: BufferingReason.networkUnstable);

        expect(event.reason, equals(BufferingReason.networkUnstable));
      });

      test('toString returns readable representation', () {
        const event = BufferingStartedEvent(reason: BufferingReason.insufficientBandwidth);

        final str = event.toString();
        expect(str, contains('BufferingStartedEvent'));
        expect(str, contains('insufficientBandwidth'));
      });
    });

    group('BufferingEndedEvent', () {
      test('creates', () {
        const event = BufferingEndedEvent();

        expect(event, isA<BufferingEndedEvent>());
      });

      test('toString returns readable representation', () {
        const event = BufferingEndedEvent();

        expect(event.toString(), contains('BufferingEndedEvent'));
      });
    });

    group('NetworkErrorEvent', () {
      test('creates with message only', () {
        const event = NetworkErrorEvent(message: 'Connection lost');

        expect(event.message, equals('Connection lost'));
        expect(event.willRetry, isFalse);
        expect(event.retryAttempt, equals(0));
        expect(event.maxRetries, equals(3));
      });

      test('creates with all parameters', () {
        const event = NetworkErrorEvent(message: 'Connection timeout', willRetry: true, retryAttempt: 2, maxRetries: 5);

        expect(event.message, equals('Connection timeout'));
        expect(event.willRetry, isTrue);
        expect(event.retryAttempt, equals(2));
        expect(event.maxRetries, equals(5));
      });

      test('toString returns readable representation', () {
        const event = NetworkErrorEvent(message: 'Network error', willRetry: true, retryAttempt: 1, maxRetries: 5);

        final str = event.toString();
        expect(str, contains('NetworkErrorEvent'));
        expect(str, contains('Network error'));
        expect(str, contains('willRetry: true'));
        expect(str, contains('1/5'));
      });
    });

    group('PlaybackRecoveredEvent', () {
      test('creates with default retries', () {
        const event = PlaybackRecoveredEvent();

        expect(event.retriesUsed, equals(0));
      });

      test('creates with retries used', () {
        const event = PlaybackRecoveredEvent(retriesUsed: 2);

        expect(event.retriesUsed, equals(2));
      });

      test('toString returns readable representation', () {
        const event = PlaybackRecoveredEvent(retriesUsed: 3);

        final str = event.toString();
        expect(str, contains('PlaybackRecoveredEvent'));
        expect(str, contains('3'));
      });
    });

    group('BufferingReason', () {
      test('has all expected values', () {
        expect(BufferingReason.values, contains(BufferingReason.initial));
        expect(BufferingReason.values, contains(BufferingReason.seeking));
        expect(BufferingReason.values, contains(BufferingReason.insufficientBandwidth));
        expect(BufferingReason.values, contains(BufferingReason.networkUnstable));
        expect(BufferingReason.values, contains(BufferingReason.unknown));
      });
    });

    group('BandwidthEstimateChangedEvent', () {
      test('creates with bandwidth', () {
        const event = BandwidthEstimateChangedEvent(5000000);

        expect(event.bandwidth, equals(5000000));
      });

      test('creates with zero bandwidth', () {
        const event = BandwidthEstimateChangedEvent(0);

        expect(event.bandwidth, equals(0));
      });

      test('creates with large bandwidth (4K streaming)', () {
        const event = BandwidthEstimateChangedEvent(25000000);

        expect(event.bandwidth, equals(25000000));
      });

      test('toString returns readable representation', () {
        const event = BandwidthEstimateChangedEvent(10000000);

        final str = event.toString();
        expect(str, contains('BandwidthEstimateChangedEvent'));
        expect(str, contains('10000000'));
      });
    });

    group('PipActionTriggeredEvent', () {
      test('creates with playPause action', () {
        const event = PipActionTriggeredEvent(action: PipActionType.playPause);

        expect(event.action, equals(PipActionType.playPause));
      });

      test('creates with skipForward action', () {
        const event = PipActionTriggeredEvent(action: PipActionType.skipForward);

        expect(event.action, equals(PipActionType.skipForward));
      });

      test('creates with skipBackward action', () {
        const event = PipActionTriggeredEvent(action: PipActionType.skipBackward);

        expect(event.action, equals(PipActionType.skipBackward));
      });

      test('creates with skipNext action', () {
        const event = PipActionTriggeredEvent(action: PipActionType.skipNext);

        expect(event.action, equals(PipActionType.skipNext));
      });

      test('creates with skipPrevious action', () {
        const event = PipActionTriggeredEvent(action: PipActionType.skipPrevious);

        expect(event.action, equals(PipActionType.skipPrevious));
      });

      test('toString returns readable representation', () {
        const event = PipActionTriggeredEvent(action: PipActionType.skipForward);

        final str = event.toString();
        expect(str, contains('PipActionTriggeredEvent'));
        expect(str, contains('skipForward'));
      });
    });

    group('PipRestoreUserInterfaceEvent', () {
      test('creates', () {
        const event = PipRestoreUserInterfaceEvent();

        expect(event, isA<PipRestoreUserInterfaceEvent>());
      });

      test('toString returns readable representation', () {
        const event = PipRestoreUserInterfaceEvent();

        expect(event.toString(), contains('PipRestoreUserInterfaceEvent'));
      });
    });

    // Embedded Subtitle Events
    group('EmbeddedSubtitleCueEvent', () {
      test('creates with cue', () {
        const cue = SubtitleCue(start: Duration(seconds: 10), end: Duration(seconds: 15), text: 'Hello world');
        const event = EmbeddedSubtitleCueEvent(cue: cue);

        expect(event.cue, equals(cue));
        expect(event.trackId, isNull);
      });

      test('creates with null cue (hides subtitle)', () {
        const event = EmbeddedSubtitleCueEvent(cue: null);

        expect(event.cue, isNull);
        expect(event.trackId, isNull);
      });

      test('creates with cue and trackId', () {
        const cue = SubtitleCue(start: Duration(seconds: 10), end: Duration(seconds: 15), text: 'Hello world');
        const event = EmbeddedSubtitleCueEvent(cue: cue, trackId: 'en-0');

        expect(event.cue, equals(cue));
        expect(event.trackId, equals('en-0'));
      });

      test('toString returns readable representation with cue', () {
        const cue = SubtitleCue(start: Duration(seconds: 10), end: Duration(seconds: 15), text: 'Hello world');
        const event = EmbeddedSubtitleCueEvent(cue: cue, trackId: 'en-0');

        final str = event.toString();
        expect(str, contains('EmbeddedSubtitleCueEvent'));
        expect(str, contains('en-0'));
      });

      test('toString returns readable representation with null cue', () {
        const event = EmbeddedSubtitleCueEvent(cue: null);

        final str = event.toString();
        expect(str, contains('EmbeddedSubtitleCueEvent'));
        expect(str, contains('null'));
      });
    });

    // Chapter Events
    group('ChaptersExtractedEvent', () {
      test('creates with empty chapters', () {
        const event = ChaptersExtractedEvent([]);

        expect(event.chapters, isEmpty);
      });

      test('creates with chapters', () {
        const chapters = [
          Chapter(id: 'chap-0', title: 'Introduction', startTime: Duration.zero),
          Chapter(id: 'chap-1', title: 'Chapter 1', startTime: Duration(minutes: 5)),
        ];
        const event = ChaptersExtractedEvent(chapters);

        expect(event.chapters, hasLength(2));
        expect(event.chapters[0].title, equals('Introduction'));
        expect(event.chapters[1].title, equals('Chapter 1'));
      });

      test('toString returns readable representation', () {
        const chapters = [Chapter(id: 'chap-0', title: 'Introduction', startTime: Duration.zero)];
        const event = ChaptersExtractedEvent(chapters);

        final str = event.toString();
        expect(str, contains('ChaptersExtractedEvent'));
        expect(str, contains('1'));
      });
    });

    group('CurrentChapterChangedEvent', () {
      test('creates with chapter', () {
        const chapter = Chapter(id: 'chap-0', title: 'Introduction', startTime: Duration.zero);
        const event = CurrentChapterChangedEvent(chapter);

        expect(event.chapter, equals(chapter));
        expect(event.chapter?.title, equals('Introduction'));
      });

      test('creates with null chapter (no chapter at position)', () {
        const event = CurrentChapterChangedEvent(null);

        expect(event.chapter, isNull);
      });

      test('toString returns readable representation with chapter', () {
        const chapter = Chapter(id: 'chap-0', title: 'Introduction', startTime: Duration.zero);
        const event = CurrentChapterChangedEvent(chapter);

        final str = event.toString();
        expect(str, contains('CurrentChapterChangedEvent'));
        expect(str, contains('Introduction'));
      });

      test('toString returns readable representation with null chapter', () {
        const event = CurrentChapterChangedEvent(null);

        final str = event.toString();
        expect(str, contains('CurrentChapterChangedEvent'));
        expect(str, contains('null'));
      });
    });

    test('all event types are sealed VideoPlayerEvent subclasses', () {
      final events = <VideoPlayerEvent>[
        const PlaybackStateChangedEvent(PlaybackState.playing),
        const PositionChangedEvent(Duration.zero),
        const BufferedPositionChangedEvent(Duration.zero),
        const DurationChangedEvent(Duration.zero),
        const PlaybackCompletedEvent(),
        ErrorEvent('error'),
        const VideoSizeChangedEvent(width: 100, height: 100),
        const SubtitleTracksChangedEvent([]),
        const SelectedSubtitleChangedEvent(null),
        const AudioTracksChangedEvent([]),
        const SelectedAudioChangedEvent(null),
        // Video quality events
        const VideoQualityTracksChangedEvent([]),
        const SelectedQualityChangedEvent(VideoQualityTrack.auto),
        const PipStateChangedEvent(isActive: false),
        // PiP remote actions events
        const PipActionTriggeredEvent(action: PipActionType.playPause),
        const PipRestoreUserInterfaceEvent(),
        const PlaybackSpeedChangedEvent(1),
        const VolumeChangedEvent(1),
        const MetadataChangedEvent(),
        const PlaylistTrackChangedEvent(0),
        const PlaylistEndedEvent(),
        const FullscreenStateChangedEvent(isFullscreen: false),
        const BackgroundPlaybackChangedEvent(isEnabled: false),
        // Network resilience events
        const BufferingStartedEvent(),
        const BufferingEndedEvent(),
        const NetworkErrorEvent(message: 'error'),
        const PlaybackRecoveredEvent(),
        const NetworkStateChangedEvent(isConnected: true),
        // Bandwidth estimation
        const BandwidthEstimateChangedEvent(5000000),
        // Chapter events
        const ChaptersExtractedEvent([]),
        const CurrentChapterChangedEvent(null),
        // Embedded subtitle events
        const EmbeddedSubtitleCueEvent(cue: null),
      ];

      for (final event in events) {
        expect(event, isA<VideoPlayerEvent>());
      }
    });
  });
}
