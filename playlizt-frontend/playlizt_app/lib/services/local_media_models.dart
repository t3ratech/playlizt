/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 21:43
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';

enum LibraryMediaType { audio, video, subtitle, image, unknown }

enum LibraryItemSource { scanned, downloaded, converted, network }

enum LibrarySortMode { name, dateAdded, modifiedAt, duration, size }

enum LibraryAvailability { available, missing }

class LibraryItem {
  final String id;
  final String path;
  final String displayTitle;
  final LibraryMediaType mediaType;
  final LibraryItemSource source;
  final int fileSizeBytes;
  final int? durationSeconds;
  final DateTime dateAdded;
  final DateTime lastSeen;
  final DateTime? modifiedAt;
  final String? parentId;
  final String? thumbnailPath;
  final LibraryAvailability availability;

  const LibraryItem({
    required this.id,
    required this.path,
    required this.displayTitle,
    required this.mediaType,
    required this.source,
    required this.fileSizeBytes,
    this.durationSeconds,
    required this.dateAdded,
    required this.lastSeen,
    this.modifiedAt,
    this.parentId,
    this.thumbnailPath,
    this.availability = LibraryAvailability.available,
  });

  String get folderPath {
    final slash = path.lastIndexOf('/');
    final backslash = path.lastIndexOf('\\');
    final index = slash > backslash ? slash : backslash;
    if (index <= 0) return '';
    return path.substring(0, index);
  }

  String get extension {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  LibraryItem copyWith({
    String? id,
    String? path,
    String? displayTitle,
    LibraryMediaType? mediaType,
    LibraryItemSource? source,
    int? fileSizeBytes,
    int? durationSeconds,
    DateTime? dateAdded,
    DateTime? lastSeen,
    DateTime? modifiedAt,
    String? parentId,
    String? thumbnailPath,
    LibraryAvailability? availability,
  }) {
    return LibraryItem(
      id: id ?? this.id,
      path: path ?? this.path,
      displayTitle: displayTitle ?? this.displayTitle,
      mediaType: mediaType ?? this.mediaType,
      source: source ?? this.source,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      dateAdded: dateAdded ?? this.dateAdded,
      lastSeen: lastSeen ?? this.lastSeen,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      parentId: parentId ?? this.parentId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      availability: availability ?? this.availability,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'displayTitle': displayTitle,
      'mediaType': mediaType.name,
      'source': source.name,
      'fileSizeBytes': fileSizeBytes,
      'durationSeconds': durationSeconds,
      'dateAdded': dateAdded.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'parentId': parentId,
      'thumbnailPath': thumbnailPath,
      'availability': availability.name,
    };
  }

  static LibraryItem fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: json['id'] as String,
      path: json['path'] as String,
      displayTitle: json['displayTitle'] as String,
      mediaType: _enumByName(
        LibraryMediaType.values,
        json['mediaType'] as String?,
        LibraryMediaType.unknown,
      ),
      source: _enumByName(
        LibraryItemSource.values,
        json['source'] as String?,
        LibraryItemSource.scanned,
      ),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      modifiedAt: _dateTimeOrNull(json['modifiedAt']),
      parentId: json['parentId'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      availability: _enumByName(
        LibraryAvailability.values,
        json['availability'] as String?,
        LibraryAvailability.available,
      ),
    );
  }

  static String stableIdForPath(String path) {
    return base64Url.encode(utf8.encode(path)).replaceAll('=', '');
  }

  static LibraryMediaType mediaTypeForPath(String path) {
    final lower = path.toLowerCase();
    final dot = lower.lastIndexOf('.');
    final ext = dot == -1 ? '' : lower.substring(dot + 1);
    if (_videoExtensions.contains(ext)) return LibraryMediaType.video;
    if (_audioExtensions.contains(ext)) return LibraryMediaType.audio;
    if (_subtitleExtensions.contains(ext)) return LibraryMediaType.subtitle;
    if (_imageExtensions.contains(ext)) return LibraryMediaType.image;
    return LibraryMediaType.unknown;
  }

  static bool isSupportedMediaPath(String path) {
    return mediaTypeForPath(path) != LibraryMediaType.unknown;
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

  static DateTime? _dateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static const _videoExtensions = {
    '3gp',
    'avi',
    'flv',
    'm4v',
    'mkv',
    'mov',
    'mp4',
    'mpeg',
    'mpg',
    'ogv',
    'ts',
    'webm',
    'wmv',
  };

  static const _audioExtensions = {
    'aac',
    'aiff',
    'alac',
    'ape',
    'flac',
    'm4a',
    'mp3',
    'oga',
    'ogg',
    'opus',
    'wav',
    'wma',
  };

  static const _subtitleExtensions = {
    'ass',
    'srt',
    'ssa',
    'sub',
    'vtt',
  };

  static const _imageExtensions = {
    'avif',
    'gif',
    'jpeg',
    'jpg',
    'png',
    'webp',
  };
}

class LibraryScanResult {
  final int scannedFiles;
  final int importedItems;
  final int removedMissingItems;
  final int markedMissingItems;
  final DateTime completedAt;

  const LibraryScanResult({
    required this.scannedFiles,
    required this.importedItems,
    required this.removedMissingItems,
    this.markedMissingItems = 0,
    required this.completedAt,
  });
}

class LibraryAvailabilityResult {
  final int checkedItems;
  final int availableItems;
  final int missingItems;
  final DateTime completedAt;

  const LibraryAvailabilityResult({
    required this.checkedItems,
    required this.availableItems,
    required this.missingItems,
    required this.completedAt,
  });
}
