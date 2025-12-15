import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Streaming format type for demo selection.
enum _StreamFormat {
  hls('HLS (.m3u8)', 'All platforms'),
  dash('DASH (.mpd)', 'Android & Web only');

  const _StreamFormat(this.label, this.platforms);
  final String label;
  final String platforms;
}

/// Demonstrates video quality selection for adaptive streams (HLS/DASH).
///
/// Shows how to:
/// - Get available quality tracks
/// - Switch between quality levels
/// - Enable automatic quality selection (ABR)
/// - Monitor bandwidth estimation
/// - Switch between HLS and DASH streams
class QualitySelectionScreen extends StatefulWidget {
  const QualitySelectionScreen({super.key});

  @override
  State<QualitySelectionScreen> createState() => _QualitySelectionScreenState();
}

class _QualitySelectionScreenState extends State<QualitySelectionScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _qualitySelectionSupported = false;
  List<VideoQualityTrack> _qualityTracks = [];
  VideoQualityTrack? _selectedQuality;
  _StreamFormat _selectedFormat = _StreamFormat.hls;

  // ABR configuration
  AbrMode _abrMode = AbrMode.auto;
  double _minBitrateMbps = 0; // 0 = no limit
  double _maxBitrateMbps = 0; // 0 = no limit

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      final url = _selectedFormat == _StreamFormat.hls ? VideoUrls.bitmovinSintelHls : VideoUrls.bitmovinSintelDash;

      await _controller.initialize(
        source: VideoSource.network(url),
        options: VideoPlayerOptions(
          autoPlay: true,
          abrMode: _abrMode,
          minBitrate: _minBitrateMbps > 0 ? (_minBitrateMbps * 1000000).toInt() : null,
          maxBitrate: _maxBitrateMbps > 0 ? (_maxBitrateMbps * 1000000).toInt() : null,
        ),
      );

      final supported = await _controller.isQualitySelectionSupported();
      final tracks = await _controller.getVideoQualities();
      final current = await _controller.getCurrentVideoQuality();

      setState(() {
        _isInitialized = true;
        _qualitySelectionSupported = supported;
        _qualityTracks = tracks;
        _selectedQuality = current;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _switchFormat(_StreamFormat format) async {
    if (format == _selectedFormat) return;

    setState(() {
      _selectedFormat = format;
      _isInitialized = false;
      _error = null;
      _qualityTracks = [];
      _selectedQuality = null;
    });

    await _controller.dispose();
    _controller = ProVideoPlayerController();
    await _initializePlayer();
  }

  bool get _isDashSupported => kIsWeb || (!kIsWeb && Platform.isAndroid);

  Future<void> _setQuality(VideoQualityTrack track) async {
    final success = await _controller.setVideoQuality(track);
    if (success) {
      setState(() => _selectedQuality = track);
    }
  }

  Future<void> _applyAbrSettings() async {
    setState(() {
      _isInitialized = false;
      _error = null;
      _qualityTracks = [];
      _selectedQuality = null;
    });

    await _controller.dispose();
    _controller = ProVideoPlayerController();
    await _initializePlayer();
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quality Selection')),
    body: _error != null
        ? _buildErrorState()
        : !_isInitialized
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
  );

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isInitialized = false;
              });
              unawaited(_initializePlayer());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildContent() => ResponsiveVideoLayout(
    videoPlayer: ProVideoPlayer(
      controller: _controller,
      placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
    ),
    controls: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormatSelector(),
          const Divider(),
          _buildAbrConfig(),
          const Divider(),
          _buildQualitySupport(),
          const Divider(),
          _buildQualitySelector(),
          const Divider(),
          _buildBandwidthInfo(),
          const Divider(),
          _buildPlaybackControls(),
        ],
      ),
    ),
    maxVideoHeightFraction: 0.35,
  );

  Widget _buildFormatSelector() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Streaming Format', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<_StreamFormat>(
          segments: [
            ButtonSegment(
              value: _StreamFormat.hls,
              label: Text(_StreamFormat.hls.label),
              icon: const Icon(Icons.play_circle_outline),
            ),
            ButtonSegment(
              value: _StreamFormat.dash,
              label: Text(_StreamFormat.dash.label),
              icon: const Icon(Icons.play_circle_outline),
              enabled: _isDashSupported,
            ),
          ],
          selected: {_selectedFormat},
          onSelectionChanged: (selected) => unawaited(_switchFormat(selected.first)),
        ),
        const SizedBox(height: 8),
        if (!_isDashSupported)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "DASH is only supported on Android and Web. iOS/macOS use AVPlayer which doesn't support DASH.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _buildAbrConfig() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ABR Configuration', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        // ABR Mode selector
        Row(
          children: [
            const Text('Mode: '),
            const SizedBox(width: 8),
            SegmentedButton<AbrMode>(
              segments: const [
                ButtonSegment(value: AbrMode.auto, label: Text('Auto'), icon: Icon(Icons.auto_awesome)),
                ButtonSegment(value: AbrMode.manual, label: Text('Manual'), icon: Icon(Icons.tune)),
              ],
              selected: {_abrMode},
              onSelectionChanged: (selected) => setState(() => _abrMode = selected.first),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Min bitrate slider
        Row(
          children: [
            const SizedBox(width: 80, child: Text('Min Bitrate:')),
            Expanded(
              child: Slider(
                value: _minBitrateMbps,
                max: 10,
                divisions: 20,
                label: _minBitrateMbps == 0 ? 'No limit' : '${_minBitrateMbps.toStringAsFixed(1)} Mbps',
                onChanged: (v) => setState(() => _minBitrateMbps = v),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(_minBitrateMbps == 0 ? 'No limit' : '${_minBitrateMbps.toStringAsFixed(1)} Mbps'),
            ),
          ],
        ),
        // Max bitrate slider
        Row(
          children: [
            const SizedBox(width: 80, child: Text('Max Bitrate:')),
            Expanded(
              child: Slider(
                value: _maxBitrateMbps,
                max: 10,
                divisions: 20,
                label: _maxBitrateMbps == 0 ? 'No limit' : '${_maxBitrateMbps.toStringAsFixed(1)} Mbps',
                onChanged: (v) => setState(() => _maxBitrateMbps = v),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(_maxBitrateMbps == 0 ? 'No limit' : '${_maxBitrateMbps.toStringAsFixed(1)} Mbps'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Platform note
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'iOS/macOS only support max bitrate. Min bitrate is ignored on Apple platforms.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Apply button
        FilledButton.icon(
          onPressed: _applyAbrSettings,
          icon: const Icon(Icons.refresh),
          label: const Text('Apply & Restart Player'),
        ),
      ],
    ),
  );

  Widget _buildQualitySupport() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quality Selection Support', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _qualitySelectionSupported
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _qualitySelectionSupported ? Colors.green : Colors.orange),
          ),
          child: Row(
            children: [
              Icon(
                _qualitySelectionSupported ? Icons.check_circle : Icons.info_outline,
                color: _qualitySelectionSupported ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _qualitySelectionSupported
                      ? 'Quality selection is available for this stream'
                      : 'Quality selection requires adaptive streams (HLS/DASH)',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Using: Sintel ${_selectedFormat.label} Stream (Multiple Quality Levels)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );

  Widget _buildQualitySelector() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Qualities', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_qualityTracks.isEmpty)
          const Text('No quality tracks available')
        else
          ..._qualityTracks.map(
            (track) => _QualityTile(
              track: track,
              isSelected: _selectedQuality?.id == track.id,
              onTap: () => _setQuality(track),
            ),
          ),
      ],
    ),
  );

  Widget _buildBandwidthInfo() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Network Info', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Estimated Bandwidth',
            value: value.estimatedBandwidth != null
                ? '${(value.estimatedBandwidth! / 1000000).toStringAsFixed(2)} Mbps'
                : 'Unknown',
          ),
          _InfoRow(label: 'Current Quality', value: value.selectedQualityTrack?.displayLabel ?? 'Auto'),
          _InfoRow(label: 'Buffered', value: _formatDuration(value.bufferedPosition)),
        ],
      ),
    ),
  );

  Widget _buildPlaybackControls() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Playback', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Slider(
            value: value.position.inMilliseconds.toDouble(),
            max: value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
            onChanged: (v) => unawaited(_controller.seekTo(Duration(milliseconds: v.toInt()))),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(_formatDuration(value.position)), Text(_formatDuration(value.duration))],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () => unawaited(_controller.seekBackward(const Duration(seconds: 10))),
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 56,
                icon: Icon(value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: () => unawaited(_controller.togglePlayPause()),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () => unawaited(_controller.seekForward(const Duration(seconds: 10))),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _QualityTile extends StatelessWidget {
  const _QualityTile({required this.track, required this.isSelected, required this.onTap});

  final VideoQualityTrack track;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAuto = track.isAuto;

    return ListTile(
      leading: Icon(
        isAuto ? Icons.auto_awesome : Icons.high_quality,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(track.displayLabel, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: isAuto
          ? const Text('Automatic quality based on network')
          : Text('${track.resolution} - ${track.bitrateInMbps.toStringAsFixed(1)} Mbps'),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    ),
  );
}
