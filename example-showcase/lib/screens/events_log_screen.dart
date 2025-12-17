import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../constants/video_constants.dart';
import '../test_keys.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates the events callback system with a live event log.
class EventsLogScreen extends StatefulWidget {
  const EventsLogScreen({super.key});

  @override
  State<EventsLogScreen> createState() => _EventsLogScreenState();
}

class _EventsLogScreenState extends State<EventsLogScreen> {
  late ProVideoPlayerController _controller;
  StreamSubscription<VideoPlayerEvent>? _eventSubscription;
  final List<_EventLogEntry> _eventLog = [];
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  bool _autoScroll = true;
  bool _filterPositionEvents = true;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    await _controller.initialize(
      source: const VideoSource.network(VideoUrls.bigBuckBunny),
      options: VideoPlayerOptions(autoPlay: kIsWeb),
    );

    // Subscribe to events from the platform interface
    final playerId = _controller.playerId;
    if (playerId != null) {
      _eventSubscription = ProVideoPlayerPlatform.instance.events(playerId).listen(_onEvent);
    }

    setState(() => _isInitialized = true);
  }

  void _onEvent(VideoPlayerEvent event) {
    // Optionally filter out position events (they fire frequently)
    if (_filterPositionEvents && event is PositionChangedEvent) {
      return;
    }

    setState(() {
      _eventLog.add(_EventLogEntry(event: event, timestamp: DateTime.now()));

      // Keep last 100 events to avoid memory issues
      if (_eventLog.length > 100) {
        _eventLog.removeAt(0);
      }
    });

    // Auto-scroll to bottom
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          unawaited(
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ),
          );
        }
      });
    }
  }

  void _clearLog() {
    setState(_eventLog.clear);
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    unawaited(_controller.dispose());
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Events Log'),
      actions: [
        IconButton(
          key: TestKeys.eventsLogClearButton,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Clear log',
          onPressed: _clearLog,
        ),
      ],
    ),
    body: ResponsiveVideoLayout(
      videoPlayer: ColoredBox(
        color: Colors.black,
        child: _isInitialized
            ? ProVideoPlayer(
                key: TestKeys.eventsLogVideoPlayer,
                controller: _controller,
                placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Controls
          _buildControls(),

          // Filter options
          _buildFilterOptions(),

          const Divider(),

          // Event log - needs to expand within the scrollable area
          Flexible(child: _buildEventLog()),
        ],
      ),
      maxVideoHeightFraction: 0.3,
    ),
  );

  Widget _buildControls() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            key: TestKeys.eventsLogSeekBackwardButton,
            icon: const Icon(Icons.replay_10),
            onPressed: () => unawaited(_controller.seekBackward(const Duration(seconds: 10))),
          ),
          IconButton(
            key: TestKeys.eventsLogPlayPauseButton,
            iconSize: 48,
            icon: Icon(value.isPlaying ? Icons.pause_circle : Icons.play_circle),
            onPressed: () => unawaited(_controller.togglePlayPause()),
          ),
          IconButton(
            key: TestKeys.eventsLogSeekForwardButton,
            icon: const Icon(Icons.forward_10),
            onPressed: () => unawaited(_controller.seekForward(const Duration(seconds: 10))),
          ),
          const SizedBox(width: 16),
          // Volume control to trigger VolumeChangedEvent
          IconButton(
            key: TestKeys.eventsLogMuteButton,
            icon: Icon(value.volume == 0 ? Icons.volume_off : Icons.volume_up),
            onPressed: () => unawaited(_controller.setVolume(value.volume == 0 ? 1.0 : 0.0)),
          ),
          // Speed control to trigger PlaybackSpeedChangedEvent
          PopupMenuButton<double>(
            key: TestKeys.eventsLogSpeedButton,
            icon: const Icon(Icons.speed),
            tooltip: 'Playback speed',
            onSelected: (speed) => unawaited(_controller.setPlaybackSpeed(speed)),
            itemBuilder: (context) => [
              0.5,
              0.75,
              1.0,
              1.25,
              1.5,
              2.0,
            ].map((speed) => PopupMenuItem(value: speed, child: Text('${speed}x'))).toList(),
          ),
        ],
      ),
    ),
  );

  Widget _buildFilterOptions() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      spacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              key: TestKeys.eventsLogFilterPositionCheckbox,
              value: _filterPositionEvents,
              onChanged: (value) => setState(() => _filterPositionEvents = value ?? true),
            ),
            const Text('Filter position'),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              key: TestKeys.eventsLogAutoScrollCheckbox,
              value: _autoScroll,
              onChanged: (value) => setState(() => _autoScroll = value ?? true),
            ),
            const Text('Auto-scroll'),
          ],
        ),
      ],
    ),
  );

  Widget _buildEventLog() {
    if (_eventLog.isEmpty) {
      return Center(
        key: TestKeys.eventsLogEmptyState,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No events yet'),
            const Text('Interact with the player to see events'),
          ],
        ),
      );
    }

    return ListView.builder(
      key: TestKeys.eventsLogList,
      controller: _scrollController,
      shrinkWrap: true, // Required when nested in SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Parent handles scrolling
      padding: const EdgeInsets.all(8),
      itemCount: _eventLog.length,
      itemBuilder: (context, index) {
        final entry = _eventLog[index];
        return _EventLogTile(key: TestKeys.eventsLogItem(index), entry: entry, index: index);
      },
    );
  }
}

