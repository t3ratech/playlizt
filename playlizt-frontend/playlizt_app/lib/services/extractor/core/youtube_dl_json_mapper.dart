import 'types.dart';
import 'utils.dart';

class YoutubeDlJsonMapper {
  static const extractorKey = 'youtube_dl';

  MediaInfo mapMediaInfo(
    Map<String, dynamic> json, {
    required String sourceUrl,
  }) {
    final id =
        _stringValue(json['id']) ??
        _stringValue(json['display_id']) ??
        sourceUrl;
    final title =
        _stringValue(json['title']) ?? _stringValue(json['fulltitle']) ?? id;
    final headers = _stringMap(json['http_headers']);
    final formats = _extractFormats(json, headers);

    return MediaInfo(
      id: id,
      title: title,
      description: _stringValue(json['description']),
      url: _stringValue(json['url']),
      sourceUrl: sourceUrl,
      extractorKey: extractorKey,
      thumbnailUrl: _stringValue(json['thumbnail']),
      uploader: _stringValue(json['uploader']),
      uploadDate: _stringValue(json['upload_date']),
      duration: _intValue(json['duration']),
      viewCount: _intValue(json['view_count']),
      likeCount: _intValue(json['like_count']),
      formats: formats,
      httpHeaders: headers,
    );
  }

  List<MediaFormat> _extractFormats(
    Map<String, dynamic> json,
    Map<String, String> topLevelHeaders,
  ) {
    final formats = <MediaFormat>[];
    final seen = <String>{};

    void addFormat(Map<String, dynamic> item, String fallbackFormatId) {
      final url = _stringValue(item['url']);
      if (url == null || url.trim().isEmpty) return;
      if (!seen.add(url)) return;

      final protocol = _stringValue(item['protocol']);
      final ext = _stringValue(item['ext']) ?? ExtractorUtils.determineExt(url);
      final vcodec = _stringValue(item['vcodec']);
      final acodec = _stringValue(item['acodec']);

      if (!_isNativelyDownloadable(url, protocol, ext, vcodec, acodec)) {
        return;
      }

      formats.add(
        MediaFormat(
          url: url,
          ext: ext,
          formatId: _stringValue(item['format_id']) ?? fallbackFormatId,
          protocol: protocol,
          vcodec: vcodec,
          acodec: acodec,
          width: _intValue(item['width']),
          height: _intValue(item['height']),
          bitrate:
              _intValue(item['tbr']) ??
              _intValue(item['vbr']) ??
              _intValue(item['abr']),
          quality: _intValue(item['height']) ?? _intValue(item['quality']),
          httpHeaders: {
            ...topLevelHeaders,
            ..._stringMap(item['http_headers']),
          },
        ),
      );
    }

    addFormat(json, 'youtube_dl_selected');

    final rawFormats = json['formats'];
    if (rawFormats is List) {
      for (final rawFormat in rawFormats) {
        if (rawFormat is Map<String, dynamic>) {
          addFormat(rawFormat, 'youtube_dl_format');
        } else if (rawFormat is Map) {
          addFormat(
            rawFormat.map((key, value) => MapEntry(key.toString(), value)),
            'youtube_dl_format',
          );
        }
      }
    }

    return formats;
  }

  bool _isNativelyDownloadable(
    String url,
    String? protocol,
    String? ext,
    String? vcodec,
    String? acodec,
  ) {
    final lowerProtocol = protocol?.toLowerCase();
    if (lowerProtocol != null &&
        lowerProtocol.isNotEmpty &&
        !<String>{
          'http',
          'https',
          'm3u8',
          'm3u8_native',
        }.contains(lowerProtocol)) {
      return false;
    }

    final hasVideoOnlyCodec =
        vcodec != null &&
        vcodec != 'none' &&
        acodec != null &&
        acodec == 'none';
    if (hasVideoOnlyCodec) return false;

    final lowerExt = ext?.toLowerCase();
    if (lowerExt == 'mpd' || lowerExt == 'f4m' || lowerExt == 'ism') {
      return false;
    }

    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).toLowerCase();
    if (path.endsWith('.mpd') ||
        path.endsWith('.f4m') ||
        path.endsWith('.ism') ||
        path.endsWith('/manifest')) {
      return false;
    }

    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int? _intValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) {
      final parsedDouble = double.tryParse(value);
      return parsedDouble?.round();
    }
    return null;
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((key, item) => MapEntry(key, item.toString()));
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item.toString()),
      );
    }
    return const {};
  }
}
