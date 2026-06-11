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
  extracting,
  downloading,
  postProcessing,
  paused,
  skipped,
  completed,
  failed,
  cancelled,
}

enum DownloadBackend { native, youtubeDl }

class DownloadOptions {
  final String? formatId;
  final bool audioOnly;
  final bool writeSubtitles;
  final bool writeThumbnail;
  final bool writeMetadata;
  final String? proxy;
  final String? rateLimit;
  final String? cookieFile;
  final String? username;
  final String? password;

  const DownloadOptions({
    this.formatId,
    this.audioOnly = false,
    this.writeSubtitles = false,
    this.writeThumbnail = false,
    this.writeMetadata = false,
    this.proxy,
    this.rateLimit,
    this.cookieFile,
    this.username,
    this.password,
  });

  bool get hasPostProcessing =>
      audioOnly || writeSubtitles || writeThumbnail || writeMetadata;

  Map<String, dynamic> toJson() {
    return {
      'formatId': formatId,
      'audioOnly': audioOnly,
      'writeSubtitles': writeSubtitles,
      'writeThumbnail': writeThumbnail,
      'writeMetadata': writeMetadata,
      'proxy': proxy,
      'rateLimit': rateLimit,
      'cookieFile': cookieFile,
      'username': username,
      'password': null,
    };
  }

  static DownloadOptions fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DownloadOptions();
    return DownloadOptions(
      formatId: json['formatId'] as String?,
      audioOnly: json['audioOnly'] as bool? ?? false,
      writeSubtitles: json['writeSubtitles'] as bool? ?? false,
      writeThumbnail: json['writeThumbnail'] as bool? ?? false,
      writeMetadata: json['writeMetadata'] as bool? ?? false,
      proxy: json['proxy'] as String?,
      rateLimit: json['rateLimit'] as String?,
      cookieFile: json['cookieFile'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }
}

class DownloadBatchParser {
  static List<String> parseUrls(String input) {
    final urls = <String>[];
    final seen = <String>{};

    for (final rawLine in const LineSplitter().convert(input)) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final tokens = line.split(RegExp(r'\s+'));
      for (final token in tokens) {
        final candidate = token.trim().replaceAll(RegExp(r',$'), '');
        if (candidate.isEmpty) continue;
        final uri = Uri.tryParse(candidate);
        if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
          urls.add(candidate);
          continue;
        }
        if (seen.add(candidate)) {
          urls.add(candidate);
        }
      }
    }

    return urls;
  }
}

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
  final DownloadOptions options;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final double? speedBytesPerSecond;
  final int? etaSeconds;
  final String currentStage;
  final String? formatLabel;
  final String? extractorName;
  final String? playlistTitle;
  final int? playlistIndex;
  final int? playlistCount;
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
    this.options = const DownloadOptions(),
    required this.status,
    required this.receivedBytes,
    required this.totalBytes,
    this.speedBytesPerSecond,
    this.etaSeconds,
    this.currentStage = 'Queued',
    this.formatLabel,
    this.extractorName,
    this.playlistTitle,
    this.playlistIndex,
    this.playlistCount,
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
    DownloadOptions? options,
    DownloadStatus? status,
    int? receivedBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
    int? etaSeconds,
    String? currentStage,
    String? formatLabel,
    String? extractorName,
    String? playlistTitle,
    int? playlistIndex,
    int? playlistCount,
    String? errorMessage,
    bool clearErrorMessage = false,
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
      options: options ?? this.options,
      status: status ?? this.status,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      currentStage: currentStage ?? this.currentStage,
      formatLabel: formatLabel ?? this.formatLabel,
      extractorName: extractorName ?? this.extractorName,
      playlistTitle: playlistTitle ?? this.playlistTitle,
      playlistIndex: playlistIndex ?? this.playlistIndex,
      playlistCount: playlistCount ?? this.playlistCount,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
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
      'options': options.toJson(),
      'status': status.name,
      'receivedBytes': receivedBytes,
      'totalBytes': totalBytes,
      'speedBytesPerSecond': speedBytesPerSecond,
      'etaSeconds': etaSeconds,
      'currentStage': currentStage,
      'formatLabel': formatLabel,
      'extractorName': extractorName,
      'playlistTitle': playlistTitle,
      'playlistIndex': playlistIndex,
      'playlistCount': playlistCount,
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
    if (resolvedStatus == DownloadStatus.downloading ||
        resolvedStatus == DownloadStatus.extracting ||
        resolvedStatus == DownloadStatus.postProcessing) {
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
      options: DownloadOptions.fromJson(
        (json['options'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      status: finalStatus,
      receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      speedBytesPerSecond: (json['speedBytesPerSecond'] as num?)?.toDouble(),
      etaSeconds: (json['etaSeconds'] as num?)?.toInt(),
      currentStage: json['currentStage'] as String? ?? finalStatus.name,
      formatLabel: json['formatLabel'] as String?,
      extractorName: json['extractorName'] as String?,
      playlistTitle: json['playlistTitle'] as String?,
      playlistIndex: (json['playlistIndex'] as num?)?.toInt(),
      playlistCount: (json['playlistCount'] as num?)?.toInt(),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class DownloadArchiveEntry {
  final String sourceUrl;
  final String outputPath;
  final String fileName;
  final String? title;
  final String? extractorName;
  final String? playlistTitle;
  final int? playlistIndex;
  final DateTime completedAt;

  const DownloadArchiveEntry({
    required this.sourceUrl,
    required this.outputPath,
    required this.fileName,
    this.title,
    this.extractorName,
    this.playlistTitle,
    this.playlistIndex,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceUrl': sourceUrl,
      'outputPath': outputPath,
      'fileName': fileName,
      'title': title,
      'extractorName': extractorName,
      'playlistTitle': playlistTitle,
      'playlistIndex': playlistIndex,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  static DownloadArchiveEntry fromJson(Map<String, dynamic> json) {
    return DownloadArchiveEntry(
      sourceUrl: json['sourceUrl'] as String,
      outputPath: json['outputPath'] as String,
      fileName: json['fileName'] as String,
      title: json['title'] as String?,
      extractorName: json['extractorName'] as String?,
      playlistTitle: json['playlistTitle'] as String?,
      playlistIndex: (json['playlistIndex'] as num?)?.toInt(),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
