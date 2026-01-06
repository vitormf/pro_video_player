import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../test_keys.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates different video source types.
class VideoSourcesScreen extends StatefulWidget {
  const VideoSourcesScreen({super.key});

  @override
  State<VideoSourcesScreen> createState() => _VideoSourcesScreenState();
}

class _VideoSourcesScreenState extends State<VideoSourcesScreen> {
  ProVideoPlayerController? _controller;
  VideoSourceType _currentSourceType = VideoSourceType.network;
  bool _isLoading = false;
  String? _error;

  // Sample video URLs for different tests
  static const _networkVideos = [
    (name: 'Big Buck Bunny (MP4)', url: VideoUrls.bigBuckBunny, headers: <String, String>{}),
    (name: 'Elephants Dream (MP4)', url: VideoUrls.elephantsDream, headers: <String, String>{}),
    (name: 'For Bigger Blazes (MP4)', url: VideoUrls.forBiggerBlazes, headers: <String, String>{}),
  ];

  // Example of video with custom headers (simulated - would work with authenticated APIs)
  static const _headersExample = {
    'Authorization': 'Bearer your-token-here',
    'X-Custom-Header': 'custom-value',
    'User-Agent': 'ProVideoPlayer/1.0',
  };

  // Sample playlist file URLs - HLS adaptive streams
  // Note: Multi-video playlist is loaded programmatically from _multiVideoPlaylist
  static const _playlistFileUrls = [
    (
      name: 'HLS Adaptive Stream (m3u8)',
      url: VideoUrls.appleHlsBipbop,
      description: 'HLS master playlist with multiple quality levels',
    ),
    (name: 'HLS Sintel (m3u8)', url: VideoUrls.bitmovinSintelHls, description: 'HLS playlist with adaptive quality'),
  ];

