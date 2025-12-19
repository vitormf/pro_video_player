import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/player_screen.dart';

void main() {
  runApp(const SimplePlayerApp());
}

/// Simple video player app that opens files from the system or URLs.
class SimplePlayerApp extends StatefulWidget {
  const SimplePlayerApp({super.key});

  @override
  State<SimplePlayerApp> createState() => _SimplePlayerAppState();
}

class _SimplePlayerAppState extends State<SimplePlayerApp> {
  static const _fileChannel = MethodChannel('simple_player/file');

  final _navigatorKey = GlobalKey<NavigatorState>();
  String? _pendingVideoPath;

  @override
  void initState() {
    super.initState();
    unawaited(_setupFileChannel());
  }

  Future<void> _setupFileChannel() async {
    _fileChannel.setMethodCallHandler((call) async {
      if (call.method == 'openFile') {
        final path = call.arguments as String;
        _playVideo(path);
      }
    });

    // Check for initial file on cold start
    await _checkInitialFile();
  }

  Future<void> _checkInitialFile() async {
    try {
      final initialFile = await _fileChannel.invokeMethod<String>('getInitialFile');
      if (initialFile != null && initialFile.isNotEmpty) {
        _playVideo(initialFile);
      }
    } on PlatformException {
      // No initial file - that's fine
    }
  }

  void _playVideo(String path) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      // Navigator not ready yet, store for later
      setState(() {
        _pendingVideoPath = path;
      });
      return;
    }

    // Navigator is ready - push replacement to replace current video
    // Use pushAndRemoveUntil to clear the stack and show only the new video
    unawaited(
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => PlayerScreen(videoPath: path, openedExternally: true)),
        (route) => false, // Remove all previous routes
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Simple Player',
    debugShowCheckedModeBanner: false,
    navigatorKey: _navigatorKey,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: _pendingVideoPath != null
        ? PlayerScreen(videoPath: _pendingVideoPath!, openedExternally: true)
        : const HomeScreen(),
  );
}
