
import '../core/info_extractor.dart';
import '../core/types.dart';
import '../core/utils.dart';

/// A specialized extractor that matches URLs based on regex patterns.
/// This is useful for simple sites or "porn" sites that often have
/// very predictable URL structures or simple inline video definitions.
class PatternMatchingExtractor extends InfoExtractor {
  final String _name;
  final List<RegExp> _urlPatterns;
  final RegExp? _videoUrlPattern;
  final RegExp? _titlePattern;
  final RegExp? _thumbnailPattern;

  PatternMatchingExtractor({
    required String name,
    required List<String> urlPatterns,
    String? videoUrlPattern,
    String? titlePattern,
    String? thumbnailPattern,
  })  : _name = name,
        _urlPatterns = urlPatterns.map((p) => RegExp(p)).toList(),
        _videoUrlPattern = videoUrlPattern != null ? RegExp(videoUrlPattern) : null,
        _titlePattern = titlePattern != null ? RegExp(titlePattern) : null,
        _thumbnailPattern = thumbnailPattern != null ? RegExp(thumbnailPattern) : null;

  @override
  String get name => _name;

  @override
  bool suitable(String url) {
    return _urlPatterns.any((p) => p.hasMatch(url));
  }

  @override
  Future<MediaInfo> extract(String url) async {
    final pageContent = await downloadWebpage(url);

    // Extract Video URL
    String? videoUrl;
    if (_videoUrlPattern != null) {
      videoUrl = ExtractorUtils.searchRegex(_videoUrlPattern!, pageContent);
    }
    
    // Fallback: Try generic methods if specific pattern fails
    // or if we want to combine them.
    // For this simple implementation, if pattern fails, we throw.
    
    if (videoUrl == null) {
      // Try to find common patterns like .mp4 inside quotes
      final commonMp4 = RegExp(r'["\x27](https?://[^"\x27]+\.mp4)["\x27]');
      videoUrl = ExtractorUtils.searchRegex(commonMp4, pageContent);
    }

    if (videoUrl == null) {
      throw ExtractionError('Could not find video URL matching pattern');
    }

    videoUrl = ExtractorUtils.urlJoin(url, videoUrl);

    // Extract Title
    String? title;
    if (_titlePattern != null) {
      title = ExtractorUtils.searchRegex(_titlePattern!, pageContent);
    }
    // Fallback title extraction
    if (title == null) {
      final titleRe = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false);
      title = ExtractorUtils.searchRegex(titleRe, pageContent)?.trim();
    }
    
    // Extract Thumbnail
    String? thumbnail;
    if (_thumbnailPattern != null) {
      thumbnail = ExtractorUtils.searchRegex(_thumbnailPattern!, pageContent);
    }

    return MediaInfo(
      id: url,
      title: title ?? 'Unknown Title',
      url: url,
      thumbnailUrl: thumbnail,
      formats: [
        MediaFormat(
          url: videoUrl,
          ext: ExtractorUtils.determineExt(videoUrl),
          formatId: 'pattern_match',
        )
      ],
    );
  }
}
