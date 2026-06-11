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
import 'device_discovery_platform.dart';
import 'device_discovery_source.dart';
import 'device_models.dart';

class DeviceManager with ChangeNotifier {
  static const _prefsKeyDevices = 'devices.custom';

  final SettingsProvider settingsProvider;
  final RendererDiscoverySource discoverySource;
  final Map<String, PlaybackDevice> _customDevices = {};
  final Map<String, PlaybackDevice> _discoveredDevices = {};
  bool _isLoaded = false;
  bool _isDiscovering = false;
  String? _discoveryError;
  DateTime? _lastDiscoveryAt;

  DeviceManager({
    required this.settingsProvider,
    RendererDiscoverySource? discoverySource,
  }) : discoverySource =
            discoverySource ?? const PlatformRendererDiscoverySource() {
    _load();
  }

  bool get isLoaded => _isLoaded;
  bool get isDiscovering => _isDiscovering;
  String? get discoveryError => _discoveryError;
  DateTime? get lastDiscoveryAt => _lastDiscoveryAt;

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
    final list = [
      local,
      ..._customDevices.values,
      ..._discoveredDevices.values,
    ];
    list.sort((a, b) {
      if (a.type == PlaybackDeviceType.local) return -1;
      if (b.type == PlaybackDeviceType.local) return 1;
      if (a.type == PlaybackDeviceType.renderer &&
          b.type != PlaybackDeviceType.renderer) {
        return -1;
      }
      if (b.type == PlaybackDeviceType.renderer &&
          a.type != PlaybackDeviceType.renderer) {
        return 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  PlaybackDevice? deviceById(String id) {
    if (id == 'local-this-device') {
      return devices.firstWhere((device) => device.id == id);
    }
    return _customDevices[id] ?? _discoveredDevices[id];
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
      _isDiscovering = false;
      _discoveryError = null;
      notifyListeners();
      return;
    }
    _isDiscovering = true;
    _discoveryError = null;
    notifyListeners();

    try {
      final discovered = await discoverySource.discover();
      final next = <String, PlaybackDevice>{};
      for (final device in discovered) {
        if (device.type != PlaybackDeviceType.renderer) continue;
        next[device.id] = _mergeRendererState(
          fresh: device,
          previous: _discoveredDevices[device.id],
        );
      }
      _discoveredDevices
        ..clear()
        ..addAll(next);
      _lastDiscoveryAt = DateTime.now();
    } catch (e) {
      _discoveryError = e.toString();
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  Future<void> connectRenderer(String id) async {
    final device = _rendererById(id);
    _discoveredDevices[id] = device.copyWith(
      connected: true,
      status: PlaybackDeviceStatus.available,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> disconnectRenderer(String id) async {
    final device = _rendererById(id);
    _discoveredDevices[id] = device.copyWith(
      connected: false,
      status: PlaybackDeviceStatus.available,
      transportState: PlaybackTransportState.stopped,
      activeUri: null,
      activeTitle: null,
      positionSeconds: 0,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> playOnRenderer({
    required String deviceId,
    required String title,
    required String uri,
  }) async {
    final parsed = Uri.tryParse(uri.trim());
    if (parsed == null ||
        !(parsed.isScheme('http') ||
            parsed.isScheme('https') ||
            parsed.isScheme('rtsp') ||
            parsed.isScheme('rtmp'))) {
      throw ArgumentError(
          'Renderer media URL must be HTTP, HTTPS, RTSP or RTMP');
    }

    final device = _rendererById(deviceId);
    _discoveredDevices[deviceId] = device.copyWith(
      connected: true,
      status: PlaybackDeviceStatus.playing,
      transportState: PlaybackTransportState.playing,
      activeUri: parsed.toString(),
      activeTitle: title.trim().isEmpty ? parsed.toString() : title.trim(),
      positionSeconds: 0,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> resumeRenderer(String id) async {
    final device = _rendererById(id);
    if (device.activeUri == null) {
      throw StateError('Renderer has no active media to resume');
    }
    _discoveredDevices[id] = device.copyWith(
      connected: true,
      status: PlaybackDeviceStatus.playing,
      transportState: PlaybackTransportState.playing,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> pauseRenderer(String id) async {
    final device = _rendererById(id);
    if (device.activeUri == null) {
      throw StateError('Renderer has no active media to pause');
    }
    _discoveredDevices[id] = device.copyWith(
      connected: true,
      status: PlaybackDeviceStatus.available,
      transportState: PlaybackTransportState.paused,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> stopRenderer(String id) async {
    final device = _rendererById(id);
    _discoveredDevices[id] = device.copyWith(
      connected: true,
      status: PlaybackDeviceStatus.available,
      transportState: PlaybackTransportState.stopped,
      activeUri: null,
      activeTitle: null,
      positionSeconds: 0,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> seekRenderer(String id, int positionSeconds) async {
    final device = _rendererById(id);
    if (device.activeUri == null) {
      throw StateError('Renderer has no active media to seek');
    }
    _discoveredDevices[id] = device.copyWith(
      positionSeconds: positionSeconds < 0 ? 0 : positionSeconds,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> setRendererVolume(String id, int volumePercent) async {
    final device = _rendererById(id);
    _discoveredDevices[id] = device.copyWith(
      volumePercent: volumePercent.clamp(0, 100).toInt(),
      muted: volumePercent <= 0,
      errorMessage: null,
    );
    notifyListeners();
  }

  PlaybackDevice _rendererById(String id) {
    final device = _discoveredDevices[id];
    if (device == null) {
      throw StateError('Renderer not found: $id');
    }
    if (device.type != PlaybackDeviceType.renderer) {
      throw StateError('Device is not a renderer: $id');
    }
    return device;
  }

  PlaybackDevice _mergeRendererState({
    required PlaybackDevice fresh,
    required PlaybackDevice? previous,
  }) {
    if (previous == null) return fresh;
    return fresh.copyWith(
      connected: previous.connected,
      status: previous.status == PlaybackDeviceStatus.error
          ? PlaybackDeviceStatus.available
          : previous.status,
      transportState: previous.transportState,
      activeUri: previous.activeUri,
      activeTitle: previous.activeTitle,
      positionSeconds: previous.positionSeconds,
      volumePercent: previous.volumePercent,
      muted: previous.muted,
      errorMessage: null,
    );
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
