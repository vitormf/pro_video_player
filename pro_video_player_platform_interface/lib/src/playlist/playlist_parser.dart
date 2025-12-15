import 'dart:async';
import 'dart:convert';

import '../types/video_source.dart';

import 'playlist_parse_result.dart';
import 'playlist_type.dart';

/// Abstract base class for playlist parsers.
abstract class PlaylistParser {
  /// Parses a playlist file content.
  ///
  /// [content] is the raw text content of the playlist file.
  /// [baseUrl] is the URL of the playlist file, used to resolve relative URLs.
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl);

  /// Detects the type of playlist from its content.
  PlaylistType detectType(String content);

  /// Resolves a potentially relative URL against a base URL.
  String resolveUrl(String url, String baseUrl) {
    // If URL is already absolute, return as-is
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('file://')) {
      return url;
    }

    // Parse base URL
    final baseUri = Uri.parse(baseUrl);

    // If URL starts with /, it's relative to the origin
    if (url.startsWith('/')) {
      return '${baseUri.scheme}://${baseUri.authority}$url';
    }

    // Otherwise, resolve relative to the base path
    final basePath = baseUri.path.substring(0, baseUri.path.lastIndexOf('/') + 1);
    return '${baseUri.scheme}://${baseUri.authority}$basePath$url';
  }
}

/// Parser for M3U/M3U8 playlists.
class M3UPlaylistParser extends PlaylistParser {
  @override
  PlaylistType detectType(String content) {
    // Check for HLS markers
    if (content.contains('#EXT-X-STREAM-INF')) {
      return PlaylistType.hlsMaster;
    }
    if (content.contains('#EXT-X-TARGETDURATION')) {
      return PlaylistType.hlsMedia;
    }
    // Simple M3U playlist
    return PlaylistType.m3uSimple;
  }

  @override
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl) {
    final type = detectType(content);

    // For HLS playlists, return empty items (they should be treated as single video sources)
    if (type == PlaylistType.hlsMaster || type == PlaylistType.hlsMedia) {
      return PlaylistParseResult(type: type, items: const [], metadata: {'originalUrl': baseUrl});
    }

    // Parse simple M3U playlist
    final items = <VideoSource>[];
    final lines = content.split('\n');
    String? title;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty || line.startsWith('#EXTM3U')) {
        continue;
      }

      // Parse #EXTINF directive (contains duration and title)
      if (line.startsWith('#EXTINF:')) {
        // Format: #EXTINF:duration,title
        // We parse this for future track metadata support
        continue;
      }

      // Parse #PLAYLIST directive (playlist title)
      if (line.startsWith('#PLAYLIST:')) {
        title = line.substring(10).trim();
        continue;
      }

      // Skip other comment lines
      if (line.startsWith('#')) {
        continue;
      }

      // This is a URL line
      final url = resolveUrl(line, baseUrl);
      items.add(VideoSource.network(url));
    }

    return PlaylistParseResult(type: type, items: items, title: title);
  }
}

/// Parser for PLS playlists.
class PLSPlaylistParser extends PlaylistParser {
  @override
  PlaylistType detectType(String content) => PlaylistType.pls;

  @override
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl) {
    final items = <VideoSource>[];
    final lines = content.split('\n');
    String? title;
    final fileMap = <int, String>{};
    final titleMap = <int, String>{};

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty || trimmed.startsWith('[playlist]')) {
        continue;
      }

      // Parse playlist title
      if (trimmed.toLowerCase().startsWith('title=')) {
        title = trimmed.substring(6);
        continue;
      }

      // Parse file entries: File1=url, File2=url, etc.
      if (trimmed.toLowerCase().startsWith('file')) {
        final equals = trimmed.indexOf('=');
        if (equals == -1) continue;

        final indexStr = trimmed.substring(4, equals);
        final url = trimmed.substring(equals + 1);

        try {
          final index = int.parse(indexStr);
          fileMap[index] = url;
        } catch (_) {
          // Invalid index, skip
        }
        continue;
      }

      // Parse title entries: Title1=name, Title2=name, etc.
      if (trimmed.toLowerCase().startsWith('title')) {
        final equals = trimmed.indexOf('=');
        if (equals == -1) continue;

        final indexStr = trimmed.substring(5, equals);
        final trackTitle = trimmed.substring(equals + 1);

        try {
          final index = int.parse(indexStr);
          titleMap[index] = trackTitle;
        } catch (_) {
          // Invalid index, skip
        }
      }
    }

    // Build items in order
    final indices = fileMap.keys.toList()..sort();
    for (final index in indices) {
      final url = fileMap[index]!;
      final resolvedUrl = resolveUrl(url, baseUrl);
      items.add(VideoSource.network(resolvedUrl));
    }

    return PlaylistParseResult(type: PlaylistType.pls, items: items, title: title, metadata: {'titles': titleMap});
  }
}

