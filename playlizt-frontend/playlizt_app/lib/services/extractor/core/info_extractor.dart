
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'types.dart';
import 'utils.dart';

abstract class InfoExtractor {
  final Dio _dio;

  /// The unique name of this extractor.
  String get name;
  
  InfoExtractor({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-us,en;q=0.5',
    },
    validateStatus: (status) => true, // Handle errors manually
  ));

  /// Returns true if this extractor is suitable for the given URL.
  bool suitable(String url);

  /// Extracts information from the given URL.
  Future<MediaInfo> extract(String url);

  // --- Helper Methods ---

  Future<Response<dynamic>> downloadWebpageResponse(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final options = Options(
        headers: headers,
        validateStatus: (status) => true,
      );
      final response = await _dio.get(url, options: options);
      if (response.statusCode != 200) {
        throw ExtractionError('Failed to download webpage: ${response.statusCode}');
      }
      return response;
    } catch (e) {
      throw ExtractionError('Network error: $e');
    }
  }

  Future<String> downloadWebpage(String url, {Map<String, String>? headers}) async {
    final response = await downloadWebpageResponse(url, headers: headers);
    return response.data.toString();
  }

  Future<Document> downloadWebpageDoc(String url, {Map<String, String>? headers}) async {
    final html = await downloadWebpage(url, headers: headers);
    return html_parser.parse(html);
  }

  Document docFromContent(String content) {
    return html_parser.parse(content);
  }

  // --- Common Extraction Helpers (ported from youtube-dl/common.py) ---

  String? ogSearchTitle(Document doc) {
    return ExtractorUtils.getMetaContent(doc, 'og:title');
  }

  String? ogSearchDescription(Document doc) {
    return ExtractorUtils.getMetaContent(doc, 'og:description');
  }

  String? ogSearchThumbnail(Document doc) {
    return ExtractorUtils.getMetaContent(doc, 'og:image');
  }
  
  String? ogSearchUrl(Document doc) {
    return ExtractorUtils.getMetaContent(doc, 'og:url');
  }
  
  String? htmlSearchMeta(Document doc, List<String> names) {
    for (final name in names) {
      final content = ExtractorUtils.getMetaContent(doc, name);
      if (content != null) return content;
    }
    return null;
  }
}
