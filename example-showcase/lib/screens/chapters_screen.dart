import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates chapter navigation support.
///
/// Shows how to:
/// - View available chapters extracted from video metadata
/// - Navigate between chapters using the controller API
/// - Use the built-in chapters button in player controls
class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key});

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
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
        source: const VideoSource.asset(VideoAssets.sampleWithChapters),
        options: const VideoPlayerOptions(autoPlay: true),
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chapter Navigation')),
    body: _error != null
        ? _buildErrorState()
        : !_isInitialized
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
  );

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text('Error: $_error'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            setState(() => _error = null);
            unawaited(_initializePlayer());
          },
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _buildContent() => ResponsiveVideoLayout(
    videoPlayer: ProVideoPlayer(
      controller: _controller,
      placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
      controlsBuilder: (context, controller) =>
          VideoPlayerControls(controller: controller, compactMode: CompactMode.never),
    ),
    controls: _buildControlPanel(),
  );

  Widget _buildControlPanel() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(),
        const SizedBox(height: 16),
        _buildChaptersCard(),
        const SizedBox(height: 16),
        _buildNavigationCard(),
        const SizedBox(height: 16),
        _buildApiCard(),
      ],
    ),
  );

  Widget _buildInfoCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('About Chapters', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Chapters are time-marked sections of a video with titles, commonly used for navigation '
            '(e.g., "Introduction", "Chapter 1: Setup", etc.).\n\n'
            'Chapters can be embedded in:\n'
            '• MP4 files (QuickTime chapter tracks)\n'
            '• MKV files (chapter markers)\n'
            '• HLS/DASH streams (manifest metadata)\n\n'
            'This demo uses a sample video with 3 embedded chapters. '
            'Tap on a chapter below to seek to that position.',
          ),
        ],
      ),
    ),
  );

  Widget _buildChaptersCard() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Available Chapters',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text('${value.chapters.length} chapters')),
              ],
            ),
            const SizedBox(height: 12),
            if (value.chapters.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('No chapters detected in this video')),
                  ],
                ),
              )
            else
              ...value.chapters.map((chapter) => _buildChapterTile(chapter, value.currentChapter)),
          ],
        ),
      ),
    ),
  );

  Widget _buildChapterTile(Chapter chapter, Chapter? currentChapter) {
    final isActive = chapter == currentChapter;

    return ListTile(
      dense: true,
      selected: isActive,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isActive ? Icons.play_arrow : Icons.bookmark_outline,
          color: isActive ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      title: Text(chapter.title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : null)),
      subtitle: Text(chapter.formattedStartTime),
      trailing: isActive ? const Icon(Icons.volume_up, size: 16) : null,
      onTap: () => _controller.seekToChapter(chapter),
    );
  }

  Widget _buildNavigationCard() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.skip_next, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Chapter Navigation', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (value.currentChapter != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Chapter', style: TextStyle(fontSize: 12)),
                          Text(value.currentChapter!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: value.hasChapters ? () => _controller.seekToPreviousChapter() : null,
                    icon: const Icon(Icons.skip_previous),
                    label: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: value.hasChapters ? () => _controller.seekToNextChapter() : null,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildApiCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Controller API', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SelectableText(
              '// Get available chapters\n'
              'List<Chapter> chapters = controller.chapters;\n\n'
              '// Get current chapter\n'
              'Chapter? current = controller.currentChapter;\n\n'
              '// Check if video has chapters\n'
              'bool hasChapters = controller.hasChapters;\n\n'
              '// Navigate to specific chapter\n'
              'await controller.seekToChapter(chapter);\n\n'
              '// Navigate to next/previous\n'
              'await controller.seekToNextChapter();\n'
              'await controller.seekToPreviousChapter();',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
