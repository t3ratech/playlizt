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
  webmClip,
  gifClip,
  thumbnail,
  mobileVideo,
  custom,
}

enum ConversionSubtitleMode {
  preserve,
  copy,
  burnIn,
  remove,
}

enum ConversionOutputKind {
  file,
  stream,
}

enum ConversionOutputCollisionPolicy {
  keepBoth,
  overwrite,
  fail,
}

enum StreamOutputProfileId {
  rtmpH264,
  rtspH264,
  udpMpegTs,
  hlsLive,
  audioMp3,
}

class ConversionAdvancedOptions {
  final String? containerExtension;
  final String? videoCodec;
  final String? audioCodec;
  final String? videoBitrate;
  final String? audioBitrate;
  final String? crf;
  final String? sampleRate;
  final String? channels;
  final String? pixelFormat;
  final String? videoFilter;
  final String? audioFilter;
  final ConversionSubtitleMode subtitleMode;
  final String? subtitlePath;

  const ConversionAdvancedOptions({
    this.containerExtension,
    this.videoCodec,
    this.audioCodec,
    this.videoBitrate,
    this.audioBitrate,
    this.crf,
    this.sampleRate,
    this.channels,
    this.pixelFormat,
    this.videoFilter,
    this.audioFilter,
    this.subtitleMode = ConversionSubtitleMode.preserve,
    this.subtitlePath,
  });

  bool get isEmpty =>
      _isBlank(containerExtension) &&
      _isBlank(videoCodec) &&
      _isBlank(audioCodec) &&
      _isBlank(videoBitrate) &&
      _isBlank(audioBitrate) &&
      _isBlank(crf) &&
      _isBlank(sampleRate) &&
      _isBlank(channels) &&
      _isBlank(pixelFormat) &&
      _isBlank(videoFilter) &&
      _isBlank(audioFilter) &&
      subtitleMode == ConversionSubtitleMode.preserve &&
      _isBlank(subtitlePath);

  String? get normalizedContainerExtension {
    final value = _normalize(containerExtension);
    if (value == null) return null;
    return value.startsWith('.') ? value.substring(1) : value;
  }

  void validate() {
    if (subtitleMode == ConversionSubtitleMode.burnIn &&
        _isBlank(subtitlePath)) {
      throw ArgumentError('Subtitle burn-in requires a subtitle file path');
    }
  }

  List<String> toFfmpegArguments() {
    validate();
    final args = <String>[];

    void addOption(String flag, String? value) {
      final normalized = _normalize(value);
      if (normalized == null) return;
      args.addAll([flag, normalized]);
    }

    addOption('-c:v', videoCodec);
    addOption('-c:a', audioCodec);
    addOption('-b:v', videoBitrate);
    addOption('-b:a', audioBitrate);
    addOption('-crf', crf);
    addOption('-ar', sampleRate);
    addOption('-ac', channels);
    addOption('-pix_fmt', pixelFormat);

    final videoFilters = <String>[
      if (_normalize(videoFilter) != null) _normalize(videoFilter)!,
      if (subtitleMode == ConversionSubtitleMode.burnIn)
        'subtitles=${_escapeFilterPath(_normalize(subtitlePath)!)}',
    ];
    if (videoFilters.isNotEmpty) {
      args.addAll(['-vf', videoFilters.join(',')]);
    }

    addOption('-af', audioFilter);

    switch (subtitleMode) {
      case ConversionSubtitleMode.preserve:
        break;
      case ConversionSubtitleMode.copy:
        args.addAll(['-c:s', 'copy']);
        break;
      case ConversionSubtitleMode.burnIn:
        break;
      case ConversionSubtitleMode.remove:
        args.add('-sn');
        break;
    }

    return args;
  }

  Map<String, dynamic> toJson() {
    return {
      'containerExtension': containerExtension,
      'videoCodec': videoCodec,
      'audioCodec': audioCodec,
      'videoBitrate': videoBitrate,
      'audioBitrate': audioBitrate,
      'crf': crf,
      'sampleRate': sampleRate,
      'channels': channels,
      'pixelFormat': pixelFormat,
      'videoFilter': videoFilter,
      'audioFilter': audioFilter,
      'subtitleMode': subtitleMode.name,
      'subtitlePath': subtitlePath,
    };
  }

