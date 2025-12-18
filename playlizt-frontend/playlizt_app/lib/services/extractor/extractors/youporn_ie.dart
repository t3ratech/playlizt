import '../core/info_extractor.dart';
import '../core/types.dart';
import '../core/utils.dart';

class YouPornIE extends InfoExtractor {
  @override
  String get name => 'YouPorn';

  @override
  bool suitable(String url) {
    return RegExp(r'https?://(?:www\.)?youporn\.com/watch/\d+').hasMatch(url);
  }

  @override
  Future<MediaInfo> extract(String url) async {
    final headers = {
      'Cookie': 'age_verified=1; platform=pc',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
      'Referer': url,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-us,en;q=0.5',
    };

    final pageContent = await downloadWebpage(url, headers: headers);
    final doc = docFromContent(pageContent);

    String? title = ogSearchTitle(doc);
    title ??= ExtractorUtils.getMetaContent(doc, 'twitter:title');
    title ??= doc.querySelector('title')?.text;
    title ??= 'YouPorn Video';

    String? thumbnail = ogSearchThumbnail(doc);
    thumbnail ??= ExtractorUtils.getMetaContent(doc, 'twitter:image');

    final formats = <MediaFormat>[];

    final flashvarsJson = ExtractorUtils.searchRegex(
      RegExp(r'''var\s+flashvars_\d+\s*=\s*({.+?});'''),
      pageContent,
    );

    if (flashvarsJson != null) {
      final flashvars = ExtractorUtils.parseJson(flashvarsJson);
      if (flashvars is Map) {
        final mediaDefinitions = flashvars['mediaDefinitions'];
        if (mediaDefinitions is List) {
          for (final def in mediaDefinitions) {
            if (def is! Map) continue;
            final videoUrl = def['videoUrl'];
            if (videoUrl is! String || videoUrl.isEmpty) continue;

            final format = def['format'];
            final qualityValue = def['quality'];
            final quality = ExtractorUtils.intOrNone(qualityValue);

            var resolvedUrl = videoUrl.replaceAll('&amp;', '&');
            if (resolvedUrl.startsWith('//')) {
              resolvedUrl = 'https:$resolvedUrl';
            }

            final isHls =
                (format is String && format.toLowerCase() == 'hls') ||
                    resolvedUrl.contains('.m3u8');

            if (!isHls && resolvedUrl.toLowerCase().contains('_fb.mp4')) {
              continue;
            }

            formats.add(
              MediaFormat(
                url: resolvedUrl,
                formatId: isHls ? 'hls_${quality ?? ''}' : 'http_${quality ?? ''}',
                ext: isHls ? 'm3u8' : 'mp4',
                height: quality,
                quality: quality,
                httpHeaders: headers,
              ),
            );
          }
        }
      }
    }

    if (formats.isEmpty) {
      final regex = RegExp(
        r'''https?://[^"'\s]+\.(?:mp4|m3u8)(?:[\?&][^"'\s]*)?''',
      );
      final unique = <String>{};
      for (final match in regex.allMatches(pageContent)) {
        final raw = match.group(0);
        if (raw == null) continue;
        var resolvedUrl = raw.replaceAll('&amp;', '&');
        if (resolvedUrl.startsWith('//')) {
          resolvedUrl = 'https:$resolvedUrl';
        }
        if (resolvedUrl.toLowerCase().contains('_fb.mp4')) {
          continue;
        }
        if (!unique.add(resolvedUrl)) continue;

        final ext = ExtractorUtils.determineExt(resolvedUrl);
        final isHls = (ext ?? '').toLowerCase() == 'm3u8' ||
            Uri.tryParse(resolvedUrl)?.path.toLowerCase().endsWith('.m3u8') ==
                true;

        formats.add(
          MediaFormat(
            url: resolvedUrl,
            formatId: isHls ? 'hls' : 'http',
            ext: isHls ? 'm3u8' : 'mp4',
            httpHeaders: headers,
          ),
        );
      }
    }

    if (formats.isEmpty) {
      throw ExtractionError('No media found for YouPorn URL');
    }

    return MediaInfo(
      id: url,
      title: title,
      thumbnailUrl: thumbnail,
      formats: formats,
      url: url,
      httpHeaders: headers,
    );
  }
}
