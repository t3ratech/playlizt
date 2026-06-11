/// Represents the result of an extraction.
class MediaInfo {
  final String id;
  final String title;
  final String? description;
  final String? url; // Direct URL if available
  final String? sourceUrl;
  final String? extractorKey;
  final String? thumbnailUrl;
  final String? uploader;
  final String? uploadDate; // YYYYMMDD
  final int? duration; // Seconds
  final int? viewCount;
  final int? likeCount;
  final List<MediaFormat> formats;
  final List<MediaThumbnail> thumbnails;
  final List<MediaSubtitle> subtitles;
  final List<MediaInfo> playlistEntries;
  final List<String> warnings;
  final Map<String, String> httpHeaders;

  MediaInfo({
    required this.id,
    required this.title,
    this.description,
    this.url,
    this.sourceUrl,
    this.extractorKey,
    this.thumbnailUrl,
    this.uploader,
    this.uploadDate,
    this.duration,
    this.viewCount,
    this.likeCount,
    this.formats = const [],
    this.thumbnails = const [],
    this.subtitles = const [],
    this.playlistEntries = const [],
    this.warnings = const [],
    this.httpHeaders = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'sourceUrl': sourceUrl,
      'extractorKey': extractorKey,
      'thumbnailUrl': thumbnailUrl,
      'uploader': uploader,
      'uploadDate': uploadDate,
      'duration': duration,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'formats': formats.map((f) => f.toJson()).toList(),
      'thumbnails': thumbnails.map((t) => t.toJson()).toList(),
      'subtitles': subtitles.map((s) => s.toJson()).toList(),
      'playlistEntries':
          playlistEntries.map((entry) => entry.toJson()).toList(),
      'warnings': warnings,
      'httpHeaders': httpHeaders,
    };
  }
}

class MediaFormat {
  final String url;
  final String? ext;
  final String? formatId;
  final String? protocol;
  final String? vcodec;
  final String? acodec;
  final int? width;
  final int? height;
  final int? bitrate; // tbr
  final int? filesize;
  final double? fps;
  final String? formatNote;
  final int? quality; // Numeric quality indicator (e.g. 720, 1080)
  final Map<String, String> httpHeaders;

  MediaFormat({
    required this.url,
    this.ext,
    this.formatId,
    this.protocol,
    this.vcodec,
    this.acodec,
    this.width,
    this.height,
    this.bitrate,
    this.filesize,
    this.fps,
    this.formatNote,
    this.quality,
    this.httpHeaders = const {},
  });

  String get friendlyLabel {
    final parts = <String>[];
    if (height != null && height! > 0) parts.add('${height}p');
    if (formatNote != null && formatNote!.trim().isNotEmpty) {
      parts.add(formatNote!.trim());
    }
    if (ext != null && ext!.trim().isNotEmpty) parts.add(ext!.toUpperCase());
    if (vcodec != null && vcodec != 'none') parts.add(vcodec!);
    if (acodec != null && acodec != 'none') parts.add(acodec!);
    if (bitrate != null && bitrate! > 0) parts.add('${bitrate}k');
    if (filesize != null && filesize! > 0) {
      parts.add(_formatBytes(filesize!));
    }
    return parts.isEmpty ? (formatId ?? 'Best available') : parts.join(' • ');
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'ext': ext,
      'formatId': formatId,
      'protocol': protocol,
      'vcodec': vcodec,
      'acodec': acodec,
      'width': width,
      'height': height,
      'bitrate': bitrate,
      'filesize': filesize,
      'fps': fps,
      'formatNote': formatNote,
      'quality': quality,
      'httpHeaders': httpHeaders,
    };
  }

  String _formatBytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) {
      return '${(value / 1024).toStringAsFixed(1)} KB';
    }
    if (value < 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class MediaThumbnail {
  final String url;
  final int? width;
  final int? height;
  final String? id;

  const MediaThumbnail({
    required this.url,
    this.width,
    this.height,
    this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'width': width,
      'height': height,
      'id': id,
    };
  }
}

class MediaSubtitle {
  final String language;
  final String url;
  final String? ext;
  final bool automatic;

  const MediaSubtitle({
    required this.language,
    required this.url,
    this.ext,
    this.automatic = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'url': url,
      'ext': ext,
      'automatic': automatic,
    };
  }
}

class ExtractionError implements Exception {
  final String message;
  final bool expected; // If true, it's a known error (e.g. geoblock)

  ExtractionError(this.message, {this.expected = false});

  @override
  String toString() => 'ExtractionError: $message';
}
