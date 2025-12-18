import 'dart:convert';
import 'content.dart';

class Playlist {
  final String id;
  final String name;
  final List<Content> items;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.items = const [],
    required this.createdAt,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<Content>? items,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((i) => i.toJson()).toList(), // Use Content's toJson
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Content.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