/// Parser for XSPF playlists.
class XSPFPlaylistParser extends PlaylistParser {
  @override
  PlaylistType detectType(String content) => PlaylistType.xspf;

  @override
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl) {
    // Simple XML parsing without external dependencies
    final items = <VideoSource>[];
    String? title;

    // Extract playlist title
    final titleMatch = RegExp('<title>(.*?)</title>').firstMatch(content);
    if (titleMatch != null) {
      title = _decodeXml(titleMatch.group(1)!);
    }

    // Extract all track locations
    final trackPattern = RegExp('<track>(.*?)</track>', dotAll: true);
    final locationPattern = RegExp('<location>(.*?)</location>');

    for (final trackMatch in trackPattern.allMatches(content)) {
      final trackContent = trackMatch.group(1)!;
      final locationMatch = locationPattern.firstMatch(trackContent);

      if (locationMatch != null) {
        final url = _decodeXml(locationMatch.group(1)!);
        final resolvedUrl = resolveUrl(url, baseUrl);
        items.add(VideoSource.network(resolvedUrl));
      }
    }

    return PlaylistParseResult(type: PlaylistType.xspf, items: items, title: title);
  }

  String _decodeXml(String text) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

/// Parser for JSPF playlists (JSON Shareable Playlist Format).
class JSPFPlaylistParser extends PlaylistParser {
  @override
  PlaylistType detectType(String content) => PlaylistType.jspf;

  @override
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl) {
    final items = <VideoSource>[];
    String? title;
    final titleMap = <int, String>{};

    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      final playlist = json['playlist'] as Map<String, dynamic>?;

      if (playlist == null) {
        return PlaylistParseResult(type: PlaylistType.jspf, items: items);
      }

      title = playlist['title'] as String?;

      final tracks = playlist['track'] as List<dynamic>?;
      if (tracks != null) {
        for (var i = 0; i < tracks.length; i++) {
          final track = tracks[i];
          if (track is Map<String, dynamic>) {
            final location = track['location'] as String?;
            if (location != null) {
              final resolvedUrl = resolveUrl(location, baseUrl);
              items.add(VideoSource.network(resolvedUrl));

              final trackTitle = track['title'] as String?;
              if (trackTitle != null) {
                titleMap[i] = trackTitle;
              }
            }
          }
        }
      }
    } catch (_) {
      // Invalid JSON, return empty result
    }

    return PlaylistParseResult(
      type: PlaylistType.jspf,
      items: items,
      title: title,
      metadata: titleMap.isNotEmpty ? {'titles': titleMap} : const {},
    );
  }
}

/// Parser for ASX playlists (Advanced Stream Redirector - Microsoft).
class ASXPlaylistParser extends PlaylistParser {
  @override
  PlaylistType detectType(String content) => PlaylistType.asx;

  @override
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl) {
    final items = <VideoSource>[];
    String? title;

    // Extract playlist title (case-insensitive)
    final titleMatch = RegExp('<title>(.*?)</title>', caseSensitive: false).firstMatch(content);
    if (titleMatch != null) {
      title = _decodeXml(titleMatch.group(1)!);
    }

    // Extract entries with ref href (case-insensitive)
    final entryPattern = RegExp('<entry[^>]*>(.*?)</entry>', caseSensitive: false, dotAll: true);
    final refPattern = RegExp(r'<ref\s+href\s*=\s*"([^"]*)"', caseSensitive: false);

    for (final entryMatch in entryPattern.allMatches(content)) {
      final entryContent = entryMatch.group(1)!;
      final refMatch = refPattern.firstMatch(entryContent);

      if (refMatch != null) {
        final url = _decodeXml(refMatch.group(1)!);
        final resolvedUrl = resolveUrl(url, baseUrl);
        items.add(VideoSource.network(resolvedUrl));
      }
    }

    return PlaylistParseResult(type: PlaylistType.asx, items: items, title: title);
  }

  String _decodeXml(String text) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

