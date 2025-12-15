import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../types/subtitle_cue.dart';
import '../types/subtitle_format.dart';
import '../types/subtitle_source.dart';
import 'srt_parser.dart';
import 'ssa_parser.dart';
import 'ttml_parser.dart';
import 'vtt_parser.dart';
import 'webvtt_converter.dart';

/// Service for loading and parsing external subtitle files.
///
/// Handles downloading subtitle files from network sources, reading from
/// local files or Flutter assets, parsing the content using format-specific
/// parsers, and optionally converting to WebVTT format for native rendering.
class SubtitleLoader {
  /// Creates a [SubtitleLoader] with an optional custom HTTP client.
  ///
  /// If [client] is not provided, a default [http.Client] will be used.
  SubtitleLoader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// SRT parser instance.
  static const _srtParser = SrtParser();

  /// WebVTT parser instance.
  static const _vttParser = VttParser();

  /// SSA/ASS parser instance.
  static const _ssaParser = SsaParser();

  /// TTML parser instance.
  static const _ttmlParser = TtmlParser();

  /// Loads and parses a subtitle file from the given [source].
  ///
  /// Returns a list of [SubtitleCue] objects representing the parsed subtitles.
  ///
  /// Throws an [Exception] if:
  /// - The subtitle file cannot be downloaded/read
  /// - The subtitle format is unsupported
  /// - The subtitle content cannot be parsed
  Future<List<SubtitleCue>> loadSubtitles(SubtitleSource source) async {
    // Load subtitle content based on source type
    final content = await _loadContent(source);

    // Parse content using appropriate parser
    return _parseContent(content, source.format ?? SubtitleFormat.fromUrl(source.path));
  }

  /// Loads and parses a subtitle file, then converts it to WebVTT format.
  ///
  /// This is useful for native rendering mode where platforms may only support
  /// WebVTT format. Non-WebVTT formats (SRT, SSA/ASS, TTML) are first parsed
  /// to extract cues, then converted to WebVTT format.
  ///
  /// Returns a WebVTT-formatted string that can be passed to native players.
  ///
  /// If the source is already WebVTT format, returns the original content.
  Future<String> loadAndConvertToWebVTT(SubtitleSource source) async {
    final format = source.format ?? SubtitleFormat.fromUrl(source.path);

    // Load subtitle content
    final content = await _loadContent(source);

    // If already WebVTT, return as-is
    if (format == SubtitleFormat.vtt) {
      return content;
    }

    // Parse to cues first
    final cues = _parseContent(content, format);

    // Convert cues to WebVTT format
    return WebVttConverter.convert(cues);
  }

  /// Loads subtitle content from the source.
  ///
  /// Handles three source types:
  /// - Network: Downloads from HTTP/HTTPS URL
  /// - File: Reads from local filesystem
  /// - Asset: Loads from Flutter asset bundle
  Future<String> _loadContent(SubtitleSource source) async {
    switch (source) {
      case NetworkSubtitleSource():
        return _downloadFromNetwork(source.path);
      case FileSubtitleSource():
        return _readFromFile(source.path);
      case AssetSubtitleSource():
        return _loadFromAsset(source.path);
    }
  }

  /// Downloads subtitle content from a network URL.
  Future<String> _downloadFromNetwork(String url) async {
    try {
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download subtitle: HTTP ${response.statusCode}');
      }

      return utf8.decode(response.bodyBytes);
    } catch (e) {
      throw Exception('Failed to download subtitle from $url: $e');
    }
  }

  /// Reads subtitle content from a local file.
  Future<String> _readFromFile(String path) async {
    try {
      final file = File(path);
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read subtitle file $path: $e');
    }
  }

  /// Loads subtitle content from Flutter asset bundle.
  Future<String> _loadFromAsset(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      throw Exception('Failed to load subtitle asset $assetPath: $e');
    }
  }

  /// Parses subtitle content using the appropriate parser for the format.
  ///
  /// Returns a list of [SubtitleCue] objects.
  ///
  /// Throws an [ArgumentError] if the format is null or unsupported.
  List<SubtitleCue> _parseContent(String content, SubtitleFormat? format) {
    if (format == null) {
      throw ArgumentError('Subtitle format cannot be null');
    }

    switch (format) {
      case SubtitleFormat.srt:
        return _srtParser.parse(content);
      case SubtitleFormat.vtt:
        return _vttParser.parse(content);
      case SubtitleFormat.ssa:
      case SubtitleFormat.ass:
        return _ssaParser.parse(content);
      case SubtitleFormat.ttml:
        return _ttmlParser.parse(content);
    }
  }

  /// Closes the HTTP client and releases resources.
  void dispose() {
    _client.close();
  }
}
