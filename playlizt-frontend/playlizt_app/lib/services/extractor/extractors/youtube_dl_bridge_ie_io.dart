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

class YoutubeDlProgress {
  final double? percent;
  final int? downloadedBytes;
  final int? totalBytes;
  final double? speedBytesPerSecond;
  final int? etaSeconds;
  final String stage;

  const YoutubeDlProgress({
    this.percent,
    this.downloadedBytes,
    this.totalBytes,
    this.speedBytesPerSecond,
    this.etaSeconds,
    required this.stage,
  });

  static YoutubeDlProgress? parse(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final progressMatch = RegExp(
      r'^\[download\]\s+(\d+(?:\.\d+)?)%\s+of\s+~?([0-9.]+)([KMGTP]?i?B)?(?:\s+at\s+([0-9.]+)([KMGTP]?i?B)/s)?(?:\s+ETA\s+([0-9:]+))?',
    ).firstMatch(trimmed);
    if (progressMatch != null) {
      final percent = double.tryParse(progressMatch.group(1) ?? '');
      final total = _parseSize(
        progressMatch.group(2),
        progressMatch.group(3),
      );
      final speed = _parseSize(
        progressMatch.group(4),
        progressMatch.group(5),
      )?.toDouble();
      final downloaded = percent != null && total != null
          ? ((percent / 100) * total).round()
          : null;
      return YoutubeDlProgress(
        percent: percent,
        downloadedBytes: downloaded,
        totalBytes: total,
        speedBytesPerSecond: speed,
        etaSeconds: _parseEta(progressMatch.group(6)),
        stage: 'Downloading',
      );
    }

    if (trimmed.startsWith('[download] Destination:')) {
      return const YoutubeDlProgress(stage: 'Preparing output');
    }
    if (trimmed.startsWith('[download] 100%')) {
      return const YoutubeDlProgress(percent: 100, stage: 'Download complete');
    }
    if (trimmed.startsWith('[ffmpeg]') ||
        trimmed.startsWith('[ExtractAudio]') ||
        trimmed.startsWith('[EmbedSubtitle]') ||
        trimmed.startsWith('[Metadata]')) {
      return YoutubeDlProgress(
          stage: trimmed.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), ''));
    }
    return null;
  }

  static int? _parseSize(String? rawNumber, String? rawUnit) {
    if (rawNumber == null || rawNumber.trim().isEmpty) return null;
    final number = double.tryParse(rawNumber);
    if (number == null) return null;
    final unit = (rawUnit ?? 'B').toLowerCase();
    final multiplier = switch (unit) {
      'kib' || 'kb' => 1024,
      'mib' || 'mb' => 1024 * 1024,
      'gib' || 'gb' => 1024 * 1024 * 1024,
      'tib' || 'tb' => 1024 * 1024 * 1024 * 1024,
      _ => 1,
    };
    return (number * multiplier).round();
  }

  static int? _parseEta(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts =
        value.split(':').map((part) => int.tryParse(part) ?? 0).toList();
    if (parts.length == 2) return parts[0] * 60 + parts[1];
    if (parts.length == 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
    return null;
  }
}

class YoutubeDlProcess {
  static const _vendoredSourceCandidates = <String>[
    'vendor/youtube-dl',
    'playlizt-frontend/playlizt_app/vendor/youtube-dl',
  ];
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

  String get resolvedSourcePath {
    final explicit = (sourcePath ?? configuredSourcePath).trim();
    if (explicit.isNotEmpty) return explicit;

    for (final candidate in _vendoredSourceCandidates) {
      if (Directory(candidate).existsSync()) return candidate;
    }

    return '';
  }

  String get resolvedExecutable => (executable ?? configuredExecutable).trim();

  bool get isConfigured =>
      resolvedSourcePath.isNotEmpty || resolvedExecutable.isNotEmpty;

  bool get isSupportedPlatform =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  Future<Map<String, dynamic>> extractJson(String url) async {
    final command = _buildCommand([
      '--dump-single-json',
      '--skip-download',
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
        'Vendored youtube-dl source or PLAYLIZT_YOUTUBE_DL_SOURCE is required',
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
    String? formatId,
    bool audioOnly = false,
    bool writeSubtitles = false,
    bool writeThumbnail = false,
    bool writeMetadata = false,
    String? proxy,
    String? rateLimit,
    required void Function(YoutubeDlProgress progress) onProgress,
  }) async {
    final args = <String>[
      '--no-playlist',
      '--no-warnings',
      '--ignore-config',
      '--newline',
      '--format',
      audioOnly
          ? 'bestaudio/best'
          : (formatId?.trim().isNotEmpty == true ? formatId!.trim() : 'best'),
      '--output',
      outputPath,
    ];

    if (writeSubtitles) args.add('--write-sub');
    if (writeThumbnail) args.add('--write-thumbnail');
    if (writeMetadata) args.add('--add-metadata');
    if (proxy != null && proxy.trim().isNotEmpty) {
      args.addAll(['--proxy', proxy.trim()]);
    }
    if (rateLimit != null && rateLimit.trim().isNotEmpty) {
      args.addAll(['--limit-rate', rateLimit.trim()]);
    }
    args.add(sourceUrl);

    final command = _buildCommand(args);

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
      final progress = YoutubeDlProgress.parse(line);
      if (progress != null) onProgress(progress);
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
