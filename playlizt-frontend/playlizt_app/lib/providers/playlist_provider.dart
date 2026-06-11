import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/content.dart';

class PlaylistProvider with ChangeNotifier {
  static const String _prefsKey = 'playlists_local';
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _playlists = jsonList.map((e) => Playlist.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading playlists: $e');
      }
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString =
          jsonEncode(_playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving playlists: $e');
      }
    }
  }

  Future<void> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_playlists.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed,
      createdAt: DateTime.now(),
      items: [],
    );
    _playlists.add(newPlaylist);
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> renamePlaylist(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _playlists[index] = _playlists[index].copyWith(name: trimmed);
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists = _playlists.where((playlist) => playlist.id != id).toList();
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> duplicatePlaylist(String id) async {
    final sourceIndex = _playlists.indexWhere((playlist) => playlist.id == id);
    if (sourceIndex == -1) return;
    final source = _playlists[sourceIndex];
    final duplicate = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '${source.name} Copy',
      items: List<Content>.from(source.items),
      createdAt: DateTime.now(),
    );
    _playlists.add(duplicate);
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> reorderPlaylistItems(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex == -1) return;
    final items = List<Content>.from(_playlists[playlistIndex].items);
    if (oldIndex < 0 || oldIndex >= items.length) return;
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;
    if (targetIndex < 0 || targetIndex > items.length) return;
    final item = items.removeAt(oldIndex);
    items.insert(targetIndex, item);
    _playlists[playlistIndex] =
        _playlists[playlistIndex].copyWith(items: items);
    notifyListeners();
    await _savePlaylists();
  }

  Future<Playlist> getOrCreatePlaylist(String name) async {
    final existingIndex = _playlists.indexWhere((p) => p.name == name);
    if (existingIndex != -1) {
      return _playlists[existingIndex];
    }
    await createPlaylist(name);
    return _playlists.firstWhere((p) => p.name == name);
  }

  Future<void> addToPlaylist(String playlistName, Content content) async {
    final index = _playlists.indexWhere((p) => p.name == playlistName);
    if (index == -1) {
      await createPlaylist(playlistName);
      // Recursion safely to add item after creation
      return addToPlaylist(playlistName, content);
    }

    final playlist = _playlists[index];
    // Check if content already exists (optional, maybe by URL or path)
    // For now, allow duplicates or check path
    final exists = playlist.items.any((i) => i.videoUrl == content.videoUrl);
    if (!exists) {
      final updatedPlaylist = playlist.copyWith(
        items: [...playlist.items, content],
      );
      _playlists[index] = updatedPlaylist;
      notifyListeners();
      await _savePlaylists();
    }
  }
}
