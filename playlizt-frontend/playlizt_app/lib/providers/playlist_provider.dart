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
      final String jsonString = jsonEncode(_playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving playlists: $e');
      }
    }
  }

  Future<void> createPlaylist(String name) async {
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      items: [],
    );
    _playlists.add(newPlaylist);
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
