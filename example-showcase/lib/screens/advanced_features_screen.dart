import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../test_keys.dart';

/// Demonstrates advanced features: error handling, multiple players.
class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  State<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Advanced Features'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(key: TestKeys.errorHandlingTab, icon: Icon(Icons.error_outline), text: 'Error Handling'),
          Tab(key: TestKeys.multiPlayerTab, icon: Icon(Icons.grid_view), text: 'Multi-Player'),
        ],
      ),
    ),
    body: TabBarView(controller: _tabController, children: const [_ErrorHandlingDemo(), _MultiPlayerDemo()]),
  );
}

// -----------------------------------------------------------------------------
// Error Handling Demo
// -----------------------------------------------------------------------------
class _ErrorHandlingDemo extends StatefulWidget {
  const _ErrorHandlingDemo();

  @override
  State<_ErrorHandlingDemo> createState() => _ErrorHandlingDemoState();
}

class _ErrorHandlingDemoState extends State<_ErrorHandlingDemo> with AutomaticKeepAliveClientMixin {
  ProVideoPlayerController? _controller;
  String? _lastError;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadVideo(String url, String description) async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    await _controller?.dispose();
    _controller = ProVideoPlayerController();

    try {
      await _controller!.initialize(source: VideoSource.network(url));
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastError = 'Failed to load "$description": $e';
      });
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error Handling Demo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Test how the player handles various error scenarios. '
            'Tap a button below to trigger different error conditions.',
          ),
          const SizedBox(height: 24),

          // Error trigger buttons
          _ErrorButton(
            key: TestKeys.errorHandlingInvalidUrlButton,
            icon: Icons.link_off,
            title: 'Invalid URL',
            description: 'Try loading a non-existent URL',
            onTap: () => _loadVideo(VideoUrls.invalidUrl, 'Invalid URL'),
          ),
          _ErrorButton(
            key: TestKeys.errorHandlingInvalidFormatButton,
            icon: Icons.broken_image,
            title: 'Invalid Format',
            description: 'Try loading a non-video file',
            onTap: () => _loadVideo('https://www.google.com/robots.txt', 'Non-video file'),
          ),
          _ErrorButton(
            key: TestKeys.errorHandlingValidVideoButton,
            icon: Icons.check_circle,
            title: 'Valid Video',
            description: 'Load a working video for comparison',
            onTap: () => _loadVideo(VideoUrls.bigBuckBunny, 'Big Buck Bunny'),
          ),

          const SizedBox(height: 24),

          // Result display
          if (_isLoading)
            const Center(key: TestKeys.errorHandlingLoadingIndicator, child: CircularProgressIndicator())
          else if (_lastError != null)
            Card(
              key: TestKeys.errorHandlingErrorCard,
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Error Caught',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_lastError!, style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              ),
            )
          else if (_controller != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                color: Colors.black,
                child: ProVideoPlayer(
                  key: TestKeys.errorHandlingVideoPlayer,
                  controller: _controller!,
                  controlsBuilder: (context, controller) =>
                      VideoPlayerControls(controller: controller, showFullscreenButton: false),
                  placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Best practices
          Text('Error Handling Best Practices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('1. Always wrap initialize() in try-catch'),
          const Text('2. Listen to VideoPlayerValue.playbackState for error state'),
          const Text('3. Check errorMessage for details'),
          const Text('4. Provide retry functionality for users'),
          const Text('5. Show meaningful error messages'),
        ],
      ),
    );
  }
}

class _ErrorButton extends StatelessWidget {
  const _ErrorButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.play_circle_outline),
      onTap: onTap,
    ),
  );
}

// -----------------------------------------------------------------------------
// Multi-Player Demo
// -----------------------------------------------------------------------------
class _MultiPlayerDemo extends StatefulWidget {
  const _MultiPlayerDemo();

  @override
  State<_MultiPlayerDemo> createState() => _MultiPlayerDemoState();
}

class _MultiPlayerDemoState extends State<_MultiPlayerDemo> with AutomaticKeepAliveClientMixin {
  final List<ProVideoPlayerController> _controllers = [];
  bool _isLoading = false;

  static const _videos = VideoLists.googleCloudSamples;

  @override
  bool get wantKeepAlive => true;

  Future<void> _addPlayer() async {
    if (_controllers.length >= 4) return;

    setState(() => _isLoading = true);

    final controller = ProVideoPlayerController();
    try {
      await controller.initialize(
        source: VideoSource.network(_videos[_controllers.length % _videos.length]),
        options: const VideoPlayerOptions(volume: 0), // Mute by default
      );
      setState(() {
        _controllers.add(controller);
        _isLoading = false;
      });
    } catch (e) {
      await controller.dispose();
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add player: $e')));
      }
    }
  }

  Future<void> _removePlayer(int index) async {
    final controller = _controllers.removeAt(index);
    await controller.dispose();
    setState(() {});
  }

  Future<void> _removeAllPlayers() async {
    for (final controller in _controllers) {
      await controller.dispose();
    }
    _controllers.clear();
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: TestKeys.multiPlayerAddButton,
                  onPressed: _controllers.length < 4 && !_isLoading ? _addPlayer : null,
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: Text('Add Player (${_controllers.length}/4)'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: TestKeys.multiPlayerRemoveAllButton,
                onPressed: _controllers.isNotEmpty ? _removeAllPlayers : null,
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Remove all',
              ),
            ],
          ),
        ),

        // Players grid
        Expanded(
          child: _controllers.isEmpty
              ? Center(
                  key: TestKeys.multiPlayerEmptyState,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_view, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Tap "Add Player" to create video players'),
                      const Text('Up to 4 players can run simultaneously'),
                    ],
                  ),
                )
              : GridView.builder(
                  key: TestKeys.multiPlayerGrid,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 16 / 9,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _controllers.length,
                  itemBuilder: (context, index) =>
                      _MiniPlayer(controller: _controllers[index], index: index, onRemove: () => _removePlayer(index)),
                ),
        ),
      ],
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.controller, required this.index, required this.onRemove});

  final ProVideoPlayerController controller;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    key: TestKeys.multiPlayerItem(index),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ProVideoPlayer(
          controller: controller,
          controlsBuilder: (context, controller) =>
              VideoPlayerControls(controller: controller, showFullscreenButton: false),
          placeholder: const Center(child: CircularProgressIndicator()),
        ),
        // Remove button overlay
        Positioned(
          top: 8,
          right: 8,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: IconButton(
              key: TestKeys.multiPlayerItemRemove(index),
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: onRemove,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    ),
  );
}
