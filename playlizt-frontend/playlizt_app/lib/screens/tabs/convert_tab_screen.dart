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

  ConversionPresetId _selectedPreset = ConversionPresetId.mp3;
  ConversionSubtitleMode _subtitleMode = ConversionSubtitleMode.preserve;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
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

    final outputDir = _outputController.text.trim().isEmpty
        ? settings.conversionOutputDirectory
        : _outputController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      if (outputDir != settings.conversionOutputDirectory) {
        await settings.setConversionOutputDirectory(outputDir);
      }
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
      await manager.enqueueConversion(
        inputPath: input,
        presetId: _selectedPreset,
        outputDirectory: outputDir,
        startTime: _startController.text,
        endTime: _endController.text,
        customArguments: _splitCustomArguments(_customArgsController.text),
        advancedOptions: advancedOptions,
      );
      _inputController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to queue conversion: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                      TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          labelText: 'Input file path',
                          hintText: '/home/user/Videos/source.mkv',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.video_file),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedPreset == ConversionPresetId.custom) ...[
                        TextField(
                          controller: _customArgsController,
                          decoration: const InputDecoration(
                            labelText: 'Custom FFmpeg output arguments',
                            hintText: '-c:v libx265 -crf 24 -c:a aac',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.tune),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ConversionPresetId>(
                              initialValue: _selectedPreset,
                              decoration: const InputDecoration(
                                labelText: 'Output profile',
                                border: OutlineInputBorder(),
                              ),
                              items: ConversionPreset.presets.map((preset) {
                                return DropdownMenuItem(
                                  value: preset.id,
                                  child: Text(
                                      '${preset.label} • ${preset.description}'),
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
                            child: TextField(
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
                            label: Text(_isSubmitting ? 'Queueing' : 'Start'),
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
                    '${job.preset.label}: ${_fileName(job.inputPath)}',
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
              job.outputPath,
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
