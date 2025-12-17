import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('subtitle_discovery_test_');
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Ignore errors if directory doesn't exist or is already deleted
    }
  });

  Future<File> createFile(String relativePath, [String content = '']) async {
    final file = File('${tempDir.path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  group('SubtitleDiscovery', () {
    group('discoverSubtitles', () {
      test('returns empty list for non-existent video', () async {
        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/non_existent.mp4');

        expect(results, isEmpty);
      });

      test('returns empty list when no subtitles exist', () async {
        await createFile('video.mp4');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/video.mp4');

        expect(results, isEmpty);
      });

      test('finds subtitle with same base name', () async {
        await createFile('movie.mp4');
        await createFile('movie.srt', '1\n00:00:01,000 --> 00:00:02,000\nHello');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, hasLength(1));
        expect(results.first, isA<FileSubtitleSource>());
        expect(results.first.path, endsWith('movie.srt'));
      });

      test('finds subtitle with language suffix', () async {
        await createFile('movie.mp4');
        await createFile('movie.en.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, hasLength(1));
        expect(results.first.language, equals('en'));
        expect(results.first.label, equals('English'));
      });

      test('finds multiple subtitles', () async {
        await createFile('movie.mp4');
        await createFile('movie.srt');
        await createFile('movie.en.vtt');
        await createFile('movie.es.ass');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, hasLength(3));
      });

      test('finds subtitles in Subs subdirectory', () async {
        await createFile('movie.mp4');
        await createFile('Subs/movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        // On case-insensitive filesystems (macOS), both Subs and subs match
        expect(results, isNotEmpty);
        expect(results.any((s) => s.path.toLowerCase().contains('subs')), isTrue);
      });

      test('finds subtitles in Subtitles subdirectory', () async {
        await createFile('movie.mp4');
        await createFile('Subtitles/movie.vtt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        // On case-insensitive filesystems (macOS), both Subtitles and subtitles match
        expect(results, isNotEmpty);
        expect(results.any((s) => s.path.toLowerCase().contains('subtitles')), isTrue);
      });

      test('finds subtitles in both main dir and subdirectory', () async {
        await createFile('movie.mp4');
        await createFile('movie.en.srt');
        await createFile('Subs/movie.es.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        // At least 2 (main + Subs), possibly more on case-insensitive FS
        expect(results.length, greaterThanOrEqualTo(2));
        expect(results.any((s) => s.language == 'en'), isTrue);
        expect(results.any((s) => s.language == 'es'), isTrue);
      });

      test('detects correct subtitle format from extension', () async {
        await createFile('movie.mp4');
        await createFile('movie.srt');
        await createFile('movie.vtt');
        await createFile('movie.ass');
        await createFile('movie.ttml');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, hasLength(4));
        final formats = results.map((s) => s.format).toSet();
        expect(formats, containsAll([SubtitleFormat.srt, SubtitleFormat.vtt, SubtitleFormat.ass, SubtitleFormat.ttml]));
      });

      test('ignores non-subtitle files', () async {
        await createFile('movie.mp4');
        await createFile('movie.txt');
        await createFile('movie.jpg');
        await createFile('movie.nfo');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, isEmpty);
      });

      test('ignores unrelated subtitles', () async {
        await createFile('movie.mp4');
        await createFile('other_movie.srt');
        await createFile('different.vtt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, isEmpty);
      });
    });

    group('strict mode', () {
      test('matches exact base name', () async {
        await createFile('movie.mp4');
        await createFile('movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles(
          '${tempDir.path}/movie.mp4',
          mode: SubtitleDiscoveryMode.strict,
        );

        expect(results, hasLength(1));
      });

      test('matches exact base name with language suffix', () async {
        await createFile('movie.mp4');
        await createFile('movie.en.srt');

        final results = await SubtitleDiscovery.discoverSubtitles(
          '${tempDir.path}/movie.mp4',
          mode: SubtitleDiscoveryMode.strict,
        );

        expect(results, hasLength(1));
      });

      test('does not match prefix in strict mode', () async {
        await createFile('movie.mp4');
        await createFile('movie_extra_info.srt');

        final results = await SubtitleDiscovery.discoverSubtitles(
          '${tempDir.path}/movie.mp4',
          mode: SubtitleDiscoveryMode.strict,
        );

        expect(results, isEmpty);
      });

      test('case insensitive matching', () async {
        await createFile('Movie.mp4');
        await createFile('movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles(
          '${tempDir.path}/Movie.mp4',
          mode: SubtitleDiscoveryMode.strict,
        );

        expect(results, hasLength(1));
      });
    });

    group('prefix mode (default)', () {
      test('matches exact base name', () async {
        await createFile('movie.mp4');
        await createFile('movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, hasLength(1));
      });

      test('matches prefixed subtitles', () async {
        await createFile('movie.mp4');
        await createFile('movie.en.srt');
        await createFile('movie_english.srt');
        await createFile('movie.2024.1080p.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, hasLength(3));
      });

      test('does not match non-prefix', () async {
        await createFile('movie.mp4');
        await createFile('the_movie.srt');
        await createFile('my-movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results, isEmpty);
      });
    });

    group('fuzzy mode', () {
      test('matches same tokens', () async {
        await createFile('My.Movie.2024.1080p.BluRay.mp4');
        await createFile('My.Movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles(
          '${tempDir.path}/My.Movie.2024.1080p.BluRay.mp4',
          mode: SubtitleDiscoveryMode.fuzzy,
        );

        expect(results, hasLength(1));
      });

      test('matches with different separators', () async {
        await createFile('My_Movie_2024.mp4');
        await createFile('My-Movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles(
          '${tempDir.path}/My_Movie_2024.mp4',
          mode: SubtitleDiscoveryMode.fuzzy,
        );

        expect(results, hasLength(1));
      });

      test('does not match different first tokens', () async {
        await createFile('My.Movie.mp4');
        await createFile('Your.Movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles(
          '${tempDir.path}/My.Movie.mp4',
          mode: SubtitleDiscoveryMode.fuzzy,
        );

        expect(results, isEmpty);
      });

      test('requires first tokens to match in order', () async {
        await createFile('The.Matrix.1999.mp4');
        await createFile('Matrix.The.srt');

        final results = await SubtitleDiscovery.discoverSubtitles(
          '${tempDir.path}/The.Matrix.1999.mp4',
          mode: SubtitleDiscoveryMode.fuzzy,
        );

        expect(results, isEmpty);
      });
    });

    group('language extraction', () {
      test('extracts 2-letter language codes', () async {
        await createFile('movie.mp4');
        await createFile('movie.en.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results.first.language, equals('en'));
      });

      test('extracts 3-letter language codes', () async {
        await createFile('movie.mp4');
        await createFile('movie.eng.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results.first.language, equals('en'));
      });

      test('maps full language names', () async {
        await createFile('movie.mp4');
        await createFile('movie.english.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results.first.language, equals('en'));
      });

      test('generates label from language', () async {
        await createFile('movie.mp4');
        await createFile('movie.es.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results.first.label, equals('Spanish'));
      });

      test('uses External label when no language detected', () async {
        await createFile('movie.mp4');
        await createFile('movie.srt');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        expect(results.first.label, equals('External'));
        expect(results.first.language, isNull);
      });

      test('extracts various languages', () async {
        await createFile('movie.mp4');
        await createFile('movie.french.srt');
        await createFile('movie.deu.vtt');
        await createFile('movie.ja.ass');

        final results = await SubtitleDiscovery.discoverSubtitles('${tempDir.path}/movie.mp4');

        final languages = results.map((s) => s.language).toSet();
        expect(languages, containsAll(['fr', 'de', 'ja']));
      });
    });

    group('supportedExtensions', () {
      test('includes common subtitle formats', () {
        expect(SubtitleDiscovery.supportedExtensions, containsAll(['.srt', '.vtt', '.ass', '.ssa', '.ttml']));
      });
    });

    group('subdirectories', () {
      test('includes common subtitle folder names', () {
        expect(SubtitleDiscovery.subdirectories, containsAll(['Subs', 'Subtitles', 'subs', 'subtitles']));
      });
    });
  });
}
