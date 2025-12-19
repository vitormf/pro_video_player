import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'player_screen.dart';

/// Home screen with options to open a file or URL.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final path = file.path;
      if (path != null && context.mounted) {
        unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerScreen(videoPath: path))));
      }
    }
  }

  Future<void> _openUrl(BuildContext context) async {
    final controller = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Video URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://example.com/video.mp4', border: OutlineInputBorder()),
          keyboardType: TextInputType.url,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Open')),
        ],
      ),
    );

    if (url != null && url.isNotEmpty && context.mounted) {
      unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerScreen(videoPath: url))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Simple Player'), centerTitle: true),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.play_circle_outline, size: 120, color: Colors.deepPurple),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => _openFile(context),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open File'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openUrl(context),
                icon: const Icon(Icons.link),
                label: const Text('Open URL'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
              ),
              const SizedBox(height: 48),
              Text(
                'You can also open videos by:\n'
                '- Selecting "Open With" from other apps\n'
                '- Sharing video files to this app\n'
                '- Double-clicking video files (macOS)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
