import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates network resilience features.
///
/// Shows how to:
/// - Monitor buffering events
/// - Configure error recovery options
/// - Handle network errors gracefully
/// - Monitor bandwidth estimation
class NetworkResilienceScreen extends StatefulWidget {
  const NetworkResilienceScreen({super.key});

  @override
  State<NetworkResilienceScreen> createState() => _NetworkResilienceScreenState();
}

class _NetworkResilienceScreenState extends State<NetworkResilienceScreen> {
  ProVideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _error;
  final List<String> _eventLog = [];
  BufferingTier _selectedTier = BufferingTier.medium;
  bool _autoRetryEnabled = true;
  int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    // Dispose existing controller if any
    await _controller?.dispose();

    _controller = ProVideoPlayerController(
      errorRecoveryOptions: ErrorRecoveryOptions(
        enableAutoRetry: _autoRetryEnabled,
        maxAutoRetries: _maxRetries,
        onRetryAttempt: (error, attempt) {
          _addToLog('Retry attempt $attempt: ${error.message}');
          return true; // Allow retry
        },
        onRecoveryFailed: (error) {
          _addToLog('Recovery failed after ${error.retryCount} attempts');
        },
      ),
    );

    try {
      await _controller!.initialize(
        source: const VideoSource.network(VideoUrls.bigBuckBunny),
        options: VideoPlayerOptions(autoPlay: true, bufferingTier: _selectedTier),
      );

      setState(() {
        _isInitialized = true;
        _error = null;
      });

      _addToLog('Player initialized with ${_selectedTier.name} buffering');
    } catch (e) {
      setState(() => _error = e.toString());
      _addToLog('Initialization error: $e');
    }
  }

  void _addToLog(String message) {
    setState(() {
      _eventLog.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_eventLog.length > 50) {
        _eventLog.removeLast();
      }
    });
  }

  Future<void> _testInvalidUrl() async {
    _addToLog('Testing with invalid URL...');

    await _controller?.dispose();
    _controller = ProVideoPlayerController(
      errorRecoveryOptions: ErrorRecoveryOptions(
        enableAutoRetry: _autoRetryEnabled,
        maxAutoRetries: _maxRetries,
        onRetryAttempt: (error, attempt) {
          _addToLog('Retry attempt $attempt');
          return true;
        },
        onRecoveryFailed: (error) {
          _addToLog('Recovery failed');
        },
      ),
    );

    setState(() {
      _isInitialized = false;
      _error = null;
    });

    try {
      await _controller!.initialize(
        source: const VideoSource.network(VideoUrls.invalidTestUrl),
        options: VideoPlayerOptions(bufferingTier: _selectedTier),
      );
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
      _addToLog('Error: $e');
    }
  }

  Future<void> _retryPlayback() async {
    if (_controller == null) return;

    _addToLog('Manual retry...');
    try {
      final success = await _controller!.retry();
      _addToLog(success ? 'Retry successful' : 'Retry failed');
    } catch (e) {
      _addToLog('Retry error: $e');
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Network Resilience')),
    body: _buildContent(),
  );

  Widget _buildContent() {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ResponsiveVideoLayout(
      videoPlayer: _error != null
          ? _buildErrorWidget()
          : !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ProVideoPlayer(
              controller: _controller!,
              placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
              // Use full Flutter controls (not compact mode) even when player is small
              controlsBuilder: (context, controller) =>
                  VideoPlayerControls(controller: controller, compactMode: CompactMode.never),
            ),
      controls: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNetworkStatus(),
            const Divider(),
            _buildBufferingTierSelector(),
            const Divider(),
            _buildErrorRecoveryConfig(),
            const Divider(),
            _buildTestActions(),
            const Divider(),
            _buildEventLog(),
          ],
        ),
      ),
      maxVideoHeightFraction: 0.3,
    );
  }

  Widget _buildErrorWidget() => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error ?? 'Unknown error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildNetworkStatus() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller!,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Network Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _StatusRow(
            icon: Icons.wifi,
            label: 'Bandwidth',
            value: value.estimatedBandwidth != null
                ? '${(value.estimatedBandwidth! / 1000000).toStringAsFixed(2)} Mbps'
                : 'Unknown',
          ),
          _StatusRow(icon: Icons.downloading, label: 'Buffered', value: _formatDuration(value.bufferedPosition)),
          _StatusRow(
            icon: value.isNetworkBuffering ? Icons.hourglass_top : Icons.check_circle,
            label: 'Buffering',
            value: value.isNetworkBuffering ? 'Yes (${value.bufferingReason ?? "loading"})' : 'No',
            valueColor: value.isNetworkBuffering ? Colors.orange : Colors.green,
          ),
          _StatusRow(icon: Icons.play_circle, label: 'State', value: value.playbackState.name),
          if (value.hasError)
            _StatusRow(
              icon: Icons.error,
              label: 'Error',
              value: value.errorMessage ?? 'Unknown',
              valueColor: Colors.red,
            ),
          _StatusRow(icon: Icons.refresh, label: 'Retry Count', value: '${value.networkRetryCount}'),
        ],
      ),
    ),
  );

  Widget _buildBufferingTierSelector() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Buffering Tier', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Controls how much video is buffered ahead',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SegmentedButton<BufferingTier>(
          segments: const [
            ButtonSegment(value: BufferingTier.min, label: Text('Min')),
            ButtonSegment(value: BufferingTier.low, label: Text('Low')),
            ButtonSegment(value: BufferingTier.medium, label: Text('Med')),
            ButtonSegment(value: BufferingTier.high, label: Text('High')),
            ButtonSegment(value: BufferingTier.max, label: Text('Max')),
          ],
          selected: {_selectedTier},
          onSelectionChanged: (tiers) {
            setState(() => _selectedTier = tiers.first);
            _addToLog('Selected buffering tier: ${tiers.first.name}');
          },
        ),
        const SizedBox(height: 8),
        Text(
          _getBufferingTierDescription(_selectedTier),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );

  String _getBufferingTierDescription(BufferingTier tier) {
    switch (tier) {
      case BufferingTier.min:
        return 'Minimal buffering (~2s). Best for limited bandwidth.';
      case BufferingTier.low:
        return 'Light buffering (~5s). Fast startup, less smooth.';
      case BufferingTier.medium:
        return 'Balanced buffering (auto). Good for most cases.';
      case BufferingTier.high:
        return 'Heavy buffering (~30s). Better for unreliable networks.';
      case BufferingTier.max:
        return 'Maximum buffering (~60s). Best for very slow networks.';
    }
  }

  Widget _buildErrorRecoveryConfig() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Error Recovery', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Auto Retry'),
          subtitle: const Text('Automatically retry on network errors'),
          value: _autoRetryEnabled,
          onChanged: (value) {
            setState(() => _autoRetryEnabled = value);
            _addToLog('Auto retry: ${value ? "enabled" : "disabled"}');
          },
        ),
        ListTile(
          title: const Text('Max Retries'),
          subtitle: Text('$_maxRetries attempts'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _maxRetries > 1
                    ? () {
                        setState(() => _maxRetries--);
                        _addToLog('Max retries: $_maxRetries');
                      }
                    : null,
              ),
              Text('$_maxRetries'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _maxRetries < 10
                    ? () {
                        setState(() => _maxRetries++);
                        _addToLog('Max retries: $_maxRetries');
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(onPressed: _initializePlayer, child: const Text('Apply & Reinitialize')),
      ],
    ),
  );

  Widget _buildTestActions() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Test Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _testInvalidUrl,
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Error'),
            ),
            OutlinedButton.icon(
              onPressed: _retryPlayback,
              icon: const Icon(Icons.refresh),
              label: const Text('Manual Retry'),
            ),
            OutlinedButton.icon(
              onPressed: _initializePlayer,
              icon: const Icon(Icons.replay),
              label: const Text('Reload Valid'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildEventLog() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Event Log', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(onPressed: () => setState(_eventLog.clear), child: const Text('Clear')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _eventLog.isEmpty
              ? Center(
                  child: Text(
                    'Events will appear here',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: _eventLog.length,
                  itemBuilder: (context, index) => Text(
                    _eventLog[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
        ),
      ],
    ),
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(color: valueColor)),
      ],
    ),
  );
}
