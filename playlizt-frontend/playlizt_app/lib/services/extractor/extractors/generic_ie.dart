
import 'package:html/dom.dart';
import '../core/info_extractor.dart';
import '../core/types.dart';
import '../core/utils.dart';

class GenericIE extends InfoExtractor {
  @override
  String get name => 'generic';

  Map<String, String> _defaultMediaHeaders(String pageUrl) {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
      'Referer': pageUrl,
      'Accept': '*/*',
    };
  }

  String _unescapeJsUrl(String url) {
    return url
        .replaceAll(r'\/', '/')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\u002f', '/')
        .replaceAll(r'\u003A', ':')
        .replaceAll(r'\u003a', ':')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\u003D', '=')
        .replaceAll(r'\u003d', '=');
  }

  String _unescapeHtmlUrl(String url) {
    return url
        .replaceAll('&amp;', '&')
        .replaceAll('&#38;', '&')
        .replaceAll('&#x26;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#34;', '"')
        .replaceAll('&#x22;', '"');
  }

  String _normalizeExtractedUrl(String url) {
    var value = url.trim();
    value = _unescapeJsUrl(value);
    value = _unescapeHtmlUrl(value);
    if (value.startsWith('//')) {
      value = 'https:$value';
    }
    return value;
  }

  int? _inferHeightFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final haystack = (uri?.pathSegments.isNotEmpty ?? false)
        ? uri!.pathSegments.last
        : (uri?.path ?? url);

    final match = RegExp(
      r'(^|[^0-9])(\d{3,4})p([^a-zA-Z0-9]|$)',
      caseSensitive: false,
    ).firstMatch(haystack);
    if (match == null) return null;
    return int.tryParse(match.group(2) ?? '');
  }

  int? _inferBitrateKbpsFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final haystack = (uri?.pathSegments.isNotEmpty ?? false)
        ? uri!.pathSegments.last
        : (uri?.path ?? url);

    final match = RegExp(
      r'(^|[^0-9])(\d{2,5})k([^a-zA-Z0-9]|$)',
      caseSensitive: false,
    ).firstMatch(haystack);
    if (match == null) return null;
    return int.tryParse(match.group(2) ?? '');
  }

  @override
  bool suitable(String url) => true; // Fallback extractor

  @override
  Future<MediaInfo> extract(String url) async {
    final mediaHeaders = _defaultMediaHeaders(url);

    // 1. Check if the URL itself is a media file
    if (_isDirectMediaUrl(url)) {
      return _extractDirectUrl(url);
    }

    final doc = await downloadWebpageDoc(url);

    // 2. Extract Title
    String? title = ogSearchTitle(doc);
    title ??= ExtractorUtils.getMetaContent(doc, 'twitter:title');
    title ??= doc.querySelector('title')?.text;
    title ??= 'Unknown Title';

    // 3. Extract Description
    String? description = ogSearchDescription(doc);
    description ??= ExtractorUtils.getMetaContent(doc, 'twitter:description');
    description ??= ExtractorUtils.getMetaContent(doc, 'description');

    // 4. Extract Thumbnail
    String? thumbnail = ogSearchThumbnail(doc);
    thumbnail ??= ExtractorUtils.getMetaContent(doc, 'twitter:image');

    // 5. Extract Formats
    final formats = <MediaFormat>[];

    // 5a. Check OpenGraph Video
    final ogVideo = ExtractorUtils.getMetaContent(doc, 'og:video');
    if (ogVideo != null) {
      final normalized = _normalizeExtractedUrl(ogVideo);
      final height = _inferHeightFromUrl(normalized);
      final bitrate = _inferBitrateKbpsFromUrl(normalized);
      formats.add(MediaFormat(
        url: normalized,
        formatId: 'og_video',
        ext: ExtractorUtils.determineExt(normalized),
        height: height,
        quality: height,
        bitrate: bitrate,
        httpHeaders: mediaHeaders,
      ));
    }
    
    final ogVideoSecure = ExtractorUtils.getMetaContent(doc, 'og:video:secure_url');
    if (ogVideoSecure != null && ogVideoSecure != ogVideo) {
      final normalized = _normalizeExtractedUrl(ogVideoSecure);
      final height = _inferHeightFromUrl(normalized);
      final bitrate = _inferBitrateKbpsFromUrl(normalized);
      formats.add(MediaFormat(
        url: normalized,
        formatId: 'og_video_secure',
        ext: ExtractorUtils.determineExt(normalized),
        height: height,
        quality: height,
        bitrate: bitrate,
        httpHeaders: mediaHeaders,
      ));
    }

    // 5b. Check Twitter Player
    final twitterStream = ExtractorUtils.getMetaContent(doc, 'twitter:player:stream');
    if (twitterStream != null) {
       final normalized = _normalizeExtractedUrl(twitterStream);
       final height = _inferHeightFromUrl(normalized);
       final bitrate = _inferBitrateKbpsFromUrl(normalized);
       formats.add(MediaFormat(
        url: normalized,
        formatId: 'twitter_stream',
        ext: ExtractorUtils.determineExt(normalized),
        height: height,
        quality: height,
        bitrate: bitrate,
        httpHeaders: mediaHeaders,
      ));
    }

    // 5c. Check HTML5 <video> and <audio> tags
    formats.addAll(_extractHtml5Media(doc, url, mediaHeaders));

    // 5d. Check common iframe embeds (basic support)
    // Many sites use iframes to embed players. If we find a src that looks like a video URL, take it.
    // Or if it looks like a supported site (e.g. PornHub embed), we could return that URL as a 'resource'.
    // For now, we'll just check if iframe src ends in media extension.
    for (final iframe in doc.querySelectorAll('iframe')) {
      final src = iframe.attributes['src'];
      if (src != null && _isDirectMediaUrl(src)) {
         final absUrl = _normalizeExtractedUrl(ExtractorUtils.urlJoin(url, src));
         final height = _inferHeightFromUrl(absUrl);
         final bitrate = _inferBitrateKbpsFromUrl(absUrl);
         formats.add(MediaFormat(
          url: absUrl,
          formatId: 'iframe_src',
          ext: ExtractorUtils.determineExt(absUrl),
          height: height,
          quality: height,
          bitrate: bitrate,
          httpHeaders: mediaHeaders,
        ));
      }
    }

    // 5e. Regex Scan for common media patterns in page content
    // Scans for http/https URLs ending in media extensions inside scripts or JSON blobs
    final mediaRegex = RegExp(r'''https?://[^"'\s]+\.(?:mp4|m3u8|mpd|flv|webm|mov|mkv)(?:[\?&][^"'\s]*)?''');
    final matches = mediaRegex.allMatches(doc.outerHtml); // Scan full HTML
    final uniqueUrls = <String>{};
    for (final match in matches) {
      final matchUrl = match.group(0);
      if (matchUrl != null) {
        final normalized = _normalizeExtractedUrl(matchUrl);
        if (uniqueUrls.contains(normalized)) {
          continue;
        }
        uniqueUrls.add(normalized);
        
        // Basic filtering to avoid junk
        if (normalized.contains('googleads') || normalized.contains('analytics')) continue;

        final height = _inferHeightFromUrl(normalized);
        final bitrate = _inferBitrateKbpsFromUrl(normalized);
        formats.add(MediaFormat(
          url: normalized,
          formatId: 'regex_match',
          ext: ExtractorUtils.determineExt(normalized),
          height: height,
          quality: height,
          bitrate: bitrate,
          httpHeaders: mediaHeaders,
        ));
      }
    }

    final escapedMediaRegex = RegExp(
      r'''https?:\\/\\/[^"'\s]+\\.(?:mp4|m3u8|mpd|flv|webm|mov|mkv)(?:\\?[^"'\s]*)?''',
    );
    final escapedMatches = escapedMediaRegex.allMatches(doc.outerHtml);
    for (final match in escapedMatches) {
      final raw = match.group(0);
      if (raw == null) continue;
      final normalized = _normalizeExtractedUrl(raw);
      if (normalized.contains('googleads') || normalized.contains('analytics')) continue;
      if (uniqueUrls.add(normalized)) {
        final height = _inferHeightFromUrl(normalized);
        final bitrate = _inferBitrateKbpsFromUrl(normalized);
        formats.add(MediaFormat(
          url: normalized,
          formatId: 'regex_match_escaped',
          ext: ExtractorUtils.determineExt(normalized),
          height: height,
          quality: height,
          bitrate: bitrate,
          httpHeaders: mediaHeaders,
        ));
      }
    }

    final protoRelativeMediaRegex = RegExp(
      r'''(?<!:)//[^"'\s]+\.(?:mp4|m3u8|mpd|flv|webm|mov|mkv)(?:[\?&][^"'\s]*)?''',
    );
    final protoMatches = protoRelativeMediaRegex.allMatches(doc.outerHtml);
    for (final match in protoMatches) {
      final raw = match.group(0);
      if (raw == null) continue;
      final normalized = _normalizeExtractedUrl(raw);
      if (normalized.contains('googleads') || normalized.contains('analytics')) continue;
      if (uniqueUrls.add(normalized)) {
        final height = _inferHeightFromUrl(normalized);
        final bitrate = _inferBitrateKbpsFromUrl(normalized);
        formats.add(MediaFormat(
          url: normalized,
          formatId: 'regex_match_proto',
          ext: ExtractorUtils.determineExt(normalized),
          height: height,
          quality: height,
          bitrate: bitrate,
          httpHeaders: mediaHeaders,
        ));
      }
    }

    final escapedProtoRelativeMediaRegex = RegExp(
      r'''(?<!:)\\/\\/[^"'\s]+\\.(?:mp4|m3u8|mpd|flv|webm|mov|mkv)(?:\\?[^"'\s]*)?''',
    );
    final escapedProtoMatches =
        escapedProtoRelativeMediaRegex.allMatches(doc.outerHtml);
    for (final match in escapedProtoMatches) {
      final raw = match.group(0);
      if (raw == null) continue;
      final normalized = _normalizeExtractedUrl(raw);
      if (normalized.contains('googleads') || normalized.contains('analytics')) continue;
      if (uniqueUrls.add(normalized)) {
        final height = _inferHeightFromUrl(normalized);
        final bitrate = _inferBitrateKbpsFromUrl(normalized);
        formats.add(MediaFormat(
          url: normalized,
          formatId: 'regex_match_proto_escaped',
          ext: ExtractorUtils.determineExt(normalized),
          height: height,
          quality: height,
          bitrate: bitrate,
          httpHeaders: mediaHeaders,
        ));
      }
    }

    // 6. JSON-LD Extraction
    final jsonLdFormats = _extractJsonLd(doc, url, mediaHeaders);
    formats.addAll(jsonLdFormats);

    if (formats.isEmpty) {
      throw ExtractionError('No media found on page');
    }

    return MediaInfo(
      id: url, // Use URL as ID for generic
      title: title,
      description: description,
      thumbnailUrl: thumbnail,
      formats: formats,
      httpHeaders: mediaHeaders,
      url: url,
    );
  }

  List<MediaFormat> _extractJsonLd(
    Document doc,
    String baseUrl,
    Map<String, String> mediaHeaders,
  ) {
    final formats = <MediaFormat>[];
    final scripts = doc.querySelectorAll('script[type="application/ld+json"]');

    for (final script in scripts) {
      try {
        final content = script.text;
        if (content.isEmpty) continue;
        
        // Basic JSON-LD parsing
        // In a real implementation, we would need a proper JSON-LD processor
        // that handles context, graph, etc.
        // Here we just look for "VideoObject" or "AudioObject".
        // We use a regex to find potential JSON blobs if the script content is messy,
        // but usually it's just JSON.
        
        // Remove comments if any (simple approach)
        final cleanContent = content.replaceAll(RegExp(r'//.*'), '');
        
        // Note: script.text from html parser usually contains the raw text
        
        // We'll try to find VideoObject in the text directly via regex or try to parse generic JSON
        // Since Dart's jsonDecode is strict, let's try to search for "contentUrl" or "embedUrl"
        
        // Simple regex search for contentUrl/embedUrl inside the script block
        // "contentUrl": "https://..."
        final urlRegex = RegExp(r'"(contentUrl|embedUrl|url)"\s*:\s*"([^"]+)"');
        final typeRegex = RegExp(r'"@type"\s*:\s*"(VideoObject|AudioObject)"');
        
        if (typeRegex.hasMatch(cleanContent)) {
          final matches = urlRegex.allMatches(cleanContent);
          for (final match in matches) {
            final url = match.group(2);
            if (url != null && _isDirectMediaUrl(url)) {
               final absUrl =
                   _normalizeExtractedUrl(ExtractorUtils.urlJoin(baseUrl, url));
               final height = _inferHeightFromUrl(absUrl);
               final bitrate = _inferBitrateKbpsFromUrl(absUrl);
               formats.add(MediaFormat(
                url: absUrl,
                formatId: 'jsonld_${match.group(1)}',
                ext: ExtractorUtils.determineExt(absUrl),
                height: height,
                quality: height,
                bitrate: bitrate,
                httpHeaders: mediaHeaders,
              ));
            }
          }
        }
      } catch (e) {
        // Ignore parsing errors for JSON-LD
        continue;
      }
    }
    return formats;
  }

  bool _isDirectMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    // Basic extensions check
    return path.endsWith('.mp4') ||
        path.endsWith('.mp3') ||
        path.endsWith('.m3u8') ||
        path.endsWith('.mpd') ||
        path.endsWith('.wav') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.flac');
  }

  MediaInfo _extractDirectUrl(String url) {
    final uri = Uri.parse(url);
    final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'media';
    
    return MediaInfo(
      id: filename,
      title: filename,
      url: url,
      formats: [
        MediaFormat(
          url: url,
          ext: ExtractorUtils.determineExt(url),
          formatId: 'direct',
          httpHeaders: _defaultMediaHeaders(url),
        )
      ],
    );
  }

  List<MediaFormat> _extractHtml5Media(
    Document doc,
    String baseUrl,
    Map<String, String> mediaHeaders,
  ) {
    final formats = <MediaFormat>[];
    
    // Check <video> tags
    for (final video in doc.querySelectorAll('video')) {
      final src = video.attributes['src'];
      if (src != null && src.isNotEmpty) {
        final absUrl =
            _normalizeExtractedUrl(ExtractorUtils.urlJoin(baseUrl, src));
        formats.add(MediaFormat(
          url: absUrl,
          formatId: 'html5_video_src',
          ext: ExtractorUtils.determineExt(absUrl),
          httpHeaders: mediaHeaders,
        ));
      }
      
      // Check <source> children
      for (final source in video.querySelectorAll('source')) {
        final src = source.attributes['src'];
        if (src != null && src.isNotEmpty) {
           final absUrl =
               _normalizeExtractedUrl(ExtractorUtils.urlJoin(baseUrl, src));
           final type = source.attributes['type'];
           // Basic mime type mapping could go here
           formats.add(MediaFormat(
            url: absUrl,
            formatId: 'html5_video_source',
            ext: ExtractorUtils.determineExt(absUrl),
            httpHeaders: {
              ...mediaHeaders,
              if (type != null && type.isNotEmpty) 'Content-Type': type,
            },
          ));
        }
      }
    }

     // Check <audio> tags (similar logic)
    for (final audio in doc.querySelectorAll('audio')) {
       final src = audio.attributes['src'];
      if (src != null && src.isNotEmpty) {
        final absUrl =
            _normalizeExtractedUrl(ExtractorUtils.urlJoin(baseUrl, src));
        formats.add(MediaFormat(
          url: absUrl,
          formatId: 'html5_audio_src',
          ext: ExtractorUtils.determineExt(absUrl),
          httpHeaders: mediaHeaders,
        ));
      }
       for (final source in audio.querySelectorAll('source')) {
        final src = source.attributes['src'];
        if (src != null && src.isNotEmpty) {
           final absUrl =
               _normalizeExtractedUrl(ExtractorUtils.urlJoin(baseUrl, src));
           formats.add(MediaFormat(
            url: absUrl,
            formatId: 'html5_audio_source',
            ext: ExtractorUtils.determineExt(absUrl),
            httpHeaders: mediaHeaders,
          ));
        }
      }
    }

    return formats;
  }
}
