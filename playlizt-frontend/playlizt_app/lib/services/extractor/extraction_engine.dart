
import 'package:flutter/foundation.dart';
import 'core/info_extractor.dart';
import 'core/types.dart';
import 'extractors/erome_ie.dart';
import 'extractors/generic_ie.dart';
import 'extractors/pattern_matching_extractor.dart';
import 'extractors/perfect_girls_ie.dart';
import 'extractors/pornhub_ie.dart';
import 'extractors/youporn_ie.dart';

class ExtractionEngine {
  final List<InfoExtractor> _extractors = [];

  ExtractionEngine() {
    _registerExtractors();
  }

  void _registerExtractors() {
    // 1. Register specialized pattern matchers (Example: Porn site)
    _extractors.add(PatternMatchingExtractor(
      name: 'SimplePornSite', 
      urlPatterns: [
        r'https?://(www\.)?example-xxx\.com/video/\d+', 
        r'https?://(www\.)?simple-porn\.net/view/\d+'
      ],
      // Example patterns - in a real scenario these would be more robust
      videoUrlPattern: r'video_url\s*:\s*["\x27](https?://[^"\x27]+\.mp4)["\x27]',
    ));

    // 2. Register other specific extractors
    _extractors.add(PornHubIE());
    _extractors.add(YouPornIE());
    _extractors.add(PerfectGirlsIE());
    _extractors.add(EromeIE());

    // 3. Register GenericIE last as fallback
    _extractors.add(GenericIE());
  }

  Future<MediaInfo> extract(String url) async {
    for (final extractor in _extractors) {
      if (extractor.suitable(url)) {
        try {
          if (kDebugMode) {
            print('Using extractor: ${extractor.runtimeType}');
          }
          return await extractor.extract(url);
        } catch (e) {
          // If a specific extractor fails, we might want to try the next one,
          // OR fail immediately depending on if it "claimed" the URL strongly.
          // For now, if it's GenericIE, we fail. If it's a specific one, maybe fallback?
          // Youtube-dl logic: if suitable() returns true, it's THE extractor.
          if (kDebugMode) {
            print('Extractor ${extractor.runtimeType} failed: $e');
          }
          // If it was the generic extractor, we are done.
          if (extractor is GenericIE) rethrow;
          
          // If a specific extractor matched but failed, it's usually an error.
          // But we could allow falling back to GenericIE if we implement "strong" vs "weak" suitability.
          rethrow;
        }
      }
    }
    throw ExtractionError('No suitable extractor found');
  }
}
