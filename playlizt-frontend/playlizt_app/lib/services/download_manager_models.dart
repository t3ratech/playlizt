/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 03:28
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';

import 'extractor/core/types.dart';

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

enum DownloadSidecarType { subtitle, thumbnail, metadata }

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
  final String? retries;
  final String? fragmentRetries;
  final String? concurrentFragments;
  final String? socketTimeoutSeconds;
  final String? maxDownloads;
  final String? userAgent;
  final String? referer;
  final String? playlistStart;
  final String? playlistEnd;
  final String? playlistItems;
  final String? matchTitle;
  final String? rejectTitle;
  final String? ageLimit;
  final bool geoBypass;
  final String? geoVerificationProxy;
  final bool forcePlaylist;

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
    this.retries,
    this.fragmentRetries,
    this.concurrentFragments,
    this.socketTimeoutSeconds,
    this.maxDownloads,
    this.userAgent,
    this.referer,
    this.playlistStart,
    this.playlistEnd,
    this.playlistItems,
    this.matchTitle,
    this.rejectTitle,
    this.ageLimit,
    this.geoBypass = false,
    this.geoVerificationProxy,
    this.forcePlaylist = false,
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
      'retries': retries,
      'fragmentRetries': fragmentRetries,
      'concurrentFragments': concurrentFragments,
      'socketTimeoutSeconds': socketTimeoutSeconds,
      'maxDownloads': maxDownloads,
      'userAgent': userAgent,
      'referer': referer,
      'playlistStart': playlistStart,
      'playlistEnd': playlistEnd,
      'playlistItems': playlistItems,
      'matchTitle': matchTitle,
      'rejectTitle': rejectTitle,
      'ageLimit': ageLimit,
      'geoBypass': geoBypass,
      'geoVerificationProxy': geoVerificationProxy,
      'forcePlaylist': forcePlaylist,
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
      retries: json['retries'] as String?,
      fragmentRetries: json['fragmentRetries'] as String?,
      concurrentFragments: json['concurrentFragments'] as String?,
      socketTimeoutSeconds: json['socketTimeoutSeconds'] as String?,
      maxDownloads: json['maxDownloads'] as String?,
      userAgent: json['userAgent'] as String?,
      referer: json['referer'] as String?,
      playlistStart: json['playlistStart'] as String?,
      playlistEnd: json['playlistEnd'] as String?,
      playlistItems: json['playlistItems'] as String?,
      matchTitle: json['matchTitle'] as String?,
      rejectTitle: json['rejectTitle'] as String?,
      ageLimit: json['ageLimit'] as String?,
      geoBypass: json['geoBypass'] as bool? ?? false,
      geoVerificationProxy: json['geoVerificationProxy'] as String?,
      forcePlaylist: json['forcePlaylist'] as bool? ?? false,
    );
  }

  int? get concurrentFragmentsCount => _positiveIntOption(
        concurrentFragments,
        'Concurrent fragments',
      );

  int? get maxDownloadsLimit => _positiveIntOption(
        maxDownloads,
        'Max downloads',
      );

  List<String> normalizedBatchUrls(Iterable<String> urls) {
    final limit = maxDownloadsLimit;
    final normalized = <String>[];
    for (final url in urls) {
      final trimmed = url.trim();
      if (trimmed.isEmpty) continue;
      normalized.add(trimmed);
      if (limit != null && normalized.length >= limit) break;
    }
    return normalized;
  }

  static int? _positiveIntOption(String? value, String label) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed < 1) {
      throw ArgumentError('$label must be a positive integer');
    }
    return parsed;
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

class DownloadPreview {
  final String requestedUrl;
  final String title;
  final String? description;
  final String? extractorName;
  final String? thumbnailUrl;
  final String? uploader;
  final String? uploadDate;
  final int? durationSeconds;
  final List<DownloadPreviewFormat> formats;
  final List<DownloadPreviewThumbnail> thumbnails;
  final List<DownloadPreviewSubtitle> subtitles;
  final List<DownloadPreviewEntry> playlistEntries;
  final List<String> warnings;

  const DownloadPreview({
    required this.requestedUrl,
    required this.title,
    this.description,
    this.extractorName,
    this.thumbnailUrl,
    this.uploader,
    this.uploadDate,
    this.durationSeconds,
    this.formats = const [],
    this.thumbnails = const [],
    this.subtitles = const [],
    this.playlistEntries = const [],
    this.warnings = const [],
  });

  bool get isPlaylist => playlistEntries.isNotEmpty;
  int get playlistCount => playlistEntries.length;
  int get formatCount => formats.length;
  int get subtitleCount => subtitles.length;
  int get thumbnailCount => thumbnails.length;

  factory DownloadPreview.fromMediaInfo(
    MediaInfo info, {
    required String requestedUrl,
  }) {
    return DownloadPreview(
      requestedUrl: requestedUrl,
      title: info.title,
      description: info.description,
      extractorName: info.extractorKey,
      thumbnailUrl: info.thumbnailUrl,
      uploader: info.uploader,
      uploadDate: info.uploadDate,
      durationSeconds: info.duration,
      formats: info.formats
          .map(DownloadPreviewFormat.fromMediaFormat)
          .toList(growable: false),
      thumbnails: info.thumbnails
          .map(DownloadPreviewThumbnail.fromMediaThumbnail)
          .toList(growable: false),
      subtitles: info.subtitles
          .map(DownloadPreviewSubtitle.fromMediaSubtitle)
          .toList(growable: false),
      playlistEntries: info.playlistEntries
          .map(DownloadPreviewEntry.fromMediaInfo)
          .toList(growable: false),
      warnings: info.warnings,
    );
  }
}

