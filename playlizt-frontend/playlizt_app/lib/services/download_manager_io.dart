/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 03:28
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import '../providers/playlist_provider.dart';
import '../models/content.dart';
import 'download_manager_models.dart';
import 'extractor/extraction_engine.dart';
import 'extractor/core/youtube_dl_json_mapper.dart';
import 'extractor/core/types.dart';
import 'extractor/extractors/youtube_dl_bridge_ie_io.dart';
import 'library_manager_platform.dart';

/// Manages the lifecycle of media downloads including queuing, progress
/// tracking, pause/cancel behaviour and basic persistence across restarts.
class DownloadManager with ChangeNotifier {
  static const _prefsKeyTasks = 'downloads.tasks';
  static const _prefsKeyArchive = 'downloads.archive';

  final SettingsProvider settingsProvider;
  final PlaylistProvider playlistProvider;
  final LibraryManager? libraryManager;
  final Dio _dio = Dio();
  final ExtractionEngine _extractionEngine = ExtractionEngine();
  final YoutubeDlProcess _youtubeDlProcess = const YoutubeDlProcess();

  final Map<String, DownloadTask> _tasks = {};
  final Map<String, DownloadArchiveEntry> _archive = {};
  final Map<String, CancelToken> _tokens = {};
  final Map<String, DownloadStatus> _pendingCancelStatus = {};

  bool _initialised = false;

  DownloadManager({
    required this.settingsProvider,
    required this.playlistProvider,
    this.libraryManager,
  }) {
    _loadPersistedTasks();
  }

