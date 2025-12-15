// ignore_for_file: avoid_classes_with_only_static_members - Necessary: utility class providing namespace for static helper methods
// ignore_for_file: avoid_slow_async_io - Necessary: subtitle discovery requires filesystem scanning to find matching subtitle files

import 'dart:io';

import '../types/subtitle_discovery_mode.dart';
import '../types/subtitle_format.dart';
import '../types/subtitle_source.dart';

/// Discovers subtitle files that match a video file.
///
/// This utility searches for subtitle files in the same directory as the video
/// and in common subdirectories, using configurable matching modes.
abstract final class SubtitleDiscovery {
  /// Supported subtitle file extensions.
  static const supportedExtensions = ['.srt', '.vtt', '.ass', '.ssa', '.ttml'];

  /// Subdirectories to search for subtitles (case-insensitive matching).
  static const subdirectories = ['Subs', 'Subtitles', 'subs', 'subtitles'];

  /// Common separators used in filenames for tokenization.
  static final _separatorPattern = RegExp(r'[.\-_\s]+');

  /// Discovers subtitle files matching the given video file path.
  ///
  /// Returns a list of [SubtitleSource] objects for discovered subtitles.
  /// The [mode] controls how strictly filenames must match.
  ///
  /// Example:
  /// ```dart
  /// final subtitles = await SubtitleDiscovery.discoverSubtitles(
  ///   '/Movies/my_movie.mp4',
  ///   mode: SubtitleDiscoveryMode.prefix,
  /// );
  /// ```
  static Future<List<SubtitleSource>> discoverSubtitles(
    String videoPath, {
    SubtitleDiscoveryMode mode = SubtitleDiscoveryMode.prefix,
  }) async {
    final videoFile = File(videoPath);
    if (!await videoFile.exists()) {
      return [];
    }

    final videoDir = videoFile.parent;
    final videoBaseName = _getBaseName(videoFile.path);

    // Search in the video's directory
    final discovered = <SubtitleSource>[...await _searchDirectory(videoDir, videoBaseName, mode)];

    // Search in common subdirectories
    for (final subdir in subdirectories) {
      final subdirPath = Directory('${videoDir.path}/$subdir');
      if (await subdirPath.exists()) {
        discovered.addAll(await _searchDirectory(subdirPath, videoBaseName, mode));
      }
    }

    return discovered;
  }

  /// Searches a directory for matching subtitle files.
  static Future<List<SubtitleSource>> _searchDirectory(
    Directory dir,
    String videoBaseName,
    SubtitleDiscoveryMode mode,
  ) async {
    final results = <SubtitleSource>[];

    try {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;

        final fileName = entity.path.split(Platform.pathSeparator).last;
        final extension = _getExtension(fileName).toLowerCase();

        // Check if it's a subtitle file
        if (!supportedExtensions.contains(extension)) continue;

        final subtitleBaseName = _getBaseName(entity.path);

        // Check if it matches according to the mode
        if (_matches(videoBaseName, subtitleBaseName, mode)) {
          final language = _extractLanguage(subtitleBaseName, videoBaseName);
          final format = SubtitleFormat.fromFileExtension(extension.substring(1));

          results.add(
            SubtitleSource.file(
              entity.path,
              label: _generateLabel(subtitleBaseName, language),
              language: language,
              format: format,
            ),
          );
        }
      }
    } catch (e) {
      // Directory access error - return what we found
    }