class DownloadPreviewFormat {
  final String? formatId;
  final String label;
  final String? extension;
  final String? protocol;
  final String? videoCodec;
  final String? audioCodec;
  final int? width;
  final int? height;
  final int? bitrate;
  final int? filesize;
  final double? fps;

  const DownloadPreviewFormat({
    this.formatId,
    required this.label,
    this.extension,
    this.protocol,
    this.videoCodec,
    this.audioCodec,
    this.width,
    this.height,
    this.bitrate,
    this.filesize,
    this.fps,
  });

  factory DownloadPreviewFormat.fromMediaFormat(MediaFormat format) {
    return DownloadPreviewFormat(
      formatId: format.formatId,
      label: format.friendlyLabel,
      extension: format.ext,
      protocol: format.protocol,
      videoCodec: format.vcodec,
      audioCodec: format.acodec,
      width: format.width,
      height: format.height,
      bitrate: format.bitrate,
      filesize: format.filesize,
      fps: format.fps,
    );
  }
}

class DownloadPreviewThumbnail {
  final String url;
  final String? id;
  final int? width;
  final int? height;

  const DownloadPreviewThumbnail({
    required this.url,
    this.id,
    this.width,
    this.height,
  });

  factory DownloadPreviewThumbnail.fromMediaThumbnail(
      MediaThumbnail thumbnail) {
    return DownloadPreviewThumbnail(
      url: thumbnail.url,
      id: thumbnail.id,
      width: thumbnail.width,
      height: thumbnail.height,
    );
  }
}

class DownloadPreviewSubtitle {
  final String language;
  final String? extension;
  final bool automatic;
  final String url;

  const DownloadPreviewSubtitle({
    required this.language,
    this.extension,
    required this.automatic,
    required this.url,
  });

  factory DownloadPreviewSubtitle.fromMediaSubtitle(MediaSubtitle subtitle) {
    return DownloadPreviewSubtitle(
      language: subtitle.language,
      extension: subtitle.ext,
      automatic: subtitle.automatic,
      url: subtitle.url,
    );
  }
}

class DownloadPreviewEntry {
  final String id;
  final String title;
  final String? url;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int formatCount;
  final int subtitleCount;

  const DownloadPreviewEntry({
    required this.id,
    required this.title,
    this.url,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.formatCount,
    required this.subtitleCount,
  });

  factory DownloadPreviewEntry.fromMediaInfo(MediaInfo info) {
    return DownloadPreviewEntry(
      id: info.id,
      title: info.title,
      url: info.sourceUrl ?? info.url,
      thumbnailUrl: info.thumbnailUrl,
      durationSeconds: info.duration,
      formatCount: info.formats.length,
      subtitleCount: info.subtitles.length,
    );
  }
}

class DownloadSidecarFile {
  final DownloadSidecarType type;
  final String path;
  final String? language;
  final String? format;
  final int? sizeBytes;

  const DownloadSidecarFile({
    required this.type,
    required this.path,
    this.language,
    this.format,
    this.sizeBytes,
  });

  String get fileName => path.split(RegExp(r'[/\\]')).last;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'path': path,
      'language': language,
      'format': format,
      'sizeBytes': sizeBytes,
    };
  }

  static DownloadSidecarFile fromJson(Map<String, dynamic> json) {
    return DownloadSidecarFile(
      type: _enumByName(
        DownloadSidecarType.values,
        json['type'] as String?,
        DownloadSidecarType.metadata,
      ),
      path: json['path'] as String,
      language: json['language'] as String?,
      format: json['format'] as String?,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    );
  }

  static DownloadSidecarType? typeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.info.json')) return DownloadSidecarType.metadata;
    final extension = extensionForPath(path);
    if (_subtitleExtensions.contains(extension)) {
      return DownloadSidecarType.subtitle;
    }
    if (_thumbnailExtensions.contains(extension)) {
      return DownloadSidecarType.thumbnail;
    }
    return null;
  }

  static String? languageForPath({
    required String sidecarPath,
    required String mediaPath,
  }) {
    final sidecarName = sidecarPath.split(RegExp(r'[/\\]')).last;
    final mediaName = mediaPath.split(RegExp(r'[/\\]')).last;
    final mediaBase = _baseName(mediaName);
    final sidecarBase = _baseName(sidecarName.replaceAll('.info', ''));
    if (!sidecarBase.startsWith('$mediaBase.')) return null;
    final suffix = sidecarBase.substring(mediaBase.length + 1);
    return suffix.trim().isEmpty ? null : suffix;
  }

  static String extensionForPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static String _baseName(String name) {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static const _subtitleExtensions = {
    'ass',
    'srt',
    'ssa',
    'sub',
    'vtt',
  };

  static const _thumbnailExtensions = {
    'avif',
    'gif',
    'jpeg',
    'jpg',
    'png',
    'webp',
  };
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
  final List<DownloadSidecarFile> sidecarFiles;
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
    this.sidecarFiles = const [],
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
    List<DownloadSidecarFile>? sidecarFiles,
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
      sidecarFiles: sidecarFiles ?? this.sidecarFiles,
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
      'sidecarFiles': sidecarFiles.map((file) => file.toJson()).toList(),
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
      sidecarFiles: (json['sidecarFiles'] as List<dynamic>?)
              ?.map((item) {
                if (item is Map<String, dynamic>) {
                  return DownloadSidecarFile.fromJson(item);
                }
                if (item is Map) {
                  return DownloadSidecarFile.fromJson(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  );
                }
                return null;
              })
              .whereType<DownloadSidecarFile>()
              .toList() ??
          const [],
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
