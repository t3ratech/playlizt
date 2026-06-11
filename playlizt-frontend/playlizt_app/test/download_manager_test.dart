import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/services/download_manager_models.dart';
import 'package:playlizt_app/services/extractor/core/youtube_dl_json_mapper.dart';
import 'package:playlizt_app/services/extractor/extraction_engine.dart';
import 'package:playlizt_app/services/extractor/extractors/youtube_dl_bridge_ie_io.dart';

const _vendoredYoutubeDlSource = String.fromEnvironment(
  'PLAYLIZT_TEST_YOUTUBE_DL_SOURCE',
  defaultValue: 'vendor/youtube-dl',
);

void main() {
  group('youtube-dl bridge', () {
    test('maps youtube-dl JSON to native downloadable formats', () {
      final mapper = YoutubeDlJsonMapper();

      final info = mapper.mapMediaInfo({
        'id': 'video-id',
        'title': 'Bridge Test Video',
        'url': 'https://cdn.example.test/selected.mp4',
        'ext': 'mp4',
        'format_id': 'selected',
        'http_headers': {'Referer': 'https://example.test/watch'},
        'formats': [
          {
            'url': 'https://cdn.example.test/video-only.mp4',
            'ext': 'mp4',
            'format_id': 'video-only',
            'vcodec': 'avc1',
            'acodec': 'none',
          },
          {
            'url': 'https://cdn.example.test/manifest.mpd',
            'ext': 'mpd',
            'format_id': 'dash',
            'protocol': 'http_dash_segments',
          },
          {
            'url': 'https://cdn.example.test/stream.m3u8',
            'ext': 'm3u8',
            'format_id': 'hls',
            'protocol': 'm3u8_native',
            'height': 720,
          },
          {
            'url': 'https://cdn.example.test/full.mp4',
            'ext': 'mp4',
            'format_id': 'full',
            'vcodec': 'avc1',
            'acodec': 'mp4a',
            'height': 480,
          },
        ],
      }, sourceUrl: 'https://example.test/watch/video-id');

      expect(info.extractorKey, YoutubeDlJsonMapper.extractorKey);
      expect(info.sourceUrl, 'https://example.test/watch/video-id');
      expect(info.title, 'Bridge Test Video');

      final urls = info.formats.map((format) => format.url).toSet();
      expect(urls, contains('https://cdn.example.test/selected.mp4'));
      expect(urls, contains('https://cdn.example.test/stream.m3u8'));
      expect(urls, contains('https://cdn.example.test/full.mp4'));
      expect(urls, isNot(contains('https://cdn.example.test/video-only.mp4')));
      expect(urls, isNot(contains('https://cdn.example.test/manifest.mpd')));
    });

    test(
      'verifies the vendored youtube-dl extractor inventory',
      () async {
        const process = YoutubeDlProcess();
        final inventory = await process.loadInventory();

        expect(inventory.version, isNotEmpty);
        expect(inventory.extractorCount, greaterThanOrEqualTo(1200));
        expect(inventory.extractorNames, contains('youtube'));
        expect(inventory.extractorNames, contains('vimeo'));
        expect(inventory.extractorNames, contains('generic'));
      },
      skip: Directory(_vendoredYoutubeDlSource).existsSync()
          ? false
          : 'Vendored youtube-dl source checkout not found',
    );

    test(
      'registers youtube-dl before the generic fallback when configured',
      () {
        final engine = ExtractionEngine(
          youtubeDlSourcePath: _vendoredYoutubeDlSource,
        );

        expect(
          engine.extractorNames,
          containsAll(['PornHub', 'YouPorn', 'generic']),
        );
        expect(engine.extractorNames.last, 'generic');

        if (Directory(_vendoredYoutubeDlSource).existsSync()) {
          final youtubeDlIndex = engine.extractorNames.indexOf('youtube-dl');
          final genericIndex = engine.extractorNames.indexOf('generic');
          expect(youtubeDlIndex, greaterThanOrEqualTo(0));
          expect(youtubeDlIndex, lessThan(genericIndex));
        }
      },
    );
  });

  group('DownloadTask persistence', () {
    test('keeps youtube-dl backend metadata across JSON round trips', () {
      const task = DownloadTask(
        id: 'task-1',
        url: 'https://example.test/watch/video-id',
        originalUrl: 'https://example.test/watch/video-id',
        filePath: '/tmp/video.mp4',
        fileName: 'video.mp4',
        backend: DownloadBackend.youtubeDl,
        status: DownloadStatus.queued,
        receivedBytes: 0,
        totalBytes: 0,
      );

      final restored = DownloadTask.fromJson(task.toJson());

      expect(restored.backend, DownloadBackend.youtubeDl);
      expect(restored.originalUrl, task.originalUrl);
      expect(restored.status, DownloadStatus.queued);
    });

    test('marks in-flight persisted tasks as failed on restore', () {
      final restored = DownloadTask.fromJson(
        const DownloadTask(
          id: 'task-2',
          url: 'https://example.test/video.mp4',
          filePath: '/tmp/video.mp4',
          fileName: 'video.mp4',
          status: DownloadStatus.downloading,
          receivedBytes: 10,
          totalBytes: 100,
        ).toJson(),
      );

      expect(restored.status, DownloadStatus.failed);
    });
  });
}