  bool _looksLikeDirectMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.m4v') ||
        path.endsWith('.m3u8') ||
        path.endsWith('.mpd') ||
        path.endsWith('.webm') ||
        path.endsWith('.mov') ||
        path.endsWith('.mkv') ||
        path.endsWith('.avi') ||
        path.endsWith('.flv') ||
        path.endsWith('.mp3') ||
        path.endsWith('.m4a') ||
        path.endsWith('.aac') ||
        path.endsWith('.ogg') ||
        path.endsWith('.oga') ||
        path.endsWith('.ogv') ||
        path.endsWith('.wav') ||
        path.endsWith('.flac') ||
        path.endsWith('.ts');
  }

  String _safeFileNameFromUri(Uri uri) {
    if (uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last;
      if (last.isNotEmpty) return last;
    }
    return 'download.bin';
  }

  String _safeTitle(String value) {
    final safe = value.replaceAll(RegExp(r'[^\w\s\.-]'), '_').trim();
    return safe.isEmpty ? 'download' : safe;
  }

  String _archiveKey(String sourceUrl) {
    return sourceUrl.trim();
  }

  Future<void> clearDownloadArchive() async {
    _archive.clear();
    await _persistArchive();
    notifyListeners();
  }

  DownloadArchiveEntry? _archiveEntryFor(String sourceUrl) {
    return _archive[_archiveKey(sourceUrl)];
  }

  Future<void> _enqueueArchivedSkip({
    required String requestedUrl,
    required DownloadArchiveEntry entry,
    String? explicitFileName,
    String? playlistTitle,
    int? playlistIndex,
    int? playlistCount,
    String? extractorName,
    DownloadOptions options = const DownloadOptions(),
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _tasks[id] = DownloadTask(
      id: id,
      url: requestedUrl,
      originalUrl: entry.sourceUrl,
      filePath: entry.outputPath,
      fileName: explicitFileName?.trim().isNotEmpty == true
          ? explicitFileName!.trim()
          : entry.fileName,
      title: entry.title,
      options: options,
      status: DownloadStatus.skipped,
      receivedBytes: 0,
      totalBytes: 0,
      currentStage: 'Already downloaded in archive',
      extractorName: extractorName ?? entry.extractorName,
      playlistTitle: playlistTitle ?? entry.playlistTitle,
      playlistIndex: playlistIndex ?? entry.playlistIndex,
      playlistCount: playlistCount,
    );
    await _persistTasks();
    notifyListeners();
  }

  bool get isInitialised => _initialised;

  List<DownloadTask> get tasks {
    final list = _tasks.values.toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  List<DownloadArchiveEntry> get archiveEntries {
    final list = _archive.values.toList();
    list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return list;
  }

  bool isArchived(String sourceUrl) {
    return _archive.containsKey(_archiveKey(sourceUrl));
  }

  Future<void> enqueueDownload({
    required String url,
    String? targetDirectory,
    String? explicitFileName,
    DownloadOptions options = const DownloadOptions(),
  }) async {
    print('DownloadManager: Enqueuing download for $url');
    if (settingsProvider.downloadArchiveEnabled) {
      final archived = _archiveEntryFor(url);
      if (archived != null) {
        await _enqueueArchivedSkip(
          requestedUrl: url,
          entry: archived,
          explicitFileName: explicitFileName,
          options: options,
        );
        return;
      }
    }

    // 1. Resolve URL using Extraction Engine
    String actualUrl = url;
    String finalFileName = explicitFileName?.trim() ?? '';
    String? title;
    String? thumbnailUrl;
    Map<String, String>? headers;
    DownloadBackend backend = DownloadBackend.native;
    String? formatLabel;
    String? extractorName;
    String? originalUrl;
    bool extractionSucceeded = false;

    try {
      final mediaInfo = await _extractionEngine.extract(url);
      extractionSucceeded = true;
      title = mediaInfo.title;
      thumbnailUrl = mediaInfo.thumbnailUrl;
      extractorName = mediaInfo.extractorKey;
      print(
        'DownloadManager: Extraction success. Title: ${mediaInfo.title}, Formats: ${mediaInfo.formats.length}',
      );
      if (mediaInfo.playlistEntries.isNotEmpty && explicitFileName == null) {
        final playlistCount = mediaInfo.playlistEntries.length;
        for (var i = 0; i < mediaInfo.playlistEntries.length; i++) {
          await _enqueueExtractedMediaInfo(
            requestedUrl: url,
            mediaInfo: mediaInfo.playlistEntries[i],
            targetDirectory: targetDirectory,
            options: options,
            playlistTitle: mediaInfo.title,
            playlistIndex: i + 1,
            playlistCount: playlistCount,
          );
        }
        await _persistTasks();
        _startNextIfPossible();
        notifyListeners();
        return;
      }
      if (mediaInfo.extractorKey == YoutubeDlJsonMapper.extractorKey) {
        backend = DownloadBackend.youtubeDl;
        originalUrl = mediaInfo.sourceUrl ?? url;
        actualUrl = originalUrl;
      }
      if (mediaInfo.formats.isNotEmpty) {
        // Select best format based on quality/resolution
        final bestFormat = _selectBestFormat(mediaInfo.formats);
        formatLabel = bestFormat.friendlyLabel;
        if (backend == DownloadBackend.native) {
          actualUrl = bestFormat.url;
          headers = bestFormat.httpHeaders;
        }

        if (finalFileName.isEmpty) {
          String ext;
          final rawExt = (bestFormat.ext ?? '').toLowerCase();
          if (rawExt.isNotEmpty) {
            ext = rawExt;
          } else {
            final resolvedUri = Uri.tryParse(bestFormat.url);
            final path = (resolvedUri?.path ?? '').toLowerCase();
            final dot = path.lastIndexOf('.');
            ext = dot != -1 ? path.substring(dot + 1) : '';
          }
          if (ext.isEmpty || ext == 'm3u8') {
            ext = 'mp4';
          }
          final safeTitle = mediaInfo.title.replaceAll(
            RegExp(r'[^\w\s\.-]'),
            '_',
          );
          finalFileName = '$safeTitle.$ext';
        }
      } else if (finalFileName.isEmpty && mediaInfo.title.isNotEmpty) {
        // Fallback if no formats but we have a title (maybe direct extraction?)
        finalFileName = mediaInfo.title;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Extraction failed for $url: $e');
      }
    }

    if (!extractionSucceeded && !_looksLikeDirectMediaUrl(actualUrl)) {
      throw Exception('Extraction failed for non-direct URL: $url');
    }

    if (settingsProvider.downloadArchiveEnabled) {
      final archiveSourceUrl = originalUrl ?? actualUrl;
      final archived = _archiveEntryFor(archiveSourceUrl);
      if (archived != null) {
        await _enqueueArchivedSkip(
          requestedUrl: archiveSourceUrl,
          entry: archived,
          explicitFileName: explicitFileName,
          options: options,
          extractorName: extractorName,
        );
        return;
      }
    }

    final uri = Uri.tryParse(actualUrl);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw ArgumentError('Only http/https URLs are supported');
    }

    final directory = targetDirectory?.trim().isNotEmpty == true
        ? targetDirectory!.trim()
        : settingsProvider.downloadDirectory;

    final suggestedName =
        finalFileName.isNotEmpty ? finalFileName : _safeFileNameFromUri(uri);

    final resolvedDirectory = _resolveHome(directory);

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final pathSeparator = resolvedDirectory.endsWith(Platform.pathSeparator)
        ? ''
        : Platform.pathSeparator;
    final fullPath = '$resolvedDirectory$pathSeparator$suggestedName';

    print('DownloadManager: Creating task $id for $suggestedName');

    final task = DownloadTask(
      id: id,
      url: actualUrl, // Use the resolved URL
      originalUrl: originalUrl,
      filePath: fullPath,
      fileName: suggestedName,
      headers: headers,
      backend: backend,
      options: options,
      title: title,
      thumbnailUrl: thumbnailUrl,
      formatLabel: formatLabel,
      extractorName: extractorName,
      currentStage: 'Queued',
      status: DownloadStatus.queued,
      receivedBytes: 0,
      totalBytes: 0,
    );

    _tasks[id] = task;
    await _persistTasks();
    _startNextIfPossible();
    notifyListeners();
    print('DownloadManager: Task added. Total tasks: ${_tasks.length}');
  }

  Future<void> _enqueueExtractedMediaInfo({
    required String requestedUrl,
    required MediaInfo mediaInfo,
    String? targetDirectory,
    DownloadOptions options = const DownloadOptions(),
    String? playlistTitle,
    int? playlistIndex,
    int? playlistCount,
  }) async {
    final backend = mediaInfo.extractorKey == YoutubeDlJsonMapper.extractorKey
        ? DownloadBackend.youtubeDl
        : DownloadBackend.native;
    final originalUrl = backend == DownloadBackend.youtubeDl
        ? (mediaInfo.sourceUrl ?? mediaInfo.url ?? requestedUrl)
        : null;

    String actualUrl = mediaInfo.url ?? mediaInfo.sourceUrl ?? requestedUrl;
    Map<String, String>? headers;
    String? formatLabel;
    String finalFileName = '';

    if (mediaInfo.formats.isNotEmpty) {
      final bestFormat = _selectBestFormat(mediaInfo.formats);
      formatLabel = bestFormat.friendlyLabel;
      if (backend == DownloadBackend.native) {
        actualUrl = bestFormat.url;
        headers = bestFormat.httpHeaders;
      }
      final rawExt = (bestFormat.ext ?? '').toLowerCase();
      var ext = rawExt.isNotEmpty ? rawExt : '';
      if (ext.isEmpty || ext == 'm3u8') ext = 'mp4';
      finalFileName = '${_safeTitle(mediaInfo.title)}.$ext';
    } else {
      finalFileName = '${_safeTitle(mediaInfo.title)}.mp4';
    }

    if (settingsProvider.downloadArchiveEnabled) {
      final archiveSourceUrl =
          backend == DownloadBackend.youtubeDl ? originalUrl! : actualUrl;
      final archived = _archiveEntryFor(archiveSourceUrl);
      if (archived != null) {
        await _enqueueArchivedSkip(
          requestedUrl: archiveSourceUrl,
          entry: archived,
          explicitFileName: finalFileName,
          playlistTitle: playlistTitle,
          playlistIndex: playlistIndex,
          playlistCount: playlistCount,
          extractorName: mediaInfo.extractorKey,
          options: options,
        );
        return;
      }
    }

    final directory = targetDirectory?.trim().isNotEmpty == true
        ? targetDirectory!.trim()
        : settingsProvider.downloadDirectory;
    final resolvedDirectory = _resolveHome(directory);
    final pathSeparator = resolvedDirectory.endsWith(Platform.pathSeparator)
        ? ''
        : Platform.pathSeparator;
    final fullPath = '$resolvedDirectory$pathSeparator$finalFileName';
    final id = '${DateTime.now().microsecondsSinceEpoch}-${playlistIndex ?? 0}';

    _tasks[id] = DownloadTask(
      id: id,
      url: backend == DownloadBackend.youtubeDl ? originalUrl! : actualUrl,
      originalUrl: originalUrl,
      filePath: fullPath,
      fileName: finalFileName,
      title: mediaInfo.title,
      thumbnailUrl: mediaInfo.thumbnailUrl,
      headers: headers,
      backend: backend,
      options: options,
      status: DownloadStatus.queued,
      receivedBytes: 0,
      totalBytes: 0,
      currentStage: 'Queued',
      formatLabel: formatLabel,
      extractorName: mediaInfo.extractorKey,
      playlistTitle: playlistTitle,
      playlistIndex: playlistIndex,
      playlistCount: playlistCount,
    );
  }

  Future<void> pauseDownload(String id) async {
    if (_tokens.containsKey(id)) {
      _pendingCancelStatus[id] = DownloadStatus.paused;
      _tokens[id]!.cancel('paused');
    }
  }

  Future<void> cancelDownload(String id) async {
    if (_tokens.containsKey(id)) {
      _pendingCancelStatus[id] = DownloadStatus.cancelled;
      _tokens[id]!.cancel('cancelled');
    } else {
      final existing = _tasks[id];
      if (existing != null) {
        _tasks[id] = existing.copyWith(status: DownloadStatus.cancelled);
        await _persistTasks();
        notifyListeners();
      }
    }
  }

  Future<void> resumeDownload(String id) async {
    final existing = _tasks[id];
    if (existing == null) return;
    final reset = existing.copyWith(
      status: DownloadStatus.queued,
      receivedBytes: 0,
      totalBytes: 0,
      clearErrorMessage: true,
    );
    _tasks[id] = reset;
    await _persistTasks();
    _startNextIfPossible();
    notifyListeners();
  }

  Future<void> _loadPersistedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyTasks);
      final decoded = raw == null || raw.isEmpty ? const [] : jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final task = DownloadTask.fromJson(item);
            _tasks[task.id] = task;
          } else if (item is Map) {
            final task = DownloadTask.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v)),
            );
            _tasks[task.id] = task;
          }
        }
      }

      final rawArchive = prefs.getString(_prefsKeyArchive);
      if (rawArchive != null && rawArchive.isNotEmpty) {
        final archiveDecoded = jsonDecode(rawArchive);
        if (archiveDecoded is List) {
          for (final item in archiveDecoded) {
            final Map<String, dynamic>? rawEntry;
            if (item is Map<String, dynamic>) {
              rawEntry = item;
            } else if (item is Map) {
              rawEntry = item.map((k, v) => MapEntry(k.toString(), v));
            } else {
              rawEntry = null;
            }
            if (rawEntry == null) continue;
            final entry = DownloadArchiveEntry.fromJson(rawEntry);
            _archive[_archiveKey(entry.sourceUrl)] = entry;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DownloadManager: failed to load tasks: $e');
      }
    } finally {
      _initialised = true;
      notifyListeners();
    }
  }

  Future<void> _persistTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _tasks.values.map((t) => t.toJson()).toList();
      await prefs.setString(_prefsKeyTasks, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('DownloadManager: failed to persist tasks: $e');
      }
    }
  }

  Future<void> _persistArchive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _archive.values.map((entry) => entry.toJson()).toList();
      await prefs.setString(_prefsKeyArchive, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('DownloadManager: failed to persist archive: $e');
      }
    }
  }

  Future<void> _recordArchive(DownloadTask task) async {
    if (!settingsProvider.downloadArchiveEnabled) return;
    final sourceUrl = task.originalUrl ?? task.url;
    if (sourceUrl.trim().isEmpty) return;

    final entry = DownloadArchiveEntry(
      sourceUrl: sourceUrl,
      outputPath: task.filePath,
      fileName: task.fileName,
      title: task.title,
      extractorName: task.extractorName,
      playlistTitle: task.playlistTitle,
      playlistIndex: task.playlistIndex,
      completedAt: DateTime.now(),
    );
    _archive[_archiveKey(sourceUrl)] = entry;
    await _persistArchive();
  }

  void _startNextIfPossible() {
    final maxActive = settingsProvider.maxConcurrentDownloads;
    if (_tokens.length >= maxActive) {
      return;
    }

    final next = _tasks.values
        .where((t) => t.status == DownloadStatus.queued)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final task in next) {
      if (_tokens.length >= maxActive) {
        break;
      }
      if (_tokens.containsKey(task.id)) continue;
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    final file = File(task.filePath);
    try {
      await file.parent.create(recursive: true);
    } catch (e) {
      _tasks[task.id] = task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: 'Failed to create directory: $e',
      );
      await _persistTasks();
      notifyListeners();
      return;
    }

    final updated = task.copyWith(
      status: DownloadStatus.downloading,
      receivedBytes: 0,
      totalBytes: 0,
      currentStage: 'Starting download',
      clearErrorMessage: true,
    );
    _tasks[task.id] = updated;
    final token = CancelToken();
    _tokens[task.id] = token;
    notifyListeners();

    try {
      print('DownloadManager: Starting download...');
      print('URL: ${task.url}');
      print('Headers: ${task.headers}');

      if (task.backend == DownloadBackend.youtubeDl) {
        await _downloadWithYoutubeDl(task.id, cancelToken: token);
      } else if (_isHlsUrl(task.url)) {
        await _downloadHlsToFile(task.id, cancelToken: token);
      } else if (_isUnsupportedManifestUrl(task.url)) {
        throw Exception('Unsupported native manifest URL: ${task.url}');
      } else {
        await _dio.download(
          task.url,
          file.path,
          cancelToken: token,
          options: Options(headers: task.headers, followRedirects: true),
          onReceiveProgress: (received, total) {
            final current = _tasks[task.id];
            if (current == null) return;
            _tasks[task.id] = current.copyWith(
              receivedBytes: received,
              totalBytes: total,
              currentStage: 'Downloading',
            );
            notifyListeners();
          },
        );
      }

      _tokens.remove(task.id);
      _tasks[task.id] = _tasks[task.id]!.copyWith(
        status: DownloadStatus.completed,
      );
      await _recordArchive(_tasks[task.id]!);
      await _persistTasks();

      // Add to Downloads playlist
      try {
        final completedTask = _tasks[task.id]!;
        final content = Content(
          id: DateTime.now().millisecondsSinceEpoch, // Local ID
          creatorId: 0, // Local
          title: completedTask.title ?? completedTask.fileName,
          category: 'Downloads',
          tags: ['downloaded'],
          thumbnailUrl: completedTask.thumbnailUrl,
          videoUrl: completedTask.filePath, // Use local path
          durationSeconds: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isPublished: false,
          viewCount: 0,
        );
        await playlistProvider.addToPlaylist('Downloads', content);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to add to playlist: $e');
        }
      }

      try {
        await libraryManager?.importPath(
          path: _tasks[task.id]!.filePath,
          source: LibraryItemSource.downloaded,
          displayTitle: _tasks[task.id]!.title ?? _tasks[task.id]!.fileName,
          thumbnailPath: _tasks[task.id]!.thumbnailUrl,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to import download into library: $e');
        }
      }

      _startNextIfPossible();
      notifyListeners();
    } on DioException catch (e) {
      _tokens.remove(task.id);
      final requestedStatus = _pendingCancelStatus.remove(task.id);

      if (e.type == DioExceptionType.cancel && requestedStatus != null) {
        _tasks[task.id] = _tasks[task.id]!.copyWith(
          status: requestedStatus,
          errorMessage: requestedStatus == DownloadStatus.paused
              ? 'Paused by user'
              : 'Cancelled by user',
        );
      } else {
        _tasks[task.id] = _tasks[task.id]!.copyWith(
          status: DownloadStatus.failed,
          errorMessage: e.message ?? 'Download failed',
        );
      }

      await _persistTasks();
      _startNextIfPossible();
      notifyListeners();
    } catch (e) {
      _tokens.remove(task.id);
      _tasks[task.id] = _tasks[task.id]!.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      await _persistTasks();
      _startNextIfPossible();
      notifyListeners();
    }
  }

  bool _isHlsUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).toLowerCase();
    return path.endsWith('.m3u8');
  }

  bool _isUnsupportedManifestUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).toLowerCase();
    return path.endsWith('.mpd') ||
        path.endsWith('.f4m') ||
        path.endsWith('.ism') ||
        path.endsWith('/manifest');
  }

  Future<void> _downloadWithYoutubeDl(
    String taskId, {
    required CancelToken cancelToken,
  }) async {
    final task = _tasks[taskId];
    if (task == null) return;

    if (!_youtubeDlProcess.isConfigured ||
        !_youtubeDlProcess.isSupportedPlatform) {
      throw Exception('youtube-dl backend is not configured for this platform');
    }

    await _youtubeDlProcess.download(
      sourceUrl: task.originalUrl ?? task.url,
      outputPath: task.filePath,
      cancelToken: cancelToken,
      formatId: task.options.formatId,
      audioOnly: task.options.audioOnly,
      writeSubtitles: task.options.writeSubtitles,
      writeThumbnail: task.options.writeThumbnail,
      writeMetadata: task.options.writeMetadata,
      proxy: task.options.proxy,
      rateLimit: task.options.rateLimit,
      cookieFile: task.options.cookieFile,
      username: task.options.username,
      password: task.options.password,
      onProgress: (progress) {
        final current = _tasks[taskId];
        if (current == null) return;
        const syntheticTotal = 10000;
        final percent = progress.percent?.clamp(0, 100).toDouble();
        final totalBytes = progress.totalBytes ??
            (percent != null ? syntheticTotal : current.totalBytes);
        final receivedBytes = progress.downloadedBytes ??
            (percent != null ? (percent * 100).round() : current.receivedBytes);
        final stage = progress.stage;
        final status = stage == 'Downloading' ||
                stage == 'Preparing output' ||
                stage == 'Download complete'
            ? DownloadStatus.downloading
            : DownloadStatus.postProcessing;
        _tasks[taskId] = current.copyWith(
          status: status,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          speedBytesPerSecond: progress.speedBytesPerSecond,
          etaSeconds: progress.etaSeconds,
          currentStage: stage,
        );
        notifyListeners();
      },
    );
  }

  Future<void> _downloadHlsToFile(
    String taskId, {
    required CancelToken cancelToken,
  }) async {
    final initialTask = _tasks[taskId];
    if (initialTask == null) return;

    final headers = initialTask.headers;
    final masterUri = Uri.parse(initialTask.url);

    final masterResponse = await _dio.get<String>(
      initialTask.url,
      cancelToken: cancelToken,
      options: Options(
        headers: headers,
        responseType: ResponseType.plain,
        followRedirects: true,
      ),
    );

    final masterBody = masterResponse.data?.toString() ?? '';
    final lines = masterBody.split('\n').map((l) => l.trim()).toList();

    final variants = <({int bandwidth, String uri})>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;

      final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
      final bandwidth = int.tryParse(bwMatch?.group(1) ?? '') ?? 0;
      if (i + 1 >= lines.length) continue;
      final next = lines[i + 1];
      if (next.isEmpty || next.startsWith('#')) continue;
      variants.add((bandwidth: bandwidth, uri: next));
    }

    Uri playlistUri = masterUri;
    String playlistBody = masterBody;
    if (variants.isNotEmpty) {
      final sortedVariants = List<({int bandwidth, String uri})>.from(variants)
        ..sort((a, b) => b.bandwidth.compareTo(a.bandwidth));

      Uri? fallbackUri;
      String? fallbackBody;
      bool selectedFmp4 = false;

      for (final variant in sortedVariants) {
        final candidateUri = masterUri.resolve(variant.uri);
        final playlistResponse = await _dio.get<String>(
          candidateUri.toString(),
          cancelToken: cancelToken,
          options: Options(
            headers: headers,
            responseType: ResponseType.plain,
            followRedirects: true,
          ),
        );
        final candidateBody = playlistResponse.data?.toString() ?? '';

        fallbackUri ??= candidateUri;
        fallbackBody ??= candidateBody;

        if (candidateBody.contains('#EXT-X-MAP:')) {
          playlistUri = candidateUri;
          playlistBody = candidateBody;
          selectedFmp4 = true;
          break;
        }
      }

      if (!selectedFmp4 && fallbackUri != null && fallbackBody != null) {
        playlistUri = fallbackUri;
        playlistBody = fallbackBody;
      }
    }

    final playlistLines = playlistBody
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? initUri;
    for (final line in playlistLines) {
      if (!line.startsWith('#EXT-X-MAP:')) continue;
      final match = RegExp(r'URI="([^"]+)"').firstMatch(line);
      initUri = match?.group(1);
      break;
    }

    final segmentUris = <String>[];
    for (final line in playlistLines) {
      if (line.startsWith('#')) continue;
      segmentUris.add(line);
    }

    if (segmentUris.isEmpty) {
      throw Exception('HLS playlist has no segments');
    }

    String outputExt = 'mp4';
    if (initUri == null) {
      final sample = segmentUris.first;
      final samplePath = Uri.tryParse(sample)?.path ?? sample;
      if (samplePath.toLowerCase().endsWith('.ts')) {
        outputExt = 'ts';
      }
    }

    final currentTask = _tasks[taskId];
    if (currentTask == null) return;

    if (!currentTask.filePath.toLowerCase().endsWith('.$outputExt')) {
      final lastDot = currentTask.filePath.lastIndexOf('.');
      final basePath = lastDot == -1
          ? currentTask.filePath
          : currentTask.filePath.substring(0, lastDot);
      final newPath = '$basePath.$outputExt';

      final lastNameDot = currentTask.fileName.lastIndexOf('.');
      final baseName = lastNameDot == -1
          ? currentTask.fileName
          : currentTask.fileName.substring(0, lastNameDot);
      final newName = '$baseName.$outputExt';

      _tasks[taskId] = currentTask.copyWith(
        filePath: newPath,
        fileName: newName,
      );
      notifyListeners();
    }

    final finalTask = _tasks[taskId]!;
    final outputFile = File(finalTask.filePath);
    await outputFile.parent.create(recursive: true);

    final sink = outputFile.openWrite(mode: FileMode.writeOnly);
    int receivedBytes = 0;
    var lastNotifyAt = DateTime.now();
    var sinceLastNotifyBytes = 0;

    Future<void> updateProgress({required bool force}) async {
      final current = _tasks[taskId];
      if (current == null) return;

      final now = DateTime.now();
      final shouldNotify = force ||
          sinceLastNotifyBytes >= 256 * 1024 ||
          now.difference(lastNotifyAt) >= const Duration(seconds: 1);

      if (!shouldNotify) return;

      _tasks[taskId] = current.copyWith(
        receivedBytes: receivedBytes,
        totalBytes: 0,
        currentStage: 'Downloading HLS segments',
      );
      notifyListeners();
      sinceLastNotifyBytes = 0;
      lastNotifyAt = now;
      await sink.flush();
    }

    Future<void> downloadStreamToSink(String url) async {
      final resp = await _dio.get<ResponseBody>(
        url,
        cancelToken: cancelToken,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
          followRedirects: true,
        ),
      );
      final body = resp.data;
      if (body == null) {
        throw Exception('Empty HLS segment response body');
      }

      await for (final chunk in body.stream) {
        if (chunk.isEmpty) continue;
        sink.add(chunk);
        receivedBytes += chunk.length;
        sinceLastNotifyBytes += chunk.length;
        await updateProgress(force: false);
      }
      await updateProgress(force: true);
    }

    try {
      if (initUri != null) {
        final initUrl = playlistUri.resolve(initUri).toString();
        await downloadStreamToSink(initUrl);
      }

      for (final segment in segmentUris) {
        final segUrl = playlistUri.resolve(segment).toString();
        await downloadStreamToSink(segUrl);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  MediaFormat _selectBestFormat(List<MediaFormat> formats) {
    if (formats.isEmpty) throw StateError('No formats available');

    final normalized = formats.map((f) {
      final ext = (f.ext ?? '').toLowerCase();
      return (format: f, ext: ext);
    }).toList();

    int heightOf(MediaFormat f) => f.height ?? f.quality ?? 0;

    bool isProbablyPreview(MediaFormat f) {
      final url = f.url.toLowerCase();
      if (url.contains('_fb.mp4')) return true;
      if (url.contains('preview')) return true;
      if (url.contains('trailer')) return true;
      if (url.contains('/thumb/')) return true;
      if (url.contains('sample')) return true;
      return false;
    }

    final allCandidates = normalized.map((f) => f.format).toList();

    int extRank(MediaFormat f) {
      final ext = (f.ext ?? '').toLowerCase();
      const ranks = <String, int>{
        'mp4': 0,
        'mkv': 1,
        'mpeg': 2,
        'mpg': 3,
        'webm': 4,
        'mov': 5,
        'avi': 6,
        'flv': 7,
        'ts': 8,
      };
      return ranks[ext] ?? 50;
    }

    void sortFormats(List<MediaFormat> list) {
      list.sort((a, b) {
        final hA = heightOf(a);
        final hB = heightOf(b);
        if (hA != hB) return hB.compareTo(hA);

        final bA = a.bitrate ?? 0;
        final bB = b.bitrate ?? 0;
        if (bA != bB) return bB.compareTo(bA);

        final pA = isProbablyPreview(a);
        final pB = isProbablyPreview(b);
        if (pA != pB) return pA ? 1 : -1;

        final rA = extRank(a);
        final rB = extRank(b);
        if (rA != rB) return rA.compareTo(rB);

        return 0;
      });
    }

    sortFormats(allCandidates);
    final best = allCandidates.first;

    final directCandidates =
        allCandidates.where((f) => !_isHlsUrl(f.url)).toList();
    final hlsCandidates = allCandidates.where((f) => _isHlsUrl(f.url)).toList();

    final bestDirect =
        directCandidates.isNotEmpty ? directCandidates.first : null;
    final bestHls = hlsCandidates.isNotEmpty ? hlsCandidates.first : null;

    if (bestDirect != null && bestHls != null) {
      final directHeight = heightOf(bestDirect);
      final hlsHeight = heightOf(bestHls);

      if (directHeight > 0 &&
          directHeight <= 360 &&
          (hlsHeight > directHeight || hlsHeight == 0)) {
        return bestHls;
      }
    }

    return best;
  }

  String _resolveHome(String path) {
    final trimmed = path.trim();
    if (trimmed == '~') {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) return trimmed;
      return home;
    }
    if (trimmed.startsWith('~/')) {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) return trimmed;
      return '$home/${trimmed.substring(2)}';
    }
    return trimmed;
  }
}
