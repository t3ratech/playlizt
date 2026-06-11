import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/services/local_playback_history_store.dart';
import 'package:playlizt_app/services/playback_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('PlaybackEngineConfiguration prefers hardware decoder paths', () {
    const configuration = PlaybackEngineConfiguration(
      hardwareAccelerationEnabled: true,
    );

    final options = configuration.toFvpOptions(
      platforms: const ['linux', 'windows', 'macos'],
    );

    expect(options['platforms'], const ['linux', 'windows', 'macos']);
    expect(options, isNot(contains('video.decoders')));
    expect(options['player'], containsPair('avformat.rtsp_transport', 'tcp'));
    expect(options['player'], containsPair('avio.reconnect', '1'));
  });

  test('PlaybackEngineConfiguration forces software decoder paths', () {
    const configuration = PlaybackEngineConfiguration(
      hardwareAccelerationEnabled: false,
    );

    final options = configuration.toFvpOptions(
      platforms: const ['linux', 'windows', 'macos'],
    );

    expect(options['video.decoders'], const ['FFmpeg', 'dav1d']);
    expect(options['player'], containsPair('video.decoder', 'FFmpeg'));
  });

  test('PlaybackSnapshotPath creates filesystem-safe PNG names', () {
    final fileName = PlaybackSnapshotPath.fileName(
      title: 'Episode 1: Pilot / Opening?',
      capturedAt: DateTime.utc(2026, 6, 11, 20, 15, 30),
    );

    expect(fileName, startsWith('Episode_1_Pilot_Opening_'));
    expect(fileName, endsWith('.png'));
    expect(fileName, isNot(contains(':')));
    expect(fileName, isNot(contains('/')));
  });

  test('LocalPlaybackPosition reports fractional progress', () {
    final position = LocalPlaybackPosition(
      key: 'url:/tmp/video.mp4',
      positionSeconds: 30,
      durationSeconds: 120,
      updatedAt: DateTime.utc(2026, 6, 11),
    );

    expect(position.progress, 0.25);
  });

  test('LocalPlaybackHistoryStore saves, restores and clears positions',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalPlaybackHistoryStore();
    final updatedAt = DateTime.utc(2026, 6, 11, 18, 45);

    await store.savePosition(
      LocalPlaybackPosition(
        key: 'url:/tmp/video.mp4',
        positionSeconds: 75,
        durationSeconds: 300,
        updatedAt: updatedAt,
      ),
    );

    final restored = await store.loadPosition('url:/tmp/video.mp4');
    expect(restored, isNotNull);
    expect(restored!.positionSeconds, 75);
    expect(restored.durationSeconds, 300);
    expect(restored.updatedAt, updatedAt);

    await store.clearPosition('url:/tmp/video.mp4');
    expect(await store.loadPosition('url:/tmp/video.mp4'), isNull);
  });
}
