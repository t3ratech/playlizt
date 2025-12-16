/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 03:28
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import 'download_manager_models.dart';

/// Web implementation of DownloadManager.
///
/// Flutter Web cannot write to the local filesystem. Instead we fetch the bytes
/// and trigger a browser download using a Blob + anchor click.
class DownloadManager with ChangeNotifier {
  static const _prefsKeyTasks = 'downloads.tasks';

  final SettingsProvider settingsProvider;
  final Dio _dio = Dio();

  final Map<String, DownloadTask> _tasks = {};
  final Map<String, CancelToken> _tokens = {};
  final Map<String, DownloadStatus> _pendingCancelStatus = {};

  bool _initialised = false;

  DownloadManager({required this.settingsProvider}) {
    _loadPersistedTasks();
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
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw ArgumentError('Only http/https URLs are supported');
    }

    final suggestedName = explicitFileName?.trim().isNotEmpty == true
        ? explicitFileName!.trim()
        : (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'download.bin');

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // On web, directory selection is not supported. We still store a descriptive
    // filePath string so the UI has something to render.
    final filePath = suggestedName;

    final task = DownloadTask(
      id: id,
      url: url,
      filePath: filePath,
      fileName: suggestedName,
      status: DownloadStatus.queued,
      receivedBytes: 0,
      totalBytes: 0,
    );

    _tasks[id] = task;
    await _persistTasks();
    _startNextIfPossible();
    notifyListeners();
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
        print('DownloadManager(web): failed to load tasks: $e');
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
        print('DownloadManager(web): failed to persist tasks: $e');
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
      final response = await _dio.get<List<int>>(
        task.url,
        cancelToken: token,
        options: Options(responseType: ResponseType.bytes, followRedirects: true),
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

      final bytes = response.data;
      if (bytes == null) {
        throw StateError('No response bytes received');
      }

      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final objectUrl = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: objectUrl)
        ..download = task.fileName
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(objectUrl);

      _tokens.remove(task.id);
      _tasks[task.id] = _tasks[task.id]!.copyWith(
        status: DownloadStatus.completed,
      );
      await _persistTasks();
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
}
