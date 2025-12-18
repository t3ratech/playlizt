import '../core/info_extractor.dart';
import '../core/types.dart';
import '../core/utils.dart';
import 'package:dio/dio.dart';

class PerfectGirlsIE extends InfoExtractor {
  @override
  String get name => 'PerfectGirls';

  @override
  bool suitable(String url) {
    return RegExp(r'https?://(?:www\.)?perfectgirls\.xxx/video/\d+/').hasMatch(url);
  }

  @override
  Future<MediaInfo> extract(String url) async {
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
      'Referer': url,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Upgrade-Insecure-Requests': '1',
    };

    final pageResponse = await downloadWebpageResponse(url, headers: headers);
    _mergeSetCookiesIntoHeaders(headers, pageResponse);
    final pageContent = pageResponse.data.toString();
    _mergeHtmlCookiesIntoHeaders(headers, pageContent);
    final doc = docFromContent(pageContent);

    // 1. Extract Title
    String? title = ExtractorUtils.getMetaContent(doc, 'og:title');
    title ??= doc.querySelector('title')?.text;
    title ??= 'PerfectGirls Video';

    // 2. Extract Thumbnail
    String? thumbnail = ExtractorUtils.getMetaContent(doc, 'og:image');

    final formats = <MediaFormat>[];

    // 3. Try to find direct video links in script tags or generic sources
    // PerfectGirls often puts video links in standard HTML5 video tags or specific JS variables
    // Based on curl output, it uses JSON-LD which points to an embed URL.
    
    // Look for "video_url" or similar in JS (on main page)
    final videoUrlMatch = ExtractorUtils.searchRegex(
      RegExp(r"video_url\s*:\s*'([^']+)'"),
      pageContent,
    );
    
    if (videoUrlMatch != null) {
      final candidate = ExtractorUtils.urlJoin(url, videoUrlMatch);
      final resolved = await _resolveWrappedMp4(candidate, headers);
      formats.add(MediaFormat(
        url: resolved,
        formatId: 'js_video_url',
        ext: 'mp4',
        httpHeaders: headers,
      ));
    }

    // JSON-LD Embed extraction
    final scripts = doc.querySelectorAll('script[type="application/ld+json"]');
    for (final script in scripts) {
      try {
        final json = ExtractorUtils.parseJson(script.text);
        if (json != null && (json['@type'] == 'VideoObject')) {
           final embedUrl = json['embedUrl'];
           if (embedUrl != null && embedUrl is String) {
             final embedUrlAbs = ExtractorUtils.urlJoin(url, embedUrl);

             // Fetch embed page
             final embedHeaders = {
               ...headers,
               'Referer': url,
             };
            final embedResponse =
                await downloadWebpageResponse(embedUrlAbs, headers: embedHeaders);
            _mergeSetCookiesIntoHeaders(headers, embedResponse);
            final embedContent = embedResponse.data.toString();
            _mergeHtmlCookiesIntoHeaders(headers, embedContent);
             
             // Extract video_url from embed
             final embedVideoUrl = ExtractorUtils.searchRegex(
                RegExp(r"video_url\s*:\s*'([^']+)'"),
                embedContent,
             );
             if (embedVideoUrl != null) {
                final candidate = ExtractorUtils.urlJoin(embedUrlAbs, embedVideoUrl);
                final embedMediaHeaders = {
                  ...headers,
                };
                final resolvedVideoUrl =
                    await _resolveWrappedMp4(candidate, embedMediaHeaders);
                formats.add(MediaFormat(
                  url: resolvedVideoUrl,
                  formatId: 'embed_js_video',
                  ext: 'mp4',
                  httpHeaders: embedMediaHeaders,
                ));
             }
             
             // Also check for standard video tags in embed
             final embedDoc = docFromContent(embedContent);
             final embedVideoTags = embedDoc.querySelectorAll('video source');
             for (final source in embedVideoTags) {
                final src = source.attributes['src'];
                if (src != null) {
                   final candidate = ExtractorUtils.urlJoin(embedUrlAbs, src);
                   final embedMediaHeaders = {
                     ...headers,
                     'Referer': url,
                   };
                   final absUrl =
                       await _resolveWrappedMp4(candidate, embedMediaHeaders);
                  formats.add(MediaFormat(
                    url: absUrl,
                    formatId: 'embed_html5_source',
                    ext: 'mp4',
                    httpHeaders: embedMediaHeaders,
                  ));
                }
             }
           }
        }
      } catch (_) {
        // Ignore json parsing errors
      }
    }

