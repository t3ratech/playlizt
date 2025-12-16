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

class DownloadTask {
  final String id;
  final String url;
  final String filePath;
  final String fileName;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.filePath,
    required this.fileName,
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
    String? filePath,
    String? fileName,
    DownloadStatus? status,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
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
      'filePath': filePath,
      'fileName': fileName,
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

    DownloadStatus finalStatus = resolvedStatus;
    if (resolvedStatus == DownloadStatus.downloading ||
        resolvedStatus == DownloadStatus.queued) {
      finalStatus = DownloadStatus.failed;
    }

    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      status: finalStatus,
      receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
