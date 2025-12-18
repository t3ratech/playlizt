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
import 'extractor/core/types.dart';

/// Manages the lifecycle of media downloads including queuing, progress
/// tracking, pause/cancel behaviour and basic persistence across restarts.
class DownloadManager with ChangeNotifier {
  static const _prefsKeyTasks = 'downloads.tasks';

  final SettingsProvider settingsProvider;
  final PlaylistProvider playlistProvider;
  final Dio _dio = Dio();
  final ExtractionEngine _extractionEngine = ExtractionEngine();

  final Map<String, DownloadTask> _tasks = {};
  final Map<String, CancelToken> _tokens = {};
  final Map<String, DownloadStatus> _pendingCancelStatus = {};

  bool _initialised = false;

  DownloadManager({
    required this.settingsProvider,
    required this.playlistProvider,
  }) {
    _loadPersistedTasks();
  }

  bool _looksLikeDirectMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.m3u8') ||
        path.endsWith('.mpd') ||
        path.endsWith('.webm') ||
        path.endsWith('.mov') ||
        path.endsWith('.mkv') ||
        path.endsWith('.mp3') ||
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

  bool get isInitialised => _initialised;

  List<DownloadTask> get tasks {
    final list = _tasks.values.toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  Future<void> enqueueDownload({
    required String url,
    String? targetDirectory,
    String? explicitFileName,
  }) async {
    print('DownloadManager: Enqueuing download for $url');
    // 1. Resolve URL using Extraction Engine
    String actualUrl = url;
    String finalFileName = explicitFileName?.trim() ?? '';
    String? title;
    String? thumbnailUrl;
    Map<String, String>? headers;
    bool extractionSucceeded = false;
    
    try {
      final mediaInfo = await _extractionEngine.extract(url);
      extractionSucceeded = true;
      title = mediaInfo.title;
      thumbnailUrl = mediaInfo.thumbnailUrl;
      print('DownloadManager: Extraction success. Title: ${mediaInfo.title}, Formats: ${mediaInfo.formats.length}');
      if (mediaInfo.formats.isNotEmpty) {
        // Select best format based on quality/resolution
        final bestFormat = _selectBestFormat(mediaInfo.formats);
        actualUrl = bestFormat.url;
        headers = bestFormat.httpHeaders;
        
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
          final safeTitle = mediaInfo.title.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
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

    final uri = Uri.tryParse(actualUrl);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw ArgumentError('Only http/https URLs are supported');
    }

    final directory = targetDirectory?.trim().isNotEmpty == true
        ? targetDirectory!.trim()
        : settingsProvider.downloadDirectory;

    final suggestedName = finalFileName.isNotEmpty
        ? finalFileName
        : _safeFileNameFromUri(uri);

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
      filePath: fullPath,
      fileName: suggestedName,
      headers: headers,
      title: title,
      thumbnailUrl: thumbnailUrl,
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
      errorMessage: null,
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
      if (raw == null || raw.isEmpty) {
        _initialised = true;
        return;
      }

      final decoded = jsonDecode(raw);
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
      errorMessage: null,
    );
    _tasks[task.id] = updated;
    final token = CancelToken();
    _tokens[task.id] = token;
    notifyListeners();

    try {
      print('DownloadManager: Starting download...');
      print('URL: ${task.url}');
      print('Headers: ${task.headers}');
      
      if (_isHlsUrl(task.url)) {
        await _downloadHlsToFile(task.id, cancelToken: token);
      } else {
        await _dio.download(
          task.url,
          file.path,
          cancelToken: token,
          options: Options(
            headers: task.headers,
            followRedirects: true,
          ),
          onReceiveProgress: (received, total) {
            final current = _tasks[task.id];
            if (current == null) return;
            _tasks[task.id] = current.copyWith(
              receivedBytes: received,
              totalBytes: total,
            );
            notifyListeners();
          },
        );
      }

      _tokens.remove(task.id);
      _tasks[task.id] = _tasks[task.id]!.copyWith(
        status: DownloadStatus.completed,
      );
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
          durationSeconds: 0, // TODO: Extract duration
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

    final playlistLines =
        playlistBody.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

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

      _tasks[taskId] = currentTask.copyWith(filePath: newPath, fileName: newName);
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
      final shouldNotify =
          force ||
          sinceLastNotifyBytes >= 256 * 1024 ||
          now.difference(lastNotifyAt) >= const Duration(seconds: 1);

      if (!shouldNotify) return;

      _tasks[taskId] = current.copyWith(
        receivedBytes: receivedBytes,
        totalBytes: 0,
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

    bool isHls(({MediaFormat format, String ext}) item) {
      if (item.ext == 'm3u8') return true;
      final uri = Uri.tryParse(item.format.url);
      final path = (uri?.path ?? item.format.url).toLowerCase();
      return path.endsWith('.m3u8');
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

    final bestDirect = directCandidates.isNotEmpty ? directCandidates.first : null;
    final bestHls = hlsCandidates.isNotEmpty ? hlsCandidates.first : null;

    if (bestDirect != null && bestHls != null) {
      final directHeight = heightOf(bestDirect);
      final hlsHeight = heightOf(bestHls);

      if (directHeight > 0 && directHeight <= 360 && (hlsHeight > directHeight || hlsHeight == 0)) {
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