  static ConversionAdvancedOptions fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ConversionAdvancedOptions();
    return ConversionAdvancedOptions(
      containerExtension: json['containerExtension'] as String?,
      videoCodec: json['videoCodec'] as String?,
      audioCodec: json['audioCodec'] as String?,
      videoBitrate: json['videoBitrate'] as String?,
      audioBitrate: json['audioBitrate'] as String?,
      crf: json['crf'] as String?,
      sampleRate: json['sampleRate'] as String?,
      channels: json['channels'] as String?,
      pixelFormat: json['pixelFormat'] as String?,
      videoFilter: json['videoFilter'] as String?,
      audioFilter: json['audioFilter'] as String?,
      subtitleMode: ConversionJob._enumByName(
        ConversionSubtitleMode.values,
        json['subtitleMode'] as String?,
        ConversionSubtitleMode.preserve,
      ),
      subtitlePath: json['subtitlePath'] as String?,
    );
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _escapeFilterPath(String path) {
    return path
        .replaceAll(r'\', r'\\')
        .replaceAll(':', r'\:')
        .replaceAll("'", r"\'");
  }
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

enum FfmpegCapabilitySection {
  encoders,
  decoders,
  muxers,
  demuxers,
  filters,
  bitstreamFilters,
  protocols,
}

class FfmpegCapabilityEntry {
  final FfmpegCapabilitySection section;
  final String name;
  final String description;
  final String flags;
  final bool supportsInput;
  final bool supportsOutput;

  const FfmpegCapabilityEntry({
    required this.section,
    required this.name,
    this.description = '',
    this.flags = '',
    this.supportsInput = false,
    this.supportsOutput = false,
  });

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        description.toLowerCase().contains(normalized) ||
        flags.toLowerCase().contains(normalized);
  }
}

class FfmpegCapabilityCatalog {
  final List<FfmpegCapabilityEntry> encoders;
  final List<FfmpegCapabilityEntry> decoders;
  final List<FfmpegCapabilityEntry> muxers;
  final List<FfmpegCapabilityEntry> demuxers;
  final List<FfmpegCapabilityEntry> filters;
  final List<FfmpegCapabilityEntry> bitstreamFilters;
  final List<FfmpegCapabilityEntry> protocols;

  const FfmpegCapabilityCatalog({
    required this.encoders,
    required this.decoders,
    required this.muxers,
    required this.demuxers,
    required this.filters,
    required this.bitstreamFilters,
    required this.protocols,
  });

  FfmpegCapabilityInventory get inventory => FfmpegCapabilityInventory(
        encoders: encoders.length,
        decoders: decoders.length,
        muxers: muxers.length,
        demuxers: demuxers.length,
        filters: filters.length,
        bitstreamFilters: bitstreamFilters.length,
        protocols: protocols.length,
      );

  List<FfmpegCapabilityEntry> entriesFor(FfmpegCapabilitySection section) {
    switch (section) {
      case FfmpegCapabilitySection.encoders:
        return encoders;
      case FfmpegCapabilitySection.decoders:
        return decoders;
      case FfmpegCapabilitySection.muxers:
        return muxers;
      case FfmpegCapabilitySection.demuxers:
        return demuxers;
      case FfmpegCapabilitySection.filters:
        return filters;
      case FfmpegCapabilitySection.bitstreamFilters:
        return bitstreamFilters;
      case FfmpegCapabilitySection.protocols:
        return protocols;
    }
  }

  List<FfmpegCapabilityEntry> search(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return [
        ...encoders,
        ...decoders,
        ...muxers,
        ...demuxers,
        ...filters,
        ...bitstreamFilters,
        ...protocols,
      ];
    }
    return [
      ...encoders.where((entry) => entry.matches(normalized)),
      ...decoders.where((entry) => entry.matches(normalized)),
      ...muxers.where((entry) => entry.matches(normalized)),
      ...demuxers.where((entry) => entry.matches(normalized)),
      ...filters.where((entry) => entry.matches(normalized)),
      ...bitstreamFilters.where((entry) => entry.matches(normalized)),
      ...protocols.where((entry) => entry.matches(normalized)),
    ];
  }

