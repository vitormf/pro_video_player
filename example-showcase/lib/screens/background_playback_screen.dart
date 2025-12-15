import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates background playback features.
///
/// Shows how to:
/// - Enable/disable background audio playback
/// - Configure auto-enter PiP on app background
/// - Mix audio with other apps (iOS)
class BackgroundPlaybackScreen extends StatefulWidget {
  const BackgroundPlaybackScreen({super.key});

  @override
  State<BackgroundPlaybackScreen> createState() => _BackgroundPlaybackScreenState();
}

class _BackgroundPlaybackScreenState extends State<BackgroundPlaybackScreen> with WidgetsBindingObserver {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _backgroundSupported = false;
  bool _pipSupported = false;
  AppLifecycleState? _lastLifecycleState;

  // Configuration options
  bool _backgroundPlaybackEnabled = false;
  bool _autoEnterPipEnabled = false;
  bool _mixWithOthers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      await _controller.initialize(
        source: const VideoSource.network(VideoUrls.bigBuckBunny),
        options: VideoPlayerOptions(
          autoPlay: true,
          allowBackgroundPlayback: _backgroundPlaybackEnabled,
          autoEnterPipOnBackground: _autoEnterPipEnabled,
          mixWithOthers: _mixWithOthers,
        ),
      );

      final backgroundSupported = await _controller.isBackgroundPlaybackSupported();
      final pipSupported = await _controller.isPipSupported();

      setState(() {
        _isInitialized = true;
        _backgroundSupported = backgroundSupported;
        _pipSupported = pipSupported;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _reinitializeWithOptions() async {
    setState(() {
      _isInitialized = false;
      _error = null;
    });

    await _controller.dispose();
    _controller = ProVideoPlayerController();

    try {
      await _controller.initialize(
        source: const VideoSource.network(VideoUrls.bigBuckBunny),
        options: VideoPlayerOptions(
          autoPlay: true,
          allowBackgroundPlayback: _backgroundPlaybackEnabled,
          autoEnterPipOnBackground: _autoEnterPipEnabled,
          mixWithOthers: _mixWithOthers,
        ),
      );

      final backgroundSupported = await _controller.isBackgroundPlaybackSupported();
      final pipSupported = await _controller.isPipSupported();

      setState(() {
        _isInitialized = true;
        _backgroundSupported = backgroundSupported;
        _pipSupported = pipSupported;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _lastLifecycleState = state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isPipActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ProVideoPlayer(controller: _controller, placeholder: const SizedBox.shrink()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Background Playback')),
      body: _error != null
          ? _buildErrorState()
          : !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

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
          _buildLifecycleStatus(),
          const Divider(),
          _buildPlatformSupport(),
          const Divider(),
          _buildConfigurationOptions(),
          const Divider(),
          _buildPlaybackControls(),
          const Divider(),
          _buildInstructions(),
        ],
      ),
    ),
    maxVideoHeightFraction: 0.35,
  );

  Widget _buildLifecycleStatus() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('App Lifecycle', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _lastLifecycleState == AppLifecycleState.resumed
                    ? Icons.visibility
                    : _lastLifecycleState == AppLifecycleState.paused
                    ? Icons.visibility_off
                    : Icons.sync,
                color: _lastLifecycleState == AppLifecycleState.resumed ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Text('State: ${_lastLifecycleState?.name ?? 'resumed'}', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Minimize the app to test background playback',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );

  Widget _buildPlatformSupport() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Platform Support', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _SupportRow(
          label: 'Background Playback',
          supported: _backgroundSupported,
          description: _backgroundSupported
              ? 'Audio continues when app is backgrounded'
              : 'Not available on this platform',
        ),
        const SizedBox(height: 8),
        _SupportRow(
          label: 'Auto-Enter PiP',
          supported: _pipSupported,
          description: _pipSupported ? 'Video enters PiP when app backgrounds' : 'PiP not supported on this platform',
        ),
      ],
    ),
  );

  Widget _buildConfigurationOptions() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Configuration', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _reinitializeWithOptions,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Changes require reinitializing the player',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Background Playback'),
          subtitle: const Text('Allow audio when app is backgrounded'),
          value: _backgroundPlaybackEnabled,
          onChanged: _backgroundSupported ? (value) => setState(() => _backgroundPlaybackEnabled = value) : null,
        ),
        SwitchListTile(
          title: const Text('Auto-Enter PiP'),
          subtitle: const Text('Enter PiP when app goes to background'),
          value: _autoEnterPipEnabled,
          onChanged: _pipSupported ? (value) => setState(() => _autoEnterPipEnabled = value) : null,
        ),
        SwitchListTile(
          title: const Text('Mix with Others (iOS)'),
          subtitle: const Text('Mix audio with other apps'),
          value: _mixWithOthers,
          onChanged: (value) => setState(() => _mixWithOthers = value),
        ),
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
          Text('Playback Controls', style: Theme.of(context).textTheme.titleMedium),
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
          const SizedBox(height: 16),
          _InfoRow(label: 'State', value: value.playbackState.name),
          _InfoRow(label: 'Background Enabled', value: value.isBackgroundPlaybackEnabled ? 'Yes' : 'No'),
          _InfoRow(label: 'PiP Active', value: value.isPipActive ? 'Yes' : 'No'),
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
        const _InstructionItem(number: '1', text: 'Enable "Background Playback" and tap "Apply"'),
        const _InstructionItem(number: '2', text: 'Start playing the video'),
        const _InstructionItem(number: '3', text: 'Press the home button or switch apps'),
        const _InstructionItem(number: '4', text: 'Audio should continue playing in the background'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'iOS: Requires "Audio, AirPlay, and Picture in Picture" '
                  'background mode in Info.plist',
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

class _SupportRow extends StatelessWidget {
  const _SupportRow({required this.label, required this.supported, required this.description});

  final String label;
  final bool supported;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(supported ? Icons.check_circle : Icons.cancel, color: supported ? Colors.green : Colors.red, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    ],
  );
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