class _EventLogEntry {
  _EventLogEntry({required this.event, required this.timestamp});

  final VideoPlayerEvent event;
  final DateTime timestamp;
}

class _EventLogTile extends StatelessWidget {
  const _EventLogTile({required this.entry, required this.index, super.key});

  final _EventLogEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final event = entry.event;
    final (icon, color, title, subtitle) = _getEventDetails(event);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(_formatTimestamp(entry.timestamp), style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String, String) _getEventDetails(VideoPlayerEvent event) => switch (event) {
    PlaybackStateChangedEvent(:final state) => (
      Icons.play_arrow,
      Colors.blue,
      'PlaybackStateChanged',
      'State: ${state.name}',
    ),
    PositionChangedEvent(:final position) => (
      Icons.timer,
      Colors.orange,
      'PositionChanged',
      'Position: ${_formatDuration(position)}',
    ),
    BufferedPositionChangedEvent(:final bufferedPosition) => (
      Icons.download,
      Colors.cyan,
      'BufferedPositionChanged',
      'Buffered: ${_formatDuration(bufferedPosition)}',
    ),
    DurationChangedEvent(:final duration) => (
      Icons.schedule,
      Colors.purple,
      'DurationChanged',
      'Duration: ${_formatDuration(duration)}',
    ),
    PlaybackCompletedEvent() => (Icons.check_circle, Colors.green, 'PlaybackCompleted', ''),
    ErrorEvent(:final message, :final code) => (
      Icons.error,
      Colors.red,
      'Error',
      code != null ? '[$code] $message' : message,
    ),
    VideoSizeChangedEvent(:final width, :final height) => (
      Icons.aspect_ratio,
      Colors.teal,
      'VideoSizeChanged',
      'Size: ${width}x$height',
    ),
    SubtitleTracksChangedEvent(:final tracks) => (
      Icons.subtitles,
      Colors.indigo,
      'SubtitleTracksChanged',
      '${tracks.length} track(s) available',
    ),
    SelectedSubtitleChangedEvent(:final track) => (
      Icons.closed_caption,
      Colors.indigo,
      'SelectedSubtitleChanged',
      track != null ? 'Selected: ${track.label}' : 'Subtitles off',
    ),
    PlaylistTrackChangedEvent(:final index) => (
      Icons.skip_next,
      Colors.deepPurple,
      'PlaylistTrackChanged',
      'Track ${index + 1}',
    ),
    PlaylistEndedEvent() => (Icons.playlist_play, Colors.deepOrange, 'PlaylistEnded', 'Playlist completed'),
    PipStateChangedEvent(:final isActive) => (
      Icons.picture_in_picture,
      Colors.amber,
      'PipStateChanged',
      isActive ? 'Entered PiP' : 'Exited PiP',
    ),
    FullscreenStateChangedEvent(:final isFullscreen) => (
      Icons.fullscreen,
      Colors.deepOrange,
      'FullscreenStateChanged',
      isFullscreen ? 'Entered fullscreen' : 'Exited fullscreen',
    ),
    PlaybackSpeedChangedEvent(:final speed) => (Icons.speed, Colors.pink, 'PlaybackSpeedChanged', 'Speed: ${speed}x'),
    VolumeChangedEvent(:final volume) => (
      Icons.volume_up,
      Colors.lightBlue,
      'VolumeChanged',
      'Volume: ${(volume * 100).round()}%',
    ),
    AudioTracksChangedEvent(:final tracks) => (
      Icons.audiotrack,
      Colors.deepPurple,
      'AudioTracksChanged',
      '${tracks.length} track(s) available',
    ),
    SelectedAudioChangedEvent(:final track) => (
      Icons.audiotrack,
      Colors.deepPurple,
      'SelectedAudioChanged',
      track != null ? 'Selected: ${track.label}' : 'Default audio',
    ),
    VideoQualityTracksChangedEvent(:final tracks) => (
      Icons.high_quality,
      Colors.blueAccent,
      'VideoQualityTracksChanged',
      '${tracks.length} quality option(s) available',
    ),
    SelectedQualityChangedEvent(:final track) => (
      Icons.high_quality,
      Colors.blueAccent,
      'SelectedQualityChanged',
      'Selected: ${track.displayLabel}',
    ),
    BackgroundPlaybackChangedEvent(:final isEnabled) => (
      Icons.headphones,
      isEnabled ? Colors.green : Colors.grey,
      'BackgroundPlaybackChanged',
      isEnabled ? 'Enabled' : 'Disabled',
    ),
    MetadataChangedEvent(:final title) => (
      Icons.info,
      Colors.blueGrey,
      'MetadataChanged',
      title != null ? 'Title: $title' : 'No metadata',
    ),
    // Network Resilience Events
    BufferingStartedEvent(:final reason) => (
      Icons.hourglass_top,
      Colors.orange,
      'BufferingStarted',
      'Reason: ${reason.name}',
    ),
    BufferingEndedEvent() => (Icons.hourglass_bottom, Colors.green, 'BufferingEnded', 'Buffering complete'),
    NetworkErrorEvent(:final message, :final willRetry, :final retryAttempt, :final maxRetries) => (
      Icons.wifi_off,
      willRetry ? Colors.orange : Colors.red,
      'NetworkError',
      willRetry ? 'Retry $retryAttempt/$maxRetries: $message' : message,
    ),
    PlaybackRecoveredEvent(:final retriesUsed) => (
      Icons.wifi,
      Colors.green,
      'PlaybackRecovered',
      retriesUsed > 0 ? 'Recovered after $retriesUsed retries' : 'Recovered',
    ),
    NetworkStateChangedEvent(:final isConnected) => (
      isConnected ? Icons.signal_wifi_4_bar : Icons.signal_wifi_off,
      isConnected ? Colors.green : Colors.red,
      'NetworkStateChanged',
      isConnected ? 'Connected' : 'Disconnected',
    ),
    PipActionTriggeredEvent(:final action) => (
      Icons.touch_app,
      Colors.amber,
      'PipActionTriggered',
      'Action: ${action.name}',
    ),
    PipRestoreUserInterfaceEvent() => (
      Icons.open_in_full,
      Colors.amber,
      'PipRestoreUserInterface',
      'User requested to return from PiP',
    ),
    BandwidthEstimateChangedEvent(:final bandwidth) => (
      Icons.network_check,
      Colors.lightGreen,
      'BandwidthEstimateChanged',
      '${(bandwidth / 1000000).toStringAsFixed(1)} Mbps',
    ),
    VideoMetadataExtractedEvent(:final metadata) => (
      Icons.video_library,
      Colors.teal,
      'VideoMetadataExtracted',
      metadata.videoCodec != null ? '${metadata.videoCodec}' : 'Metadata extracted',
    ),
    CastStateChangedEvent(:final state, :final device) => (
      Icons.cast_connected,
      Colors.blue,
      'CastStateChanged',
      device != null ? '${state.name}: ${device.name}' : state.name,
    ),
    CastDevicesChangedEvent(:final devices) => (
      Icons.cast,
      Colors.blueGrey,
      'CastDevicesChanged',
      '${devices.length} device(s) available',
    ),
    ChaptersExtractedEvent(:final chapters) => (
      Icons.list,
      Colors.deepPurple,
      'ChaptersExtracted',
      '${chapters.length} chapter(s) found',
    ),
    CurrentChapterChangedEvent(:final chapter) => (
      Icons.bookmark,
      Colors.deepPurple,
      'CurrentChapterChanged',
      chapter?.title ?? 'No chapter',
    ),
    EmbeddedSubtitleCueEvent(:final cue) => (
      Icons.closed_caption,
      Colors.indigo,
      'EmbeddedSubtitleCue',
      cue?.text ?? 'Cue cleared',
    ),
  };

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTimestamp(DateTime timestamp) {
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    final seconds = timestamp.second.toString().padLeft(2, '0');
    final millis = timestamp.millisecond.toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }
}