/// Parser for WPL playlists (Windows Media Player Playlist).
class WPLPlaylistParser extends PlaylistParser {
  @override
  PlaylistType detectType(String content) => PlaylistType.wpl;

  @override
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl) {
    final items = <VideoSource>[];
    String? title;

    // Extract title (case-insensitive)
    final titleMatch = RegExp('<title>(.*?)</title>', caseSensitive: false).firstMatch(content);
    if (titleMatch != null) {
      title = _decodeXml(titleMatch.group(1)!);
    }

    // Extract media items (case-insensitive)
    final mediaPattern = RegExp(r'<media\s+src\s*=\s*"([^"]*)"', caseSensitive: false);

    for (final match in mediaPattern.allMatches(content)) {
      final url = _decodeXml(match.group(1)!);
      final resolvedUrl = resolveUrl(url, baseUrl);
      items.add(VideoSource.network(resolvedUrl));
    }

    return PlaylistParseResult(type: PlaylistType.wpl, items: items, title: title);
  }

  String _decodeXml(String text) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

/// Parser for CUE sheets (describes tracks within a single file).
class CUEPlaylistParser extends PlaylistParser {
  @override
  PlaylistType detectType(String content) => PlaylistType.cue;

  @override
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl) {
    final files = <String>[];
    String? title;
    String? performer;
    String? currentFile;
    int? currentTrack;
    final trackMetadata = <int, Map<String, dynamic>>{};

    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      // PERFORMER "Artist Name" (album level)
      if (trimmed.startsWith('PERFORMER ') && performer == null && currentTrack == null) {
        performer = _extractQuoted(trimmed.substring(10));
        continue;
      }

      // TITLE "Album Name" (album level)
      if (trimmed.startsWith('TITLE ') && title == null && currentTrack == null) {
        title = _extractQuoted(trimmed.substring(6));
        continue;
      }

      // FILE "filename.mp4" TYPE
      if (trimmed.startsWith('FILE ')) {
        final fileMatch = RegExp(r'FILE\s+"([^"]+)"').firstMatch(trimmed);
        if (fileMatch != null) {
          currentFile = fileMatch.group(1);
          if (!files.contains(currentFile)) {
            files.add(currentFile!);
          }
        }
        continue;
      }

      // TRACK 01 VIDEO (or AUDIO)
      if (trimmed.startsWith('TRACK ')) {
        final trackMatch = RegExp(r'TRACK\s+(\d+)').firstMatch(trimmed);
        if (trackMatch != null && currentFile != null) {
          currentTrack = int.parse(trackMatch.group(1)!);
          trackMetadata[currentTrack] = {'file': currentFile};
        }
        continue;
      }

      // TITLE "Track Title" (track level)
      if (trimmed.startsWith('TITLE ') && currentTrack != null) {
        final trackTitle = _extractQuoted(trimmed.substring(6));
        if (trackTitle != null) {
          trackMetadata[currentTrack]?['title'] = trackTitle;
        }
        continue;
      }

      // INDEX 01 MM:SS:FF (start time)
      if (trimmed.startsWith('INDEX 01 ') && currentTrack != null) {
        final timeStr = trimmed.substring(9).trim();
        final millis = _parseTimestamp(timeStr);
        trackMetadata[currentTrack]?['startMs'] = millis;
        continue;
      }
    }

    // Build items from unique files
    final items = files.map((file) {
      final resolvedUrl = resolveUrl(file, baseUrl);
      return VideoSource.network(resolvedUrl);
    }).toList();

    final metadata = <String, dynamic>{};
    if (trackMetadata.isNotEmpty) {
      metadata['tracks'] = trackMetadata;
    }
    if (performer != null) {
      metadata['performer'] = performer;
    }

    return PlaylistParseResult(type: PlaylistType.cue, items: items, title: title, metadata: metadata);
  }

  String? _extractQuoted(String text) {
    final match = RegExp('"([^"]*)"').firstMatch(text);
    return match?.group(1);
  }

  /// Parses MM:SS:FF timestamp to milliseconds (75 frames per second).
  int _parseTimestamp(String timestamp) {
    final parts = timestamp.split(':');
    if (parts.length != 3) return 0;

    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    final frames = int.tryParse(parts[2]) ?? 0;

    return (minutes * 60 * 1000) + (seconds * 1000) + (frames * 1000 ~/ 75);
  }
}

