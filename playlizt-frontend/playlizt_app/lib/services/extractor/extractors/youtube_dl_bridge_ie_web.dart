import '../core/info_extractor.dart';
import '../core/types.dart';

class YoutubeDlInventory {
  final String version;
  final int extractorCount;
  final List<String> extractorNames;

  const YoutubeDlInventory({
    required this.version,
    required this.extractorCount,
    required this.extractorNames,
  });
}

class YoutubeDlProcess {
  static const configuredSourcePath = String.fromEnvironment(
    'PLAYLIZT_YOUTUBE_DL_SOURCE',
  );
  static const configuredExecutable = String.fromEnvironment(
    'PLAYLIZT_YOUTUBE_DL_EXECUTABLE',
  );

  final String? sourcePath;
  final String? executable;

  const YoutubeDlProcess({this.sourcePath, this.executable});

  bool get isConfigured => false;
}

class YoutubeDlBridgeIE extends InfoExtractor {
  final YoutubeDlProcess process;

  YoutubeDlBridgeIE({
    String? sourcePath,
    String? executable,
    YoutubeDlProcess? process,
  }) : process =
           process ??
           YoutubeDlProcess(sourcePath: sourcePath, executable: executable);

  bool get isConfigured => false;

  @override
  String get name => 'youtube-dl';

  @override
  bool get canFallbackOnFailure => true;

  @override
  bool suitable(String url) => false;

  @override
  Future<MediaInfo> extract(String url) {
    throw ExtractionError(
      'youtube-dl bridge is not available on Flutter Web',
      expected: true,
    );
  }
}