  // Multi-video playlist (programmatic)
  Playlist get _multiVideoPlaylist => Playlist(
    items: [
      const VideoSource.network(VideoUrls.bigBuckBunny),
      const VideoSource.network(VideoUrls.elephantsDream),
      const VideoSource.network(VideoUrls.forBiggerBlazes),
      const VideoSource.network(VideoUrls.forBiggerEscapes),
    ],
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadVideo(_networkVideos[0].url));
  }

  Future<void> _loadVideo(String url, {Map<String, String>? headers}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Dispose previous controller
    await _controller?.dispose();
    _controller = ProVideoPlayerController();

    try {
      await _controller!.initialize(source: VideoSource.network(url, headers: headers));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadPlaylistFile(String url) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentSourceType = VideoSourceType.playlistFile;
    });

    await _controller?.dispose();
    _controller = ProVideoPlayerController();

    try {
      // Use VideoSource.playlist() which automatically detects and parses the playlist type
      await _controller!.initialize(source: VideoSource.playlist(url));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load playlist: $e';
      });
    }
  }

  Future<void> _loadAssetVideo() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentSourceType = VideoSourceType.asset;
    });

    await _controller?.dispose();
    _controller = ProVideoPlayerController();

    try {
      // Note: You would need to add an actual asset video to assets/videos/
      await _controller!.initialize(source: const VideoSource.asset(VideoAssets.sampleVideo));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Asset video not found. Add a video file at ${VideoAssets.sampleVideo}';
      });
    }
  }

  Future<void> _loadMultiVideoPlaylist() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentSourceType = VideoSourceType.playlistFile;
    });

    await _controller?.dispose();
    _controller = ProVideoPlayerController();

    try {
      // Initialize with a programmatic playlist of multiple videos
      await _controller!.initializeWithPlaylist(
        playlist: _multiVideoPlaylist,
        options: const VideoPlayerOptions(autoPlay: true),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load playlist: $e';
      });
    }
  }

  Future<void> _pickAndLoadLocalFile() async {
    // Web doesn't support file:// URLs, so we need different handling
    if (kIsWeb) {
      setState(() => _error = 'Local file playback is not supported on web');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = result.files.first;
      final path = file.path;

      if (path == null) {
        setState(() => _error = 'Could not get file path');
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
        _currentSourceType = VideoSourceType.asset; // Using asset type for local files
      });

      await _controller?.dispose();
      _controller = ProVideoPlayerController();

      // Use file:// URL for local files
      final fileUrl = File(path).uri.toString();
      await _controller!.initialize(source: VideoSource.network(fileUrl));

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load local file: $e';
      });
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Video Sources')),
    body: ResponsiveVideoLayout(
      videoPlayer: _buildVideoPlayer(),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Source type selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<VideoSourceType>(
              segments: const [
                ButtonSegment(value: VideoSourceType.network, label: Text('Network'), icon: Icon(Icons.cloud)),
                ButtonSegment(
                  value: VideoSourceType.playlistFile,
                  label: Text('Playlist'),
                  icon: Icon(Icons.playlist_play),
                ),
                ButtonSegment(value: VideoSourceType.asset, label: Text('Asset'), icon: Icon(Icons.folder)),
                ButtonSegment(value: VideoSourceType.file, label: Text('File'), icon: Icon(Icons.file_present)),
              ],
              selected: {_currentSourceType},
              onSelectionChanged: (selection) {
                final type = selection.first;
                setState(() => _currentSourceType = type);
                if (type == VideoSourceType.asset) {
                  unawaited(_loadAssetVideo());
                } else if (type == VideoSourceType.file) {
                  unawaited(_pickAndLoadLocalFile());
                }
              },
            ),
          ),

          // Video metadata display (if available)
          if (_controller != null) _buildMetadataSection(),

          // Content based on source type (not expanded - let it size naturally)
          _buildSourceContent(),
        ],
      ),
    ),
  );

  Widget _buildMetadataSection() => ListenableBuilder(
    listenable: _controller!,
    builder: (context, _) {
      final metadata = _controller!.videoMetadata;
      if (metadata == null || metadata.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          key: TestKeys.videoMetadataCard,
          child: ExpansionTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Video Metadata'),
            subtitle: Text(
              metadata.resolution != null
                  ? '${metadata.resolution} • ${metadata.videoCodec ?? "unknown codec"}'
                  : 'Tap to expand',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metadata.videoCodec != null) _metadataRow('Video Codec', metadata.videoCodec!),
                    if (metadata.audioCodec != null) _metadataRow('Audio Codec', metadata.audioCodec!),
                    if (metadata.resolution != null) _metadataRow('Resolution', metadata.resolution!),
                    if (metadata.aspectRatio != null)
                      _metadataRow('Aspect Ratio', metadata.aspectRatio!.toStringAsFixed(2)),
                    if (metadata.frameRate != null)
                      _metadataRow('Frame Rate', '${metadata.frameRate!.toStringAsFixed(1)} fps'),
                    if (metadata.videoBitrateInMbps != null)
                      _metadataRow('Video Bitrate', '${metadata.videoBitrateInMbps!.toStringAsFixed(2)} Mbps'),
                    if (metadata.audioBitrateInKbps != null)
                      _metadataRow('Audio Bitrate', '${metadata.audioBitrateInKbps!.toStringAsFixed(0)} kbps'),
                    if (metadata.duration != null) _metadataRow('Duration', _formatDuration(metadata.duration!)),
                    if (metadata.containerFormat != null) _metadataRow('Container', metadata.containerFormat!),
                    if (metadata.isHD) _metadataRow('Quality', metadata.is4K ? '4K UHD' : 'HD'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _metadataRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Center(
        key: TestKeys.videoSourcesLoadingIndicator,
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        key: TestKeys.videoSourcesErrorDisplay,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return const Center(
        child: Text('Select a video source', style: TextStyle(color: Colors.white)),
      );
    }

    return ProVideoPlayer(
      key: TestKeys.videoSourcesVideoPlayer,
      controller: _controller!,
      controlsBuilder: (context, controller) =>
          VideoPlayerControls(controller: controller, buttonsConfig: const ButtonsConfig(showFullscreenButton: false)),
      placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildSourceContent() {
    switch (_currentSourceType) {
      case VideoSourceType.network:
        return _buildNetworkSourceList();
      case VideoSourceType.playlistFile:
        return _buildPlaylistFileList();
      case VideoSourceType.asset:
        return _buildAssetSourceInfo();
      case VideoSourceType.file:
        return _buildFileSourceInfo();
    }
  }

  Widget _buildPlaylistFileList() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Playlist File Sources', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Playlist files are automatically detected and parsed. Supported formats: M3U, M3U8, PLS, XSPF',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        // Multi-video playlist (programmatic)
        Card(
          child: ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Multi-Video Playlist'),
            subtitle: const Text('4 videos: Big Buck Bunny, Elephants Dream, For Bigger Blazes, For Bigger Escapes'),
            trailing: const Icon(Icons.play_circle_outline),
            onTap: () => unawaited(_loadMultiVideoPlaylist()),
          ),
        ),
        const SizedBox(height: 8),
        // HLS adaptive streams
        ..._playlistFileUrls.map(
          (playlist) => Card(
            child: ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text(playlist.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    playlist.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 10),
                  ),
                ],
              ),
              trailing: const Icon(Icons.play_circle_outline),
              onTap: () {
                setState(() => _currentSourceType = VideoSourceType.playlistFile);
                unawaited(_loadPlaylistFile(playlist.url));
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Automatic Detection',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '• HLS adaptive streams (m3u8) are detected automatically\n'
                '• Simple playlists with multiple videos create a playlist\n'
                '• URL and content-based format detection',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildNetworkSourceList() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._networkVideos.asMap().entries.map((entry) {
          final index = entry.key;
          final video = entry.value;
          return Card(
            key: TestKeys.videoSourcesNetworkItem(index),
            child: ListTile(
              leading: const Icon(Icons.video_library),
              title: Text(video.name),
              subtitle: Text(
                video.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.play_circle_outline),
              onTap: () {
                setState(() => _currentSourceType = VideoSourceType.network);
                unawaited(_loadVideo(video.url, headers: video.headers.isEmpty ? null : video.headers));
              },
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildCustomHeadersSection(),
      ],
    ),
  );

  Widget _buildCustomHeadersSection() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.vpn_key, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Custom HTTP Headers', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Network sources support custom headers for authenticated or protected content:',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VideoSource.network(',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                "  'https://example.com/video.mp4',",
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
              ),
              const Text('  headers: {', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ..._headersExample.entries.map(
                (e) => Text(
                  "    '${e.key}': '${e.value}',",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
              const Text('  },', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
              const Text(')', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildAssetSourceInfo() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Asset Video Source', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.video_library),
            title: Text('Big Buck Bunny (Sample)'),
            subtitle: Text(VideoAssets.sampleVideo),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Asset videos are bundled with your app during build time.'),
        const SizedBox(height: 8),
        const Text('To add your own asset videos:'),
        const SizedBox(height: 8),
        const Text('1. Place video files in the assets/videos/ folder'),
        const Text('2. Declare them in pubspec.yaml under flutter > assets'),
        const Text('3. Use VideoSource.asset("assets/videos/your_video.mp4")'),
      ],
    ),
  );

  Widget _buildFileSourceInfo() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('File Video Source', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        const Text('File videos are loaded from the device storage. To implement file picking:'),
        const SizedBox(height: 8),
        const Text('1. Add file_picker or image_picker package'),
        const Text('2. Pick a video file from the device'),
        const Text('3. Use VideoSource.file(path) to load it'),
        const SizedBox(height: 16),
        const Text('Example code:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'final result = await FilePicker.platform.pickFiles(\n'
            '  type: FileType.video,\n'
            ');\n'
            'if (result != null) {\n'
            '  final path = result.files.single.path!;\n'
            '  await controller.initialize(\n'
            '    source: VideoSource.file(path),\n'
            '  );\n'
            '}',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

enum VideoSourceType { network, asset, file, playlistFile }
