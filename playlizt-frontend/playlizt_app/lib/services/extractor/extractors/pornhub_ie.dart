import 'package:dio/dio.dart';
import '../core/info_extractor.dart';
import '../core/types.dart';
import '../core/utils.dart';

class PornHubIE extends InfoExtractor {
  @override
  String get name => 'PornHub';

  @override
  bool suitable(String url) {
    return RegExp(r'https?://(?:www\.)?pornhub\.(?:com|net|org)/view_video\.php\?viewkey=[\da-z]+').hasMatch(url);
  }

  @override
  Future<MediaInfo> extract(String url) async {
    // Add cookies to help with age verification and platform detection
    final pageHeaders = {
      'Cookie': 'age_verified=1; platform=pc',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
      'Referer': url,
    };

    final pageContent = await downloadWebpage(url, headers: pageHeaders);

    // 1. Extract Title
    String? title = ExtractorUtils.getMetaContent(docFromContent(pageContent), 'twitter:title');
    title ??= ExtractorUtils.searchRegex(
      RegExp(r'''<h1[^>]+class=["']title["'][^>]*>(.+?)</h1>'''),
      pageContent,
    );
    title ??= 'PornHub Video';

    // 2. Extract Thumbnail
    String? thumbnail = ExtractorUtils.getMetaContent(docFromContent(pageContent), 'twitter:image');
    thumbnail ??= ExtractorUtils.searchRegex(
      RegExp(r'''"image_url"\s*:\s*"([^"]+)"'''),
      pageContent,
    );

    // 3. Extract Flashvars
    final flashvarsJson = ExtractorUtils.searchRegex(
      RegExp(r'''var\s+flashvars_\d+\s*=\s*({.+?});'''),
      pageContent,
    );

    final formats = <MediaFormat>[];

    // Common headers
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
      'Referer': url,
      'Cookie': 'age_verified=1; platform=pc',
    };

    if (flashvarsJson != null) {
      final flashvars = ExtractorUtils.parseJson(flashvarsJson);
      if (flashvars != null && flashvars is Map) {
        // Debug log
        // print('PornHubIE: Flashvars parsed successfully');
        
        // mediaDefinitions
        final mediaDefinitions = flashvars['mediaDefinitions'];
        if (mediaDefinitions is List) {
          // print('PornHubIE: Found ${mediaDefinitions.length} mediaDefinitions');
          for (final def in mediaDefinitions) {
            if (def is Map) {
              final videoUrl = def['videoUrl'];
              // print('PornHubIE: Found videoUrl: $videoUrl');
              if (videoUrl != null && videoUrl is String && videoUrl.isNotEmpty) {
                final format = def['format']; // 'mp4', 'hls', etc.
                final quality = def['quality']; // [1080, 720, etc] or string
                
                await _addFormat(
                  formats,
                  videoUrl,
                  quality,
                  headers,
                  format: format is String ? format : null,
                );
              }
            }
          }
        }
      }
    }

    final getMediaUrlRegex =
        RegExp(r'''https?://[^"'\s]+/video/get_media[^"'\s]+''');
    for (final match in getMediaUrlRegex.allMatches(pageContent)) {
      final candidate = match.group(0);
      if (candidate == null || candidate.isEmpty) continue;
      await _addFormat(formats, candidate, null, headers);
    }

    final getMediaUrlEscapedRegex =
        RegExp(r'''https?:\\/\\/[^"'\s]+\\/video\\/get_media[^"'\s]+''');
    for (final match in getMediaUrlEscapedRegex.allMatches(pageContent)) {
      final raw = match.group(0);
      if (raw == null || raw.isEmpty) continue;
      final candidate = raw.replaceAll(r'\/', '/');
      await _addFormat(formats, candidate, null, headers);
    }

    final getMediaRelativeRegex =
        RegExp(r'''(?:^|["'])(/video/get_media[^"'\s]+)''');
    for (final match in getMediaRelativeRegex.allMatches(pageContent)) {
      final rel = match.group(1);
      if (rel == null || rel.isEmpty) continue;
      final candidate = 'https://www.pornhub.com$rel';
      await _addFormat(formats, candidate, null, headers);
    }

    // Fallback: JS vars extraction if flashvars failed or empty
    final hasDirect = formats.any(
      (f) => (f.ext ?? '').toLowerCase() != 'm3u8',
    );
    if (formats.isEmpty || !hasDirect) {
      // Look for quality items in JS
      // Generic regex for quality items
      // var quality_720p = "https://...";
      final qualityMatches = RegExp(r'var\s+quality_(\d+[pP]?)\s*=\s*"([^"]+)";').allMatches(pageContent);
      for (final match in qualityMatches) {
        final quality = match.group(1);
        final videoUrl = match.group(2);
        if (videoUrl != null) {
           await _addFormat(formats, videoUrl, quality?.replaceAll('p', ''), headers);
        }
      }
    }

