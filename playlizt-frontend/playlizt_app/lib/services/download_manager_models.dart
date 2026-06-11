/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 03:28
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

enum DownloadBackend { native, youtubeDl }

class DownloadTask {
  final String id;
  final String url;
  final String? originalUrl;
  final String filePath;
  final String fileName;
  final String? title;
  final String? thumbnailUrl;
  final Map<String, String>? headers;
  final DownloadBackend backend;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;

  const DownloadTask({
    required this.id,
    required this.url,
    this.originalUrl,
    required this.filePath,
    required this.fileName,
    this.title,
    this.thumbnailUrl,
    this.headers,
    this.backend = DownloadBackend.native,
    required this.status,
    required this.receivedBytes,
    required this.totalBytes,
    this.errorMessage,
  });

  double? get progress {
    if (totalBytes <= 0) return null;
    return receivedBytes / totalBytes;
  }

  DownloadTask copyWith({
    String? id,
    String? url,
    String? originalUrl,
    String? filePath,
    String? fileName,
    String? title,
    String? thumbnailUrl,
    Map<String, String>? headers,
    DownloadBackend? backend,
    DownloadStatus? status,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      originalUrl: originalUrl ?? this.originalUrl,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      headers: headers ?? this.headers,
      backend: backend ?? this.backend,
      status: status ?? this.status,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'originalUrl': originalUrl,
      'filePath': filePath,
      'fileName': fileName,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'headers': headers,
      'backend': backend.name,
      'status': status.name,
      'receivedBytes': receivedBytes,
      'totalBytes': totalBytes,
      'errorMessage': errorMessage,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static DownloadTask fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String?;
    final resolvedStatus = DownloadStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => DownloadStatus.failed,
    );
    final rawBackend = json['backend'] as String?;
    final resolvedBackend = DownloadBackend.values.firstWhere(
      (backend) => backend.name == rawBackend,
      orElse: () => DownloadBackend.native,
    );

    DownloadStatus finalStatus = resolvedStatus;
    if (resolvedStatus == DownloadStatus.downloading) {
      finalStatus = DownloadStatus.failed;
    }

    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      originalUrl: json['originalUrl'] as String?,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      title: json['title'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      backend: resolvedBackend,
      status: finalStatus,
      receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
