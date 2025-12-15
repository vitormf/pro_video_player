import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../test_keys.dart';
import '../widgets/responsive_video_layout.dart';

class VideoMetadataScreen extends StatefulWidget {
  const VideoMetadataScreen({super.key});
  @override
  State<VideoMetadataScreen> createState() => _VideoMetadataScreenState();
}

class _VideoMetadataScreenState extends State<VideoMetadataScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      await _controller.initialize(
        source: const VideoSource.network(VideoUrls.bitmovinSintelHls),
        options: const VideoPlayerOptions(autoPlay: true),
      );
      _controller.addListener(_onUpdate);
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Video Metadata')),
    body: _error != null
        ? Center(child: Text('Error: $_error'))
        : !_isInitialized
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
  );

  Widget _buildContent() => ResponsiveVideoLayout(
    videoPlayer: ProVideoPlayer(key: TestKeys.videoMetadataVideoPlayer, controller: _controller),
    controls: SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildMetadataSection()]),
    ),
    maxVideoHeightFraction: 0.35,
  );

  Widget _buildMetadataSection() => Padding(
    key: TestKeys.videoMetadataInfoSection,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video Metadata', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (_controller.videoMetadata == null) const Text('Waiting...') else _buildMetadataGrid(),
      ],
    ),
  );

  Widget _buildMetadataGrid() {
    final m = _controller.videoMetadata!;
    return Column(
      children: [
        _MetadataRow(icon: Icons.videocam, label: 'Video Codec', value: m.videoCodec ?? 'Unknown'),
        _MetadataRow(icon: Icons.audiotrack, label: 'Audio Codec', value: m.audioCodec ?? 'Unknown'),
        _MetadataRow(icon: Icons.aspect_ratio, label: 'Resolution', value: m.resolution ?? 'Unknown'),
        _MetadataRow(icon: Icons.folder, label: 'Container', value: m.containerFormat ?? 'Unknown'),
        _MetadataRow(icon: Icons.high_quality, label: 'Quality', value: m.isHD ? 'HD' : 'SD'),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value),
      ],
    ),
  );
}
