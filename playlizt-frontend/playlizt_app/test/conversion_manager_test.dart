import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/services/conversion_models.dart';

void main() {
  group('FFmpeg conversion models', () {
    test('tracks the required full converter inventory counts', () {
      const inventory = FfmpegCapabilityInventory.requiredInventory();

      expect(inventory.encoders, 273);
      expect(inventory.decoders, 607);
      expect(inventory.muxers, 185);
      expect(inventory.demuxers, 367);
      expect(inventory.filters, 596);
      expect(inventory.bitstreamFilters, 51);
      expect(inventory.protocols, 55);
      expect(inventory.satisfiesRequiredCounts, isTrue);
    });

    test('builds preset arguments with probe-friendly progress output', () {
      final preset = ConversionPreset.byId(ConversionPresetId.mp4720);

      final args = preset.buildFfmpegArguments(
        inputPath: '/tmp/source.mkv',
        outputPath: '/tmp/out.mp4',
        startTime: '00:00:05',
        endTime: '00:00:10',
      );

      expect(args, containsAll(['-progress', 'pipe:1', '-nostats']));
      expect(args, containsAll(['-ss', '00:00:05', '-to', '00:00:10']));
      expect(args, containsAll(['-vf', 'scale=-2:720']));
      expect(args.last, '/tmp/out.mp4');
    });

    test('builds custom profile arguments before the output path', () {
      final preset = ConversionPreset.byId(ConversionPresetId.custom);

      final args = preset.buildFfmpegArguments(
        inputPath: '/tmp/source.mkv',
        outputPath: '/tmp/out.mkv',
        customArguments: const ['-c:v', 'libx265', '-crf', '24'],
      );

      expect(args, containsAll(['-c:v', 'libx265', '-crf', '24']));
      expect(args.last, '/tmp/out.mkv');
    });

    test('parses ffmpeg progress snapshots into Playlizt progress', () {
      final parser = FfmpegProgressParser();

      expect(parser.addLine('out_time_us=5000000'), isNull);
      expect(parser.addLine('speed=1.25x'), isNull);
      final snapshot = parser.addLine('progress=continue');

      expect(snapshot, isNotNull);
      expect(snapshot!.processedSeconds, 5);
      expect(snapshot.speed, 1.25);
      expect(snapshot.stage, 'Converting');
      expect(snapshot.finished, isFalse);
    });

    test('persists custom conversion arguments in job JSON', () {
      final now = DateTime.utc(2026, 6, 11);
      final job = ConversionJob(
        id: 'job-1',
        inputPath: '/tmp/source.mkv',
        outputPath: '/tmp/out.mkv',
        presetId: ConversionPresetId.custom,
        status: ConversionStatus.queued,
        customArguments: const ['-c:v', 'libx265'],
        currentStage: 'Queued',
        createdAt: now,
        updatedAt: now,
      );

      final restored = ConversionJob.fromJson(job.toJson());

      expect(restored.presetId, ConversionPresetId.custom);
      expect(restored.customArguments, const ['-c:v', 'libx265']);
    });
  });
}
