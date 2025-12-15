import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Screen demonstrating audio and subtitle track selection.
class StreamSelectionScreen extends StatefulWidget {
  const StreamSelectionScreen({super.key});

  @override
  State<StreamSelectionScreen> createState() => _StreamSelectionScreenState();
}

class _StreamSelectionScreenState extends State<StreamSelectionScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitializing = false;

  static const _sources = [
    _SourceOption(label: 'Shaka (Angel One HLS)', url: VideoUrls.shakaAngelOneHls),
    _SourceOption(label: 'Bitmovin (Sintel HLS)', url: VideoUrls.bitmovinSintelHls),
    _SourceOption(label: 'AWS (Bipbop Advanced HLS)', url: VideoUrls.awsBipbopHls),
  ];

  _SourceOption _selectedSource = _sources.first;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer(_selectedSource, _controller));
  }

  Future<void> _initializePlayer(_SourceOption source, ProVideoPlayerController controller) async {
    if (mounted) {
      setState(() => _isInitializing = true);
    }
    try {
      await controller.initialize(
        source: VideoSource.network(source.url),
        options: const VideoPlayerOptions(
          autoPlay: true,
          showSubtitlesByDefault: true,
          preferredSubtitleLanguage: 'en',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize player: $e')));
      }
    } finally {
      if (mounted && identical(controller, _controller)) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _switchSource(_SourceOption source) async {
    if (source.url == _selectedSource.url) return;
    final oldController = _controller;
    if (mounted) {
      setState(() => _isInitializing = true);
    }
    await oldController.dispose();
    final newController = ProVideoPlayerController();
    if (mounted) {
      setState(() {
        _selectedSource = source;
        _controller = newController;
      });
    } else {
      return;
    }
    await _initializePlayer(source, newController);
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Stream Selection')),
    body: ResponsiveVideoLayout(
      videoPlayer: ProVideoPlayer(
        controller: _controller,
        controlsBuilder: (context, controller) => VideoPlayerControls(controller: controller),
      ),
      controls: _buildInfoPanel(),
    ),
  );

  Widget _buildInfoPanel() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Video Source'),
        const SizedBox(height: 8),
        DropdownButton<String>(
          key: const Key('streamSelection.videoDropdown'),
          value: _selectedSource.url,
          isExpanded: true,
          onChanged: _isInitializing
              ? null
              : (value) {
                  final option = _sources.firstWhere((s) => s.url == value);
                  unawaited(_switchSource(option));
                },
          items: _sources.map((s) => DropdownMenuItem<String>(value: s.url, child: Text(s.label))).toList(),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Audio & Subtitle Track Selection'),
        const SizedBox(height: 8),
        const Text(
          'This demo shows how to select different audio and subtitle tracks when multiple streams are available.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Features'),
        const SizedBox(height: 8),
        _buildFeatureItem('🎵', 'Multiple audio tracks', 'Switch between different audio languages or quality'),
        _buildFeatureItem('📝', 'Subtitle selection', 'Enable, disable, or change subtitle languages'),
        _buildFeatureItem('🎨', 'Clean UI', 'Easy-to-use picker dialogs for track selection'),
        _buildFeatureItem('🔄', 'Real-time switching', 'Change tracks without interrupting playback'),
        const SizedBox(height: 24),
        _buildSectionTitle('Network & Quality Info'),
        const SizedBox(height: 8),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, child) => _buildNetworkInfo(value),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Available Tracks'),
        const SizedBox(height: 8),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrackInfo('Audio Tracks', value.audioTracks, value.selectedAudioTrack),
              const SizedBox(height: 16),
              _buildTrackInfo('Subtitle Tracks', value.subtitleTracks, value.selectedSubtitleTrack),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('How to Use'),
        const SizedBox(height: 8),
        _buildStepItem('1', 'Look for the 🎵 (audio) or CC (subtitle) buttons in the video controls'),
        _buildStepItem('2', 'Tap the button to open the track selection dialog'),
        _buildStepItem('3', 'Select your preferred track from the list'),
        _buildStepItem('4', 'The track will switch immediately without pausing playback'),
        const SizedBox(height: 24),
        _buildSectionTitle('Notes'),
        const SizedBox(height: 8),
        _buildNoteItem('📌', 'The audio button only appears when the video has multiple audio tracks available.'),
        _buildNoteItem(
          '📌',
          'The subtitle button only appears when subtitle tracks are available and subtitles are enabled.',
        ),
        _buildNoteItem(
          '📌',
          'Most standard MP4 videos have a single audio track. Videos with multiple audio tracks are typically HLS/DASH adaptive streams or specially-encoded multi-language content.',
        ),
        _buildNoteItem('📌', 'Track selection persists throughout the video playback session.'),
      ],
    ),
  );

  Widget _buildSectionTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));

  Widget _buildNetworkInfo(VideoPlayerValue value) {
    final bandwidth = value.estimatedBandwidth;
    final quality = value.selectedQualityTrack;

    return Card(
      key: const Key('streamSelection.networkInfo'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandwidth info
            Row(
              children: [
                Icon(
                  Icons.network_check,
                  size: 20,
                  color: bandwidth != null ? _getBandwidthColor(bandwidth) : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text('Bandwidth: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  key: const Key('streamSelection.bandwidthValue'),
                  bandwidth != null ? _formatBandwidth(bandwidth) : 'Measuring...',
                  style: TextStyle(
                    color: bandwidth != null ? _getBandwidthColor(bandwidth) : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Current quality info
            Row(
              children: [
                const Icon(Icons.high_quality, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Quality: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(quality?.displayLabel ?? 'Auto', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            if (bandwidth != null) ...[const SizedBox(height: 12), _buildBandwidthIndicator(bandwidth)],
          ],
        ),
      ),
    );
  }

  String _formatBandwidth(int bitsPerSecond) {
    final mbps = bitsPerSecond / 1000000;
    if (mbps >= 1) {
      return '${mbps.toStringAsFixed(1)} Mbps';
    } else {
      final kbps = bitsPerSecond / 1000;
      return '${kbps.toStringAsFixed(0)} Kbps';
    }
  }

  Color _getBandwidthColor(int bitsPerSecond) {
    final mbps = bitsPerSecond / 1000000;
    if (mbps >= 10) return Colors.green;
    if (mbps >= 5) return Colors.lightGreen;
    if (mbps >= 2) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBandwidthIndicator(int bitsPerSecond) {
    final mbps = bitsPerSecond / 1000000;
    // Scale: 0-25 Mbps maps to 0-100%
    final percentage = (mbps / 25).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: const Key('streamSelection.bandwidthIndicator'),
                  value: percentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_getBandwidthColor(bitsPerSecond)),
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            Text(
              _getQualityRecommendation(bitsPerSecond),
              style: TextStyle(fontSize: 11, color: _getBandwidthColor(bitsPerSecond), fontWeight: FontWeight.w500),
            ),
            Text('25+ Mbps', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  String _getQualityRecommendation(int bitsPerSecond) {
    final mbps = bitsPerSecond / 1000000;
    if (mbps >= 25) return 'Excellent for 4K';
    if (mbps >= 10) return 'Good for 1080p';
    if (mbps >= 5) return 'Good for 720p';
    if (mbps >= 2) return 'Good for 480p';
    return 'Low bandwidth';
  }

  Widget _buildFeatureItem(String emoji, String title, String description) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(description, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildTrackInfo(String title, List<Object> tracks, Object? selectedTrack) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (tracks.isEmpty)
            const Text('No tracks available', style: TextStyle(color: Colors.grey))
          else
            ...tracks.map((track) {
              final isSelected =
                  selectedTrack != null &&
                  ((track is SubtitleTrack && track.id == (selectedTrack as SubtitleTrack).id) ||
                      (track is AudioTrack && track.id == (selectedTrack as AudioTrack).id));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        track is SubtitleTrack
                            ? track.label
                            : track is AudioTrack
                            ? track.label
                            : 'Unknown',
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                    ),
                    if (track is SubtitleTrack && track.language != null)
                      Text(track.language!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (track is AudioTrack && track.language != null)
                      Text(track.language!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    ),
  );

  Widget _buildStepItem(String number, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _buildNoteItem(String emoji, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ),
      ],
    ),
  );
}

class _SourceOption {
  const _SourceOption({required this.label, required this.url});
  final String label;
  final String url;
}
