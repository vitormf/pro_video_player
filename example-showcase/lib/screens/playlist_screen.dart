import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Screen demonstrating playlist functionality.
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  ProVideoPlayerController? _controller;
  bool _isLoading = true;
  bool _useMultipleUrls = true; // Toggle between multiple URLs and playlist file

  // Sample playlist with various video sources
  final _multiUrlPlaylist = Playlist(
    items: [
      const VideoSource.network(VideoUrls.bigBuckBunny),
      const VideoSource.network(VideoUrls.elephantsDream),
      const VideoSource.network(VideoUrls.forBiggerBlazes),
      const VideoSource.network(VideoUrls.forBiggerEscapes),
      const VideoSource.network(VideoUrls.forBiggerFun),
    ],
  );

  // HLS playlist file URL (contains multiple quality variants)
  static const _playlistFileUrl = VideoUrls.appleHlsBipbop;

  @override
  void initState() {
    super.initState();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    setState(() => _isLoading = true);

    _controller = ProVideoPlayerController();

    try {
      if (_useMultipleUrls) {
        // Initialize with multiple individual URLs
        await _controller!.initializeWithPlaylist(
          playlist: _multiUrlPlaylist,
          options: const VideoPlayerOptions(autoPlay: true),
        );
      } else {
        // Initialize with a playlist file URL (e.g., HLS master playlist)
        await _controller!.initialize(
          source: const VideoSource.network(_playlistFileUrl),
          options: const VideoPlayerOptions(autoPlay: true),
        );
      }
    } catch (e) {
      debugPrint('Error initializing playlist: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _switchPlaylistType() async {
    await _controller?.dispose();
    setState(() {
      _useMultipleUrls = !_useMultipleUrls;
      _controller = null;
    });
    await _initializePlayer();
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_useMultipleUrls ? 'Playlist Demo - Multiple URLs' : 'Playlist Demo - Playlist File'),
      actions: [
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Switch playlist type',
          onPressed: _isLoading ? null : _switchPlaylistType,
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ResponsiveVideoLayout(
            videoPlayer: ProVideoPlayer(controller: _controller!),
            controls: _buildPlaylistInfo(),
          ),
  );

  Widget _buildPlaylistInfo() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller!,
    builder: (context, value, child) {
      final currentIndex = value.playlistIndex ?? 0;
      final totalTracks = value.playlist?.length ?? 0;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current track info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _useMultipleUrls ? Icons.queue_music : Icons.playlist_play,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _useMultipleUrls ? 'Multiple URLs' : 'Playlist File (HLS)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Now Playing',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTrackName(currentIndex),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track ${currentIndex + 1} of $totalTracks',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildModeChip(
                        'Shuffle',
                        value.isShuffled,
                        Icons.shuffle,
                        () => _controller!.setPlaylistShuffle(enabled: !value.isShuffled),
                      ),
                      const SizedBox(width: 8),
                      _buildRepeatModeChip(value.playlistRepeatMode),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Supported formats info
            if (!_useMultipleUrls)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: colorScheme.tertiary),
                        const SizedBox(width: 8),
                        Text(
                          'Supported Playlist Formats',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _FormatChip(label: 'M3U', description: 'Standard playlist'),
                        _FormatChip(label: 'M3U8', description: 'HLS adaptive'),
                        _FormatChip(label: 'PLS', description: 'Winamp/Shoutcast'),
                        _FormatChip(label: 'XSPF', description: 'XML Shareable'),
                        _FormatChip(label: 'JSPF', description: 'JSON Shareable'),
                        _FormatChip(label: 'ASX', description: 'Advanced Stream Redirector'),
                        _FormatChip(label: 'WPL', description: 'Windows Media Player'),
                        _FormatChip(label: 'CUE', description: 'Cue Sheet'),
                      ],
                    ),
                  ],
                ),
              ),
            // Track list header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Playlist', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            // Track list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalTracks,
              itemBuilder: (context, index) {
                final isCurrentTrack = index == currentIndex;
                final colorScheme = Theme.of(context).colorScheme;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: isCurrentTrack ? 2 : 0,
                  color: isCurrentTrack ? colorScheme.primaryContainer : colorScheme.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentTrack ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                      child: isCurrentTrack
                          ? Icon(Icons.play_arrow, color: colorScheme.onPrimary, size: 20)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                    title: Text(
                      _getTrackName(index),
                      style: TextStyle(
                        fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentTrack ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Track ${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrentTrack ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: isCurrentTrack ? Icon(Icons.equalizer, color: colorScheme.primary) : null,
                    onTap: () => _controller!.playlistJumpTo(index),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );

  Widget _buildModeChip(String label, bool isActive, IconData icon, VoidCallback onTap) => Builder(
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildRepeatModeChip(PlaylistRepeatMode mode) {
    String label;
    IconData icon;
    switch (mode) {
      case PlaylistRepeatMode.none:
        label = 'No Repeat';
        icon = Icons.repeat;
      case PlaylistRepeatMode.all:
        label = 'Repeat All';
        icon = Icons.repeat;
      case PlaylistRepeatMode.one:
        label = 'Repeat One';
        icon = Icons.repeat_one;
    }

    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isActive = mode != PlaylistRepeatMode.none;
        return InkWell(
          onTap: () {
            final nextMode = switch (mode) {
              PlaylistRepeatMode.none => PlaylistRepeatMode.all,
              PlaylistRepeatMode.all => PlaylistRepeatMode.one,
              PlaylistRepeatMode.one => PlaylistRepeatMode.none,
            };
            _controller!.setPlaylistRepeatMode(nextMode);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTrackName(int index) {
    const names = ['Big Buck Bunny', 'Elephants Dream', 'For Bigger Blazes', 'For Bigger Escapes', 'For Bigger Fun'];
    return index < names.length ? names[index] : 'Video ${index + 1}';
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