  ConversionValidationResult validateAdvancedOptions(
    ConversionAdvancedOptions options,
  ) {
    final issues = <ConversionValidationIssue>[];

    void requireEntry({
      required String field,
      required String value,
      required FfmpegCapabilitySection section,
      required List<FfmpegCapabilityEntry> entries,
      bool commaSeparatedName = false,
    }) {
      final normalized = value.trim();
      if (normalized.isEmpty) return;
      final exists = entries.any((entry) {
        if (entry.name == normalized) return true;
        if (!commaSeparatedName) return false;
        return entry.name.split(',').map((part) => part.trim()).contains(
              normalized,
            );
      });
      if (!exists) {
        issues.add(
          ConversionValidationIssue(
            field: field,
            value: normalized,
            message:
                '$field "$normalized" is not available in ${section.name}.',
          ),
        );
      }
    }

    final container = options.normalizedContainerExtension;
    if (container != null) {
      requireEntry(
        field: 'Container',
        value: container,
        section: FfmpegCapabilitySection.muxers,
        entries: muxers,
        commaSeparatedName: true,
      );
    }
    final videoCodec = _normalize(options.videoCodec);
    if (videoCodec != null) {
      requireEntry(
        field: 'Video codec',
        value: videoCodec,
        section: FfmpegCapabilitySection.encoders,
        entries: encoders,
      );
    }
    final audioCodec = _normalize(options.audioCodec);
    if (audioCodec != null) {
      requireEntry(
        field: 'Audio codec',
        value: audioCodec,
        section: FfmpegCapabilitySection.encoders,
        entries: encoders,
      );
    }

    for (final filterName in _filterNames(options.videoFilter)) {
      requireEntry(
        field: 'Video filter',
        value: filterName,
        section: FfmpegCapabilitySection.filters,
        entries: filters,
      );
    }
    for (final filterName in _filterNames(options.audioFilter)) {
      requireEntry(
        field: 'Audio filter',
        value: filterName,
        section: FfmpegCapabilitySection.filters,
        entries: filters,
      );
    }

    return ConversionValidationResult(issues: issues);
  }

  factory FfmpegCapabilityCatalog.fromFfmpegOutputs({
    required String encoders,
    required String decoders,
    required String muxers,
    required String demuxers,
    required String filters,
    required String bitstreamFilters,
    required String protocols,
  }) {
    return FfmpegCapabilityCatalog(
      encoders: _parseFlaggedEntries(
        encoders,
        FfmpegCapabilitySection.encoders,
      ),
      decoders: _parseFlaggedEntries(
        decoders,
        FfmpegCapabilitySection.decoders,
      ),
      muxers: _parseFlaggedEntries(muxers, FfmpegCapabilitySection.muxers),
      demuxers: _parseFlaggedEntries(
        demuxers,
        FfmpegCapabilitySection.demuxers,
      ),
      filters: _parseFlaggedEntries(filters, FfmpegCapabilitySection.filters),
      bitstreamFilters: _parseSimpleEntries(
        bitstreamFilters,
        FfmpegCapabilitySection.bitstreamFilters,
      ),
      protocols: _parseProtocolEntries(protocols),
    );
  }

  static List<FfmpegCapabilityEntry> _parseFlaggedEntries(
    String text,
    FfmpegCapabilitySection section,
  ) {
    final entries = <FfmpegCapabilityEntry>[];
    final pattern = RegExp(r'^\s*([A-Z\.]{1,8})\s+(\S+)\s*(.*)$');
    for (final rawLine in text.split('\n')) {
      final match = pattern.firstMatch(rawLine);
      if (match == null) continue;
      entries.add(
        FfmpegCapabilityEntry(
          section: section,
          flags: match.group(1) ?? '',
          name: match.group(2) ?? '',
          description: (match.group(3) ?? '').trim(),
        ),
      );
    }
    return entries;
  }

