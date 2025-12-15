import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates Picture-in-Picture action buttons.
///
/// Shows how to:
/// - Configure custom PiP remote actions
/// - Use different action presets (standard, playlist, minimal)
/// - Handle PiP action events
class PipActionsScreen extends StatefulWidget {
  const PipActionsScreen({super.key});

  @override
  State<PipActionsScreen> createState() => _PipActionsScreenState();
}

class _PipActionsScreenState extends State<PipActionsScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _pipSupported = false;
  String _selectedPreset = 'standard';
  final List<String> _actionLog = [];

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
        options: const VideoPlayerOptions(autoPlay: true),
      );

      final pipSupported = await _controller.isPipSupported();

      // Set default PiP actions
      await _controller.setPipActions(PipActions.standard);

      setState(() {
        _isInitialized = true;
        _pipSupported = pipSupported;
      });

      // Listen for PiP action events
      _listenForPipActions();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _listenForPipActions() {
    // We can listen to the controller's value changes for PiP state
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // Log PiP state changes
    if (_controller.value.isPipActive) {
      _addToLog('Entered PiP mode');
    }
  }

  void _addToLog(String message) {
    setState(() {
      _actionLog.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_actionLog.length > 20) {
        _actionLog.removeLast();
      }
    });
  }

  Future<void> _setActionPreset(String preset) async {
    List<PipAction>? actions;

    switch (preset) {
      case 'standard':
        actions = PipActions.standard;
      case 'playlist':
        actions = PipActions.playlist;
      case 'minimal':
        actions = PipActions.minimal;
      case 'custom':
        actions = [
          const PipAction(type: PipActionType.skipBackward, skipInterval: Duration(seconds: 15)),
          const PipAction(type: PipActionType.playPause),
          const PipAction(type: PipActionType.skipForward, skipInterval: Duration(seconds: 15)),
        ];
      case 'none':
        actions = null;
    }

    await _controller.setPipActions(actions);
    setState(() => _selectedPreset = preset);
    _addToLog('Set PiP actions: $preset');
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
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
      appBar: AppBar(title: const Text('PiP Actions')),
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
      // Use full Flutter controls (not compact mode) even when player is small
      controlsBuilder: (context, controller) =>
          VideoPlayerControls(controller: controller, compactMode: CompactMode.never),
    ),
    controls: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPipStatus(),
          const Divider(),
          _buildActionPresets(),
          const Divider(),
          _buildPipControls(),
          const Divider(),
          _buildActionLog(),
        ],
      ),
    ),
    maxVideoHeightFraction: 0.3,
  );

  Widget _buildPipStatus() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PiP Support', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _pipSupported ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _pipSupported ? Colors.green : Colors.red),
          ),
          child: Row(
            children: [
              Icon(_pipSupported ? Icons.check_circle : Icons.cancel, color: _pipSupported ? Colors.green : Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _pipSupported
                      ? 'PiP is supported. Enter PiP to see action buttons.'
                      : 'PiP is not supported on this device/platform.',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildActionPresets() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Action Presets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Configure which buttons appear in the PiP window',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        _PresetTile(
          title: 'Standard',
          description: 'Skip Back (10s), Play/Pause, Skip Forward (10s)',
          icons: const [Icons.replay_10, Icons.play_arrow, Icons.forward_10],
          isSelected: _selectedPreset == 'standard',
          onTap: () => _setActionPreset('standard'),
        ),
        const SizedBox(height: 8),
        _PresetTile(
          title: 'Playlist',
          description: 'Previous Track, Play/Pause, Next Track',
          icons: const [Icons.skip_previous, Icons.play_arrow, Icons.skip_next],
          isSelected: _selectedPreset == 'playlist',
          onTap: () => _setActionPreset('playlist'),
        ),
        const SizedBox(height: 8),
        _PresetTile(
          title: 'Minimal',
          description: 'Play/Pause only',
          icons: const [Icons.play_arrow],
          isSelected: _selectedPreset == 'minimal',
          onTap: () => _setActionPreset('minimal'),
        ),
        const SizedBox(height: 8),
        _PresetTile(
          title: 'Custom (15s)',
          description: 'Skip Back (15s), Play/Pause, Skip Forward (15s)',
          icons: const [Icons.replay, Icons.play_arrow, Icons.forward],
          isSelected: _selectedPreset == 'custom',
          onTap: () => _setActionPreset('custom'),
        ),
        const SizedBox(height: 8),
        _PresetTile(
          title: 'None',
          description: 'No custom actions (system defaults)',
          icons: const [],
          isSelected: _selectedPreset == 'none',
          onTap: () => _setActionPreset('none'),
        ),
      ],
    ),
  );

  Widget _buildPipControls() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Controls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.icon(
                onPressed: _pipSupported && !value.isPipActive
                    ? () async {
                        final success = await _controller.enterPip();
                        if (success) {
                          _addToLog('Entering PiP...');
                        } else {
                          _addToLog('Failed to enter PiP');
                        }
                      }
                    : null,
                icon: const Icon(Icons.picture_in_picture),
                label: const Text('Enter PiP'),
              ),
              OutlinedButton.icon(
                onPressed: value.isPipActive
                    ? () {
                        unawaited(_controller.exitPip());
                        _addToLog('Exiting PiP...');
                      }
                    : null,
                icon: const Icon(Icons.fullscreen_exit),
                label: const Text('Exit PiP'),
              ),
            ],
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
                iconSize: 48,
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

  Widget _buildActionLog() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Event Log', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(onPressed: () => setState(_actionLog.clear), child: const Text('Clear')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _actionLog.isEmpty
              ? Center(
                  child: Text(
                    'Events will appear here',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: _actionLog.length,
                  itemBuilder: (context, index) => Text(
                    _actionLog[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
        ),
      ],
    ),
  );
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.title,
    required this.description,
    required this.icons,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final List<IconData> icons;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          if (icons.isEmpty)
            Container(
              width: 80,
              alignment: Alignment.center,
              child: const Text('—', style: TextStyle(fontSize: 20)),
            )
          else
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: icons.map((icon) => Icon(icon, size: 20)).toList(),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (isSelected) Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    ),
  );
}
