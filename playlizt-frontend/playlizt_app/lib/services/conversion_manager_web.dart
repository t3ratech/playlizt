/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 21:43
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import 'conversion_models.dart';
import 'library_manager_platform.dart';

class ConversionManager with ChangeNotifier {
  static const _prefsKeyJobs = 'conversion.jobs';

  final SettingsProvider settingsProvider;
  final LibraryManager libraryManager;

  final Map<String, ConversionJob> _jobs = {};
  bool _isLoaded = false;

  ConversionManager({
    required this.settingsProvider,
    required this.libraryManager,
  }) {
    _load();
  }

  bool get isLoaded => _isLoaded;
  bool get isConfigured => false;

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
  }) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final job = ConversionJob(
      id: id,
      inputPath: inputPath,
      outputPath: outputDirectory?.trim().isNotEmpty == true
          ? '${outputDirectory!.trim()}/web-conversion-disabled'
          : 'web-conversion-disabled',
      presetId: presetId,
      status: ConversionStatus.failed,
      startTime: startTime,
      endTime: endTime,
      currentStage: 'Unavailable on web',
      errorMessage:
          'Local conversion requires the desktop app with FFmpeg configured.',
      createdAt: now,
      updatedAt: now,
    );
    _jobs[id] = job;
    await _persist();
    notifyListeners();
    return job;
  }

  Future<void> cancelConversion(String id) async {
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
      status: ConversionStatus.failed,
      currentStage: 'Unavailable on web',
      errorMessage:
          'Local conversion requires the desktop app with FFmpeg configured.',
    );
    await _persist();
    notifyListeners();
  }

  Future<MediaProbeInfo> probeMedia(String inputPath) async {
    throw StateError(
        'Media probe requires the desktop app with FFprobe configured.');
  }

  Future<FfmpegCapabilityInventory> loadCapabilityInventory() async {
    throw StateError(
      'FFmpeg capability inventory requires the desktop app with FFmpeg configured.',
    );
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
}
