/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 21:43
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';

enum ConversionStatus {
  queued,
  probing,
  running,
  completed,
  failed,
  cancelled,
}

enum ConversionPresetId {
  mp3,
  aac,
  flac,
  wav,
  mp4720,
  mp41080,
  remux,
  audioOnly,
  webClip,
  mobileVideo,
  custom,
}

class FfmpegCapabilityInventory {
  static const requiredEncoders = 273;
  static const requiredDecoders = 607;
  static const requiredMuxers = 185;
  static const requiredDemuxers = 367;
  static const requiredFilters = 596;
  static const requiredBitstreamFilters = 51;
  static const requiredProtocols = 55;

  final int encoders;
  final int decoders;
  final int muxers;
  final int demuxers;
  final int filters;
  final int bitstreamFilters;
  final int protocols;

  const FfmpegCapabilityInventory({
    required this.encoders,
    required this.decoders,
    required this.muxers,
    required this.demuxers,
    required this.filters,
    required this.bitstreamFilters,
    required this.protocols,
  });

  const FfmpegCapabilityInventory.requiredInventory()
      : encoders = requiredEncoders,
        decoders = requiredDecoders,
        muxers = requiredMuxers,
        demuxers = requiredDemuxers,
        filters = requiredFilters,
        bitstreamFilters = requiredBitstreamFilters,
        protocols = requiredProtocols;

  bool get satisfiesRequiredCounts =>
      encoders >= requiredEncoders &&
      decoders >= requiredDecoders &&
      muxers >= requiredMuxers &&
      demuxers >= requiredDemuxers &&
      filters >= requiredFilters &&
      bitstreamFilters >= requiredBitstreamFilters &&
      protocols >= requiredProtocols;
}

class ConversionPreset {
  final ConversionPresetId id;
  final String label;
  final String description;
  final String outputExtension;

