/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 21:43
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import 'local_media_models.dart';

class LibraryManager with ChangeNotifier {
  static const _prefsKeyItems = 'library.items';
  static const _prefsKeyLastScanAt = 'library.lastScanAt';

  final SettingsProvider settingsProvider;

  final Map<String, LibraryItem> _items = {};
  bool _isLoaded = false;
  bool _isScanning = false;
  DateTime? _lastScanAt;
  String _searchQuery = '';
  LibrarySortMode _sortMode = LibrarySortMode.name;
  final Set<LibraryMediaType> _mediaTypeFilters = {};
  final Set<LibraryItemSource> _sourceFilters = {};
  bool _showMissingOnly = false;

  LibraryManager({required this.settingsProvider}) {
    _load();
  }

  bool get isLoaded => _isLoaded;
  bool get isScanning => _isScanning;
  DateTime? get lastScanAt => _lastScanAt;
  String get searchQuery => _searchQuery;
  LibrarySortMode get sortMode => _sortMode;
  Set<LibraryMediaType> get mediaTypeFilters =>
      Set.unmodifiable(_mediaTypeFilters);
  Set<LibraryItemSource> get sourceFilters => Set.unmodifiable(_sourceFilters);
  bool get showMissingOnly => _showMissingOnly;

  List<LibraryItem> get items {
    final list = _items.values.toList();
    return _sortItems(list);
  }