    // 4. Extract Download Buttons (often contain direct MP4s)
    // Note: Dart RegExp doesn't support Python-style named groups like (?P<name>...) in all versions/platforms easily.
    // We use a simpler regex that captures the URL.
    final downloadRegex = RegExp(r'<a[^>]+\bclass=["'']downloadBtn\b[^>]+\bhref=["'']([^"''\s]+)["'']');
    final downloadMatches = downloadRegex.allMatches(pageContent);
    for (final match in downloadMatches) {
      final videoUrl = match.group(1);
      if (videoUrl != null && videoUrl.isNotEmpty) {
         // Usually we don't know quality from the button text easily without parsing inner text
         // But we can try to guess or just add it.
         // Often the URL itself might have info, or we treat it as unknown quality.
         await _addFormat(formats, videoUrl, null, headers);
      }
    }

    if (formats.isEmpty) {
      throw ExtractionError('No media found for PornHub URL');
    }
    
    // Debug: Log found formats
    print('PornHubIE: Found ${formats.length} formats:');
    for (final f in formats) {
      print(' - ${f.formatId}: ${f.ext}, ${f.url.substring(0, f.url.length > 50 ? 50 : f.url.length)}...');
    }

    return MediaInfo(
      id: url,
      title: title,
      thumbnailUrl: thumbnail,
      formats: formats,
      url: url,
    );
  }

  Future<bool> _isProbablyDownloadableMp4(
    String url,
    Map<String, String> headers,
  ) async {
    final probeHeaders = {
      ...headers,
      'Range': 'bytes=0-0',
    };

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          validateStatus: (_) => true,
        ),
      );
      final resp = await dio.get(
        url,
        options: Options(
          headers: probeHeaders,
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      final status = resp.statusCode ?? 0;
      if (status != 200 && status != 206) return false;

      final ct = (resp.headers.value('content-type') ?? '').toLowerCase();
      if (ct.contains('text/html') || ct.contains('application/xhtml+xml')) {
        return false;
      }

      final data = resp.data;
      if (data is List<int> && data.isNotEmpty && data.first == 0x3c) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _addFormat(
    List<MediaFormat> formats, 
    String videoUrl, 
    dynamic quality, 
    Map<String, String> headers, 
    {String? format}
  ) async {
    // Skip if videoUrl is invalid or empty
    if (videoUrl.isEmpty) return;

    if (videoUrl.startsWith('//')) {
      videoUrl = 'https:$videoUrl';
    }

    videoUrl = videoUrl.replaceAll('&amp;', '&');

    // Handle get_media URL (API call) - Resolve it recursively
    if (videoUrl.contains('/video/get_media')) {
      try {
        final jsonStr = await downloadWebpage(videoUrl, headers: headers);
        final parsed = ExtractorUtils.parseJson(jsonStr);

        dynamic medias;
        if (parsed is List) {
          medias = parsed;
        } else if (parsed is Map) {
          medias = parsed['media'] ?? parsed['data'];
        }

        if (medias is List) {
          for (final media in medias) {
            if (media is! Map) continue;
            final realUrl = media['videoUrl'] ?? media['url'];
            final q = media['quality'];
            final fmt = media['format'];
            if (realUrl is String && realUrl.isNotEmpty) {
              await _addFormat(formats, realUrl, q, headers, format: fmt is String ? fmt : null);
            }
          }
        }
      } catch (e) {
        // print('PornHubIE: Failed to fetch get_media: $e');
      }
      return;
    }

    if (format == 'hls' || videoUrl.contains('.m3u8')) {
      final uri = Uri.tryParse(videoUrl);
      if (uri != null && uri.path.endsWith('/master.m3u8')) {
        final mp4Uri = uri.replace(
          path: uri.path.substring(0, uri.path.length - '/master.m3u8'.length),
        );
        final mp4Url = mp4Uri.toString();
        if (await _isProbablyDownloadableMp4(mp4Url, headers)) {
          formats.add(MediaFormat(
            url: mp4Url,
            formatId: 'http_$quality',
            ext: 'mp4',
            quality: ExtractorUtils.intOrNone(quality),
            httpHeaders: headers,
          ));
        }
      }

      formats.add(MediaFormat(
        url: videoUrl,
        formatId: 'hls_$quality',
        ext: 'm3u8', // Correctly identify as HLS
        quality: ExtractorUtils.intOrNone(quality),
        httpHeaders: headers,
      ));
    } else {
      formats.add(MediaFormat(
        url: videoUrl,
        formatId: 'http_$quality',
        ext: 'mp4',
        quality: ExtractorUtils.intOrNone(quality),
        httpHeaders: headers,
      ));
    }
  }
}
