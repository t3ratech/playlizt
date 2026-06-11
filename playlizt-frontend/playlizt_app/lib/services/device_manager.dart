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
import 'device_models.dart';

class DeviceManager with ChangeNotifier {
  static const _prefsKeyDevices = 'devices.custom';

  final SettingsProvider settingsProvider;
  final Map<String, PlaybackDevice> _customDevices = {};
  bool _isLoaded = false;

  DeviceManager({required this.settingsProvider}) {
    _load();
  }

  bool get isLoaded => _isLoaded;

  List<PlaybackDevice> get devices {
    final local = PlaybackDevice(
      id: 'local-this-device',
      name: 'This Device',
      type: PlaybackDeviceType.local,
      status: PlaybackDeviceStatus.available,
      capabilities: const [
        'local playback',
        'network streams',
        'conversion handoff',
      ],
      lastSeen: DateTime.now(),
    );
    final list = [local, ..._customDevices.values];
    list.sort((a, b) {
      if (a.type == PlaybackDeviceType.local) return -1;
      if (b.type == PlaybackDeviceType.local) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<PlaybackDevice> addNetworkStream({
    required String name,
    required String uri,
  }) async {
    final parsed = Uri.tryParse(uri.trim());
    if (parsed == null ||
        !(parsed.isScheme('http') ||
            parsed.isScheme('https') ||
            parsed.isScheme('rtsp') ||
            parsed.isScheme('rtmp'))) {
      throw ArgumentError('Network stream must be HTTP, HTTPS, RTSP or RTMP');
    }

    final now = DateTime.now();
    final id = 'stream-${now.microsecondsSinceEpoch}';
    final device = PlaybackDevice(
      id: id,
      name: name.trim().isEmpty ? parsed.host : name.trim(),
      type: PlaybackDeviceType.networkStream,
      status: PlaybackDeviceStatus.available,
      uri: parsed.toString(),
      capabilities: const ['network playback', 'local player'],
      lastSeen: now,
    );
    _customDevices[id] = device;
    await _persist();
    notifyListeners();
    return device;
  }

  Future<void> removeDevice(String id) async {
    _customDevices.remove(id);
    await _persist();
    notifyListeners();
  }

  Future<void> markPlaying(String id) async {
    final device = _customDevices[id];
    if (device == null) return;
    _customDevices[id] = device.copyWith(
      status: PlaybackDeviceStatus.playing,
      errorMessage: null,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> markAvailable(String id) async {
    final device = _customDevices[id];
    if (device == null) return;
    _customDevices[id] = device.copyWith(
      status: PlaybackDeviceStatus.available,
      errorMessage: null,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> markError(String id, String message) async {
    final device = _customDevices[id];
    if (device == null) return;
    _customDevices[id] = device.copyWith(
      status: PlaybackDeviceStatus.error,
      errorMessage: message,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> refreshDiscovery() async {
    await settingsProvider.ensureLoaded();
    if (!settingsProvider.rendererDiscoveryEnabled) {
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyDevices);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final device = PlaybackDevice.fromJson(item);
              _customDevices[device.id] = device;
            } else if (item is Map) {
              final device = PlaybackDevice.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              );
              _customDevices[device.id] = device;
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
      _prefsKeyDevices,
      jsonEncode(
          _customDevices.values.map((device) => device.toJson()).toList()),
    );
  }
}