/// Parser for DASH manifests (MPD - Media Presentation Description).
///
/// DASH (Dynamic Adaptive Streaming over HTTP) manifests are XML files
/// that describe adaptive streaming content with multiple quality levels.
///
/// This parser detects DASH manifests and returns them as a single video
/// source to be passed directly to the native player for adaptive playback.
///
/// ## Platform Support
///
/// | Platform | Support | Implementation |
/// |----------|---------|----------------|
/// | Android  | ✅      | ExoPlayer native |
/// | Web      | ✅      | dash.js library |
/// | iOS      | ❌      | AVPlayer limitation |
/// | macOS    | ❌      | AVPlayer limitation |
///
/// For Apple platforms, use HLS (.m3u8) instead of DASH (.mpd).
///
/// ## Detection
///
/// DASH manifests are detected by:
/// - URL ending in `.mpd` or containing `.mpd?`
/// - XML content containing `<MPD` root element
class DASHPlaylistParser extends PlaylistParser {
  @override
  PlaylistType detectType(String content) => PlaylistType.dash;

  @override
  FutureOr<PlaylistParseResult> parse(String content, String baseUrl) {
    // DASH manifests should be treated as single adaptive sources
    // Return empty items - the original URL should be used directly
    String? title;

    // Try to extract title from MPD if present
    final titleMatch = RegExp('<Title>(.*?)</Title>', caseSensitive: false).firstMatch(content);
    if (titleMatch != null) {
      title = _decodeXml(titleMatch.group(1)!);
    }

    return PlaylistParseResult(
      type: PlaylistType.dash,
      items: const [],
      title: title,
      metadata: {'originalUrl': baseUrl},
    );
  }

  String _decodeXml(String text) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

/// Creates a parser based on file extension or content.
PlaylistParser createPlaylistParser({String? url, String? content}) {
  // Try to detect from content first
  if (content != null) {
    // DASH: XML with <MPD> root element
    if (content.contains('<MPD') || content.contains('<mpd')) {
      return DASHPlaylistParser();
    }
    if (content.contains('#EXTM3U') || content.contains('#EXTINF')) {
      return M3UPlaylistParser();
    }
    if (content.contains('[playlist]')) {
      return PLSPlaylistParser();
    }
    if (content.contains('<playlist') && content.contains('xmlns="http://xspf.org')) {
      return XSPFPlaylistParser();
    }
    // JSPF: JSON with "playlist" key
    if (content.trimLeft().startsWith('{') && content.contains('"playlist"')) {
      return JSPFPlaylistParser();
    }
    // ASX: XML with <asx> tag
    if (content.toLowerCase().contains('<asx')) {
      return ASXPlaylistParser();
    }
    // WPL: XML with <?wpl> declaration
    if (content.contains('<?wpl')) {
      return WPLPlaylistParser();
    }
    // CUE: Contains FILE and TRACK directives
    if (content.contains('FILE ') && content.contains('TRACK ')) {
      return CUEPlaylistParser();
    }
  }

  // Fall back to URL extension
  if (url != null) {
    final lowerUrl = url.toLowerCase();
    // Check for .mpd with or without query params
    if (lowerUrl.endsWith('.mpd') || lowerUrl.contains('.mpd?')) {
      return DASHPlaylistParser();
    }
    if (lowerUrl.endsWith('.m3u') || lowerUrl.endsWith('.m3u8')) {
      return M3UPlaylistParser();
    }
    if (lowerUrl.endsWith('.pls')) {
      return PLSPlaylistParser();
    }
    if (lowerUrl.endsWith('.xspf')) {
      return XSPFPlaylistParser();
    }
    if (lowerUrl.endsWith('.jspf')) {
      return JSPFPlaylistParser();
    }
    if (lowerUrl.endsWith('.asx')) {
      return ASXPlaylistParser();
    }
    if (lowerUrl.endsWith('.wpl')) {
      return WPLPlaylistParser();
    }
    if (lowerUrl.endsWith('.cue')) {
      return CUEPlaylistParser();
    }
  }

  // Default to M3U parser
  return M3UPlaylistParser();
}
