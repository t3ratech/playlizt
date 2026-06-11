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

    test('builds structured advanced codec and filter arguments', () {
      final preset = ConversionPreset.byId(ConversionPresetId.mp41080);

      final args = preset.buildFfmpegArguments(
        inputPath: '/tmp/source.mkv',
        outputPath: '/tmp/out.mp4',
        advancedOptions: const ConversionAdvancedOptions(
          videoCodec: 'libx265',
          audioCodec: 'aac',
          videoBitrate: '3000k',
          audioBitrate: '160k',
          crf: '24',
          sampleRate: '48000',
          channels: '2',
          pixelFormat: 'yuv420p',
          videoFilter: 'crop=1280:720:0:0',
          audioFilter: 'loudnorm',
          subtitleMode: ConversionSubtitleMode.copy,
        ),
      );

      expect(args, containsAll(['-c:v', 'libx265']));
      expect(args, containsAll(['-c:a', 'aac']));
      expect(args, containsAll(['-b:v', '3000k', '-b:a', '160k']));
      expect(args, containsAll(['-crf', '24']));
      expect(args, containsAll(['-ar', '48000', '-ac', '2']));
      expect(args, containsAll(['-pix_fmt', 'yuv420p']));
      expect(args, containsAll(['-vf', 'crop=1280:720:0:0']));
      expect(args, containsAll(['-af', 'loudnorm']));
      expect(args, containsAll(['-c:s', 'copy']));
      expect(args.last, '/tmp/out.mp4');
    });

    test('validates subtitle burn-in requires a subtitle path', () {
      const options = ConversionAdvancedOptions(
        subtitleMode: ConversionSubtitleMode.burnIn,
      );

      expect(options.validate, throwsArgumentError);
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
        advancedOptions: const ConversionAdvancedOptions(
          containerExtension: 'mp4',
          videoCodec: 'libx265',
          audioCodec: 'aac',
          subtitleMode: ConversionSubtitleMode.remove,
        ),
        currentStage: 'Queued',
        createdAt: now,
        updatedAt: now,
      );

      final restored = ConversionJob.fromJson(job.toJson());

      expect(restored.presetId, ConversionPresetId.custom);
      expect(restored.customArguments, const ['-c:v', 'libx265']);
      expect(restored.advancedOptions.normalizedContainerExtension, 'mp4');
      expect(restored.advancedOptions.videoCodec, 'libx265');
      expect(restored.advancedOptions.audioCodec, 'aac');
      expect(
        restored.advancedOptions.subtitleMode,
        ConversionSubtitleMode.remove,
      );
    });
  });
}