  const ConversionPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.outputExtension,
  });

  static const presets = [
    ConversionPreset(
      id: ConversionPresetId.mp3,
      label: 'MP3',
      description: 'Audio-only MP3 at 192 kbps',
      outputExtension: 'mp3',
    ),
    ConversionPreset(
      id: ConversionPresetId.aac,
      label: 'AAC',
      description: 'Audio-only AAC at 192 kbps',
      outputExtension: 'm4a',
    ),
    ConversionPreset(
      id: ConversionPresetId.flac,
      label: 'FLAC',
      description: 'Lossless audio output',
      outputExtension: 'flac',
    ),
    ConversionPreset(
      id: ConversionPresetId.wav,
      label: 'WAV',
      description: 'Uncompressed PCM audio',
      outputExtension: 'wav',
    ),
    ConversionPreset(
      id: ConversionPresetId.mp4720,
      label: 'MP4 720p',
      description: 'H.264 video scaled to 720p with AAC audio',
      outputExtension: 'mp4',
    ),
    ConversionPreset(
      id: ConversionPresetId.mp41080,
      label: 'MP4 1080p',
      description: 'H.264 video scaled to 1080p with AAC audio',
      outputExtension: 'mp4',
    ),
    ConversionPreset(
      id: ConversionPresetId.remux,
      label: 'Remux',
      description: 'Copy streams into a new container without re-encoding',
      outputExtension: 'mkv',
    ),
    ConversionPreset(
      id: ConversionPresetId.audioOnly,
      label: 'Extract Audio',
      description: 'Extract audio as AAC without video',
      outputExtension: 'm4a',
    ),
    ConversionPreset(
      id: ConversionPresetId.webClip,
      label: 'Web Clip',
      description: 'Short H.264 clip optimized for web playback',
      outputExtension: 'mp4',
    ),
    ConversionPreset(
      id: ConversionPresetId.mobileVideo,
      label: 'Mobile Video',
      description: 'H.264/AAC video tuned for phone playback',
      outputExtension: 'mp4',
    ),
  ];

  static ConversionPreset byId(ConversionPresetId id) {
    return presets.firstWhere((preset) => preset.id == id);
  }

  List<String> buildFfmpegArguments({
    required String inputPath,
    required String outputPath,
    String? startTime,
    String? endTime,
    List<String> customArguments = const [],
  }) {
    final args = <String>[
      '-hide_banner',
      '-y',
      '-progress',
      'pipe:1',
      '-nostats',
    ];

    if (startTime != null && startTime.trim().isNotEmpty) {
      args.addAll(['-ss', startTime.trim()]);
    }
    if (endTime != null && endTime.trim().isNotEmpty) {
      args.addAll(['-to', endTime.trim()]);
    }

    args.addAll(['-i', inputPath]);

    switch (id) {
      case ConversionPresetId.mp3:
        args.addAll(['-vn', '-c:a', 'libmp3lame', '-b:a', '192k']);
        break;
      case ConversionPresetId.aac:
        args.addAll(['-vn', '-c:a', 'aac', '-b:a', '192k']);
        break;
      case ConversionPresetId.flac:
        args.addAll(['-vn', '-c:a', 'flac']);
        break;
      case ConversionPresetId.wav:
        args.addAll(['-vn', '-c:a', 'pcm_s16le']);
        break;
      case ConversionPresetId.mp4720:
        args.addAll([
          '-c:v',
          'libx264',
          '-vf',
          'scale=-2:720',
          '-c:a',
          'aac',
          '-b:a',
          '160k',
          '-movflags',
          '+faststart',
        ]);
        break;
      case ConversionPresetId.mp41080:
        args.addAll([
          '-c:v',
          'libx264',
          '-vf',
          'scale=-2:1080',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          '-movflags',
          '+faststart',
        ]);
        break;
      case ConversionPresetId.remux:
        args.addAll(['-c', 'copy']);
        break;
      case ConversionPresetId.audioOnly:
        args.addAll(['-vn', '-c:a', 'aac', '-b:a', '192k']);
        break;
      case ConversionPresetId.webClip:
        args.addAll([
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-crf',
          '23',
          '-c:a',
          'aac',
          '-b:a',
          '128k',
          '-movflags',
          '+faststart',
        ]);
        break;
      case ConversionPresetId.mobileVideo:
        args.addAll([
          '-c:v',
          'libx264',
          '-profile:v',
          'main',
          '-level',
          '4.0',
          '-pix_fmt',
          'yuv420p',
          '-c:a',
          'aac',
          '-b:a',
          '128k',
          '-movflags',
          '+faststart',
        ]);
        break;
      case ConversionPresetId.custom:
        args.addAll(customArguments);
        break;
    }

    args.add(outputPath);
    return args;
  }
}

