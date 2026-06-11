import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../core/info_extractor.dart';
import '../core/types.dart';
import '../core/youtube_dl_json_mapper.dart';

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
  final Duration extractionTimeout;

  const YoutubeDlProcess({
    this.sourcePath,
    this.executable,
    this.extractionTimeout = const Duration(seconds: 45),
  });

  String get resolvedSourcePath => (sourcePath ?? configuredSourcePath).trim();

  String get resolvedExecutable => (executable ?? configuredExecutable).trim();

  bool get isConfigured =>
      resolvedSourcePath.isNotEmpty || resolvedExecutable.isNotEmpty;

  bool get isSupportedPlatform =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  Future<Map<String, dynamic>> extractJson(String url) async {
    final command = _buildCommand([
      '--dump-single-json',
      '--skip-download',
      '--no-playlist',
      '--no-warnings',
      '--ignore-config',
      '--format',
      'best',
      '--socket-timeout',
      '20',
      url,
    ]);

    final result = await _run(command).timeout(extractionTimeout);
    if (result.exitCode != 0) {
      throw ExtractionError(
        'youtube-dl extraction failed: ${_trimProcessText(result.stderr)}',
        expected: true,
      );
    }

    final jsonText = _extractJsonObject(result.stdout);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw ExtractionError('youtube-dl returned an invalid JSON payload');
    }
    return decoded;
  }

  Future<YoutubeDlInventory> loadInventory() async {
    final source = resolvedSourcePath;
    if (source.isEmpty) {
      throw ExtractionError(
        'PLAYLIZT_YOUTUBE_DL_SOURCE is required for inventory verification',
        expected: true,
      );
    }

    final script = [
      'import json, sys',
      'sys.path.insert(0, ${jsonEncode(source)})',
      'from youtube_dl import version',
      'from youtube_dl.extractor import gen_extractors',
      'names = sorted(ie.IE_NAME for ie in gen_extractors())',
      'print(json.dumps({"version": version.__version__, "extractorCount": len(names), "extractorNames": names}))',
    ].join('; ');

    final result = await _run(
      _ProcessCommand(
        executable: 'python3',
        arguments: ['-c', script],
        workingDirectory: source,
        environment: _pythonPathEnvironment(source),
      ),
    );

    if (result.exitCode != 0) {
      throw ExtractionError(
        'youtube-dl inventory failed: ${_trimProcessText(result.stderr)}',
        expected: true,
      );
    }

    final decoded = jsonDecode(_extractJsonObject(result.stdout));
    if (decoded is! Map<String, dynamic>) {
      throw ExtractionError('youtube-dl inventory returned invalid JSON');
    }

    final names = decoded['extractorNames'];
    return YoutubeDlInventory(
      version: decoded['version'].toString(),
      extractorCount: (decoded['extractorCount'] as num).toInt(),
      extractorNames:
          names is List ? names.map((name) => name.toString()).toList() : [],
    );
  }

  Future<void> download({
    required String sourceUrl,
    required String outputPath,
    required CancelToken cancelToken,
    required void Function(double percent) onProgress,
  }) async {
    final command = _buildCommand([
      '--no-playlist',
      '--no-warnings',
      '--ignore-config',
      '--newline',
      '--format',
      'best',
      '--output',
      outputPath,
      sourceUrl,
    ]);

    final process = await Process.start(
      command.executable,
      command.arguments,
      workingDirectory: command.workingDirectory,
      environment: command.environment,
      runInShell: Platform.isWindows,
    );

    unawaited(
      cancelToken.whenCancel.then((_) {
        process.kill(ProcessSignal.sigterm);
      }),
    );

    final stdoutLines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final match = RegExp(
        r'\[download\]\s+(\d+(?:\.\d+)?)%',
      ).firstMatch(line);
      if (match == null) return;
      final percent = double.tryParse(match.group(1) ?? '');
      if (percent != null) {
        onProgress(percent.clamp(0, 100).toDouble());
      }
    });

    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    await stdoutLines.cancel();
    final stderr = await stderrFuture;

    if (cancelToken.isCancelled) {
      throw DioException(
        requestOptions: RequestOptions(path: sourceUrl),
        type: DioExceptionType.cancel,
        message: 'cancelled',
      );
    }

    if (exitCode != 0) {
      throw ExtractionError(
        'youtube-dl download failed: ${_trimProcessText(stderr)}',
      );
    }
  }

  _ProcessCommand _buildCommand(List<String> youtubeDlArguments) {
    final configuredBinary = resolvedExecutable;
    if (configuredBinary.isNotEmpty) {
      return _ProcessCommand(
        executable: configuredBinary,
        arguments: youtubeDlArguments,
      );
    }

    final source = resolvedSourcePath;
    return _ProcessCommand(
      executable: 'python3',
      arguments: ['-m', 'youtube_dl', ...youtubeDlArguments],
      workingDirectory: source,
      environment: _pythonPathEnvironment(source),
    );
  }

  Future<_ProcessResult> _run(_ProcessCommand command) async {
    final process = await Process.start(
      command.executable,
      command.arguments,
      workingDirectory: command.workingDirectory,
      environment: command.environment,
      runInShell: Platform.isWindows,
    );

    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;

    return _ProcessResult(
      exitCode: exitCode,
      stdout: await stdoutFuture,
      stderr: await stderrFuture,
    );
  }

  Map<String, String>? _pythonPathEnvironment(String source) {
    if (source.isEmpty) return null;
    final existing = Platform.environment['PYTHONPATH'];
    final envSeparator = Platform.isWindows ? ';' : ':';
    return {
      'PYTHONPATH': existing == null || existing.isEmpty
          ? source
          : '$source$envSeparator$existing',
    };
  }

  String _extractJsonObject(String raw) {
    final trimmed = raw.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw ExtractionError('youtube-dl output did not contain JSON');
    }
    return trimmed.substring(start, end + 1);
  }

  String _trimProcessText(String text) {
    final normalized = text.trim();
    if (normalized.length <= 800) return normalized;
    return normalized.substring(0, 800);
  }
}

