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

    test('parses named FFmpeg capability catalog entries', () {
      final catalog = FfmpegCapabilityCatalog.fromFfmpegOutputs(
        encoders: '''
Encoders:
 V..... libx264              H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10
 A..... aac                  AAC (Advanced Audio Coding)
''',
        decoders: '''
Decoders:
 VFS..D h264                 H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10
 A....D mp3                  MP3 (MPEG audio layer 3)
''',
        muxers: '''
Muxers:
 E matroska        Matroska
 E mp4             MP4 (MPEG-4 Part 14)
''',
        demuxers: '''
Demuxers:
 D matroska,webm   Matroska / WebM
 D mov,mp4,m4a     QuickTime / MOV
''',
        filters: '''
Filters:
 ... acopy             A->A       Copy the input audio unchanged.
 T.C scale             V->V       Scale video frames.
''',
        bitstreamFilters: '''
Bitstream filters:
aac_adtstoasc
av1_frame_merge
''',
        protocols: '''
Supported file protocols:
Input:
  file http https
Output:
  file rtmp
''',
      );

      expect(catalog.encoders.map((entry) => entry.name), [
        'libx264',
        'aac',
      ]);
      expect(catalog.decoders.last.description, 'MP3 (MPEG audio layer 3)');
      expect(catalog.muxers.last.name, 'mp4');
      expect(catalog.demuxers.first.name, 'matroska,webm');
      expect(catalog.filters.last.flags, 'T.C');
      expect(catalog.bitstreamFilters.last.name, 'av1_frame_merge');

      final fileProtocol = catalog.protocols.firstWhere(
        (entry) => entry.name == 'file',
      );
      final rtmpProtocol = catalog.protocols.firstWhere(
        (entry) => entry.name == 'rtmp',
      );
      expect(fileProtocol.supportsInput, isTrue);
      expect(fileProtocol.supportsOutput, isTrue);
      expect(rtmpProtocol.supportsInput, isFalse);
      expect(rtmpProtocol.supportsOutput, isTrue);

      expect(catalog.inventory.encoders, 2);
      expect(catalog.inventory.protocols, 4);
      expect(catalog.search('scale').single.name, 'scale');
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

    test('builds thumbnail and short clip workflow presets', () {
      final thumbnail = ConversionPreset.byId(ConversionPresetId.thumbnail);
      final gif = ConversionPreset.byId(ConversionPresetId.gifClip);
      final webm = ConversionPreset.byId(ConversionPresetId.webmClip);

      expect(thumbnail.outputExtension, 'jpg');
      expect(
        thumbnail.buildFfmpegArguments(
          inputPath: '/tmp/source.mkv',
          outputPath: '/tmp/thumb.jpg',
          startTime: '00:00:03',
        ),
        containsAll(['-frames:v', '1', '-q:v', '2', '-an']),
      );

      expect(gif.outputExtension, 'gif');
      expect(
        gif.buildFfmpegArguments(
          inputPath: '/tmp/source.mkv',
          outputPath: '/tmp/clip.gif',
        ),
        containsAll(['-vf', 'fps=15,scale=640:-1:flags=lanczos']),
      );

      expect(webm.outputExtension, 'webm');
      expect(
        webm.buildFfmpegArguments(
          inputPath: '/tmp/source.mkv',
          outputPath: '/tmp/clip.webm',
        ),
        containsAll(['-c:v', 'libvpx-vp9', '-c:a', 'libopus']),
      );
    });

    test('builds stream output profile arguments', () {
      final rtmp = StreamOutputProfile.byId(StreamOutputProfileId.rtmpH264);
      final hls = StreamOutputProfile.byId(StreamOutputProfileId.hlsLive);

      final rtmpArgs = rtmp.buildFfmpegArguments(
        inputPath: '/tmp/source.mkv',
        outputUri: 'rtmp://stream.example/live/playlizt',
      );

      expect(rtmpArgs, containsAll(['-progress', 'pipe:1', '-re']));
      expect(rtmpArgs, containsAll(['-tune', 'zerolatency']));
      expect(rtmpArgs, containsAll(['-f', 'flv']));
      expect(rtmpArgs.last, 'rtmp://stream.example/live/playlizt');

      final hlsArgs = hls.buildFfmpegArguments(
        inputPath: 'https://media.example/live.m3u8',
        outputUri: '/tmp/live/index.m3u8',
        advancedOptions: const ConversionAdvancedOptions(
          videoFilter: 'scale=-2:720',
        ),
      );

      expect(hlsArgs, containsAll(['-f', 'hls']));
      expect(hlsArgs, containsAll(['-hls_time', '4']));
      expect(hlsArgs, containsAll(['-vf', 'scale=-2:720']));
      expect(hlsArgs.last, '/tmp/live/index.m3u8');
    });

    test('validates subtitle burn-in requires a subtitle path', () {
      const options = ConversionAdvancedOptions(
        subtitleMode: ConversionSubtitleMode.burnIn,
      );

      expect(options.validate, throwsArgumentError);
    });

    test('maps ffprobe JSON into media probe metadata', () {
      final info = MediaProbeInfo.fromFfprobeJson({
        'format': {
          'format_name': 'matroska,webm',
          'format_long_name': 'Matroska / WebM',
          'duration': '125.42',
          'bit_rate': '2500000',
          'size': '39321600',
          'tags': {'title': 'Probe Sample'},
        },
        'streams': [
          {
            'index': 0,
            'codec_type': 'video',
            'codec_name': 'h264',
            'codec_long_name': 'H.264 / AVC',
            'width': 1920,
            'height': 1080,
            'avg_frame_rate': '30000/1001',
            'bit_rate': '2200000',
            'tags': {'language': 'eng'},
          },
          {
            'index': 1,
            'codec_type': 'audio',
            'codec_name': 'aac',
            'sample_rate': '48000',
            'channels': 2,
          },
        ],
      }, path: '/tmp/source.mkv');

      expect(info.path, '/tmp/source.mkv');
      expect(info.formatName, 'matroska,webm');
      expect(info.formatLongName, 'Matroska / WebM');
      expect(info.durationSeconds, 125);
      expect(info.bitrate, 2500000);
      expect(info.sizeBytes, 39321600);
      expect(info.metadata['title'], 'Probe Sample');
      expect(info.streams, hasLength(2));
      expect(info.streams.first.codecType, 'video');
      expect(info.streams.first.frameRate, closeTo(29.97, 0.01));
      expect(info.streams.first.language, 'eng');
      expect(info.streams.last.sampleRate, 48000);
      expect(info.streams.last.channels, 2);
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

    test('persists stream output jobs in JSON', () {
      final now = DateTime.utc(2026, 6, 11);
      final job = ConversionJob(
        id: 'stream-job-1',
        inputPath: 'https://media.example/source.m3u8',
        outputPath: 'rtmp://stream.example/live/playlizt',
        presetId: ConversionPresetId.webClip,
        status: ConversionStatus.queued,
        outputKind: ConversionOutputKind.stream,
        streamProfileId: StreamOutputProfileId.rtmpH264,
        currentStage: 'Queued',
        createdAt: now,
        updatedAt: now,
      );

      final restored = ConversionJob.fromJson(job.toJson());

      expect(restored.outputKind, ConversionOutputKind.stream);
      expect(restored.streamProfileId, StreamOutputProfileId.rtmpH264);
      expect(restored.streamProfile?.outputFormat, 'flv');
      expect(restored.displayLabel, 'RTMP H.264');
      expect(restored.outputPath, 'rtmp://stream.example/live/playlizt');
    });
  });
}
