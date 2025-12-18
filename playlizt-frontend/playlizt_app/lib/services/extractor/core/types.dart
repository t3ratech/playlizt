/// Represents the result of an extraction.
class MediaInfo {
  final String id;
  final String title;
  final String? description;
  final String? url; // Direct URL if available
  final String? thumbnailUrl;
  final String? uploader;
  final String? uploadDate; // YYYYMMDD
  final int? duration; // Seconds
  final int? viewCount;
  final int? likeCount;
  final List<MediaFormat> formats;
  final Map<String, String> httpHeaders;

  MediaInfo({
    required this.id,
    required this.title,
    this.description,
    this.url,
    this.thumbnailUrl,
    this.uploader,
    this.uploadDate,
    this.duration,
    this.viewCount,
    this.likeCount,
    this.formats = const [],
    this.httpHeaders = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'uploader': uploader,
      'uploadDate': uploadDate,
      'duration': duration,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'formats': formats.map((f) => f.toJson()).toList(),
      'httpHeaders': httpHeaders,
    };
  }
}

class MediaFormat {
  final String url;
  final String? ext;
  final String? formatId;
  final int? width;
  final int? height;
  final int? bitrate; // tbr
  final int? quality; // Numeric quality indicator (e.g. 720, 1080)
  final Map<String, String> httpHeaders;

  MediaFormat({
    required this.url,
    this.ext,
    this.formatId,
    this.width,
    this.height,
    this.bitrate,
    this.quality,
    this.httpHeaders = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'ext': ext,
      'formatId': formatId,
      'width': width,
      'height': height,
      'bitrate': bitrate,
      'quality': quality,
      'httpHeaders': httpHeaders,
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
