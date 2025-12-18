import '../core/info_extractor.dart';
import '../core/types.dart';
import '../core/utils.dart';

class EromeIE extends InfoExtractor {
  @override
  String get name => 'Erome';

  @override
  bool suitable(String url) {
    return RegExp(r'https?://(?:www\.)?erome\.com/a/[\da-zA-Z]+').hasMatch(url);
  }

  @override
  Future<MediaInfo> extract(String url) async {
    final pageContent = await downloadWebpage(url);
    final doc = docFromContent(pageContent);

    // 1. Extract Title
    String? title = ExtractorUtils.getMetaContent(doc, 'twitter:title');
    title ??= ExtractorUtils.getMetaContent(doc, 'og:title');
    title ??= doc.querySelector('title')?.text;
    title ??= 'Erome Video';

    // 2. Extract Thumbnail
    String? thumbnail = ExtractorUtils.getMetaContent(doc, 'twitter:image');
    thumbnail ??= ExtractorUtils.getMetaContent(doc, 'og:image');

    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
      'Referer': url,
    };

    final formats = <MediaFormat>[];

    // Erome uses <source> tags directly in the HTML as seen in curl output
    final sourceTags = doc.querySelectorAll('source');
    for (final source in sourceTags) {
      final src = source.attributes['src'];
      final label = source.attributes['label']; // e.g. HD
      final res = source.attributes['res']; // e.g. 720
      
      if (src != null) {
         final absUrl = ExtractorUtils.urlJoin(url, src);
         formats.add(MediaFormat(
           url: absUrl,
           formatId: 'html5_${label ?? 'sd'}_${res ?? ''}',
           ext: 'mp4',
           quality: ExtractorUtils.intOrNone(res),
           httpHeaders: headers,
         ));
      }
    }
    
    // Also check for video tags directly
    final videoTags = doc.querySelectorAll('video');
    for (final video in videoTags) {
       final src = video.attributes['src'];
       if (src != null && src.isNotEmpty) {
          final absUrl = ExtractorUtils.urlJoin(url, src);
          formats.add(MediaFormat(
           url: absUrl,
           formatId: 'html5_video_src',
           ext: 'mp4',
           httpHeaders: headers,
         ));
       }
    }

    if (formats.isEmpty) {
      throw ExtractionError('No media found for Erome URL');
    }

    // Deduplicate formats
    final uniqueFormats = <String, MediaFormat>{};
    for (final f in formats) {
      uniqueFormats[f.url] = f;
    }

    return MediaInfo(
      id: url,
      title: title,
      thumbnailUrl: thumbnail,
      formats: uniqueFormats.values.toList(),
      url: url,
    );
  }
}
