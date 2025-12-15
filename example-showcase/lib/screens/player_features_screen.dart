import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../test_keys.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates all player features including fullscreen, PiP, and playback controls.
class PlayerFeaturesScreen extends StatefulWidget {
  const PlayerFeaturesScreen({super.key});

  @override
  State<PlayerFeaturesScreen> createState() => _PlayerFeaturesScreenState();
}

class _PlayerFeaturesScreenState extends State<PlayerFeaturesScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _pipSupported = false;
  FullscreenOrientation _fullscreenOrientation = FullscreenOrientation.landscapeBoth;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      await _controller.initialize(source: const VideoSource.network(VideoUrls.bigBuckBunny));
      final pipSupported = await _controller.isPipSupported();
      setState(() {
        _isInitialized = true;
        _pipSupported = pipSupported;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    // Exit fullscreen if active before disposing
    if (_controller.value.isFullscreen) {
      unawaited(_controller.exitFullscreen());
    }
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) {
      // Show fullscreen video when in fullscreen mode
      if (value.isFullscreen) {
        return _buildFullscreenPlayer();
      }

      // On Android, when PiP is active, the entire app is shown in the PiP window.
      // We should show only the video player to fill the small PiP window.
      if (value.isPipActive) {
        return _buildPipPlayer();
      }

      // Normal view
      return Scaffold(
        appBar: AppBar(title: const Text('Player Features')),
        body: _error != null
            ? _buildErrorState()
            : !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      );
    },
  );

  /// Builds a minimal view for PiP mode.
  /// On Android, the entire app is shown in the small PiP window,
  /// so we show only the video player filling the available space.
  Widget _buildPipPlayer() => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: ProVideoPlayer(controller: _controller, placeholder: const SizedBox.shrink()),
    ),
  );

  Widget _buildFullscreenPlayer() => Scaffold(
    backgroundColor: Colors.black,
    body: GestureDetector(
      onTap: () => unawaited(_controller.toggleFullscreen()),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player filling the screen
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.size != null
                  ? _controller.value.size!.width / _controller.value.size!.height
                  : 16 / 9,
              child: ProVideoPlayer(
                controller: _controller,
                placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          ),

          // Minimal fullscreen controls overlay
          Positioned(bottom: 20, left: 0, right: 0, child: _buildFullscreenControls()),

          // Exit fullscreen button in corner
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              key: TestKeys.playerFeaturesFullscreenExitButton,
              icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 32),
              onPressed: () => unawaited(_controller.exitFullscreen()),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildFullscreenControls() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              trackHeight: 3,
            ),
            child: Slider(
              value: value.position.inMilliseconds.toDouble(),
              max: value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              onChanged: (newValue) {
                unawaited(_controller.seekTo(Duration(milliseconds: newValue.toInt())));
              },
            ),
          ),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () => unawaited(_controller.seekBackward(const Duration(seconds: 10))),
              ),
              IconButton(
                iconSize: 48,
                icon: Icon(value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white),
                onPressed: () => unawaited(_controller.togglePlayPause()),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () => unawaited(_controller.seekForward(const Duration(seconds: 10))),
              ),
              const SizedBox(width: 16),
              Text(_formatDuration(value.duration), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    ),
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
      key: TestKeys.playerFeaturesVideoPlayer,
      controller: _controller,
      placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
    ),
    controls: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress and time
        _buildProgressSection(),

        const Divider(),

        // Playback controls
        _buildPlaybackControls(),

        const Divider(),

        // Feature buttons
        _buildFeatureButtons(),

        const Divider(),

        // Player info
        _buildPlayerInfo(),
      ],
    ),
    maxVideoHeightFraction: 0.35,
  );

  Widget _buildProgressSection() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Slider(
            key: TestKeys.playerFeaturesProgressSlider,
            value: value.position.inMilliseconds.toDouble(),
            max: value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
            onChanged: (newValue) {
              unawaited(_controller.seekTo(Duration(milliseconds: newValue.toInt())));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(value.position), key: TestKeys.playerFeaturesPositionText),
                Text(_formatDuration(value.duration), key: TestKeys.playerFeaturesDurationText),
              ],
            ),
          ),
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
          Text('Playback Controls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          // Main playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: TestKeys.playerFeaturesSeekBackwardButton,
                icon: const Icon(Icons.replay_10),
                onPressed: () => unawaited(_controller.seekBackward(const Duration(seconds: 10))),
                tooltip: 'Rewind 10s',
              ),
              const SizedBox(width: 16),
              IconButton(
                key: TestKeys.playerFeaturesPlayPauseButton,
                iconSize: 56,
                icon: Icon(value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: () => unawaited(_controller.togglePlayPause()),
                tooltip: value.isPlaying ? 'Pause' : 'Play',
              ),
              const SizedBox(width: 16),
              IconButton(
                key: TestKeys.playerFeaturesSeekForwardButton,
                icon: const Icon(Icons.forward_10),
                onPressed: () => unawaited(_controller.seekForward(const Duration(seconds: 10))),
                tooltip: 'Forward 10s',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Speed control
          Row(
            children: [
              const Icon(Icons.speed),
              const SizedBox(width: 8),
              const Text('Speed:'),
              const SizedBox(width: 8),
              DropdownButton<double>(
                key: TestKeys.playerFeaturesSpeedDropdown,
                value: value.playbackSpeed,
                items: const [
                  DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                  DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                  DropdownMenuItem(value: 1, child: Text('1.0x')),
                  DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                  DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                  DropdownMenuItem(value: 2, child: Text('2.0x')),
                ],
                onChanged: (speed) {
                  if (speed != null) {
                    unawaited(_controller.setPlaybackSpeed(speed));
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Volume control
          Row(
            children: [
              Icon(value.volume == 0 ? Icons.volume_off : Icons.volume_up),
              const SizedBox(width: 8),
              const Text('Volume:'),
              Expanded(
                child: Slider(
                  key: TestKeys.playerFeaturesVolumeSlider,
                  value: value.volume,
                  onChanged: (volume) => unawaited(_controller.setVolume(volume)),
                ),
              ),
              Text('${(value.volume * 100).round()}%'),
            ],
          ),

          const SizedBox(height: 8),

          // Loop toggle
          SwitchListTile(
            key: TestKeys.playerFeaturesLoopSwitch,
            title: const Text('Loop'),
            secondary: const Icon(Icons.repeat),
            value: value.isLooping,
            onChanged: (looping) => unawaited(_controller.setLooping(looping: looping)),
          ),
        ],
      ),
    ),
  );

  Widget _buildFeatureButtons() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced Features', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          // Fullscreen orientation selector
          Row(
            children: [
              const Icon(Icons.screen_rotation),
              const SizedBox(width: 16),
              const Text('Orientation:'),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButton<FullscreenOrientation>(
                  value: _fullscreenOrientation,
                  underline: const SizedBox.shrink(),
                  isExpanded: true,
                  items: FullscreenOrientation.values
                      .map(
                        (orientation) =>
                            DropdownMenuItem(value: orientation, child: Text(_getOrientationLabel(orientation))),
                      )
                      .toList(),
                  onChanged: (orientation) {
                    if (orientation != null) {
                      setState(() => _fullscreenOrientation = orientation);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fullscreen button
          ListTile(
            key: TestKeys.playerFeaturesFullscreenTile,
            contentPadding: EdgeInsets.zero,
            leading: Icon(value.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            title: Text(value.isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen'),
            onTap: () {
              if (value.isFullscreen) {
                unawaited(_controller.exitFullscreen());
              } else {
                unawaited(_controller.enterFullscreen(orientation: _fullscreenOrientation));
              }
            },
          ),

          // PiP button
          ListTile(
            key: TestKeys.playerFeaturesPipTile,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.picture_in_picture, color: _pipSupported ? null : Colors.grey),
            title: Text(value.isPipActive ? 'Exit PiP' : 'Enter PiP'),
            subtitle: Text(
              _pipSupported ? (value.isPipActive ? 'In PiP mode' : 'Picture-in-Picture') : 'Not supported',
              overflow: TextOverflow.ellipsis,
            ),
            enabled: _pipSupported,
            onTap: _pipSupported
                ? () {
                    if (value.isPipActive) {
                      unawaited(_controller.exitPip());
                    } else {
                      unawaited(_controller.enterPip());
                    }
                  }
                : null,
          ),
        ],
      ),
    ),
  );

  Widget _buildPlayerInfo() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Player Info', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _InfoRow(key: TestKeys.playerFeaturesStateText, label: 'State', value: value.playbackState.name),
          if (value.size != null) _InfoRow(label: 'Video Size', value: '${value.size!.width}x${value.size!.height}'),
          _InfoRow(label: 'Buffered', value: _formatDuration(value.bufferedPosition)),
          _InfoRow(label: 'Fullscreen', value: value.isFullscreen ? 'Yes' : 'No'),
          _InfoRow(label: 'PiP Active', value: value.isPipActive ? 'Yes' : 'No'),
          _InfoRow(label: 'PiP Supported', value: _pipSupported ? 'Yes' : 'No'),
        ],
      ),
    ),
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getOrientationLabel(FullscreenOrientation orientation) => switch (orientation) {
    FullscreenOrientation.portraitUp => 'Portrait Up',
    FullscreenOrientation.portraitDown => 'Portrait Down',
    FullscreenOrientation.portraitBoth => 'Portrait Both',
    FullscreenOrientation.landscapeLeft => 'Landscape Left',
    FullscreenOrientation.landscapeRight => 'Landscape Right',
    FullscreenOrientation.landscapeBoth => 'Landscape Both',
    FullscreenOrientation.all => 'All Orientations',
  };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, super.key});

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
