/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 21:43
 * Email        : tkaviya@t3ratech.co.zw
 */
enum PlaybackDeviceType { local, networkStream, renderer }

enum PlaybackDeviceStatus { available, playing, offline, error }

enum PlaybackTransportState { stopped, playing, paused }

const Object _unsetDeviceValue = Object();

class PlaybackDevice {
  final String id;
  final String name;
  final PlaybackDeviceType type;
  final PlaybackDeviceStatus status;
  final String? uri;
  final List<String> capabilities;
  final String? errorMessage;
  final DateTime lastSeen;
  final bool connected;
  final PlaybackTransportState transportState;
  final String? activeUri;
  final String? activeTitle;
  final int positionSeconds;
  final int volumePercent;
  final bool muted;

  const PlaybackDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.uri,
    this.capabilities = const [],
    this.errorMessage,
    required this.lastSeen,
    this.connected = false,
    this.transportState = PlaybackTransportState.stopped,
    this.activeUri,
    this.activeTitle,
    this.positionSeconds = 0,
    this.volumePercent = 80,
    this.muted = false,
  });

  bool get canPlayLocally =>
      type == PlaybackDeviceType.local ||
      type == PlaybackDeviceType.networkStream;

  bool get canRemoteControl => type == PlaybackDeviceType.renderer;

  bool get isPlaying => transportState == PlaybackTransportState.playing;

  PlaybackDevice copyWith({
    String? name,
    PlaybackDeviceStatus? status,
    Object? uri = _unsetDeviceValue,
    List<String>? capabilities,
    Object? errorMessage = _unsetDeviceValue,
    DateTime? lastSeen,
    bool? connected,
    PlaybackTransportState? transportState,
    Object? activeUri = _unsetDeviceValue,
    Object? activeTitle = _unsetDeviceValue,
    int? positionSeconds,
    int? volumePercent,
    bool? muted,
  }) {
    return PlaybackDevice(
      id: id,
      name: name ?? this.name,
      type: type,
      status: status ?? this.status,
      uri: uri == _unsetDeviceValue ? this.uri : uri as String?,
      capabilities: capabilities ?? this.capabilities,
      errorMessage: errorMessage == _unsetDeviceValue
          ? this.errorMessage
          : errorMessage as String?,
      lastSeen: lastSeen ?? DateTime.now(),
      connected: connected ?? this.connected,
      transportState: transportState ?? this.transportState,
      activeUri: activeUri == _unsetDeviceValue
          ? this.activeUri
          : activeUri as String?,
      activeTitle: activeTitle == _unsetDeviceValue
          ? this.activeTitle
          : activeTitle as String?,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      volumePercent: volumePercent ?? this.volumePercent,
      muted: muted ?? this.muted,
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
      'connected': connected,
      'transportState': transportState.name,
      'activeUri': activeUri,
      'activeTitle': activeTitle,
      'positionSeconds': positionSeconds,
      'volumePercent': volumePercent,
      'muted': muted,
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
      connected: json['connected'] as bool? ?? false,
      transportState: _enumByName(
        PlaybackTransportState.values,
        json['transportState'] as String?,
        PlaybackTransportState.stopped,
      ),
      activeUri: json['activeUri'] as String?,
      activeTitle: json['activeTitle'] as String?,
      positionSeconds: json['positionSeconds'] as int? ?? 0,
      volumePercent: json['volumePercent'] as int? ?? 80,
      muted: json['muted'] as bool? ?? false,
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
