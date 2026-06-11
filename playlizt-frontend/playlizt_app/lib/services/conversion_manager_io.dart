/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 21:43
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import 'conversion_models.dart';
import 'library_manager_platform.dart';

class ConversionManager with ChangeNotifier {
  static const _prefsKeyJobs = 'conversion.jobs';
  static const configuredFfmpegExecutable = String.fromEnvironment(
    'PLAYLIZT_FFMPEG_EXECUTABLE',
  );
  static const configuredFfprobeExecutable = String.fromEnvironment(
    'PLAYLIZT_FFPROBE_EXECUTABLE',
  );

  final SettingsProvider settingsProvider;
  final LibraryManager libraryManager;

  final Map<String, ConversionJob> _jobs = {};
  final Map<String, Process> _runningProcesses = {};
  bool _isLoaded = false;

  ConversionManager({
    required this.settingsProvider,
    required this.libraryManager,
  }) {
    _load();
  }

  bool get isLoaded => _isLoaded;
  bool get isConfigured =>
      configuredFfmpegExecutable.trim().isNotEmpty &&
      configuredFfprobeExecutable.trim().isNotEmpty;

  List<ConversionJob> get jobs {
    final list = _jobs.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<ConversionJob> enqueueConversion({
    required String inputPath,
    required ConversionPresetId presetId,
    String? outputDirectory,
    String? startTime,
    String? endTime,
    List<String> customArguments = const [],
    ConversionAdvancedOptions advancedOptions =
        const ConversionAdvancedOptions(),
  }) async {
    await settingsProvider.ensureLoaded();
    advancedOptions.validate();
    final resolvedInput = _resolveHome(inputPath);
    final inputFile = File(resolvedInput);
    if (!await inputFile.exists()) {
      throw StateError('Input file does not exist: $inputPath');
    }

    final preset = ConversionPreset.byId(presetId);
    final directory = _resolveHome(
      outputDirectory?.trim().isNotEmpty == true
          ? outputDirectory!.trim()
          : settingsProvider.conversionOutputDirectory,
    );
    final outputPath = await _nextOutputPath(
      directory: directory,
      inputPath: resolvedInput,
      extension: advancedOptions.normalizedContainerExtension ??
          preset.outputExtension,
    );

    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final job = ConversionJob(
      id: id,
      inputPath: resolvedInput,
      outputPath: outputPath,
      presetId: presetId,
      status: ConversionStatus.queued,
      startTime: _emptyToNull(startTime),
      endTime: _emptyToNull(endTime),
      customArguments: customArguments,
      advancedOptions: advancedOptions,
      currentStage: 'Queued',
      createdAt: now,
      updatedAt: now,
    );

    _jobs[id] = job;
    await _persist();
    notifyListeners();
    _startNextIfPossible();
    return job;
  }

  Future<ConversionJob> enqueueStreamOutput({
    required String inputPath,
    required String outputUri,
    required StreamOutputProfileId profileId,
    String? startTime,
    String? endTime,
    ConversionAdvancedOptions advancedOptions =
        const ConversionAdvancedOptions(),
  }) async {
    await settingsProvider.ensureLoaded();
    advancedOptions.validate();
    final resolvedInput = _resolveMediaInput(inputPath);
    if (!_isNetworkMediaUri(resolvedInput)) {
      final inputFile = File(resolvedInput);
      if (!await inputFile.exists()) {
        throw StateError('Input file does not exist: $inputPath');
      }
    }

    final target = outputUri.trim();
    _validateStreamOutputTarget(profileId, target);

    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final job = ConversionJob(
      id: id,
      inputPath: resolvedInput,
      outputPath: target,
      presetId: ConversionPresetId.webClip,
      status: ConversionStatus.queued,
      startTime: _emptyToNull(startTime),
      endTime: _emptyToNull(endTime),
      advancedOptions: advancedOptions,
      outputKind: ConversionOutputKind.stream,
      streamProfileId: profileId,
      currentStage: 'Queued',
      createdAt: now,
      updatedAt: now,
    );

    _jobs[id] = job;
    await _persist();
    notifyListeners();
    _startNextIfPossible();
    return job;
  }

  Future<void> cancelConversion(String id) async {
    final process = _runningProcesses[id];
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
    }

    final job = _jobs[id];
    if (job == null) return;
    _jobs[id] = job.copyWith(
      status: ConversionStatus.cancelled,
      currentStage: 'Cancelled',
      errorMessage: 'Cancelled by user',
    );
    await _persist();
    notifyListeners();
  }