  static List<FfmpegCapabilityEntry> _parseSimpleEntries(
    String text,
    FfmpegCapabilitySection section,
  ) {
    final names = <String>{};
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.endsWith(':') || line.startsWith('-')) {
        continue;
      }
      if (line.contains(' ')) continue;
      if (!RegExp(r'^[a-zA-Z0-9_.,+-]+$').hasMatch(line)) continue;
      names.add(line);
    }
    return names
        .map((name) => FfmpegCapabilityEntry(section: section, name: name))
        .toList();
  }

  static List<FfmpegCapabilityEntry> _parseProtocolEntries(String text) {
    final byName = <String, ({bool input, bool output})>{};
    String? direction;
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('-')) continue;
      if (line == 'Input:') {
        direction = 'input';
        continue;
      }
      if (line == 'Output:') {
        direction = 'output';
        continue;
      }
      if (line.endsWith(':')) continue;
      if (direction == null) continue;

      for (final token in line.split(RegExp(r'\s+'))) {
        if (token.isEmpty || !RegExp(r'^[a-zA-Z0-9_.,+-]+$').hasMatch(token)) {
          continue;
        }
        final current = byName[token] ?? (input: false, output: false);
        byName[token] = (
          input: current.input || direction == 'input',
          output: current.output || direction == 'output',
        );
      }
    }

    final entries = byName.entries.map((entry) {
      final support = entry.value;
      return FfmpegCapabilityEntry(
        section: FfmpegCapabilitySection.protocols,
        name: entry.key,
        description: support.input && support.output
            ? 'Input and output protocol'
            : support.input
                ? 'Input protocol'
                : 'Output protocol',
        supportsInput: support.input,
        supportsOutput: support.output,
      );
    }).toList();
    entries.sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _filterNames(String? filterChain) {
    final normalized = _normalize(filterChain);
    if (normalized == null) return const [];
    return normalized
        .split(',')
        .map((part) => part.trim().split('=').first.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList();
  }
}

class ConversionValidationIssue {
  final String field;
  final String value;
  final String message;

  const ConversionValidationIssue({
    required this.field,
    required this.value,
    required this.message,
  });
}

class ConversionValidationResult {
  final List<ConversionValidationIssue> issues;

  const ConversionValidationResult({required this.issues});

  bool get isValid => issues.isEmpty;

  String get userMessage {
    if (issues.isEmpty) return 'Conversion settings are valid';
    return issues.map((issue) => issue.message).join(' ');
  }
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
      id: ConversionPresetId.webmClip,
      label: 'WebM Clip',
      description: 'VP9/Opus clip for lightweight web sharing',
      outputExtension: 'webm',
    ),
    ConversionPreset(
      id: ConversionPresetId.gifClip,
      label: 'GIF Clip',
      description: 'Animated GIF clip with web-friendly scaling',
      outputExtension: 'gif',
    ),
    ConversionPreset(
      id: ConversionPresetId.thumbnail,
      label: 'Thumbnail',
      description: 'Single JPEG frame from the selected timestamp',
      outputExtension: 'jpg',
    ),
    ConversionPreset(
      id: ConversionPresetId.mobileVideo,
      label: 'Mobile Video',
      description: 'H.264/AAC video tuned for phone playback',
      outputExtension: 'mp4',
    ),
    ConversionPreset(
      id: ConversionPresetId.custom,
      label: 'Custom',
      description: 'User supplied FFmpeg output arguments',
      outputExtension: 'mkv',
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
    ConversionAdvancedOptions advancedOptions =
        const ConversionAdvancedOptions(),
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
      case ConversionPresetId.webmClip:
        args.addAll([
          '-c:v',
          'libvpx-vp9',
          '-b:v',
          '0',
          '-crf',
          '32',
          '-c:a',
          'libopus',
          '-b:a',
          '96k',
        ]);
        break;
      case ConversionPresetId.gifClip:
        args.addAll([
          '-vf',
          'fps=15,scale=640:-1:flags=lanczos',
          '-loop',
          '0',
        ]);
        break;
      case ConversionPresetId.thumbnail:
        args.addAll(['-frames:v', '1', '-q:v', '2', '-an']);
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

    args.addAll(advancedOptions.toFfmpegArguments());
    args.add(outputPath);
    return args;
  }
}

class StreamOutputProfile {
  final StreamOutputProfileId id;
  final String label;
  final String description;
  final String outputFormat;
  final List<String> defaultArguments;

