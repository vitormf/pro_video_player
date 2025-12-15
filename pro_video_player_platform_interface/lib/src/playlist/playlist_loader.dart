import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../types/playlist.dart';
import '../types/video_source.dart';

import 'playlist_parse_result.dart';
import 'playlist_parser.dart';

/// Service for loading and parsing playlist files.
class PlaylistLoader {
  /// Creates a [PlaylistLoader] with an optional custom HTTP client.
  ///
  /// If [client] is not provided, a default [http.Client] will be used.
  PlaylistLoader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Loads and parses a playlist from a URL.
  ///
  /// Returns a [PlaylistParseResult] containing the parsed playlist information.
  /// If the playlist is an HLS adaptive stream, the result will have empty items
  /// and should be treated as a single video source.
  Future<PlaylistParseResult> loadPlaylist(String url, {Map<String, String>? headers}) async {
    try {
      // Fetch the playlist file
      final response = await _client.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Failed to load playlist: HTTP ${response.statusCode}');
      }

      // Decode content
      final content = utf8.decode(response.bodyBytes);

      // Create appropriate parser
      final parser = createPlaylistParser(url: url, content: content);

      // Parse the playlist
      return await parser.parse(content, url);
    } catch (e) {
      throw Exception('Failed to load playlist from $url: $e');
    }
  }

  /// Converts a [PlaylistParseResult] to a [Playlist] object.
  ///
  /// Only works for multi-video playlists. Returns null for adaptive streams.
  Playlist? toPlaylist(PlaylistParseResult result) {
    if (result.isAdaptiveStream || result.items.isEmpty) {
      return null;
    }

    return Playlist(items: result.items);
  }

  /// Converts a [PlaylistVideoSource] to either a [Playlist] or a [VideoSource].
  ///
  /// If the playlist is a simple multi-video playlist, returns a [Playlist].
  /// If it's an HLS adaptive stream, returns the original URL as a [NetworkVideoSource].
  Future<dynamic> loadAndConvert(PlaylistVideoSource source) async {
    final result = await loadPlaylist(source.url, headers: source.headers);

    if (result.isAdaptiveStream) {
      // Treat as a single video source
      return VideoSource.network(source.url, headers: source.headers);
    }

    // Convert to playlist
    return toPlaylist(result);
  }
}
