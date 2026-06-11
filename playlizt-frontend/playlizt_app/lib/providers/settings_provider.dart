/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:20
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlizt_tab.dart';
import '../services/conversion_models.dart';

/// Centralised runtime settings store for the frontend shell.
///
/// This keeps user-facing configuration such as download directories,
/// library scan folders and general UI preferences. Values are persisted
/// via SharedPreferences so they survive restarts.
class SettingsProvider with ChangeNotifier {
  static const _keyUseDefaultDownloadLocation =
      'settings.useDefaultDownloadLocation';
  static const _keyDownloadDirectory = 'settings.downloadDirectory';
  static const _keyLibraryScanFolders = 'settings.libraryScanFolders';
  static const _keyMaxConcurrentDownloads = 'settings.maxConcurrentDownloads';
  static const _keyStartupTabIndex = 'settings.startupTabIndex';
  static const _keyCompactLayout = 'settings.compactLayout';
  static const _keyVisibleTabs = 'settings.visibleTabs';
  static const _keyRecursiveLibraryScan = 'settings.recursiveLibraryScan';
  static const _keyConversionOutputDirectory =
      'settings.conversionOutputDirectory';
  static const _keyConversionOutputCollisionPolicy =
      'settings.conversionOutputCollisionPolicy';
  static const _keyHardwareAccelerationEnabled =
      'settings.hardwareAccelerationEnabled';
  static const _keyRendererDiscoveryEnabled =
      'settings.rendererDiscoveryEnabled';
  static const _keyDownloadArchiveEnabled = 'settings.downloadArchiveEnabled';

  bool _useDefaultDownloadLocation = true;
  String _downloadDirectory = '~/Downloads';
  List<String> _libraryScanFolders = [];
  int _maxConcurrentDownloads = 2;
  int _startupTabIndex = 2; // 0=Library,1=Playlists,2=Streaming(default),...
  bool _compactLayout = false;
  bool _recursiveLibraryScan = true;
  String _conversionOutputDirectory = '~/Videos/Playlizt';
  ConversionOutputCollisionPolicy _conversionOutputCollisionPolicy =
      ConversionOutputCollisionPolicy.keepBoth;
  bool _hardwareAccelerationEnabled = true;
  bool _rendererDiscoveryEnabled = true;
  bool _downloadArchiveEnabled = true;

  // Indices of visible tabs in the global shell, in order.
  // 0=Library,1=Playlists,2=Streaming,3=Download,4=Convert,5=Devices.
  List<int> _visibleTabIndices = List<int>.generate(6, (index) => index);

  bool _isLoaded = false;
  Completer<void>? _loadCompleter;

  bool get isLoaded => _isLoaded;
  bool get useDefaultDownloadLocation => _useDefaultDownloadLocation;
  String get downloadDirectory => _downloadDirectory;
  List<String> get libraryScanFolders => List.unmodifiable(_libraryScanFolders);
  int get maxConcurrentDownloads => _maxConcurrentDownloads;
  int get startupTabIndex => _startupTabIndex;
  bool get compactLayout => _compactLayout;
  bool get recursiveLibraryScan => _recursiveLibraryScan;
  String get conversionOutputDirectory => _conversionOutputDirectory;
  ConversionOutputCollisionPolicy get conversionOutputCollisionPolicy =>
      _conversionOutputCollisionPolicy;
  bool get hardwareAccelerationEnabled => _hardwareAccelerationEnabled;
  bool get rendererDiscoveryEnabled => _rendererDiscoveryEnabled;
  bool get downloadArchiveEnabled => _downloadArchiveEnabled;
  List<int> get visibleTabIndices => List.unmodifiable(_visibleTabIndices);
  bool isTabVisible(int index) => _visibleTabIndices.contains(index);

  static Future<bool> loadInitialHardwareAccelerationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHardwareAccelerationEnabled) ?? true;
  }

  SettingsProvider() {
    _load();
  }

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    _loadCompleter ??= Completer<void>();
    return _loadCompleter!.future;
  }

  Future<void> _load() async {
    _loadCompleter ??= Completer<void>();
    try {
      final prefs = await SharedPreferences.getInstance();
      _useDefaultDownloadLocation =
          prefs.getBool(_keyUseDefaultDownloadLocation) ?? true;
      _downloadDirectory =
          prefs.getString(_keyDownloadDirectory) ?? _downloadDirectory;
      _libraryScanFolders =
          prefs.getStringList(_keyLibraryScanFolders) ?? <String>[];
      _maxConcurrentDownloads =
          prefs.getInt(_keyMaxConcurrentDownloads) ?? _maxConcurrentDownloads;
      _startupTabIndex = prefs.getInt(_keyStartupTabIndex) ?? _startupTabIndex;
      _compactLayout = prefs.getBool(_keyCompactLayout) ?? _compactLayout;
      _recursiveLibraryScan =
          prefs.getBool(_keyRecursiveLibraryScan) ?? _recursiveLibraryScan;
      _conversionOutputDirectory =
          prefs.getString(_keyConversionOutputDirectory) ??
              _conversionOutputDirectory;
      _conversionOutputCollisionPolicy = _enumByName(
        ConversionOutputCollisionPolicy.values,
        prefs.getString(_keyConversionOutputCollisionPolicy),
        _conversionOutputCollisionPolicy,
      );
      _hardwareAccelerationEnabled =
          prefs.getBool(_keyHardwareAccelerationEnabled) ??
              _hardwareAccelerationEnabled;
      _rendererDiscoveryEnabled = prefs.getBool(_keyRendererDiscoveryEnabled) ??
          _rendererDiscoveryEnabled;
      _downloadArchiveEnabled =
          prefs.getBool(_keyDownloadArchiveEnabled) ?? _downloadArchiveEnabled;

      final storedVisible = prefs.getStringList(_keyVisibleTabs);
      if (storedVisible != null && storedVisible.isNotEmpty) {
        _visibleTabIndices = storedVisible
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .where((i) => i >= 0 && i < 6)
            .toSet()
            .toList()
          ..sort();
      }

      _enforceVisibilityConstraints();

      _isLoaded = true;
      if (!(_loadCompleter?.isCompleted ?? true)) {
        _loadCompleter!.complete();
      }
      notifyListeners();
    } catch (e) {
      if (!(_loadCompleter?.isCompleted ?? true)) {
        _loadCompleter!.completeError(e);
      }
      if (kDebugMode) {
        print('SettingsProvider: failed to load settings: $e');
      }
    }
  }

  Future<void> applyRemoteSettings({
    required String downloadDirectory,
    required List<String> libraryScanFolders,
    required int maxConcurrentDownloads,
    required List<String> visibleTabs,
    required String startupTab,
  }) async {
    _downloadDirectory = downloadDirectory;
    _libraryScanFolders = List<String>.from(libraryScanFolders);
    _maxConcurrentDownloads = maxConcurrentDownloads;

    // Map visible tabs strings to indices
    final Set<int> indices = {};
    for (final tabName in visibleTabs) {
      final tab = playliztTabFromId(tabName);
      if (tab != null) {
        indices.add(tab.index);
      }
    }
    // Always ensure streaming is there if fallback logic requires it,
    // but _enforceVisibilityConstraints handles mandatory logic.
    if (indices.isNotEmpty) {
      _visibleTabIndices = indices.toList()..sort();
    }

    final startTabEnum = playliztTabFromId(startupTab);
    if (startTabEnum != null) {
      _startupTabIndex = startTabEnum.index;
    }

    _enforceVisibilityConstraints();

    // Persist these remote settings to local storage so they survive offline restart
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDownloadDirectory, _downloadDirectory);
    await prefs.setStringList(_keyLibraryScanFolders, _libraryScanFolders);
    await prefs.setInt(_keyMaxConcurrentDownloads, _maxConcurrentDownloads);
    await prefs.setBool(_keyRecursiveLibraryScan, _recursiveLibraryScan);
    await prefs.setString(
      _keyConversionOutputDirectory,
      _conversionOutputDirectory,
    );
    await prefs.setString(
      _keyConversionOutputCollisionPolicy,
      _conversionOutputCollisionPolicy.name,
    );
    await prefs.setBool(
      _keyHardwareAccelerationEnabled,
      _hardwareAccelerationEnabled,
    );
    await prefs.setBool(
        _keyRendererDiscoveryEnabled, _rendererDiscoveryEnabled);
    await prefs.setBool(_keyDownloadArchiveEnabled, _downloadArchiveEnabled);
    await prefs.setStringList(
      _keyVisibleTabs,
      _visibleTabIndices.map((e) => e.toString()).toList(),
    );
    await prefs.setInt(_keyStartupTabIndex, _startupTabIndex);

    notifyListeners();
  }

  Future<void> setUseDefaultDownloadLocation(bool value) async {
    _useDefaultDownloadLocation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseDefaultDownloadLocation, value);
    notifyListeners();
  }

  Future<void> setDownloadDirectory(String directory) async {
    _downloadDirectory = directory;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDownloadDirectory, directory);
    notifyListeners();
  }

  Future<void> setLibraryScanFolders(List<String> folders) async {
    _libraryScanFolders = List<String>.from(folders);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyLibraryScanFolders, _libraryScanFolders);
    notifyListeners();
  }

  Future<void> addLibraryScanFolder(String folder) async {
    if (folder.isEmpty) return;
    if (_libraryScanFolders.contains(folder)) return;
    _libraryScanFolders = List<String>.from(_libraryScanFolders)..add(folder);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyLibraryScanFolders, _libraryScanFolders);
    notifyListeners();
  }

  Future<void> removeLibraryScanFolder(String folder) async {
    _libraryScanFolders =
        _libraryScanFolders.where((f) => f != folder).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyLibraryScanFolders, _libraryScanFolders);
    notifyListeners();
  }

  Future<void> setMaxConcurrentDownloads(int value) async {
    if (value < 0) {
      value = 0;
    }
    _maxConcurrentDownloads = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxConcurrentDownloads, value);
    notifyListeners();
  }

  Future<void> setStartupTabIndex(int index) async {
    _startupTabIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStartupTabIndex, index);
    notifyListeners();
  }

  Future<void> setCompactLayout(bool value) async {
    _compactLayout = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompactLayout, value);
    notifyListeners();
  }

  Future<void> setRecursiveLibraryScan(bool value) async {
    _recursiveLibraryScan = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecursiveLibraryScan, value);
    notifyListeners();
  }

  Future<void> setConversionOutputDirectory(String directory) async {
    if (directory.trim().isEmpty) return;
    _conversionOutputDirectory = directory.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyConversionOutputDirectory,
      _conversionOutputDirectory,
    );
    notifyListeners();
  }

  Future<void> setConversionOutputCollisionPolicy(
    ConversionOutputCollisionPolicy policy,
  ) async {
    _conversionOutputCollisionPolicy = policy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConversionOutputCollisionPolicy, policy.name);
    notifyListeners();
  }

  Future<void> setHardwareAccelerationEnabled(bool value) async {
    _hardwareAccelerationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHardwareAccelerationEnabled, value);
    notifyListeners();
  }

  Future<void> setRendererDiscoveryEnabled(bool value) async {
    _rendererDiscoveryEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRendererDiscoveryEnabled, value);
    notifyListeners();
  }

  Future<void> setDownloadArchiveEnabled(bool value) async {
    _downloadArchiveEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDownloadArchiveEnabled, value);
    notifyListeners();
  }

  Future<void> setTabVisible(int index, bool visible) async {
    final current = _visibleTabIndices.toSet();
    if (visible) {
      current.add(index);
    } else {
      current.remove(index);
    }
    _visibleTabIndices = current.toList()..sort();
    _enforceVisibilityConstraints();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyVisibleTabs,
      _visibleTabIndices.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  void _enforceVisibilityConstraints() {
    final set = _visibleTabIndices.toSet();

    // Streaming tab must always be visible.
    set.add(2);

    // On web, Library and Devices tabs cannot be enabled.
    if (kIsWeb) {
      set.remove(0);
      set.remove(5);
    }

    if (set.isEmpty) {
      set.add(2);
    }

    _visibleTabIndices = set.toList()..sort();

    // Ensure startup tab is one of the visible tabs.
    if (!_visibleTabIndices.contains(_startupTabIndex)) {
      _startupTabIndex =
          _visibleTabIndices.contains(2) ? 2 : _visibleTabIndices.first;
    }
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
