import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/services/download_manager_models.dart';

void main() {
  test(
    'DownloadTask progress reports a fractional value when total is known',
    () {
      const task = DownloadTask(
        id: 'progress-task',
        url: 'https://example.test/video.mp4',
        filePath: '/tmp/video.mp4',
        fileName: 'video.mp4',
        status: DownloadStatus.downloading,
        receivedBytes: 25,
        totalBytes: 100,
      );

      expect(task.progress, 0.25);
    },
  );
}
