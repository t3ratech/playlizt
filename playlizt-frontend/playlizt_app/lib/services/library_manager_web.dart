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
import 'local_media_models.dart';

class LibraryManager with ChangeNotifier {
  static const _prefsKeyItems = 'library.items';

  final SettingsProvider settingsProvider;
  final Map<String, LibraryItem> _items = {};
  bool _isLoaded = false;
  bool _isScanning = false;
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
  DateTime? get lastScanAt => null;
  String get searchQuery => _searchQuery;
  LibrarySortMode get sortMode => _sortMode;
  Set<LibraryMediaType> get mediaTypeFilters =>
      Set.unmodifiable(_mediaTypeFilters);
  Set<LibraryItemSource> get sourceFilters => Set.unmodifiable(_sourceFilters);
  bool get showMissingOnly => _showMissingOnly;
  int get missingCount => _items.values
      .where((item) => item.availability == LibraryAvailability.missing)
      .length;
  int get audioCount => _items.values
      .where((item) => item.mediaType == LibraryMediaType.audio)
      .length;
  int get videoCount => _items.values
      .where((item) => item.mediaType == LibraryMediaType.video)
      .length;

  List<LibraryItem> get items => _sortItems(_items.values.toList());

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
    _isScanning = true;
    notifyListeners();
    try {
      return LibraryScanResult(
        scannedFiles: 0,
        importedItems: 0,
        removedMissingItems: 0,
        markedMissingItems: 0,
        completedAt: DateTime.now(),
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
    final now = DateTime.now();
    final id = LibraryItem.stableIdForPath(path);
    final item = LibraryItem(
      id: id,
      path: path,
      displayTitle: displayTitle?.trim().isNotEmpty == true
          ? displayTitle!.trim()
          : path.split('/').last,
      mediaType: LibraryItem.mediaTypeForPath(path),
      source: source,
      fileSizeBytes: 0,
      durationSeconds: durationSeconds,
      dateAdded: _items[id]?.dateAdded ?? now,
      lastSeen: now,
      parentId: parentId,
      thumbnailPath: thumbnailPath,
      availability: LibraryAvailability.available,
    );
    _items[id] = item;
    await _persist();
    notifyListeners();
    return item;
  }

  Future<LibraryAvailabilityResult> refreshAvailability() async {
    final now = DateTime.now();
    for (final entry in _items.entries.toList()) {
      _items[entry.key] = entry.value.copyWith(
        availability: LibraryAvailability.available,
        lastSeen: now,
      );
    }
    await _persist();
    notifyListeners();
    return LibraryAvailabilityResult(
      checkedItems: _items.length,
      availableItems: _items.length,
      missingItems: 0,
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
}
