import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('SubtitleSource', () {
    group('SubtitleSource.network', () {
      test('creates network source with URL', () {
        const source = SubtitleSource.network('https://example.com/subtitles.srt');

        expect(source, isA<NetworkSubtitleSource>());
        expect(source.path, equals('https://example.com/subtitles.srt'));
        expect(source.sourceType, equals('network'));
      });

      test('creates network source with all parameters', () {
        const source = SubtitleSource.network(
          'https://example.com/subtitles.vtt',
          label: 'English',
          language: 'en',
          format: SubtitleFormat.vtt,
          isDefault: true,
        );

        expect(source.path, equals('https://example.com/subtitles.vtt'));
        expect(source.label, equals('English'));
        expect(source.language, equals('en'));
        expect(source.format, equals(SubtitleFormat.vtt));
        expect(source.isDefault, isTrue);
      });

      test('has correct default values', () {
        const source = SubtitleSource.network('https://example.com/sub.srt');

        expect(source.label, isNull);
        expect(source.language, isNull);
        expect(source.format, isNull);
        expect(source.isDefault, isFalse);
      });
    });

    group('SubtitleSource.file', () {
      test('creates file source with path', () {
        const source = SubtitleSource.file('/path/to/subtitles.srt');

        expect(source, isA<FileSubtitleSource>());
        expect(source.path, equals('/path/to/subtitles.srt'));
        expect(source.sourceType, equals('file'));
      });

      test('creates file source with all parameters', () {
        const source = SubtitleSource.file(
          '/path/to/subtitles.ass',
          label: 'Spanish',
          language: 'es',
          format: SubtitleFormat.ass,
        );

        expect(source.path, equals('/path/to/subtitles.ass'));
        expect(source.label, equals('Spanish'));
        expect(source.language, equals('es'));
        expect(source.format, equals(SubtitleFormat.ass));
        expect(source.isDefault, isFalse);
      });
    });

    group('SubtitleSource.asset', () {
      test('creates asset source with path', () {
        const source = SubtitleSource.asset('assets/subtitles/english.vtt');

        expect(source, isA<AssetSubtitleSource>());
        expect(source.path, equals('assets/subtitles/english.vtt'));
        expect(source.sourceType, equals('asset'));
      });

      test('creates asset source with all parameters', () {
        const source = SubtitleSource.asset(
          'assets/subtitles/french.srt',
          label: 'French',
          language: 'fr',
          format: SubtitleFormat.srt,
        );

        expect(source.path, equals('assets/subtitles/french.srt'));
        expect(source.label, equals('French'));
        expect(source.language, equals('fr'));
        expect(source.format, equals(SubtitleFormat.srt));
      });
    });

    group('SubtitleSource.from', () {
      group('network sources', () {
        test('detects http:// URLs', () {
          final source = SubtitleSource.from('http://example.com/sub.srt');

          expect(source, isA<NetworkSubtitleSource>());
          expect(source.path, equals('http://example.com/sub.srt'));
        });

        test('detects https:// URLs', () {
          final source = SubtitleSource.from('https://example.com/sub.vtt');

          expect(source, isA<NetworkSubtitleSource>());
          expect(source.path, equals('https://example.com/sub.vtt'));
        });

        test('adds https:// to bare domains', () {
          final source = SubtitleSource.from('example.com/subtitles.srt');

          expect(source, isA<NetworkSubtitleSource>());
          expect(source.path, equals('https://example.com/subtitles.srt'));
        });

        test('preserves case for URLs', () {
          final source = SubtitleSource.from('HTTPS://Example.Com/Sub.SRT');

          expect(source, isA<NetworkSubtitleSource>());
          expect(source.path, equals('HTTPS://Example.Com/Sub.SRT'));
        });
      });

      group('file sources', () {
        test('detects absolute Unix paths', () {
          final source = SubtitleSource.from('/var/mobile/Documents/sub.srt');

          expect(source, isA<FileSubtitleSource>());
          expect(source.path, equals('/var/mobile/Documents/sub.srt'));
        });

        test('detects file:// URIs and decodes path', () {
          final source = SubtitleSource.from('file:///path/to/subtitles.vtt');

          expect(source, isA<FileSubtitleSource>());
          expect(source.path, equals('/path/to/subtitles.vtt'));
        });

        test('decodes URL-encoded file:// paths', () {
          final source = SubtitleSource.from('file:///path/with%20spaces/sub.srt');

          expect(source, isA<FileSubtitleSource>());
          expect(source.path, equals('/path/with spaces/sub.srt'));
        });

        test('detects Windows paths with backslash', () {
          final source = SubtitleSource.from(r'C:\Users\Videos\sub.srt');

          expect(source, isA<FileSubtitleSource>());
          expect(source.path, equals(r'C:\Users\Videos\sub.srt'));
        });

        test('detects Windows paths with forward slash', () {
          final source = SubtitleSource.from('D:/Movies/sub.vtt');

          expect(source, isA<FileSubtitleSource>());
          expect(source.path, equals('D:/Movies/sub.vtt'));
        });

        test('detects Android content:// URIs', () {
          final source = SubtitleSource.from('content://media/external/video/123/sub.srt');

          expect(source, isA<FileSubtitleSource>());
          expect(source.path, equals('content://media/external/video/123/sub.srt'));
        });
      });

      group('asset sources', () {
        test('detects assets/ paths', () {
          final source = SubtitleSource.from('assets/subtitles/english.srt');

          expect(source, isA<AssetSubtitleSource>());
          expect(source.path, equals('assets/subtitles/english.srt'));
        });

        test('detects packages/ paths', () {
          final source = SubtitleSource.from('packages/my_package/assets/sub.vtt');

          expect(source, isA<AssetSubtitleSource>());
          expect(source.path, equals('packages/my_package/assets/sub.vtt'));
        });
      });

      group('with metadata', () {
        test('passes metadata to network source', () {
          final source = SubtitleSource.from(
            'https://example.com/sub.srt',
            label: 'English',
            language: 'en',
            format: SubtitleFormat.srt,
            isDefault: true,
          );

          expect(source.label, equals('English'));
          expect(source.language, equals('en'));
          expect(source.format, equals(SubtitleFormat.srt));
          expect(source.isDefault, isTrue);
        });

        test('passes metadata to file source', () {
          final source = SubtitleSource.from('/path/to/sub.vtt', label: 'Spanish', language: 'es');

          expect(source, isA<FileSubtitleSource>());
          expect(source.label, equals('Spanish'));
          expect(source.language, equals('es'));
        });

        test('passes metadata to asset source', () {
          final source = SubtitleSource.from(
            'assets/subtitles/french.ass',
            label: 'French',
            language: 'fr',
            format: SubtitleFormat.ass,
          );

          expect(source, isA<AssetSubtitleSource>());
          expect(source.label, equals('French'));
          expect(source.language, equals('fr'));
          expect(source.format, equals(SubtitleFormat.ass));
        });
      });

      group('edge cases', () {
        test('trims whitespace', () {
          final source = SubtitleSource.from('  https://example.com/sub.srt  ');

          expect(source, isA<NetworkSubtitleSource>());
          expect(source.path, equals('https://example.com/sub.srt'));
        });

        test('throws on empty input', () {
          expect(() => SubtitleSource.from(''), throwsA(isA<ArgumentError>()));
        });

        test('throws on whitespace-only input', () {
          expect(() => SubtitleSource.from('   '), throwsA(isA<ArgumentError>()));
        });
      });
    });

    group('equality', () {
      test('network sources are equal with same values', () {
        const source1 = SubtitleSource.network('https://example.com/sub.srt', label: 'English', language: 'en');
        const source2 = SubtitleSource.network('https://example.com/sub.srt', label: 'English', language: 'en');

        expect(source1, equals(source2));
        expect(source1.hashCode, equals(source2.hashCode));
      });

      test('network sources are not equal with different URLs', () {
        const source1 = SubtitleSource.network('https://example.com/sub1.srt');
        const source2 = SubtitleSource.network('https://example.com/sub2.srt');

        expect(source1, isNot(equals(source2)));
      });

      test('file sources are equal with same values', () {
        const source1 = SubtitleSource.file('/path/to/sub.srt', label: 'Test');
        const source2 = SubtitleSource.file('/path/to/sub.srt', label: 'Test');

        expect(source1, equals(source2));
        expect(source1.hashCode, equals(source2.hashCode));
      });

      test('different source types are not equal', () {
        const network = SubtitleSource.network('https://example.com/sub.srt');
        const file = SubtitleSource.file('/path/to/sub.srt');

        expect(network, isNot(equals(file)));
      });
    });

    group('toString', () {
      test('network source toString includes URL', () {
        const source = SubtitleSource.network('https://example.com/sub.srt', label: 'English');

        final str = source.toString();
        expect(str, contains('NetworkSubtitleSource'));
        expect(str, contains('https://example.com/sub.srt'));
        expect(str, contains('English'));
      });

      test('file source toString includes path', () {
        const source = SubtitleSource.file('/path/to/sub.srt');

        final str = source.toString();
        expect(str, contains('FileSubtitleSource'));
        expect(str, contains('/path/to/sub.srt'));
      });

      test('asset source toString includes asset path', () {
        const source = SubtitleSource.asset('assets/sub.vtt');

        final str = source.toString();
        expect(str, contains('AssetSubtitleSource'));
        expect(str, contains('assets/sub.vtt'));
      });
    });
  });
}