  List<LibraryItem> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    final list = _items.values.where((item) {
      if (query.isNotEmpty &&
          !item.displayTitle.toLowerCase().contains(query) &&
          !item.path.toLowerCase().contains(query) &&
          !item.extension.contains(query) &&
          !item.folderPath.toLowerCase().contains(query) &&
          !item.mediaType.name.contains(query) &&
          !item.source.name.contains(query)) {
        return false;
      }
      if (_mediaTypeFilters.isNotEmpty &&
          !_mediaTypeFilters.contains(item.mediaType)) {
        return false;
      }
      if (_sourceFilters.isNotEmpty && !_sourceFilters.contains(item.source)) {
        return false;
      }
      if (_showMissingOnly &&
          item.availability != LibraryAvailability.missing) {
        return false;
      }
      return true;
    }).toList();
    return _sortItems(list);
  }

  int get audioCount => _items.values
      .where((item) => item.mediaType == LibraryMediaType.audio)
      .length;

  int get videoCount => _items.values
      .where((item) => item.mediaType == LibraryMediaType.video)
      .length;

  int get missingCount => _items.values
      .where((item) => item.availability == LibraryAvailability.missing)
      .length;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSortMode(LibrarySortMode value) {
    _sortMode = value;
    notifyListeners();
  }

  void toggleMediaTypeFilter(LibraryMediaType value) {
    if (_mediaTypeFilters.contains(value)) {
      _mediaTypeFilters.remove(value);
    } else {
      _mediaTypeFilters.add(value);
    }
    notifyListeners();
  }

  void toggleSourceFilter(LibraryItemSource value) {
    if (_sourceFilters.contains(value)) {
      _sourceFilters.remove(value);
    } else {
      _sourceFilters.add(value);
    }
    notifyListeners();
  }

  void setShowMissingOnly(bool value) {
    _showMissingOnly = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _mediaTypeFilters.clear();
    _sourceFilters.clear();
    _showMissingOnly = false;
    notifyListeners();
  }

  Future<LibraryScanResult> rescan() async {
    await settingsProvider.ensureLoaded();
    _isScanning = true;
    notifyListeners();

    final now = DateTime.now();
    final seenIds = <String>{};
    var scannedFiles = 0;
    var importedItems = 0;

    try {
      for (final folder in settingsProvider.libraryScanFolders) {
        final resolvedFolder = _resolveHome(folder);
        final directory = Directory(resolvedFolder);
        if (!await directory.exists()) continue;

        await for (final entity in directory.list(
          recursive: settingsProvider.recursiveLibraryScan,
          followLinks: false,
        )) {
          if (entity is! File) continue;
          final path = entity.path;
          if (!LibraryItem.isSupportedMediaPath(path)) continue;

          scannedFiles++;
          final id = LibraryItem.stableIdForPath(path);
          seenIds.add(id);

          final stat = await entity.stat();
          final existing = _items[id];
          final item = LibraryItem(
            id: id,
            path: path,
            displayTitle: _titleFromPath(path),
            mediaType: LibraryItem.mediaTypeForPath(path),
            source: existing?.source ?? LibraryItemSource.scanned,
            fileSizeBytes: stat.size,
            durationSeconds: existing?.durationSeconds,
            dateAdded: existing?.dateAdded ?? now,
            lastSeen: now,
            modifiedAt: stat.modified,
            parentId: existing?.parentId,
            thumbnailPath: existing?.thumbnailPath,
            availability: LibraryAvailability.available,
          );

          if (existing == null) importedItems++;
          _items[id] = item;
        }
      }

      final beforeRemoval = _items.length;
      _items.removeWhere((id, item) {
        if (item.source != LibraryItemSource.scanned) return false;
        return !seenIds.contains(id);
      });
      final removedMissingItems = beforeRemoval - _items.length;
      final markedMissingItems = await _markImportedMissing(now);

      _lastScanAt = now;
      await _persist();

      return LibraryScanResult(
        scannedFiles: scannedFiles,
        importedItems: importedItems,
        removedMissingItems: removedMissingItems,
        markedMissingItems: markedMissingItems,
        completedAt: now,
      );
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<LibraryItem> importPath({
    required String path,
    required LibraryItemSource source,
    String? parentId,
    String? displayTitle,
    int? durationSeconds,
    String? thumbnailPath,
  }) async {
    final resolvedPath = _resolveHome(path);
    final file = File(resolvedPath);
    if (!await file.exists()) {
      throw StateError(
          'Library import failed because the file does not exist: $path');
    }

    final now = DateTime.now();
    final stat = await file.stat();
    final id = LibraryItem.stableIdForPath(resolvedPath);
    final existing = _items[id];
    final item = LibraryItem(
      id: id,
      path: resolvedPath,
      displayTitle: displayTitle?.trim().isNotEmpty == true
          ? displayTitle!.trim()
          : _titleFromPath(resolvedPath),
      mediaType: LibraryItem.mediaTypeForPath(resolvedPath),
      source: source,
      fileSizeBytes: stat.size,
      durationSeconds: durationSeconds ?? existing?.durationSeconds,
      dateAdded: existing?.dateAdded ?? now,
      lastSeen: now,
      modifiedAt: stat.modified,
      parentId: parentId ?? existing?.parentId,
      thumbnailPath: thumbnailPath ?? existing?.thumbnailPath,
      availability: LibraryAvailability.available,
    );

    _items[id] = item;
    await _persist();
    notifyListeners();
    return item;
  }

  Future<LibraryAvailabilityResult> refreshAvailability() async {
    final now = DateTime.now();
    var checked = 0;
    var available = 0;
    var missing = 0;

    for (final entry in _items.entries.toList()) {
      final item = entry.value;
      final exists =
          _isRemoteMediaPath(item.path) || await File(item.path).exists();
      checked++;
      if (exists) {
        available++;
      } else {
        missing++;
      }
      _items[entry.key] = item.copyWith(
        availability: exists
            ? LibraryAvailability.available
            : LibraryAvailability.missing,
        lastSeen: exists ? now : item.lastSeen,
      );
    }

    await _persist();
    notifyListeners();
    return LibraryAvailabilityResult(
      checkedItems: checked,
      availableItems: available,
      missingItems: missing,
      completedAt: now,
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawItems = prefs.getString(_prefsKeyItems);
      if (rawItems != null && rawItems.isNotEmpty) {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) {
          for (final raw in decoded) {
            if (raw is Map<String, dynamic>) {
              final item = LibraryItem.fromJson(raw);
              _items[item.id] = item;
            } else if (raw is Map) {
              final item = LibraryItem.fromJson(
                raw.map((key, value) => MapEntry(key.toString(), value)),
              );
              _items[item.id] = item;
            }
          }
        }
      }

      final lastScanRaw = prefs.getString(_prefsKeyLastScanAt);
      _lastScanAt = lastScanRaw == null ? null : DateTime.tryParse(lastScanRaw);
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKeyItems,
      jsonEncode(_items.values.map((item) => item.toJson()).toList()),
    );
    if (_lastScanAt != null) {
      await prefs.setString(
          _prefsKeyLastScanAt, _lastScanAt!.toIso8601String());
    }
  }

  Future<int> _markImportedMissing(DateTime now) async {
    var missing = 0;
    for (final entry in _items.entries.toList()) {
      final item = entry.value;
      if (item.source == LibraryItemSource.scanned) continue;
      final exists =
          _isRemoteMediaPath(item.path) || await File(item.path).exists();
      if (!exists) missing++;
      _items[entry.key] = item.copyWith(
        availability: exists
            ? LibraryAvailability.available
            : LibraryAvailability.missing,
        lastSeen: exists ? now : item.lastSeen,
      );
    }
    return missing;
  }

  List<LibraryItem> _sortItems(List<LibraryItem> list) {
    list.sort((a, b) {
      switch (_sortMode) {
        case LibrarySortMode.name:
          return a.displayTitle.toLowerCase().compareTo(
                b.displayTitle.toLowerCase(),
              );
        case LibrarySortMode.dateAdded:
          return b.dateAdded.compareTo(a.dateAdded);
        case LibrarySortMode.modifiedAt:
          return (b.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                  a.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        case LibrarySortMode.duration:
          return (b.durationSeconds ?? 0).compareTo(a.durationSeconds ?? 0);
        case LibrarySortMode.size:
          return b.fileSizeBytes.compareTo(a.fileSizeBytes);
      }
    });
    return list;
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

  bool _isRemoteMediaPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null || !uri.hasScheme) return false;
    return uri.isScheme('http') ||
        uri.isScheme('https') ||
        uri.isScheme('rtsp') ||
        uri.isScheme('rtmp') ||
        uri.isScheme('rtmps');
  }
}