  const StreamOutputProfile({
    required this.id,
    required this.label,
    required this.description,
    required this.outputFormat,
    required this.defaultArguments,
  });

  static const profiles = [
    StreamOutputProfile(
      id: StreamOutputProfileId.rtmpH264,
      label: 'RTMP H.264',
      description: 'Low-latency H.264/AAC stream for RTMP endpoints',
      outputFormat: 'flv',
      defaultArguments: [
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-tune',
        'zerolatency',
        '-c:a',
        'aac',
        '-b:a',
        '160k',
      ],
    ),
    StreamOutputProfile(
      id: StreamOutputProfileId.rtspH264,
      label: 'RTSP H.264',
      description: 'H.264/AAC stream for RTSP receivers',
      outputFormat: 'rtsp',
      defaultArguments: [
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-tune',
        'zerolatency',
        '-c:a',
        'aac',
        '-b:a',
        '160k',
      ],
    ),
    StreamOutputProfile(
      id: StreamOutputProfileId.udpMpegTs,
      label: 'UDP MPEG-TS',
      description: 'MPEG-TS stream for LAN playback targets',
      outputFormat: 'mpegts',
      defaultArguments: [
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-tune',
        'zerolatency',
        '-c:a',
        'aac',
        '-b:a',
        '160k',
      ],
    ),
    StreamOutputProfile(
      id: StreamOutputProfileId.hlsLive,
      label: 'HLS Live',
      description: 'Rolling HLS segments for HTTP playback',
      outputFormat: 'hls',
      defaultArguments: [
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-c:a',
        'aac',
        '-b:a',
        '160k',
        '-hls_time',
        '4',
        '-hls_list_size',
        '6',
        '-hls_flags',
        'delete_segments+append_list',
      ],
    ),
    StreamOutputProfile(
      id: StreamOutputProfileId.audioMp3,
      label: 'Audio MP3 Stream',
      description: 'Audio-only MP3 stream output',
      outputFormat: 'mp3',
      defaultArguments: ['-vn', '-c:a', 'libmp3lame', '-b:a', '192k'],
    ),
  ];

  static StreamOutputProfile byId(StreamOutputProfileId id) {
    return profiles.firstWhere((profile) => profile.id == id);
  }

