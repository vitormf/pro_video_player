import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

void main() {
  group('VideoSource', () {
    group('NetworkVideoSource', () {
      test('creates with url only', () {
        const source = VideoSource.network('https://example.com/video.mp4');

        expect(source, isA<NetworkVideoSource>());
        expect((source as NetworkVideoSource).url, equals('https://example.com/video.mp4'));
        expect(source.headers, isNull);
      });

      test('creates with url and headers', () {
        const source = VideoSource.network('https://example.com/video.mp4', headers: {'Authorization': 'Bearer token'});

        expect(source, isA<NetworkVideoSource>());
        const networkSource = source as NetworkVideoSource;
        expect(networkSource.url, equals('https://example.com/video.mp4'));
        expect(networkSource.headers, equals({'Authorization': 'Bearer token'}));
      });

      test('equality works correctly', () {
        const source1 = VideoSource.network('https://example.com/video.mp4');
        const source2 = VideoSource.network('https://example.com/video.mp4');
        const source3 = VideoSource.network('https://example.com/other.mp4');

        expect(source1, equals(source2));
        expect(source1, isNot(equals(source3)));
      });

      test('equality with headers works correctly', () {
        const source1 = VideoSource.network('https://example.com/video.mp4', headers: {'key': 'value'});
        const source2 = VideoSource.network('https://example.com/video.mp4', headers: {'key': 'value'});
        const source3 = VideoSource.network('https://example.com/video.mp4', headers: {'key': 'other'});

        expect(source1, equals(source2));
        expect(source1, isNot(equals(source3)));
      });

      test('hashCode is consistent with equality', () {
        const source1 = VideoSource.network('https://example.com/video.mp4');
        const source2 = VideoSource.network('https://example.com/video.mp4');

        expect(source1.hashCode, equals(source2.hashCode));
      });

      test('toString returns readable representation', () {
        const source = VideoSource.network('https://example.com/video.mp4');

        expect(source.toString(), contains('NetworkVideoSource'));
        expect(source.toString(), contains('https://example.com/video.mp4'));
      });
    });

    group('FileVideoSource', () {
      test('creates with path', () {
        const source = VideoSource.file('/path/to/video.mp4');

        expect(source, isA<FileVideoSource>());
        expect((source as FileVideoSource).path, equals('/path/to/video.mp4'));
      });

      test('equality works correctly', () {
        const source1 = VideoSource.file('/path/to/video.mp4');
        const source2 = VideoSource.file('/path/to/video.mp4');
        const source3 = VideoSource.file('/path/to/other.mp4');

        expect(source1, equals(source2));
        expect(source1, isNot(equals(source3)));
      });

      test('hashCode is consistent with equality', () {
        const source1 = VideoSource.file('/path/to/video.mp4');
        const source2 = VideoSource.file('/path/to/video.mp4');

        expect(source1.hashCode, equals(source2.hashCode));
      });

      test('toString returns readable representation', () {
        const source = VideoSource.file('/path/to/video.mp4');

        expect(source.toString(), contains('FileVideoSource'));
        expect(source.toString(), contains('/path/to/video.mp4'));
      });
    });

    group('AssetVideoSource', () {
      test('creates with asset path', () {
        const source = VideoSource.asset('assets/video.mp4');

        expect(source, isA<AssetVideoSource>());
        expect((source as AssetVideoSource).assetPath, equals('assets/video.mp4'));
      });

      test('equality works correctly', () {
        const source1 = VideoSource.asset('assets/video.mp4');
        const source2 = VideoSource.asset('assets/video.mp4');
        const source3 = VideoSource.asset('assets/other.mp4');

        expect(source1, equals(source2));
        expect(source1, isNot(equals(source3)));
      });

      test('hashCode is consistent with equality', () {
        const source1 = VideoSource.asset('assets/video.mp4');
        const source2 = VideoSource.asset('assets/video.mp4');

        expect(source1.hashCode, equals(source2.hashCode));
      });

      test('toString returns readable representation', () {
        const source = VideoSource.asset('assets/video.mp4');

        expect(source.toString(), contains('AssetVideoSource'));
        expect(source.toString(), contains('assets/video.mp4'));
      });
    });

    test('different source types are not equal', () {
      const networkSource = VideoSource.network('https://example.com/video.mp4');
      const fileSource = VideoSource.file('/path/to/video.mp4');
      const assetSource = VideoSource.asset('assets/video.mp4');

      expect(networkSource, isNot(equals(fileSource)));
      expect(networkSource, isNot(equals(assetSource)));
      expect(fileSource, isNot(equals(assetSource)));
    });

    group('NetworkVideoSource headers equality edge cases', () {
      test('null headers equals null headers', () {
        const source1 = VideoSource.network('https://example.com/video.mp4');
        const source2 = VideoSource.network('https://example.com/video.mp4');

        expect(source1, equals(source2));
      });

      test('empty headers equals empty headers', () {
        const source1 = VideoSource.network('https://example.com/video.mp4', headers: {});
        const source2 = VideoSource.network('https://example.com/video.mp4', headers: {});

        expect(source1, equals(source2));
      });

      test('null headers not equal to empty headers', () {
        const source1 = VideoSource.network('https://example.com/video.mp4');
        const source2 = VideoSource.network('https://example.com/video.mp4', headers: {});

        // null and empty map should not be equal based on _mapsEqual logic
        expect(source1, isNot(equals(source2)));
      });

      test('headers with different keys are not equal', () {
        const source1 = VideoSource.network('https://example.com/video.mp4', headers: {'key1': 'value'});
        const source2 = VideoSource.network('https://example.com/video.mp4', headers: {'key2': 'value'});

        expect(source1, isNot(equals(source2)));
      });

      test('headers with different number of entries are not equal', () {
        const source1 = VideoSource.network('https://example.com/video.mp4', headers: {'key1': 'value'});
        const source2 = VideoSource.network(
          'https://example.com/video.mp4',
          headers: {'key1': 'value', 'key2': 'value2'},
        );

        expect(source1, isNot(equals(source2)));
      });

      test('headers with multiple matching entries are equal', () {
        const source1 = VideoSource.network(
          'https://example.com/video.mp4',
          headers: {'Authorization': 'Bearer token', 'Content-Type': 'video/mp4'},
        );
        const source2 = VideoSource.network(
          'https://example.com/video.mp4',
          headers: {'Authorization': 'Bearer token', 'Content-Type': 'video/mp4'},
        );

        expect(source1, equals(source2));
        expect(source1.hashCode, equals(source2.hashCode));
      });

      test('identical sources are equal', () {
        const source = VideoSource.network('https://example.com/video.mp4', headers: {'key': 'value'});

        expect(source, equals(source));
      });

      test('toString includes headers when present', () {
        const source = VideoSource.network('https://example.com/video.mp4', headers: {'Authorization': 'Bearer token'});

        final str = source.toString();
        expect(str, contains('NetworkVideoSource'));
        expect(str, contains('Authorization'));
        expect(str, contains('Bearer token'));
      });
    });

    group('identical() optimization', () {
      test('FileVideoSource identical check', () {
        const source = VideoSource.file('/path/to/video.mp4');
        expect(source == source, isTrue);
      });

      test('AssetVideoSource identical check', () {
        const source = VideoSource.asset('assets/video.mp4');
        expect(source == source, isTrue);
      });
    });

    group('VideoSource.from() auto-detection', () {
      group('detects network URLs', () {
        test('https:// URL', () {
          final source = VideoSource.from('https://example.com/video.mp4');

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, 'https://example.com/video.mp4');
        });

        test('http:// URL', () {
          final source = VideoSource.from('http://example.com/video.mp4');

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, 'http://example.com/video.mp4');
        });

        test('HLS stream URL', () {
          final source = VideoSource.from('https://example.com/stream.m3u8');

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, 'https://example.com/stream.m3u8');
        });

        test('DASH stream URL', () {
          final source = VideoSource.from('https://example.com/manifest.mpd');

          expect(source, isA<NetworkVideoSource>());
        });

        test('rtsp:// streaming URL', () {
          final source = VideoSource.from('rtsp://camera.local/stream');

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, 'rtsp://camera.local/stream');
        });

        test('rtmp:// streaming URL', () {
          final source = VideoSource.from('rtmp://server.com/live/stream');

          expect(source, isA<NetworkVideoSource>());
        });

        test('bare domain adds https://', () {
          final source = VideoSource.from('example.com/video.mp4');

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, 'https://example.com/video.mp4');
        });

        test('bare domain with port adds https://', () {
          final source = VideoSource.from('example.com:8080/video.mp4');

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, 'https://example.com:8080/video.mp4');
        });

        test('URL with query parameters', () {
          final source = VideoSource.from('https://example.com/video.mp4?token=abc&quality=hd');

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, contains('token=abc'));
        });

        test('accepts optional headers for network sources', () {
          final source = VideoSource.from('https://example.com/video.mp4', headers: {'Authorization': 'Bearer token'});

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).headers, {'Authorization': 'Bearer token'});
        });
      });

      group('detects file paths', () {
        test('absolute Unix path', () {
          final source = VideoSource.from('/var/mobile/video.mp4');

          expect(source, isA<FileVideoSource>());
          expect((source as FileVideoSource).path, '/var/mobile/video.mp4');
        });

        test('file:// URI', () {
          final source = VideoSource.from('file:///var/mobile/video.mp4');

          expect(source, isA<FileVideoSource>());
          expect((source as FileVideoSource).path, '/var/mobile/video.mp4');
        });

        test('file:// URI with spaces encoded', () {
          final source = VideoSource.from('file:///path/to/my%20video.mp4');

          expect(source, isA<FileVideoSource>());
          expect((source as FileVideoSource).path, '/path/to/my video.mp4');
        });

        test('Windows absolute path with drive letter', () {
          final source = VideoSource.from(r'C:\Users\Videos\video.mp4');

          expect(source, isA<FileVideoSource>());
          expect((source as FileVideoSource).path, r'C:\Users\Videos\video.mp4');
        });

        test('Windows path with forward slashes', () {
          final source = VideoSource.from('D:/Videos/video.mp4');

          expect(source, isA<FileVideoSource>());
          expect((source as FileVideoSource).path, 'D:/Videos/video.mp4');
        });
      });

      group('detects asset paths', () {
        test('assets/ prefix', () {
          final source = VideoSource.from('assets/videos/intro.mp4');

          expect(source, isA<AssetVideoSource>());
          expect((source as AssetVideoSource).assetPath, 'assets/videos/intro.mp4');
        });

        test('packages/ prefix for package assets', () {
          final source = VideoSource.from('packages/my_package/assets/video.mp4');

          expect(source, isA<AssetVideoSource>());
          expect((source as AssetVideoSource).assetPath, 'packages/my_package/assets/video.mp4');
        });
      });

      group('edge cases', () {
        test('empty string throws ArgumentError', () {
          expect(() => VideoSource.from(''), throwsArgumentError);
        });

        test('whitespace only throws ArgumentError', () {
          expect(() => VideoSource.from('   '), throwsArgumentError);
        });

        test('trims whitespace from input', () {
          final source = VideoSource.from('  https://example.com/video.mp4  ');

          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, 'https://example.com/video.mp4');
        });

        test('headers are ignored for file sources', () {
          final source = VideoSource.from('/path/to/video.mp4', headers: {'Authorization': 'Bearer token'});

          expect(source, isA<FileVideoSource>());
        });

        test('headers are ignored for asset sources', () {
          final source = VideoSource.from('assets/video.mp4', headers: {'Authorization': 'Bearer token'});

          expect(source, isA<AssetVideoSource>());
        });

        test('localhost URL is detected as network', () {
          final source = VideoSource.from('http://localhost:3000/video.mp4');

          expect(source, isA<NetworkVideoSource>());
        });

        test('IP address URL is detected as network', () {
          final source = VideoSource.from('http://192.168.1.1/video.mp4');

          expect(source, isA<NetworkVideoSource>());
        });

        test('content:// URI for Android content provider', () {
          final source = VideoSource.from('content://media/external/video/123');

          expect(source, isA<FileVideoSource>());
          expect((source as FileVideoSource).path, 'content://media/external/video/123');
        });
      });
    });
  });
}