class ConversionJob {
  final String id;
  final String inputPath;
  final String outputPath;
  final ConversionPresetId presetId;
  final ConversionStatus status;
  final String? startTime;
  final String? endTime;
  final double? progress;
  final int? durationSeconds;
  final int? processedSeconds;
  final double? speed;
  final int? outputSizeBytes;
  final String currentStage;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversionJob({
    required this.id,
    required this.inputPath,
    required this.outputPath,
    required this.presetId,
    required this.status,
    this.startTime,
    this.endTime,
    this.progress,
    this.durationSeconds,
    this.processedSeconds,
    this.speed,
    this.outputSizeBytes,
    required this.currentStage,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  ConversionPreset get preset => ConversionPreset.byId(presetId);

  ConversionJob copyWith({
    ConversionStatus? status,
    double? progress,
    int? durationSeconds,
    int? processedSeconds,
    double? speed,
    int? outputSizeBytes,
    String? currentStage,
    String? errorMessage,
    DateTime? updatedAt,
  }) {
    return ConversionJob(
      id: id,
      inputPath: inputPath,
      outputPath: outputPath,
      presetId: presetId,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime,
      progress: progress ?? this.progress,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      processedSeconds: processedSeconds ?? this.processedSeconds,
      speed: speed ?? this.speed,
      outputSizeBytes: outputSizeBytes ?? this.outputSizeBytes,
      currentStage: currentStage ?? this.currentStage,
      errorMessage: errorMessage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inputPath': inputPath,
      'outputPath': outputPath,
      'presetId': presetId.name,
      'status': status.name,
      'startTime': startTime,
      'endTime': endTime,
      'progress': progress,
      'durationSeconds': durationSeconds,
      'processedSeconds': processedSeconds,
      'speed': speed,
      'outputSizeBytes': outputSizeBytes,
      'currentStage': currentStage,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static ConversionJob fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String?;
    var status = _enumByName(
      ConversionStatus.values,
      rawStatus,
      ConversionStatus.failed,
    );
    if (status == ConversionStatus.running ||
        status == ConversionStatus.probing) {
      status = ConversionStatus.failed;
    }

    return ConversionJob(
      id: json['id'] as String,
      inputPath: json['inputPath'] as String,
      outputPath: json['outputPath'] as String,
      presetId: _enumByName(
        ConversionPresetId.values,
        json['presetId'] as String?,
        ConversionPresetId.mp4720,
      ),
      status: status,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      processedSeconds: (json['processedSeconds'] as num?)?.toInt(),
      speed: (json['speed'] as num?)?.toDouble(),
      outputSizeBytes: (json['outputSizeBytes'] as num?)?.toInt(),
      currentStage: json['currentStage'] as String? ?? 'Restored',
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

class MediaProbeInfo {
  final String path;
  final int? durationSeconds;
  final int? bitrate;
  final List<MediaProbeStream> streams;

  const MediaProbeInfo({
    required this.path,
    this.durationSeconds,
    this.bitrate,
    this.streams = const [],
  });
}

class MediaProbeStream {
  final int index;
  final String codecType;
  final String? codecName;
  final int? width;
  final int? height;
  final int? sampleRate;
  final int? channels;

  const MediaProbeStream({
    required this.index,
    required this.codecType,
    this.codecName,
    this.width,
    this.height,
    this.sampleRate,
    this.channels,
  });
}

class FfmpegProgressSnapshot {
  final int? processedSeconds;
  final double? speed;
  final int? outputSizeBytes;
  final String stage;
  final bool finished;

  const FfmpegProgressSnapshot({
    this.processedSeconds,
    this.speed,
    this.outputSizeBytes,
    required this.stage,
    required this.finished,
  });
}

class FfmpegProgressParser {
  final Map<String, String> _values = {};

  FfmpegProgressSnapshot? addLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !trimmed.contains('=')) return null;
    final index = trimmed.indexOf('=');
    final key = trimmed.substring(0, index);
    final value = trimmed.substring(index + 1);
    _values[key] = value;

    if (key != 'progress') return null;

    final outTimeUs = int.tryParse(_values['out_time_us'] ?? '');
    final outTimeMs = int.tryParse(_values['out_time_ms'] ?? '');
    final outTime = _parseTimestamp(_values['out_time']);
    final processedSeconds = outTimeUs != null
        ? (outTimeUs / 1000000).round()
        : outTimeMs != null
            ? (outTimeMs / 1000000).round()
            : outTime;

    final speedText = (_values['speed'] ?? '').replaceAll('x', '');
    final sizeText = (_values['total_size'] ?? _values['out_size'] ?? '');

    return FfmpegProgressSnapshot(
      processedSeconds: processedSeconds,
      speed: double.tryParse(speedText),
      outputSizeBytes: int.tryParse(sizeText),
      stage: value == 'end' ? 'Finalizing' : 'Converting',
      finished: value == 'end',
    );
  }

  static int? _parseTimestamp(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 3) return null;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = double.tryParse(parts[2]) ?? 0;
    return (hours * 3600 + minutes * 60 + seconds).round();
  }
}
