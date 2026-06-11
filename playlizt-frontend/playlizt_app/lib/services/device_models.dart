/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 21:43
 * Email        : tkaviya@t3ratech.co.zw
 */
enum PlaybackDeviceType { local, networkStream, renderer }

enum PlaybackDeviceStatus { available, playing, offline, error }

class PlaybackDevice {
  final String id;
  final String name;
  final PlaybackDeviceType type;
  final PlaybackDeviceStatus status;
  final String? uri;
  final List<String> capabilities;
  final String? errorMessage;
  final DateTime lastSeen;

  const PlaybackDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.uri,
    this.capabilities = const [],
    this.errorMessage,
    required this.lastSeen,
  });

  bool get canPlayLocally =>
      type == PlaybackDeviceType.local ||
      type == PlaybackDeviceType.networkStream;

  PlaybackDevice copyWith({
    String? name,
    PlaybackDeviceStatus? status,
    String? uri,
    List<String>? capabilities,
    String? errorMessage,
    DateTime? lastSeen,
  }) {
    return PlaybackDevice(
      id: id,
      name: name ?? this.name,
      type: type,
      status: status ?? this.status,
      uri: uri ?? this.uri,
      capabilities: capabilities ?? this.capabilities,
      errorMessage: errorMessage,
      lastSeen: lastSeen ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'uri': uri,
      'capabilities': capabilities,
      'errorMessage': errorMessage,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  static PlaybackDevice fromJson(Map<String, dynamic> json) {
    return PlaybackDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _enumByName(
        PlaybackDeviceType.values,
        json['type'] as String?,
        PlaybackDeviceType.networkStream,
      ),
      status: _enumByName(
        PlaybackDeviceStatus.values,
        json['status'] as String?,
        PlaybackDeviceStatus.available,
      ),
      uri: json['uri'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      errorMessage: json['errorMessage'] as String?,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );
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
