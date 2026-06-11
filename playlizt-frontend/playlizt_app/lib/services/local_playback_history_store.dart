/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 22:58
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'playback_models.dart';

class LocalPlaybackHistoryStore {
  static const _prefsKey = 'playback.local.positions';

  Future<LocalPlaybackPosition?> loadPosition(String key) async {
    final positions = await loadPositions();
    return positions[key];
  }

  Future<Map<String, LocalPlaybackPosition>> loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const {};

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const {};

    final positions = <String, LocalPlaybackPosition>{};
    for (final item in decoded) {
      final Map<String, dynamic>? rawPosition;
      if (item is Map<String, dynamic>) {
        rawPosition = item;
      } else if (item is Map) {
        rawPosition = item.map((key, value) => MapEntry(key.toString(), value));
      } else {
        rawPosition = null;
      }
      if (rawPosition == null) continue;
      final position = LocalPlaybackPosition.fromJson(rawPosition);
      positions[position.key] = position;
    }
    return positions;
  }

  Future<void> savePosition(LocalPlaybackPosition position) async {
    final positions = Map<String, LocalPlaybackPosition>.from(
      await loadPositions(),
    );
    positions[position.key] = position;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(positions.values.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> clearPosition(String key) async {
    final positions = Map<String, LocalPlaybackPosition>.from(
      await loadPositions(),
    )..remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(positions.values.map((entry) => entry.toJson()).toList()),
    );
  }
}