  List<String> buildFfmpegArguments({
    required String inputPath,
    required String outputUri,
    String? startTime,
    String? endTime,
    ConversionAdvancedOptions advancedOptions =
        const ConversionAdvancedOptions(),
  }) {
    final args = <String>[
      '-hide_banner',
      '-y',
      '-progress',
      'pipe:1',
      '-nostats',
      '-re',
    ];

    if (startTime != null && startTime.trim().isNotEmpty) {
      args.addAll(['-ss', startTime.trim()]);
    }
    if (endTime != null && endTime.trim().isNotEmpty) {
      args.addAll(['-to', endTime.trim()]);
    }

    args.addAll(['-i', inputPath]);
    args.addAll(defaultArguments);
    args.addAll(advancedOptions.toFfmpegArguments());
    args.addAll(['-f', outputFormat, outputUri]);
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
  final List<String> customArguments;
  final ConversionAdvancedOptions advancedOptions;
  final ConversionOutputKind outputKind;
  final StreamOutputProfileId? streamProfileId;
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
    this.customArguments = const [],
    this.advancedOptions = const ConversionAdvancedOptions(),
    this.outputKind = ConversionOutputKind.file,
    this.streamProfileId,
    required this.currentStage,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  ConversionPreset get preset => ConversionPreset.byId(presetId);

  StreamOutputProfile? get streamProfile => streamProfileId == null
      ? null
      : StreamOutputProfile.byId(streamProfileId!);

  String get displayLabel =>
      outputKind == ConversionOutputKind.stream && streamProfile != null
          ? streamProfile!.label
          : preset.label;

  ConversionJob copyWith({
    ConversionStatus? status,
    double? progress,
    int? durationSeconds,
    int? processedSeconds,
    double? speed,
    int? outputSizeBytes,
    List<String>? customArguments,
    ConversionAdvancedOptions? advancedOptions,
    ConversionOutputKind? outputKind,
    StreamOutputProfileId? streamProfileId,
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
      customArguments: customArguments ?? this.customArguments,
      advancedOptions: advancedOptions ?? this.advancedOptions,
      outputKind: outputKind ?? this.outputKind,
      streamProfileId: streamProfileId ?? this.streamProfileId,
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
      'customArguments': customArguments,
      'advancedOptions': advancedOptions.toJson(),
      'outputKind': outputKind.name,
      'streamProfileId': streamProfileId?.name,
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
      customArguments: (json['customArguments'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      advancedOptions: ConversionAdvancedOptions.fromJson(
        (json['advancedOptions'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      outputKind: _enumByName(
        ConversionOutputKind.values,
        json['outputKind'] as String?,
        ConversionOutputKind.file,
      ),
      streamProfileId: _nullableEnumByName(
        StreamOutputProfileId.values,
        json['streamProfileId'] as String?,
      ),
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

  static T? _nullableEnumByName<T extends Enum>(
    List<T> values,
    String? name,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

class MediaProbeInfo {
  final String path;
  final String? formatName;
  final String? formatLongName;
  final int? durationSeconds;
  final int? bitrate;
  final int? sizeBytes;
  final Map<String, String> metadata;
  final List<MediaProbeStream> streams;
  final List<MediaProbeChapter> chapters;
  final List<MediaProbeAttachment> attachments;

  const MediaProbeInfo({
    required this.path,
    this.formatName,
    this.formatLongName,
    this.durationSeconds,
    this.bitrate,
    this.sizeBytes,
    this.metadata = const {},
    this.streams = const [],
    this.chapters = const [],
    this.attachments = const [],
  });

  static MediaProbeInfo fromFfprobeJson(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final format = json['format'];
    final streams = <MediaProbeStream>[];
    final rawStreams = json['streams'];
    if (rawStreams is List) {
      for (final raw in rawStreams) {
        if (raw is! Map) continue;
        streams.add(
          MediaProbeStream.fromFfprobeJson(
            raw.map((key, value) => MapEntry(key.toString(), value)),
            fallbackIndex: streams.length,
          ),
        );
      }
    }
    final chapters = <MediaProbeChapter>[];
    final rawChapters = json['chapters'];
    if (rawChapters is List) {
      for (final raw in rawChapters) {
        if (raw is! Map) continue;
        chapters.add(
          MediaProbeChapter.fromFfprobeJson(
            raw.map((key, value) => MapEntry(key.toString(), value)),
            fallbackIndex: chapters.length,
          ),
        );
      }
    }
    final attachments = streams
        .where((stream) =>
            stream.codecType == 'attachment' || stream.isAttachedPicture)
        .map(MediaProbeAttachment.fromStream)
        .toList(growable: false);

    if (format is! Map) {
      return MediaProbeInfo(
        path: path,
        streams: streams,
        chapters: chapters,
        attachments: attachments,
      );
    }

    final rawFormat =
        format.map((key, value) => MapEntry(key.toString(), value));
    return MediaProbeInfo(
      path: path,
      formatName: rawFormat['format_name']?.toString(),
      formatLongName: rawFormat['format_long_name']?.toString(),
      durationSeconds:
          double.tryParse(rawFormat['duration']?.toString() ?? '')?.round(),
      bitrate: int.tryParse(rawFormat['bit_rate']?.toString() ?? ''),
      sizeBytes: int.tryParse(rawFormat['size']?.toString() ?? ''),
      metadata: _stringMap(rawFormat['tags']),
      streams: streams,
      chapters: chapters,
      attachments: attachments,
    );
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, raw) => MapEntry(key.toString(), raw.toString()));
  }
}

class MediaProbeChapter {
  final int index;
  final int? startSeconds;
  final int? endSeconds;
  final String? title;
  final Map<String, String> metadata;

  const MediaProbeChapter({
    required this.index,
    this.startSeconds,
    this.endSeconds,
    this.title,
    this.metadata = const {},
  });

  int? get durationSeconds {
    final start = startSeconds;
    final end = endSeconds;
    if (start == null || end == null || end < start) return null;
    return end - start;
  }

  static MediaProbeChapter fromFfprobeJson(
    Map<String, dynamic> json, {
    required int fallbackIndex,
  }) {
    final metadata = _stringMap(json['tags']);
    return MediaProbeChapter(
      index: (json['id'] as num?)?.toInt() ??
          (json['index'] as num?)?.toInt() ??
          fallbackIndex,
      startSeconds: _secondsValue(json['start_time']),
      endSeconds: _secondsValue(json['end_time']),
      title: metadata['title'],
      metadata: metadata,
    );
  }

  static int? _secondsValue(Object? value) {
    if (value == null) return null;
    if (value is num) return value.round();
    return double.tryParse(value.toString())?.round();
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, raw) => MapEntry(key.toString(), raw.toString()));
  }
}

class MediaProbeAttachment {
  final int streamIndex;
  final String? fileName;
  final String? mimeType;
  final String? codecName;
  final bool isCoverArt;

  const MediaProbeAttachment({
    required this.streamIndex,
    this.fileName,
    this.mimeType,
    this.codecName,
    this.isCoverArt = false,
  });

  factory MediaProbeAttachment.fromStream(MediaProbeStream stream) {
    return MediaProbeAttachment(
      streamIndex: stream.index,
      fileName: stream.metadata['filename'],
      mimeType: stream.metadata['mimetype'],
      codecName: stream.codecName,
      isCoverArt: stream.isAttachedPicture,
    );
  }
}

class MediaProbeStream {
  final int index;
  final String codecType;
  final String? codecName;
  final String? codecLongName;
  final int? width;
  final int? height;
  final double? frameRate;
  final int? bitrate;
  final int? durationSeconds;
  final int? sampleRate;
  final int? channels;
  final String? channelLayout;
  final String? pixelFormat;
  final String? colorRange;
  final String? colorSpace;
  final String? colorTransfer;
  final String? colorPrimaries;
  final String? language;
  final Map<String, String> metadata;
  final Map<String, String> disposition;

  const MediaProbeStream({
    required this.index,
    required this.codecType,
    this.codecName,
    this.codecLongName,
    this.width,
    this.height,
    this.frameRate,
    this.bitrate,
    this.durationSeconds,
    this.sampleRate,
    this.channels,
    this.channelLayout,
    this.pixelFormat,
    this.colorRange,
    this.colorSpace,
    this.colorTransfer,
    this.colorPrimaries,
    this.language,
    this.metadata = const {},
    this.disposition = const {},
  });

  bool get isAttachedPicture {
    final value = disposition['attached_pic']?.toLowerCase();
    return value == '1' || value == 'true' || value == 'yes';
  }

  static MediaProbeStream fromFfprobeJson(
    Map<String, dynamic> json, {
    required int fallbackIndex,
  }) {
    final metadata = _stringMap(json['tags']);
    final disposition = _stringMap(json['disposition']);
    return MediaProbeStream(
      index: (json['index'] as num?)?.toInt() ?? fallbackIndex,
      codecType: json['codec_type']?.toString() ?? 'unknown',
      codecName: json['codec_name']?.toString(),
      codecLongName: json['codec_long_name']?.toString(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      frameRate: _parseFrameRate(json['avg_frame_rate']?.toString()),
      bitrate: int.tryParse(json['bit_rate']?.toString() ?? ''),
      durationSeconds:
          double.tryParse(json['duration']?.toString() ?? '')?.round(),
      sampleRate: int.tryParse(json['sample_rate']?.toString() ?? ''),
      channels: (json['channels'] as num?)?.toInt(),
      channelLayout: json['channel_layout']?.toString(),
      pixelFormat: json['pix_fmt']?.toString(),
      colorRange: json['color_range']?.toString(),
      colorSpace: json['color_space']?.toString(),
      colorTransfer: json['color_transfer']?.toString(),
      colorPrimaries: json['color_primaries']?.toString(),
      language: metadata['language'],
      metadata: metadata,
      disposition: disposition,
    );
  }

  static double? _parseFrameRate(String? value) {
    if (value == null || value.isEmpty || value == '0/0') return null;
    final parts = value.split('/');
    if (parts.length == 2) {
      final numerator = double.tryParse(parts[0]);
      final denominator = double.tryParse(parts[1]);
      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }
      return numerator / denominator;
    }
    return double.tryParse(value);
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, raw) => MapEntry(key.toString(), raw.toString()));
  }
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
