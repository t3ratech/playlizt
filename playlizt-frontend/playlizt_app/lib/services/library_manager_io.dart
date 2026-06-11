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

  LibraryManager({required this.settingsProvider}) {
    _load();
  }

  bool get isLoaded => _isLoaded;
  bool get isScanning => _isScanning;
  DateTime? get lastScanAt => _lastScanAt;
  String get searchQuery => _searchQuery;
  LibrarySortMode get sortMode => _sortMode;

  List<LibraryItem> get items {
    final list = _items.values.toList();
    return _sortItems(list);
  }

  List<LibraryItem> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    final list = query.isEmpty
        ? _items.values.toList()
        : _items.values.where((item) {
            return item.displayTitle.toLowerCase().contains(query) ||
                item.path.toLowerCase().contains(query) ||
                item.mediaType.name.contains(query) ||
                item.source.name.contains(query);
          }).toList();
    return _sortItems(list);
  }

  int get audioCount => _items.values
      .where((item) => item.mediaType == LibraryMediaType.audio)
      .length;

  int get videoCount => _items.values
      .where((item) => item.mediaType == LibraryMediaType.video)
      .length;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSortMode(LibrarySortMode value) {
    _sortMode = value;
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

      _lastScanAt = now;
      await _persist();

      return LibraryScanResult(
        scannedFiles: scannedFiles,
        importedItems: importedItems,
        removedMissingItems: removedMissingItems,
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
    );

    _items[id] = item;
    await _persist();
    notifyListeners();
    return item;
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
}