class YoutubeDlBridgeIE extends InfoExtractor {
  final YoutubeDlProcess process;
  final YoutubeDlJsonMapper mapper;

  YoutubeDlBridgeIE({
    String? sourcePath,
    String? executable,
    YoutubeDlProcess? process,
    YoutubeDlJsonMapper? mapper,
  })  : process = process ??
            YoutubeDlProcess(sourcePath: sourcePath, executable: executable),
        mapper = mapper ?? YoutubeDlJsonMapper();

  bool get isConfigured => process.isConfigured && process.isSupportedPlatform;

  @override
  String get name => 'youtube-dl';

  @override
  bool get canFallbackOnFailure => true;

  @override
  bool suitable(String url) {
    if (!isConfigured) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }
    return !_looksLikeDirectMediaUrl(uri);
  }

  @override
  Future<MediaInfo> extract(String url) async {
    final json = await process.extractJson(url);
    return mapper.mapMediaInfo(json, sourceUrl: url);
  }

  bool _looksLikeDirectMediaUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.m4v') ||
        path.endsWith('.webm') ||
        path.endsWith('.mov') ||
        path.endsWith('.mkv') ||
        path.endsWith('.avi') ||
        path.endsWith('.flv') ||
        path.endsWith('.mp3') ||
        path.endsWith('.m4a') ||
        path.endsWith('.aac') ||
        path.endsWith('.ogg') ||
        path.endsWith('.oga') ||
        path.endsWith('.wav') ||
        path.endsWith('.flac') ||
        path.endsWith('.m3u8');
  }
}

class _ProcessCommand {
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  final Map<String, String>? environment;

  const _ProcessCommand({
    required this.executable,
    required this.arguments,
    this.workingDirectory,
    this.environment,
  });
}

class _ProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const _ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}
