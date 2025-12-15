import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates media metadata for platform media controls.
///
/// Shows how to:
/// - Set custom title, artist, and artwork for Control Center/notification
/// - Update metadata during playback
/// - Clear metadata
class MediaControlsScreen extends StatefulWidget {
  const MediaControlsScreen({super.key});

  @override
  State<MediaControlsScreen> createState() => _MediaControlsScreenState();
}

class _MediaControlsScreenState extends State<MediaControlsScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _backgroundSupported = false;
  MediaMetadata _currentMetadata = MediaMetadata.empty;

  // Sample metadata options
  static const _sampleMetadata = [
    MediaMetadata(
      title: 'Big Buck Bunny',
      artist: 'Blender Foundation',
      album: 'Open Movies',
      artworkUrl: 'https://peach.blender.org/wp-content/uploads/bbb-splash.png',
    ),
    MediaMetadata(
      title: 'Episode 1: The Beginning',
      artist: 'My Video Series',
      album: 'Season 1',
      artworkUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/220px-Big_buck_bunny_poster_big.jpg',
    ),
    MediaMetadata(title: 'Custom Video Title', artist: 'Your Channel Name'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      await _controller.initialize(
        source: const VideoSource.network(VideoUrls.bigBuckBunny),
        options: const VideoPlayerOptions(autoPlay: true, allowBackgroundPlayback: true),
      );

      final backgroundSupported = await _controller.isBackgroundPlaybackSupported();
      await _controller.setBackgroundPlayback(enabled: true);

      // Set initial metadata
      await _controller.setMediaMetadata(_sampleMetadata[0]);

      setState(() {
        _isInitialized = true;
        _backgroundSupported = backgroundSupported;
        _currentMetadata = _sampleMetadata[0];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _setMetadata(MediaMetadata metadata) async {
    await _controller.setMediaMetadata(metadata);
    setState(() => _currentMetadata = metadata);
  }

  Future<void> _clearMetadata() async {
    await _controller.setMediaMetadata(MediaMetadata.empty);
    setState(() => _currentMetadata = MediaMetadata.empty);
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Media Controls')),
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
      // Use full Flutter controls (not compact mode) even when player is small
      controlsBuilder: (context, controller) =>
          VideoPlayerControls(controller: controller, compactMode: CompactMode.never),
    ),
    controls: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBackgroundStatus(),
          const Divider(),
          _buildCurrentMetadata(),
          const Divider(),
          _buildMetadataPresets(),
          const Divider(),
          _buildPlaybackControls(),
          const Divider(),
          _buildInstructions(),
        ],
      ),
    ),
    maxVideoHeightFraction: 0.3,
  );

  Widget _buildBackgroundStatus() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Background Playback', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _backgroundSupported ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _backgroundSupported ? Colors.green : Colors.orange),
          ),
          child: Row(
            children: [
              Icon(
                _backgroundSupported ? Icons.check_circle : Icons.warning,
                color: _backgroundSupported ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _backgroundSupported
                      ? 'Background playback enabled. Metadata will appear in Control Center/notifications.'
                      : 'Background playback not supported. Metadata may not be visible.',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildCurrentMetadata() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Current Metadata', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _clearMetadata,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_currentMetadata.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('No metadata set')),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_currentMetadata.artworkUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _currentMetadata.artworkUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey,
                        child: const Icon(Icons.image, color: Colors.white),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentMetadata.title ?? 'Unknown Title',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_currentMetadata.artist != null)
                        Text(
                          _currentMetadata.artist!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (_currentMetadata.album != null)
                        Text(
                          _currentMetadata.album!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _buildMetadataPresets() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preset Metadata', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Tap to apply different metadata configurations',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ...List.generate(_sampleMetadata.length, (index) {
          final metadata = _sampleMetadata[index];
          final isSelected = _currentMetadata == metadata;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                ),
              ),
              selected: isSelected,
              leading: Icon(Icons.library_music, color: isSelected ? Theme.of(context).colorScheme.primary : null),
              title: Text(metadata.title ?? 'Untitled'),
              subtitle: Text(metadata.artist ?? 'Unknown artist'),
              trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
              onTap: () => _setMetadata(metadata),
            ),
          );
        }),
      ],
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

  Widget _buildInstructions() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How to Test', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        const _InstructionItem(number: '1', text: 'Start playing the video'),
        const _InstructionItem(number: '2', text: 'Minimize the app (press home button)'),
        const _InstructionItem(
          number: '3',
          text: 'iOS: Open Control Center to see Now Playing\nAndroid: Check notification shade',
        ),
        const _InstructionItem(number: '4', text: 'Switch between presets to update metadata'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The metadata appears in system media controls when the app is backgrounded '
                  'with background playback enabled.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(
              number,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