  Future<void> retryConversion(String id) async {
    final job = _jobs[id];
    if (job == null) return;
    _jobs[id] = job.copyWith(
      status: ConversionStatus.queued,
      progress: 0,
      processedSeconds: 0,
      currentStage: 'Queued',
      errorMessage: null,
    );
    await _persist();
    notifyListeners();
    _startNextIfPossible();
  }

  Future<MediaProbeInfo> probeMedia(String inputPath) async {
    final executable = _requiredFfprobeExecutable();
    final result = await Process.run(executable, [
      '-v',
      'error',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      _resolveHome(inputPath),
    ]);

    if (result.exitCode != 0) {
      throw StateError(
          'Media probe failed: ${_trimProcessText(result.stderr)}');
    }

    final decoded = jsonDecode(result.stdout.toString());
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Media probe returned invalid JSON');
    }
    return MediaProbeInfo.fromFfprobeJson(
      decoded,
      path: _resolveHome(inputPath),
    );
  }

  Future<FfmpegCapabilityInventory> loadCapabilityInventory() async {
    final executable = _requiredFfmpegExecutable();
    final encoders = await _countCapabilityLines(executable, '-encoders');
    final decoders = await _countCapabilityLines(executable, '-decoders');
    final muxers = await _countCapabilityLines(executable, '-muxers');
    final demuxers = await _countCapabilityLines(executable, '-demuxers');
    final filters = await _countCapabilityLines(executable, '-filters');
    final bitstreamFilters = await _countSimpleList(executable, '-bsfs');
    final protocols = await _countSimpleList(executable, '-protocols');

    return FfmpegCapabilityInventory(
      encoders: encoders,
      decoders: decoders,
      muxers: muxers,
      demuxers: demuxers,
      filters: filters,
      bitstreamFilters: bitstreamFilters,
      protocols: protocols,
    );
  }

  void _startNextIfPossible() {
    if (_runningProcesses.isNotEmpty) return;
    final queued = _jobs.values
        .where((job) => job.status == ConversionStatus.queued)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (queued.isEmpty) return;
    unawaited(_startJob(queued.first));
  }

  Future<void> _startJob(ConversionJob job) async {
    try {
      final ffmpeg = _requiredFfmpegExecutable();
      _jobs[job.id] = job.copyWith(
        status: ConversionStatus.probing,
        currentStage: 'Probing media',
        errorMessage: null,
      );
      await _persist();
      notifyListeners();

      final probe = await probeMedia(job.inputPath);
      final duration = _clipDurationSeconds(job, probe.durationSeconds);

      final runningJob = _jobs[job.id]!.copyWith(
        status: ConversionStatus.running,
        durationSeconds: duration,
        currentStage: 'Starting conversion',
      );
      _jobs[job.id] = runningJob;
      await _persist();
      notifyListeners();

      if (job.outputKind == ConversionOutputKind.file) {
        await File(job.outputPath).parent.create(recursive: true);
      }
      final args = _buildJobArguments(job);

      final process = await Process.start(ffmpeg, args);
      _runningProcesses[job.id] = process;
      final parser = FfmpegProgressParser();
      final stderr = StringBuffer();

      final stdoutSub = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final snapshot = parser.addLine(line);
        if (snapshot == null) return;
        final current = _jobs[job.id];
        if (current == null) return;

        final processed = snapshot.processedSeconds;
        final percent = processed != null && duration != null && duration > 0
            ? (processed / duration).clamp(0, 1).toDouble()
            : current.progress;

        _jobs[job.id] = current.copyWith(
          progress: percent,
          processedSeconds: processed,
          speed: snapshot.speed,
          outputSizeBytes: snapshot.outputSizeBytes,
          currentStage: snapshot.stage,
        );
        notifyListeners();
      });

      final stderrSub = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.trim().isNotEmpty) {
          stderr.writeln(line);
        }
      });

      final exitCode = await process.exitCode;
      await stdoutSub.cancel();
      await stderrSub.cancel();
      _runningProcesses.remove(job.id);

      final current = _jobs[job.id];
      if (current == null) return;
      if (current.status == ConversionStatus.cancelled) {
        await _persist();
        notifyListeners();
        _startNextIfPossible();
        return;
      }

      if (exitCode != 0) {
        _jobs[job.id] = current.copyWith(
          status: ConversionStatus.failed,
          currentStage: 'Failed',
          errorMessage: _friendlyFfmpegError(stderr.toString()),
        );
      } else {
        if (job.outputKind == ConversionOutputKind.file) {
          await libraryManager.importPath(
            path: job.outputPath,
            source: LibraryItemSource.converted,
            parentId: LibraryItem.stableIdForPath(job.inputPath),
            displayTitle: _titleFromPath(job.outputPath),
            durationSeconds: duration,
          );
        }
        _jobs[job.id] = current.copyWith(
          status: ConversionStatus.completed,
          progress: 1,
          currentStage: 'Completed',
          errorMessage: null,
        );
      }

      await _persist();
      notifyListeners();
      _startNextIfPossible();
    } catch (e) {
      _runningProcesses.remove(job.id);
      final current = _jobs[job.id] ?? job;
      _jobs[job.id] = current.copyWith(
        status: ConversionStatus.failed,
        currentStage: 'Failed',
        errorMessage: _friendlyFfmpegError(e.toString()),
      );
      await _persist();
      notifyListeners();
      _startNextIfPossible();
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyJobs);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final job = ConversionJob.fromJson(item);
              _jobs[job.id] = job;
            } else if (item is Map) {
              final job = ConversionJob.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              );
              _jobs[job.id] = job;
            }
          }
        }
      }
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKeyJobs,
      jsonEncode(_jobs.values.map((job) => job.toJson()).toList()),
    );
  }

  List<String> _buildJobArguments(ConversionJob job) {
    if (job.outputKind == ConversionOutputKind.stream) {
      final profile = job.streamProfile;
      if (profile == null) {
        throw StateError('Stream output profile is required');
      }
      return profile.buildFfmpegArguments(
        inputPath: job.inputPath,
        outputUri: job.outputPath,
        startTime: job.startTime,
        endTime: job.endTime,
        advancedOptions: job.advancedOptions,
      );
    }

    return job.preset.buildFfmpegArguments(
      inputPath: job.inputPath,
      outputPath: job.outputPath,
      startTime: job.startTime,
      endTime: job.endTime,
      customArguments: job.customArguments,
      advancedOptions: job.advancedOptions,
    );
  }

  Future<String> _nextOutputPath({
    required String directory,
    required String inputPath,
    required String extension,
  }) async {
    final safeBase = _titleFromPath(inputPath).replaceAll(
      RegExp(r'[^\w\s\.-]'),
      '_',
    );
    var candidate = '$directory${Platform.pathSeparator}$safeBase.$extension';
    var index = 2;
    while (await File(candidate).exists()) {
      candidate =
          '$directory${Platform.pathSeparator}$safeBase ($index).$extension';
      index++;
    }
    return candidate;
  }

  Future<int> _countCapabilityLines(String executable, String flag) async {
    final result = await Process.run(executable, ['-hide_banner', flag]);
    if (result.exitCode != 0) {
      throw StateError('FFmpeg capability query failed for $flag');
    }
    final text = '${result.stdout}\n${result.stderr}';
    return text
        .split('\n')
        .where((line) => RegExp(r'^\s*[A-Z\.]{2,8}\s+\S+').hasMatch(line))
        .length;
  }

  Future<int> _countSimpleList(String executable, String flag) async {
    final result = await Process.run(executable, ['-hide_banner', flag]);
    if (result.exitCode != 0) {
      throw StateError('FFmpeg capability query failed for $flag');
    }
    final text = '${result.stdout}\n${result.stderr}';
    final names = <String>{};
    var inList = false;
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.endsWith(':')) {
        inList = true;
        continue;
      }
      if (!inList) continue;
      if (line.startsWith('-')) continue;
      for (final token in line.split(RegExp(r'\s+'))) {
        if (token.isNotEmpty &&
            RegExp(r'^[a-zA-Z0-9_.,+-]+$').hasMatch(token)) {
          names.add(token);
        }
      }
    }
    return names.length;
  }

  int? _clipDurationSeconds(ConversionJob job, int? inputDuration) {
    final start = _parseTimestamp(job.startTime);
    final end = _parseTimestamp(job.endTime);
    if (start != null && end != null && end > start) return end - start;
    if (start != null && inputDuration != null && inputDuration > start) {
      return inputDuration - start;
    }
    return inputDuration;
  }

  int? _parseTimestamp(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 3) return null;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = double.tryParse(parts[2]) ?? 0;
    return (hours * 3600 + minutes * 60 + seconds).round();
  }

  String _requiredFfmpegExecutable() {
    final executable = configuredFfmpegExecutable.trim();
    if (executable.isEmpty) {
      throw StateError('PLAYLIZT_FFMPEG_EXECUTABLE is required for conversion');
    }
    return executable;
  }

  String _requiredFfprobeExecutable() {
    final executable = configuredFfprobeExecutable.trim();
    if (executable.isEmpty) {
      throw StateError(
          'PLAYLIZT_FFPROBE_EXECUTABLE is required for media probe');
    }
    return executable;
  }

  String _friendlyFfmpegError(String raw) {
    final text = _trimProcessText(raw);
    if (text.contains('Invalid data found')) {
      return 'The selected file could not be read as media. $text';
    }
    if (text.contains('Unknown encoder')) {
      return 'The selected output encoder is not available. $text';
    }
    if (text.contains('No such file or directory')) {
      return 'A required input or output path was not found. $text';
    }
    if (text.contains('PLAYLIZT_FFMPEG_EXECUTABLE') ||
        text.contains('PLAYLIZT_FFPROBE_EXECUTABLE')) {
      return text;
    }
    return text.isEmpty ? 'Conversion failed' : text;
  }

  String _trimProcessText(Object value) {
    final normalized = value.toString().trim();
    if (normalized.length <= 1000) return normalized;
    return normalized.substring(0, 1000);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _resolveMediaInput(String value) {
    final trimmed = value.trim();
    return _isNetworkMediaUri(trimmed) ? trimmed : _resolveHome(trimmed);
  }

  bool _isNetworkMediaUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return false;
    return uri.isScheme('http') ||
        uri.isScheme('https') ||
        uri.isScheme('rtsp') ||
        uri.isScheme('rtmp') ||
        uri.isScheme('rtmps') ||
        uri.isScheme('udp') ||
        uri.isScheme('srt');
  }

  void _validateStreamOutputTarget(
    StreamOutputProfileId profileId,
    String outputUri,
  ) {
    if (outputUri.isEmpty) {
      throw ArgumentError('Stream output target is required');
    }
    final uri = Uri.tryParse(outputUri);
    final scheme = uri?.scheme.toLowerCase();
    switch (profileId) {
      case StreamOutputProfileId.rtmpH264:
        if (scheme == 'rtmp' || scheme == 'rtmps') return;
        break;
      case StreamOutputProfileId.rtspH264:
        if (scheme == 'rtsp') return;
        break;
      case StreamOutputProfileId.udpMpegTs:
        if (scheme == 'udp') return;
        break;
      case StreamOutputProfileId.hlsLive:
        if (scheme == 'http' ||
            scheme == 'https' ||
            scheme == 'file' ||
            outputUri.endsWith('.m3u8')) {
          return;
        }
        break;
      case StreamOutputProfileId.audioMp3:
        if (scheme == 'http' ||
            scheme == 'https' ||
            scheme == 'icecast' ||
            scheme == 'tcp') {
          return;
        }
        break;
    }
    throw ArgumentError(
      'Stream output target is not compatible with ${profileId.name}: '
      '$outputUri',
    );
  }

  String _titleFromPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  String _resolveHome(String path) {
    final trimmed = path.trim();
    if (trimmed == '~') {
      final home = Platform.environment['HOME'];
      return home == null || home.isEmpty ? trimmed : home;
    }
    if (trimmed.startsWith('~/')) {
      final home = Platform.environment['HOME'];
      return home == null || home.isEmpty
          ? trimmed
          : '$home/${trimmed.substring(2)}';
    }
    return trimmed;
  }
}