    return results;
  }

  /// Checks if a subtitle filename matches a video filename.
  static bool _matches(String videoBaseName, String subtitleBaseName, SubtitleDiscoveryMode mode) {
    final videoLower = videoBaseName.toLowerCase();
    final subtitleLower = subtitleBaseName.toLowerCase();

    switch (mode) {
      case SubtitleDiscoveryMode.strict:
        // Exact match or exact match with language suffix
        // video.mp4 matches video.srt, video.en.srt
        return subtitleLower == videoLower || subtitleLower.startsWith('$videoLower.');

      case SubtitleDiscoveryMode.prefix:
        // Subtitle starts with video's base name
        return subtitleLower.startsWith(videoLower);

      case SubtitleDiscoveryMode.fuzzy:
        // First 2-3 tokens must match
        return _fuzzyMatch(videoBaseName, subtitleBaseName);
    }
  }

  /// Performs fuzzy matching based on filename tokens.
  static bool _fuzzyMatch(String videoBaseName, String subtitleBaseName) {
    final videoTokens = _tokenize(videoBaseName);
    final subtitleTokens = _tokenize(subtitleBaseName);

    if (videoTokens.isEmpty || subtitleTokens.isEmpty) {
      return false;
    }

    // Require at least 2 matching tokens, or all tokens if fewer
    final requiredMatches = videoTokens.length >= 3 ? 2 : videoTokens.length;
    var matches = 0;

    for (var i = 0; i < requiredMatches && i < subtitleTokens.length; i++) {
      if (i < videoTokens.length && videoTokens[i].toLowerCase() == subtitleTokens[i].toLowerCase()) {
        matches++;
      } else {
        break; // Tokens must match in order from the start
      }
    }

    return matches >= requiredMatches;
  }

  /// Tokenizes a filename by common separators.
  static List<String> _tokenize(String name) => name.split(_separatorPattern).where((t) => t.isNotEmpty).toList();

  /// Extracts the base name from a file path (without extension).
  static String _getBaseName(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final lastDot = fileName.lastIndexOf('.');
    return lastDot > 0 ? fileName.substring(0, lastDot) : fileName;
  }

  /// Gets the file extension including the dot.
  static String _getExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    return lastDot > 0 ? fileName.substring(lastDot) : '';
  }

  /// Extracts language code from subtitle filename.
  ///
  /// Looks for common patterns like:
  /// - movie.en.srt → 'en'
  /// - movie.eng.srt → 'eng'
  /// - movie.english.srt → 'en' (mapped)
  static String? _extractLanguage(String subtitleBaseName, String videoBaseName) {
    // Remove video base name to get the suffix
    final videoLower = videoBaseName.toLowerCase();
    final subtitleLower = subtitleBaseName.toLowerCase();

    if (!subtitleLower.startsWith(videoLower)) {
      return null;
    }

    final suffix = subtitleBaseName.substring(videoBaseName.length);
    if (suffix.isEmpty) {
      return null;
    }

    // Parse suffix parts (e.g., ".en" or ".english" or ".eng.sdh")
    final parts = suffix.split('.').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return null;
    }

    // Check first part for language
    final firstPart = parts.first.toLowerCase();
    return _languageMap[firstPart] ?? (firstPart.length <= 3 ? firstPart : null);
  }

  /// Generates a display label for a subtitle track.
  static String _generateLabel(String subtitleBaseName, String? language) {
    if (language != null) {
      final langName = _languageNames[language] ?? language.toUpperCase();
      return langName;
    }
    return 'External';
  }

  /// Maps common language names to ISO 639-1 codes.
  static const _languageMap = {
    'english': 'en',
    'eng': 'en',
    'spanish': 'es',
    'spa': 'es',
    'french': 'fr',
    'fra': 'fr',
    'fre': 'fr',
    'german': 'de',
    'deu': 'de',
    'ger': 'de',
    'portuguese': 'pt',
    'por': 'pt',
    'italian': 'it',
    'ita': 'it',
    'japanese': 'ja',
    'jpn': 'ja',
    'korean': 'ko',
    'kor': 'ko',
    'chinese': 'zh',
    'chi': 'zh',
    'zho': 'zh',
    'russian': 'ru',
    'rus': 'ru',
    'arabic': 'ar',
    'ara': 'ar',
    'dutch': 'nl',
    'nld': 'nl',
    'dut': 'nl',
    'polish': 'pl',
    'pol': 'pl',
    'turkish': 'tr',
    'tur': 'tr',
    'swedish': 'sv',
    'swe': 'sv',
    'norwegian': 'no',
    'nor': 'no',
    'danish': 'da',
    'dan': 'da',
    'finnish': 'fi',
    'fin': 'fi',
    'greek': 'el',
    'ell': 'el',
    'gre': 'el',
    'hebrew': 'he',
    'heb': 'he',
    'hindi': 'hi',
    'hin': 'hi',
    'thai': 'th',
    'tha': 'th',
    'vietnamese': 'vi',
    'vie': 'vi',
    'indonesian': 'id',
    'ind': 'id',
    'malay': 'ms',
    'msa': 'ms',
    'may': 'ms',
  };

  /// Maps ISO 639-1 codes to display names.
  static const _languageNames = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'pt': 'Portuguese',
    'it': 'Italian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ru': 'Russian',
    'ar': 'Arabic',
    'nl': 'Dutch',
    'pl': 'Polish',
    'tr': 'Turkish',
    'sv': 'Swedish',
    'no': 'Norwegian',
    'da': 'Danish',
    'fi': 'Finnish',
    'el': 'Greek',
    'he': 'Hebrew',
    'hi': 'Hindi',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'id': 'Indonesian',
    'ms': 'Malay',
  };
}
