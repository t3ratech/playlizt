/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 22:58
 * Email        : tkaviya@t3ratech.co.zw
 */
class LocalPlaybackPosition {
  final String key;
  final int positionSeconds;
  final int? durationSeconds;
  final DateTime updatedAt;

  const LocalPlaybackPosition({
    required this.key,
    required this.positionSeconds,
    this.durationSeconds,
    required this.updatedAt,
  });

  double? get progress {
    final duration = durationSeconds;
    if (duration == null || duration <= 0) return null;
    return (positionSeconds / duration).clamp(0, 1).toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'positionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static LocalPlaybackPosition fromJson(Map<String, dynamic> json) {
    return LocalPlaybackPosition(
      key: json['key'] as String,
      positionSeconds: (json['positionSeconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class PlaybackSpeedOption {
  final double value;
  final String label;

  const PlaybackSpeedOption(this.value, this.label);

  static const options = [
    PlaybackSpeedOption(0.5, '0.5x'),
    PlaybackSpeedOption(0.75, '0.75x'),
    PlaybackSpeedOption(1, '1x'),
    PlaybackSpeedOption(1.25, '1.25x'),
    PlaybackSpeedOption(1.5, '1.5x'),
    PlaybackSpeedOption(2, '2x'),
  ];
}

class PlaybackEngineConfiguration {
  final bool hardwareAccelerationEnabled;

  const PlaybackEngineConfiguration({
    this.hardwareAccelerationEnabled = true,
  });

  Map<String, dynamic> toFvpOptions({required List<String> platforms}) {
    final playerOptions = <String, String>{
      'avformat.rtsp_transport': 'tcp',
      'avio.reconnect': '1',
      'avio.reconnect_delay_max': '7',
    };
    final options = <String, dynamic>{
      'platforms': platforms,
      'player': playerOptions,
    };

    if (!hardwareAccelerationEnabled) {
      options['video.decoders'] = const ['FFmpeg', 'dav1d'];
      playerOptions['video.decoder'] = 'FFmpeg';
    }

    return options;
  }
}

class PlaybackSnapshotPath {
  static String fileName({
    required String title,
    required DateTime capturedAt,
  }) {
    final safeTitle = title
        .replaceAll(RegExp(r'[^\w\s\.-]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final prefix = safeTitle.isEmpty ? 'playlizt' : safeTitle;
    final stamp =
        capturedAt.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    return '$prefix-$stamp.png';
  }
}
