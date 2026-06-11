import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/services/local_playback_history_store.dart';
import 'package:playlizt_app/services/playback_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
