import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/providers/playlist_provider.dart';
import 'package:playlizt_app/providers/settings_provider.dart';
import 'package:playlizt_app/services/download_manager_platform.dart'
    as download_platform;
import 'package:playlizt_app/services/download_manager_models.dart';
import 'package:playlizt_app/services/extractor/core/youtube_dl_json_mapper.dart';
import 'package:playlizt_app/services/extractor/extraction_engine.dart';
import 'package:playlizt_app/services/extractor/extractors/youtube_dl_bridge_ie_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _vendoredYoutubeDlSource = String.fromEnvironment(
  'PLAYLIZT_TEST_YOUTUBE_DL_SOURCE',
  defaultValue: 'vendor/youtube-dl',
);

Future<void> _waitForDownloadManager(
  download_platform.DownloadManager manager,
) async {
  for (var i = 0; i < 20 && !manager.isInitialised; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(manager.isInitialised, isTrue);
}

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
        'thumbnail': 'https://cdn.example.test/thumb.jpg',
        'http_headers': {'Referer': 'https://example.test/watch'},
        'subtitles': {
          'en': [
            {'url': 'https://cdn.example.test/subs.vtt', 'ext': 'vtt'}
          ]
        },
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
            'filesize': 2048,
            'format_note': 'SD',
          },
        ],
        'entries': [
          {
            'id': 'playlist-entry',
            'title': 'Playlist Entry',
            'webpage_url': 'https://example.test/watch/playlist-entry',
            'url': 'https://cdn.example.test/playlist-entry.mp4',
            'ext': 'mp4',
          }
        ],
      }, sourceUrl: 'https://example.test/watch/video-id');

      expect(info.extractorKey, YoutubeDlJsonMapper.extractorKey);
      expect(info.sourceUrl, 'https://example.test/watch/video-id');
      expect(info.title, 'Bridge Test Video');

      final urls = info.formats.map((format) => format.url).toSet();
      expect(urls, contains('https://cdn.example.test/selected.mp4'));
      expect(urls, contains('https://cdn.example.test/stream.m3u8'));
      expect(urls, contains('https://cdn.example.test/full.mp4'));
      expect(urls, isNot(contains('https://cdn.example.test/manifest.mpd')));
      expect(info.thumbnails.single.url, 'https://cdn.example.test/thumb.jpg');
      expect(info.subtitles.single.language, 'en');
      expect(info.playlistEntries.single.title, 'Playlist Entry');
      expect(
        info.formats
            .firstWhere((format) => format.formatId == 'full')
            .friendlyLabel,
        contains('SD'),
      );
    });

    test('parses youtube-dl progress into user-friendly fields', () {
      final progress = YoutubeDlProgress.parse(
        '[download]  25.0% of 10.00MiB at 1.00MiB/s ETA 00:05',
      );

      expect(progress, isNotNull);
      expect(progress!.percent, 25);
      expect(progress.totalBytes, 10 * 1024 * 1024);
      expect(progress.downloadedBytes, 2621440);
      expect(progress.speedBytesPerSecond, 1024 * 1024);
      expect(progress.etaSeconds, 5);
      expect(progress.stage, 'Downloading');
    });

    test('normalizes extractor metadata into a download preview', () {
      final mapper = YoutubeDlJsonMapper();
      final info = mapper.mapMediaInfo({
        'id': 'playlist-id',
        'title': 'Preview Playlist',
        'description': 'A previewable playlist',
        'thumbnail': 'https://cdn.example.test/thumb.jpg',
        'uploader': 'Playlizt Channel',
        'upload_date': '20260611',
        'duration': 120,
        'warnings': ['geo-bypass may be required'],
        'subtitles': {
          'en': [
            {'url': 'https://cdn.example.test/en.vtt', 'ext': 'vtt'}
          ]
        },
        'automatic_captions': {
          'fr': [
            {'url': 'https://cdn.example.test/fr.vtt', 'ext': 'vtt'}
          ]
        },
        'thumbnails': [
          {
            'url': 'https://cdn.example.test/thumb-large.jpg',
            'width': 1280,
            'height': 720,
          }
        ],
        'formats': [
          {
            'url': 'https://cdn.example.test/720.mp4',
            'format_id': '720p',
            'ext': 'mp4',
            'height': 720,
            'width': 1280,
            'vcodec': 'avc1',
            'acodec': 'mp4a',
          }
        ],
        'entries': [
          {
            'id': 'entry-1',
            'title': 'Entry One',
            'webpage_url': 'https://example.test/watch/entry-1',
            'url': 'https://cdn.example.test/entry-1.mp4',
            'ext': 'mp4',
          }
        ],
      }, sourceUrl: 'https://example.test/playlist');

      final preview = DownloadPreview.fromMediaInfo(
        info,
        requestedUrl: 'https://example.test/playlist',
      );

      expect(preview.requestedUrl, 'https://example.test/playlist');
      expect(preview.title, 'Preview Playlist');
      expect(preview.extractorName, YoutubeDlJsonMapper.extractorKey);
      expect(preview.uploader, 'Playlizt Channel');
      expect(preview.durationSeconds, 120);
      expect(preview.formatCount, 1);
      expect(preview.formats.single.formatId, '720p');
      expect(preview.formats.single.label, contains('720p'));
      expect(preview.subtitleCount, 2);
      expect(preview.subtitles.last.automatic, isTrue);
      expect(preview.thumbnailCount, 2);
      expect(preview.warnings.single, 'geo-bypass may be required');
      expect(preview.isPlaylist, isTrue);
      expect(preview.playlistCount, 1);
      expect(preview.playlistEntries.single.title, 'Entry One');
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
        options: DownloadOptions(
          formatId: 'bestvideo+bestaudio/best',
          audioOnly: true,
          writeSubtitles: true,
          writeThumbnail: true,
          writeMetadata: true,
          proxy: 'socks5://127.0.0.1:1080',
          rateLimit: '2M',
          cookieFile: '/tmp/cookies.txt',
          username: 'demo-user',
          password: 'demo-pass',
          retries: '5',
          fragmentRetries: '3',
          socketTimeoutSeconds: '15',
          userAgent: 'PlayliztTest/1.0',
          referer: 'https://example.test/watch',
          playlistStart: '2',
          playlistEnd: '5',
          playlistItems: '2,4-6',
          matchTitle: 'episode',
          rejectTitle: 'trailer',
          ageLimit: '18',
          geoBypass: true,
          geoVerificationProxy: 'socks5://127.0.0.1:1081',
          forcePlaylist: true,
        ),
        status: DownloadStatus.queued,
        receivedBytes: 0,
        totalBytes: 0,
      );

      final restored = DownloadTask.fromJson(task.toJson());

      expect(restored.backend, DownloadBackend.youtubeDl);
      expect(restored.originalUrl, task.originalUrl);
      expect(restored.status, DownloadStatus.queued);
      expect(restored.options.formatId, 'bestvideo+bestaudio/best');
      expect(restored.options.audioOnly, isTrue);
      expect(restored.options.writeSubtitles, isTrue);
      expect(restored.options.writeThumbnail, isTrue);
      expect(restored.options.writeMetadata, isTrue);
      expect(restored.options.proxy, 'socks5://127.0.0.1:1080');
      expect(restored.options.rateLimit, '2M');
      expect(restored.options.cookieFile, '/tmp/cookies.txt');
      expect(restored.options.username, 'demo-user');
      expect(restored.options.password, isNull);
      expect(restored.options.retries, '5');
      expect(restored.options.fragmentRetries, '3');
      expect(restored.options.socketTimeoutSeconds, '15');
      expect(restored.options.userAgent, 'PlayliztTest/1.0');
      expect(restored.options.referer, 'https://example.test/watch');
      expect(restored.options.playlistStart, '2');
      expect(restored.options.playlistEnd, '5');
      expect(restored.options.playlistItems, '2,4-6');
      expect(restored.options.matchTitle, 'episode');
      expect(restored.options.rejectTitle, 'trailer');
      expect(restored.options.ageLimit, '18');
      expect(restored.options.geoBypass, isTrue);
      expect(restored.options.geoVerificationProxy, 'socks5://127.0.0.1:1081');
      expect(restored.options.forcePlaylist, isTrue);
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

    test('marks extraction and post-processing persisted tasks as failed', () {
      final extracting = DownloadTask.fromJson(
        const DownloadTask(
          id: 'task-3',
          url: 'https://example.test/video.mp4',
          filePath: '/tmp/video.mp4',
          fileName: 'video.mp4',
          status: DownloadStatus.extracting,
          receivedBytes: 0,
          totalBytes: 0,
        ).toJson(),
      );
      final postProcessing = DownloadTask.fromJson(
        const DownloadTask(
          id: 'task-4',
          url: 'https://example.test/video.mp4',
          filePath: '/tmp/video.mp4',
          fileName: 'video.mp4',
          status: DownloadStatus.postProcessing,
          receivedBytes: 100,
          totalBytes: 100,
        ).toJson(),
      );

      expect(extracting.status, DownloadStatus.failed);
      expect(postProcessing.status, DownloadStatus.failed);
    });

    test('keeps skipped archive tasks stable across JSON round trips', () {
      final restored = DownloadTask.fromJson(
        const DownloadTask(
          id: 'task-5',
          url: 'https://example.test/video.mp4',
          originalUrl: 'https://example.test/video.mp4',
          filePath: '/tmp/video.mp4',
          fileName: 'video.mp4',
          status: DownloadStatus.skipped,
          receivedBytes: 0,
          totalBytes: 0,
          currentStage: 'Already downloaded in archive',
        ).toJson(),
      );

      expect(restored.status, DownloadStatus.skipped);
      expect(restored.currentStage, 'Already downloaded in archive');
    });
  });

  group('DownloadBatchParser', () {
    test('parses newline and whitespace separated URL batches', () {
      final urls = DownloadBatchParser.parseUrls('''
https://example.test/one.mp4
https://example.test/two.mp4 https://example.test/three.mp4,
# https://example.test/commented.mp4
https://example.test/one.mp4
''');

      expect(
        urls,
        const [
          'https://example.test/one.mp4',
          'https://example.test/two.mp4',
          'https://example.test/three.mp4',
        ],
      );
    });

    test('keeps invalid tokens so the UI can reject the batch', () {
      final urls = DownloadBatchParser.parseUrls(
        'https://example.test/one.mp4 ftp://example.test/file.mov',
      );

      expect(urls, contains('ftp://example.test/file.mov'));
    });
  });

  group('youtube-dl download arguments', () {
    test('passes structured site and playlist options', () {
      const process = YoutubeDlProcess();

      final args = process.buildDownloadArguments(
        sourceUrl: 'https://example.test/playlist',
        outputPath: '/tmp/%(title)s.%(ext)s',
        formatId: 'bestvideo+bestaudio/best',
        playlistStart: '2',
        playlistEnd: '5',
        playlistItems: '2,4-6',
        matchTitle: 'episode',
        rejectTitle: 'trailer',
        ageLimit: '18',
        geoBypass: true,
        geoVerificationProxy: 'socks5://127.0.0.1:1081',
        forcePlaylist: true,
      );

      expect(args.first, '--yes-playlist');
      expect(args, containsAll(['--playlist-start', '2']));
      expect(args, containsAll(['--playlist-end', '5']));
      expect(args, containsAll(['--playlist-items', '2,4-6']));
      expect(args, containsAll(['--match-title', 'episode']));
      expect(args, containsAll(['--reject-title', 'trailer']));
      expect(args, containsAll(['--age-limit', '18']));
      expect(args, contains('--geo-bypass'));
      expect(
          args,
          containsAll([
            '--geo-verification-proxy',
            'socks5://127.0.0.1:1081',
          ]));
      expect(args.last, 'https://example.test/playlist');
    });
  });

  group('Download archive', () {
    test('round trips completed source metadata', () {
      final completedAt = DateTime.utc(2026, 6, 11, 12, 30);
      final entry = DownloadArchiveEntry(
        sourceUrl: 'https://example.test/watch/video-id',
        outputPath: '/tmp/video.mp4',
        fileName: 'video.mp4',
        title: 'Archived Video',
        extractorName: 'youtube-dl',
        playlistTitle: 'Archive Playlist',
        playlistIndex: 2,
        completedAt: completedAt,
      );

      final restored = DownloadArchiveEntry.fromJson(entry.toJson());

      expect(restored.sourceUrl, entry.sourceUrl);
      expect(restored.outputPath, entry.outputPath);
      expect(restored.fileName, entry.fileName);
      expect(restored.title, entry.title);
      expect(restored.extractorName, entry.extractorName);
      expect(restored.playlistTitle, entry.playlistTitle);
      expect(restored.playlistIndex, entry.playlistIndex);
      expect(restored.completedAt, completedAt);
    });

    test('skips archived direct media without starting a network download',
        () async {
      const sourceUrl = 'https://cdn.example.test/video.mp4';
      final archiveEntry = DownloadArchiveEntry(
        sourceUrl: sourceUrl,
        outputPath: '/tmp/video.mp4',
        fileName: 'video.mp4',
        title: 'Archived Direct Video',
        completedAt: DateTime.utc(2026, 6, 11),
      );
      SharedPreferences.setMockInitialValues({
        'downloads.archive': jsonEncode([archiveEntry.toJson()]),
      });

      final settings = SettingsProvider();
      await settings.ensureLoaded();
      await settings.setMaxConcurrentDownloads(0);
      final manager = download_platform.DownloadManager(
        settingsProvider: settings,
        playlistProvider: PlaylistProvider(),
      );
      await _waitForDownloadManager(manager);

      await manager.enqueueDownload(url: sourceUrl);

      expect(manager.isArchived(sourceUrl), isTrue);
      expect(manager.tasks, hasLength(1));
      expect(manager.tasks.single.status, DownloadStatus.skipped);
      expect(manager.tasks.single.filePath, '/tmp/video.mp4');
      expect(
          manager.tasks.single.currentStage, 'Already downloaded in archive');
    });
  });

  group('Download sidecars', () {
    test('classifies subtitle thumbnail and metadata files', () {
      expect(
        DownloadSidecarFile.typeForPath('/tmp/video.en.vtt'),
        DownloadSidecarType.subtitle,
      );
      expect(
        DownloadSidecarFile.typeForPath('/tmp/video.jpg'),
        DownloadSidecarType.thumbnail,
      );
      expect(
        DownloadSidecarFile.typeForPath('/tmp/video.info.json'),
        DownloadSidecarType.metadata,
      );
      expect(
        DownloadSidecarFile.languageForPath(
          sidecarPath: '/tmp/video.en.vtt',
          mediaPath: '/tmp/video.mp4',
        ),
        'en',
      );
    });

    test('persists sidecar files on download tasks', () {
      const task = DownloadTask(
        id: 'task-sidecar',
        url: 'https://example.test/video',
        filePath: '/tmp/video.mp4',
        fileName: 'video.mp4',
        backend: DownloadBackend.youtubeDl,
        status: DownloadStatus.completed,
        receivedBytes: 100,
        totalBytes: 100,
        sidecarFiles: [
          DownloadSidecarFile(
            type: DownloadSidecarType.subtitle,
            path: '/tmp/video.en.vtt',
            language: 'en',
            format: 'vtt',
            sizeBytes: 128,
          ),
          DownloadSidecarFile(
            type: DownloadSidecarType.metadata,
            path: '/tmp/video.info.json',
            format: 'json',
            sizeBytes: 256,
          ),
        ],
      );

      final restored = DownloadTask.fromJson(task.toJson());

      expect(restored.sidecarFiles, hasLength(2));
      expect(restored.sidecarFiles.first.type, DownloadSidecarType.subtitle);
      expect(restored.sidecarFiles.first.language, 'en');
      expect(restored.sidecarFiles.last.type, DownloadSidecarType.metadata);
      expect(restored.sidecarFiles.last.sizeBytes, 256);
    });
  });
}