    // Also check for <a href="...">Download</a> links which are common
    final downloadLinks = doc.querySelectorAll('a[href*=".mp4"]');
    for (final link in downloadLinks) {
       final href = link.attributes['href'];
       if (href != null) {
        final candidate = ExtractorUtils.urlJoin(url, href);
        final absUrl = await _resolveWrappedMp4(candidate, headers);
        formats.add(MediaFormat(
          url: absUrl,
          formatId: 'download_link',
          ext: 'mp4',
          httpHeaders: headers,
         ));
       }
    }

    // Generic HTML5 check (main page)
    final videoTags = doc.querySelectorAll('video source');
    for (final source in videoTags) {
      final src = source.attributes['src'];
      if (src != null) {
         final candidate = ExtractorUtils.urlJoin(url, src);
         final absUrl = await _resolveWrappedMp4(candidate, headers);
         formats.add(MediaFormat(
           url: absUrl,
           formatId: 'html5_source',
           ext: 'mp4',
           httpHeaders: headers,
         ));
      }
    }

    if (formats.isEmpty) {
        // If still empty, try to fetch the embed URL if found in JSON-LD
        // Not implemented here to keep it simple, but we could recursively extract.
        throw ExtractionError('No media found for PerfectGirls URL');
    }

    return MediaInfo(
      id: url,
      title: title,
      thumbnailUrl: thumbnail,
      formats: formats,
      url: url,
    );
  }

  String _normalizeMediaUrl(String candidate) {
    final lower = candidate.toLowerCase();
    if (!lower.contains('/embed/function/')) {
      return _normalizeExtensionSlash(candidate);
    }

    // These wrapper URLs often look like:
    // https://host/embed/function/0/https://host/get_file/.../video.mp4/?...
    // We want the *inner* URL (second http(s) occurrence).
    final wrapperIndex = lower.indexOf('/embed/function/');
    final searchFrom = wrapperIndex == -1 ? 0 : wrapperIndex + '/embed/function/'.length;

    final innerHttpsIndex = candidate.indexOf('https://', searchFrom);
    final innerHttpIndex = candidate.indexOf('http://', searchFrom);
    int innerStartIndex = -1;
    if (innerHttpsIndex >= 0 && innerHttpIndex >= 0) {
      innerStartIndex = innerHttpsIndex < innerHttpIndex ? innerHttpsIndex : innerHttpIndex;
    } else if (innerHttpsIndex >= 0) {
      innerStartIndex = innerHttpsIndex;
    } else if (innerHttpIndex >= 0) {
      innerStartIndex = innerHttpIndex;
    }

    if (innerStartIndex >= 0) {
      return _normalizeExtensionSlash(candidate.substring(innerStartIndex));
    }

    // Fallback: last occurrence in entire string.
    final lastHttps = candidate.lastIndexOf('https://');
    final lastHttp = candidate.lastIndexOf('http://');
    final last = lastHttps > lastHttp ? lastHttps : lastHttp;
    if (last > 0) {
      return _normalizeExtensionSlash(candidate.substring(last));
    }

    return _normalizeExtensionSlash(candidate);
  }

  String _normalizeExtensionSlash(String url) {
    return url;
  }

  void _mergeSetCookiesIntoHeaders(
    Map<String, String> headers,
    Response<dynamic> response,
  ) {
    final setCookies = response.headers['set-cookie'];
    if (setCookies == null || setCookies.isEmpty) return;

    final existingCookie = headers['Cookie'] ?? headers['cookie'];
    final cookieMap = <String, String>{};

    if (existingCookie != null && existingCookie.trim().isNotEmpty) {
      final parts = existingCookie.split(';');
      for (final part in parts) {
        final kv = part.trim();
        if (kv.isEmpty) continue;
        final idx = kv.indexOf('=');
        if (idx <= 0) continue;
        cookieMap[kv.substring(0, idx).trim()] = kv.substring(idx + 1).trim();
      }
    }

    for (final setCookie in setCookies) {
      final nv = setCookie.split(';').first.trim();
      final idx = nv.indexOf('=');
      if (idx <= 0) continue;
      cookieMap[nv.substring(0, idx).trim()] = nv.substring(idx + 1).trim();
    }

    final cookieHeader = cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
    if (cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }
  }

  void _ensureCookie(Map<String, String> headers, String name, String value) {
    final existingCookie = headers['Cookie'] ?? headers['cookie'] ?? '';
    final cookieMap = <String, String>{};
    if (existingCookie.trim().isNotEmpty) {
      for (final part in existingCookie.split(';')) {
        final kv = part.trim();
        if (kv.isEmpty) continue;
        final idx = kv.indexOf('=');
        if (idx <= 0) continue;
        cookieMap[kv.substring(0, idx).trim()] = kv.substring(idx + 1).trim();
      }
    }

    cookieMap.putIfAbsent(name, () => value);
    headers['Cookie'] = cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  void _mergeHtmlCookiesIntoHeaders(Map<String, String> headers, String html) {
    final cookieMap = <String, String>{};

    final existingCookie = headers['Cookie'] ?? headers['cookie'];
    if (existingCookie != null && existingCookie.trim().isNotEmpty) {
      final parts = existingCookie.split(';');
      for (final part in parts) {
        final kv = part.trim();
        if (kv.isEmpty) continue;
        final idx = kv.indexOf('=');
        if (idx <= 0) continue;
        cookieMap[kv.substring(0, idx).trim()] = kv.substring(idx + 1).trim();
      }
    }

    final matches = RegExp(
      "document\\.cookie\\s*=\\s*(?:'([^']+)'|\\\"([^\\\"]+)\\\")",
      caseSensitive: false,
    ).allMatches(html);

    for (final m in matches) {
      final raw = (m.group(1) ?? m.group(2) ?? '').trim();
      if (raw.isEmpty) continue;
      final nv = raw.split(';').first.trim();
      final idx = nv.indexOf('=');
      if (idx <= 0) continue;
      cookieMap[nv.substring(0, idx).trim()] = nv.substring(idx + 1).trim();
    }

    final cookieHeader = cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
    if (cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }
  }

  String _unescapeWrapperContent(String input) {
    var out = input.replaceAll('&amp;', '&');

    out = out.replaceAll(r'\u002F', '/');
    out = out.replaceAll(r'\u0026', '&');
    out = out.replaceAll(r'\/', '/');

    out = out.replaceAllMapped(RegExp(r'\\x([0-9A-Fa-f]{2})'), (m) {
      final code = int.parse(m.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });
    out = out.replaceAllMapped(RegExp(r'\\x([0-9A-Fa-f]{2})'), (m) {
      final code = int.parse(m.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    out = out.replaceAll('\\', '');

    return out;
  }

  String _normalizeDirectMp4Url(String url) {
    return url;
  }

  Future<bool> _isProbablyDownloadableMp4(
    String url,
    Map<String, String> headers, {
    String? refererOverride,
  }) async {
    try {
      final probeHeaders = <String, String>{
        ...headers,
        if (refererOverride != null) 'Referer': refererOverride,
        'Range': 'bytes=0-0',
      };

      final resp = await Dio().get<List<int>>(
        url,
        options: Options(
          headers: probeHeaders,
          followRedirects: true,
          validateStatus: (status) => true,
          responseType: ResponseType.bytes,
        ),
      );

      final status = resp.statusCode ?? 0;
      if (!(status == 200 || status == 206)) {
        return false;
      }

      final ct = (resp.headers.value('content-type') ?? '').toLowerCase();
      if (ct.contains('text/html') || ct.contains('application/xhtml+xml')) {
        return false;
      }

      final bytes = resp.data;
      if (bytes != null && bytes.isNotEmpty) {
        // HTML error pages typically start with '<'
        if (bytes.first == 0x3c) {
          return false;
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _resolveWrappedMp4(
    String candidate,
    Map<String, String> headers,
  ) async {
    if (!candidate.toLowerCase().contains('/embed/function/')) {
      return candidate;
    }

    try {
      Future<String> fetchDecodedWrapper() async {
        final wrapperHeaders = <String, String>{
          ...headers,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        };
        final wrapperResponse =
            await downloadWebpageResponse(candidate, headers: wrapperHeaders);
        _mergeSetCookiesIntoHeaders(headers, wrapperResponse);
        final wrapperContent = wrapperResponse.data.toString();
        final decoded = _unescapeWrapperContent(wrapperContent);
        _mergeHtmlCookiesIntoHeaders(headers, decoded);
        return decoded;
      }

      var decoded = await fetchDecodedWrapper();
      if (decoded.toLowerCase().contains('you are not allowed to watch this video')) {
        // Common KVS gating cookie (terms accepted)
        _ensureCookie(headers, 'kt_tcookie', '1');
        _ensureCookie(headers, 'kt_is_visited', '1');
        _ensureCookie(headers, 'kt_is_adult', '1');
        decoded = await fetchDecodedWrapper();
      }

      final inner = _normalizeDirectMp4Url(_normalizeMediaUrl(candidate));
      if (inner.isNotEmpty && inner != candidate) {
        final okDefault = await _isProbablyDownloadableMp4(inner, headers);
        if (okDefault) return inner;

        final okWithWrapperReferer = await _isProbablyDownloadableMp4(
          inner,
          headers,
          refererOverride: candidate,
        );
        if (okWithWrapperReferer) {
          headers['Referer'] = candidate;
          return inner;
        }
      }

      final percentEncodedRe = RegExp(
        "https%3A%2F%2F[^\\s\"']+%2Emp4[^\\s\"']*",
        caseSensitive: false,
      );
      final percentMatch = percentEncodedRe.firstMatch(decoded);
      final encoded = percentMatch?.group(0);
      if (encoded != null && encoded.isNotEmpty) {
        final resolved = _normalizeDirectMp4Url(Uri.decodeFull(encoded));
        final okDefault = await _isProbablyDownloadableMp4(resolved, headers);
        if (okDefault) return resolved;

        final okWithWrapperReferer = await _isProbablyDownloadableMp4(
          resolved,
          headers,
          refererOverride: candidate,
        );
        if (okWithWrapperReferer) {
          headers['Referer'] = candidate;
          return resolved;
        }
      }

      final absoluteRe = RegExp(
        "https?://[^\\s\"']+\\.mp4[^\\s\"']*",
        caseSensitive: false,
      );
      final absoluteMatch = absoluteRe.firstMatch(decoded);
      final absolute = absoluteMatch?.group(0);
      if (absolute != null && absolute.isNotEmpty) {
        final resolved = _normalizeDirectMp4Url(absolute);
        final okDefault = await _isProbablyDownloadableMp4(resolved, headers);
        if (okDefault) return resolved;

        final okWithWrapperReferer = await _isProbablyDownloadableMp4(
          resolved,
          headers,
          refererOverride: candidate,
        );
        if (okWithWrapperReferer) {
          headers['Referer'] = candidate;
          return resolved;
        }
      }

      final protocolRelativeRe = RegExp(
        "//[^\\s\"']+\\.mp4[^\\s\"']*",
        caseSensitive: false,
      );
      final prMatch = protocolRelativeRe.firstMatch(decoded);
      final pr = prMatch?.group(0);
      if (pr != null && pr.isNotEmpty) {
        final resolved = _normalizeDirectMp4Url('https:$pr');
        final okDefault = await _isProbablyDownloadableMp4(resolved, headers);
        if (okDefault) return resolved;

        final okWithWrapperReferer = await _isProbablyDownloadableMp4(
          resolved,
          headers,
          refererOverride: candidate,
        );
        if (okWithWrapperReferer) {
          headers['Referer'] = candidate;
          return resolved;
        }
      }

      final relativeRe = RegExp(
        "(/get_file/[^\\s\"']+\\.mp4[^\\s\"']*)",
        caseSensitive: false,
      );
      final relativeMatch = relativeRe.firstMatch(decoded);
      final relative = relativeMatch?.group(1);
      if (relative != null && relative.isNotEmpty) {
        final resolved =
            _normalizeDirectMp4Url(ExtractorUtils.urlJoin(candidate, relative));
        final okDefault = await _isProbablyDownloadableMp4(resolved, headers);
        if (okDefault) return resolved;

        final okWithWrapperReferer = await _isProbablyDownloadableMp4(
          resolved,
          headers,
          refererOverride: candidate,
        );
        if (okWithWrapperReferer) {
          headers['Referer'] = candidate;
          return resolved;
        }
      }

      final getFileRe = RegExp(
        "(/get_file/[^\\s\"']+)",
        caseSensitive: false,
      );
      final getFileMatch = getFileRe.firstMatch(decoded);
      final getFile = getFileMatch?.group(1);
      if (getFile != null && getFile.isNotEmpty) {
        final resolved = _normalizeDirectMp4Url(ExtractorUtils.urlJoin(candidate, getFile));
        final okDefault = await _isProbablyDownloadableMp4(resolved, headers);
        if (okDefault) return resolved;

        final okWithWrapperReferer = await _isProbablyDownloadableMp4(
          resolved,
          headers,
          refererOverride: candidate,
        );
        if (okWithWrapperReferer) {
          headers['Referer'] = candidate;
          return resolved;
        }
      }
    } catch (_) {
      // ignore
    }

    // As a last resort, keep the wrapper URL (it might still be downloadable)
    // rather than unwrapping to a potentially 404 get_file URL.
    return candidate;
  }
}
