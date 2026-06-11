/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:16
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../services/conversion_manager_platform.dart';

class ConvertTabScreen extends StatefulWidget {
  const ConvertTabScreen({super.key});

  @override
  State<ConvertTabScreen> createState() => _ConvertTabScreenState();
}

class _ConvertTabScreenState extends State<ConvertTabScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _streamTargetController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _customArgsController = TextEditingController();
  final TextEditingController _containerController = TextEditingController();
  final TextEditingController _videoCodecController = TextEditingController();
  final TextEditingController _audioCodecController = TextEditingController();
  final TextEditingController _videoBitrateController = TextEditingController();
  final TextEditingController _audioBitrateController = TextEditingController();
  final TextEditingController _crfController = TextEditingController();
  final TextEditingController _sampleRateController = TextEditingController();
  final TextEditingController _channelsController = TextEditingController();
  final TextEditingController _pixelFormatController = TextEditingController();
  final TextEditingController _videoFilterController = TextEditingController();
  final TextEditingController _audioFilterController = TextEditingController();
  final TextEditingController _subtitlePathController = TextEditingController();
  final TextEditingController _capabilitySearchController =
      TextEditingController();

  ConversionPresetId _selectedPreset = ConversionPresetId.mp3;
  StreamOutputProfileId _selectedStreamProfile = StreamOutputProfileId.rtmpH264;
  ConversionSubtitleMode _subtitleMode = ConversionSubtitleMode.preserve;
  FfmpegCapabilitySection _selectedCapabilitySection =
      FfmpegCapabilitySection.encoders;
  bool _streamOutputMode = false;
  bool _isSubmitting = false;
  bool _isProbing = false;
  bool _isLoadingCapabilities = false;
  MediaProbeInfo? _probeInfo;
  String? _probeError;
  FfmpegCapabilityCatalog? _capabilityCatalog;
  String? _capabilityError;

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _streamTargetController.dispose();
    _startController.dispose();
    _endController.dispose();
    _customArgsController.dispose();
    _containerController.dispose();
    _videoCodecController.dispose();
    _audioCodecController.dispose();
    _videoBitrateController.dispose();
    _audioBitrateController.dispose();
    _crfController.dispose();
    _sampleRateController.dispose();
    _channelsController.dispose();
    _pixelFormatController.dispose();
    _videoFilterController.dispose();
    _audioFilterController.dispose();
    _subtitlePathController.dispose();
    _capabilitySearchController.dispose();
    super.dispose();
  }

  Future<void> _startConversion(
    SettingsProvider settings,
    ConversionManager manager,
  ) async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose or paste an input file path')),
      );
      return;
    }

    if (_streamOutputMode && _streamTargetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a stream output target URL')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final advancedOptions = ConversionAdvancedOptions(
        containerExtension: _emptyToNull(_containerController.text),
        videoCodec: _emptyToNull(_videoCodecController.text),
        audioCodec: _emptyToNull(_audioCodecController.text),
        videoBitrate: _emptyToNull(_videoBitrateController.text),
        audioBitrate: _emptyToNull(_audioBitrateController.text),
        crf: _emptyToNull(_crfController.text),
        sampleRate: _emptyToNull(_sampleRateController.text),
        channels: _emptyToNull(_channelsController.text),
        pixelFormat: _emptyToNull(_pixelFormatController.text),
        videoFilter: _emptyToNull(_videoFilterController.text),
        audioFilter: _emptyToNull(_audioFilterController.text),
        subtitleMode: _subtitleMode,
        subtitlePath: _emptyToNull(_subtitlePathController.text),
      );
      if (_streamOutputMode) {
        await manager.enqueueStreamOutput(
          inputPath: input,
          outputUri: _streamTargetController.text.trim(),
          profileId: _selectedStreamProfile,
          startTime: _startController.text,
          endTime: _endController.text,
          advancedOptions: advancedOptions,
        );
      } else {
        final outputDir = _outputController.text.trim().isEmpty
            ? settings.conversionOutputDirectory
            : _outputController.text.trim();
        if (outputDir != settings.conversionOutputDirectory) {
          await settings.setConversionOutputDirectory(outputDir);
        }
        await manager.enqueueConversion(
          inputPath: input,
          presetId: _selectedPreset,
          outputDirectory: outputDir,
          startTime: _startController.text,
          endTime: _endController.text,
          customArguments: _splitCustomArguments(_customArgsController.text),
          advancedOptions: advancedOptions,
        );
      }
      _inputController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to queue conversion: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _probeInput(ConversionManager manager) async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose or paste an input file path')),
      );
      return;
    }

    setState(() {
      _isProbing = true;
      _probeError = null;
      _probeInfo = null;
    });

    try {
      final probe = await manager.probeMedia(input);
      if (!mounted) return;
      setState(() {
        _probeInfo = probe;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _probeError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isProbing = false);
      }
    }
  }

  Future<void> _loadCapabilities(ConversionManager manager) async {
    setState(() {
      _isLoadingCapabilities = true;
      _capabilityError = null;
    });

    try {
      final catalog = await manager.loadCapabilityCatalog();
      if (!mounted) return;
      setState(() {
        _capabilityCatalog = catalog;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _capabilityError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingCapabilities = false);
      }
    }
  }

  List<String> _splitCustomArguments(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed.split(RegExp(r'\s+'));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _subtitleModeLabel(ConversionSubtitleMode mode) {
    switch (mode) {
      case ConversionSubtitleMode.preserve:
        return 'Preserve';
      case ConversionSubtitleMode.copy:
        return 'Copy';
      case ConversionSubtitleMode.burnIn:
        return 'Burn in';
      case ConversionSubtitleMode.remove:
        return 'Remove';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, ConversionManager>(
      builder: (context, settings, manager, _) {
        if (_outputController.text.isEmpty) {
          _outputController.text = settings.conversionOutputDirectory;
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              child: Row(
                children: [
                  const Icon(Icons.switch_video, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: 'Convert Media',
                          child: Text(
                            'Convert Media',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '273 encoders • 607 decoders • 185 muxers • '
                          '367 demuxers • 596 filters • '
                          '51 bitstream filters • 55 protocols',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (!manager.isConfigured)
                    const Chip(
                      avatar: Icon(Icons.error_outline, size: 18),
                      label: Text('FFmpeg not configured'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _CapabilityPanel(
                catalog: _capabilityCatalog,
                errorMessage: _capabilityError,
                isLoading: _isLoadingCapabilities,
                searchController: _capabilitySearchController,
                selectedSection: _selectedCapabilitySection,
                onSectionChanged: (section) {
                  setState(() => _selectedCapabilitySection = section);
                },
                onLoad: () => _loadCapabilities(manager),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Conversion',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              decoration: const InputDecoration(
                                labelText: 'Input file path',
                                hintText: '/home/user/Videos/source.mkv',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.video_file),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed:
                                _isProbing ? null : () => _probeInput(manager),
                            icon: _isProbing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.info_outline),
                            label: Text(_isProbing ? 'Probing' : 'Probe'),
                          ),
                        ],
                      ),
                      if (_probeInfo != null || _probeError != null) ...[
                        const SizedBox(height: 12),
                        _ProbeSummary(
                          probeInfo: _probeInfo,
                          errorMessage: _probeError,
                        ),
                      ],
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.save_alt),
                            label: Text('File'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.cast_connected),
                            label: Text('Stream'),
                          ),
                        ],
                        selected: {_streamOutputMode},
                        onSelectionChanged: (selection) {
                          setState(
                            () => _streamOutputMode = selection.first,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _streamOutputMode
                                ? DropdownButtonFormField<
                                    StreamOutputProfileId>(
                                    initialValue: _selectedStreamProfile,
                                    decoration: const InputDecoration(
                                      labelText: 'Stream profile',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: StreamOutputProfile.profiles
                                        .map((profile) {
                                      return DropdownMenuItem(
                                        value: profile.id,
                                        child: Text(
                                          '${profile.label} • '
                                          '${profile.description}',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(
                                          () => _selectedStreamProfile = value,
                                        );
                                      }
                                    },
                                  )
                                : DropdownButtonFormField<ConversionPresetId>(
                                    initialValue: _selectedPreset,
                                    decoration: const InputDecoration(
                                      labelText: 'Output profile',
                                      border: OutlineInputBorder(),
                                    ),
                                    items:
                                        ConversionPreset.presets.map((preset) {
                                      return DropdownMenuItem(
                                        value: preset.id,
                                        child: Text(
                                          '${preset.label} • '
                                          '${preset.description}',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedPreset = value);
                                      }
                                    },
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _streamOutputMode
                                ? TextField(
                                    controller: _streamTargetController,
                                    decoration: const InputDecoration(
                                      labelText: 'Stream target URL',
                                      hintText: 'rtmp://server/live/key',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.link),
                                    ),
                                  )
                                : TextField(
                                    controller: _outputController,
                                    decoration: const InputDecoration(
                                      labelText: 'Output folder',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.folder),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (!_streamOutputMode &&
                          _selectedPreset == ConversionPresetId.custom) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customArgsController,
                          decoration: const InputDecoration(
                            labelText: 'Custom FFmpeg output arguments',
                            hintText: '-c:v libx265 -crf 24 -c:a aac',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.tune),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Advanced codec and filter controls'),
                        childrenPadding: const EdgeInsets.only(bottom: 12),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _containerController,
                                  decoration: const InputDecoration(
                                    labelText: 'Container',
                                    hintText: 'mp4',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _videoCodecController,
                                  decoration: const InputDecoration(
                                    labelText: 'Video codec',
                                    hintText: 'libx264',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _audioCodecController,
                                  decoration: const InputDecoration(
                                    labelText: 'Audio codec',
                                    hintText: 'aac',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _videoBitrateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Video bitrate',
                                    hintText: '2500k',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _audioBitrateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Audio bitrate',
                                    hintText: '160k',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _crfController,
                                  decoration: const InputDecoration(
                                    labelText: 'CRF',
                                    hintText: '23',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _sampleRateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sample rate',
                                    hintText: '48000',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _channelsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Channels',
                                    hintText: '2',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _pixelFormatController,
                                  decoration: const InputDecoration(
                                    labelText: 'Pixel format',
                                    hintText: 'yuv420p',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _videoFilterController,
                                  decoration: const InputDecoration(
                                    labelText: 'Video filter chain',
                                    hintText: 'scale=-2:720',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _audioFilterController,
                                  decoration: const InputDecoration(
                                    labelText: 'Audio filter chain',
                                    hintText: 'loudnorm',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<
                                    ConversionSubtitleMode>(
                                  initialValue: _subtitleMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Subtitles',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      ConversionSubtitleMode.values.map((mode) {
                                    return DropdownMenuItem(
                                      value: mode,
                                      child: Text(_subtitleModeLabel(mode)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _subtitleMode = value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _subtitlePathController,
                                  enabled: _subtitleMode ==
                                      ConversionSubtitleMode.burnIn,
                                  decoration: const InputDecoration(
                                    labelText: 'Subtitle file',
                                    hintText: '/home/user/subtitles.srt',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startController,
                              decoration: const InputDecoration(
                                labelText: 'Start time',
                                hintText: 'HH:MM:SS',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _endController,
                              decoration: const InputDecoration(
                                labelText: 'End time',
                                hintText: 'HH:MM:SS',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _startConversion(settings, manager),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: Text(
                              _isSubmitting
                                  ? 'Queueing'
                                  : _streamOutputMode
                                      ? 'Stream'
                                      : 'Start',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Conversion Queue',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: manager.jobs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checklist_rtl,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No conversion jobs yet'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: manager.jobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _ConversionJobTile(job: manager.jobs[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CapabilityPanel extends StatefulWidget {
  final FfmpegCapabilityCatalog? catalog;
  final String? errorMessage;
  final bool isLoading;
  final TextEditingController searchController;
  final FfmpegCapabilitySection selectedSection;
  final ValueChanged<FfmpegCapabilitySection> onSectionChanged;
  final VoidCallback onLoad;

  const _CapabilityPanel({
    required this.catalog,
    required this.errorMessage,
    required this.isLoading,
    required this.searchController,
    required this.selectedSection,
    required this.onSectionChanged,
    required this.onLoad,
  });

  @override
  State<_CapabilityPanel> createState() => _CapabilityPanelState();
}

class _CapabilityPanelState extends State<_CapabilityPanel> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _CapabilityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController == widget.searchController) return;
    oldWidget.searchController.removeListener(_refresh);
    widget.searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final inventory = catalog?.inventory;
    final sectionEntries =
        catalog?.entriesFor(widget.selectedSection) ?? const [];
    final query = widget.searchController.text.trim();
    final filteredEntries = query.isEmpty
        ? sectionEntries
        : sectionEntries.where((entry) => entry.matches(query)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'FFmpeg Capabilities',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : widget.onLoad,
                  icon: widget.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(widget.isLoading ? 'Loading' : 'Load'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _countChip('Encoders', inventory?.encoders, 273),
                _countChip('Decoders', inventory?.decoders, 607),
                _countChip('Muxers', inventory?.muxers, 185),
                _countChip('Demuxers', inventory?.demuxers, 367),
                _countChip('Filters', inventory?.filters, 596),
                _countChip(
                    'Bitstream filters', inventory?.bitstreamFilters, 51),
                _countChip('Protocols', inventory?.protocols, 55),
              ],
            ),
            if (widget.errorMessage != null &&
                widget.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (catalog != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<FfmpegCapabilitySection>(
                      initialValue: widget.selectedSection,
                      decoration: const InputDecoration(
                        labelText: 'Capability section',
                        border: OutlineInputBorder(),
                      ),
                      items: FfmpegCapabilitySection.values.map((section) {
                        return DropdownMenuItem(
                          value: section,
                          child: Text(_sectionLabel(section)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) widget.onSectionChanged(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: widget.searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search capabilities',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: filteredEntries.isEmpty
                    ? const Center(child: Text('No matching capabilities'))
                    : ListView.separated(
                        itemCount: filteredEntries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.name),
                            subtitle: Text(
                              _entrySubtitle(entry),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: entry.flags.isEmpty
                                ? null
                                : Chip(label: Text(entry.flags)),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _countChip(String label, int? actual, int requiredCount) {
    final value = actual == null ? '$requiredCount required' : '$actual';
    return Chip(label: Text('$label: $value'));
  }

  String _sectionLabel(FfmpegCapabilitySection section) {
    switch (section) {
      case FfmpegCapabilitySection.encoders:
        return 'Encoders';
      case FfmpegCapabilitySection.decoders:
        return 'Decoders';
      case FfmpegCapabilitySection.muxers:
        return 'Muxers';
      case FfmpegCapabilitySection.demuxers:
        return 'Demuxers';
      case FfmpegCapabilitySection.filters:
        return 'Filters';
      case FfmpegCapabilitySection.bitstreamFilters:
        return 'Bitstream filters';
      case FfmpegCapabilitySection.protocols:
        return 'Protocols';
    }
  }

  String _entrySubtitle(FfmpegCapabilityEntry entry) {
    if (entry.section == FfmpegCapabilitySection.protocols) {
      final directions = <String>[
        if (entry.supportsInput) 'input',
        if (entry.supportsOutput) 'output',
      ];
      return directions.isEmpty
          ? 'Protocol'
          : '${directions.join(' and ')} protocol';
    }
    return entry.description.isEmpty
        ? _sectionLabel(entry.section)
        : entry.description;
  }
}

class _ProbeSummary extends StatelessWidget {
  final MediaProbeInfo? probeInfo;
  final String? errorMessage;

  const _ProbeSummary({required this.probeInfo, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final error = errorMessage?.trim();
    if (error != null && error.isNotEmpty) {
      return Text(error, style: const TextStyle(color: Colors.red));
    }

    final info = probeInfo;
    if (info == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (info.formatLongName != null || info.formatName != null)
                  Chip(
                    label: Text(info.formatLongName ?? info.formatName!),
                  ),
                if (info.durationSeconds != null)
                  Chip(label: Text(_duration(info.durationSeconds!))),
                if (info.bitrate != null)
                  Chip(label: Text(_bitrate(info.bitrate!))),
                if (info.sizeBytes != null)
                  Chip(label: Text(_bytes(info.sizeBytes!))),
              ],
            ),
            if (info.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                info.metadata.entries
                    .take(4)
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (info.streams.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                children: info.streams.map((stream) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_streamIcon(stream.codecType)),
                    title: Text(
                      _streamTitle(stream),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _streamSubtitle(stream),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _streamIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.movie_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'subtitle':
        return Icons.subtitles_outlined;
      default:
        return Icons.notes_outlined;
    }
  }

  String _streamTitle(MediaProbeStream stream) {
    final language = stream.language == null ? '' : ' • ${stream.language}';
    return '#${stream.index} ${stream.codecType}$language';
  }

  String _streamSubtitle(MediaProbeStream stream) {
    final details = <String>[
      if (stream.codecLongName != null) stream.codecLongName!,
      if (stream.codecLongName == null && stream.codecName != null)
        stream.codecName!,
      if (stream.width != null && stream.height != null)
        '${stream.width}x${stream.height}',
      if (stream.frameRate != null)
        '${stream.frameRate!.toStringAsFixed(2)} fps',
      if (stream.sampleRate != null) '${stream.sampleRate} Hz',
      if (stream.channels != null) '${stream.channels} channels',
      if (stream.bitrate != null) _bitrate(stream.bitrate!),
    ];
    return details.isEmpty ? 'Stream details unavailable' : details.join(' • ');
  }

  String _duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remaining = seconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${remaining.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  String _bitrate(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)} Mb/s';
    return '${(value / 1000).round()} kb/s';
  }

  String _bytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
    if (value < 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _ConversionJobTile extends StatelessWidget {
  final ConversionJob job;

  const _ConversionJobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<ConversionManager>(context, listen: false);
    final progress = job.progress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${job.displayLabel}: ${_fileName(job.inputPath)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(_statusLabel(job.status))),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${job.outputKind == ConversionOutputKind.stream ? 'Target' : 'Output'}: '
              '${job.outputPath}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (progress == null) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text(job.currentStage),
            ] else ...[
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% • '
                '${job.currentStage}${_speedLabel(job)}',
              ),
            ],
            if (job.errorMessage != null &&
                job.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                job.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (job.status == ConversionStatus.running ||
                    job.status == ConversionStatus.probing ||
                    job.status == ConversionStatus.queued)
                  TextButton(
                    onPressed: () => manager.cancelConversion(job.id),
                    child: const Text('Cancel'),
                  ),
                if (job.status == ConversionStatus.failed ||
                    job.status == ConversionStatus.cancelled)
                  TextButton(
                    onPressed: () => manager.retryConversion(job.id),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(ConversionStatus status) {
    switch (status) {
      case ConversionStatus.queued:
        return 'Queued';
      case ConversionStatus.probing:
        return 'Probing';
      case ConversionStatus.running:
        return 'Running';
      case ConversionStatus.completed:
        return 'Completed';
      case ConversionStatus.failed:
        return 'Failed';
      case ConversionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _fileName(String path) {
    return path.split(RegExp(r'[/\\]')).last;
  }

  String _speedLabel(ConversionJob job) {
    final speed = job.speed;
    if (speed == null) return '';
    return ' • ${speed.toStringAsFixed(2)}x';
  }
}
