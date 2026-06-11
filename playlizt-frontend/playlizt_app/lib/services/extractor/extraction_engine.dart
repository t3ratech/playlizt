import 'package:flutter/foundation.dart';
import 'core/info_extractor.dart';
import 'core/types.dart';
import 'extractors/erome_ie.dart';
import 'extractors/generic_ie.dart';
import 'extractors/perfect_girls_ie.dart';
import 'extractors/pornhub_ie.dart';
import 'extractors/youporn_ie.dart';
import 'extractors/youtube_dl_bridge_ie.dart';

class ExtractionEngine {
  final List<InfoExtractor> _extractors = [];

  ExtractionEngine({String? youtubeDlSourcePath, String? youtubeDlExecutable}) {
    _registerExtractors(
      youtubeDlSourcePath: youtubeDlSourcePath,
      youtubeDlExecutable: youtubeDlExecutable,
    );
  }

  List<String> get extractorNames =>
      _extractors.map((extractor) => extractor.name).toList(growable: false);

  void _registerExtractors({
    String? youtubeDlSourcePath,
    String? youtubeDlExecutable,
  }) {
    _extractors.add(PornHubIE());
    _extractors.add(YouPornIE());
    _extractors.add(PerfectGirlsIE());
    _extractors.add(EromeIE());

    final youtubeDlBridge = YoutubeDlBridgeIE(
      sourcePath: youtubeDlSourcePath,
      executable: youtubeDlExecutable,
    );
    if (youtubeDlBridge.isConfigured) {
      _extractors.add(youtubeDlBridge);
    }

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
          if (kDebugMode) {
            print('Extractor ${extractor.runtimeType} failed: $e');
          }
          if (extractor.canFallbackOnFailure) {
            continue;
          }
          rethrow;
        }
      }
    }
    throw ExtractionError('No suitable extractor found');
  }
}
