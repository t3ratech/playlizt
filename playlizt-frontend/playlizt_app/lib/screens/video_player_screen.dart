/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 20:51
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' show FVPControllerExtensions;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/content.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../services/api_service.dart';
import '../services/local_playback_history_store.dart';
import '../services/playback_models.dart';
import '../widgets/themed_logo.dart';
import '../widgets/youtube_player/youtube_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Content content;

  const VideoPlayerScreen({
    super.key,
    required this.content,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Direct Video (MP4/HLS)
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final LocalPlaybackHistoryStore _localHistoryStore =
      LocalPlaybackHistoryStore();
  final TextEditingController _externalSubtitleController =
      TextEditingController();
  AuthProvider? _authProvider;
  ContentProvider? _contentProvider;

  bool _isYoutube = false;
  String? _youtubeVideoId;
  bool _isControllerInitialized = false;
  bool _isPlaying = false;
  bool _isTakingSnapshot = false;
  double _playbackSpeed = 1.0;
  int _durationSeconds = 0;
  String? _activeExternalSubtitle;
  String? _snapshotMessage;

  Timer? _playbackTimer;
  int _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    print('VideoPlayerScreen: initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _contentProvider = Provider.of<ContentProvider>(context, listen: false);
    });
    _initializePlayer();
    _startPlaybackTracking();
  }

  void _startPlaybackTracking() {
    // Delay slightly to ensure context is valid if needed, though Provider.of with listen:false is safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      // Report initial start
      if (userId != null) {
        _reportPlayback(userId, 0);
      }

      // Report progress every 10 seconds
      _playbackTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        int position = _currentPosition;

        if (_videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized) {
          position = _videoPlayerController!.value.position.inSeconds;
        } else {
          // For YouTube or other players where we might not have direct position access easily
          // We simulate progress for history tracking purposes
          position += 10;
        }

        _currentPosition = position;
        unawaited(_saveLocalPlaybackPosition(positionSeconds: position));
        if (userId != null) {
          _reportPlayback(userId, position);
        }
      });
    });
  }

  Future<void> _reportPlayback(int userId, int position) async {
    try {
      await ApiService().trackPlayback(
        userId: userId,
        contentId: widget.content.id,
        positionSeconds: position,
      );
    } catch (e) {
      print('Playback tracking error: $e');
    }
  }

  Future<void> _initializePlayer() async {
    try {
      final rawUrl = widget.content.videoUrl ?? '';
      print('VideoPlayerScreen: rawUrl=$rawUrl');

      String? videoId = _convertUrlToId(rawUrl);

      if (videoId != null) {
        print('VideoPlayerScreen: Detected YouTube videoId=$videoId');
        setState(() {
          _isYoutube = true;
          _youtubeVideoId = videoId;
          _isControllerInitialized = true;
        });
      } else {
        print('VideoPlayerScreen: Detected Direct Video URL');
        setState(() {
          _isYoutube = false;
        });
        await _initializeDirectPlayer(rawUrl);
      }
    } catch (e) {
      print('VideoPlayerScreen: Error in initState: $e');
    }
  }

  String? _convertUrlToId(String url) {
    if (url.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        if (uri.pathSegments.isNotEmpty) return uri.pathSegments.first;
      } else if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      }
    } catch (e) {
      print('Error parsing URL: $e');
    }
    return null;
  }

  Future<void> _initializeDirectPlayer(String url) async {
    final trimmed = url.trim();
    if (trimmed.startsWith('/') || trimmed.startsWith('file://')) {
      final file = trimmed.startsWith('file://')
          ? File.fromUri(Uri.parse(trimmed))
          : File(trimmed);
      _videoPlayerController = VideoPlayerController.file(file);
    } else {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    await _videoPlayerController!.initialize();

    _videoPlayerController!.addListener(_handleControllerUpdate);
    final localPosition =
        await _localHistoryStore.loadPosition(_localPlaybackKey());
    final resumeSeconds =
        widget.content.resumePositionSeconds ?? localPosition?.positionSeconds;
    if (resumeSeconds != null && resumeSeconds > 0) {
      await _videoPlayerController!.seekTo(Duration(seconds: resumeSeconds));
    }
    await _videoPlayerController!.setPlaybackSpeed(_playbackSpeed);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      showControls: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isControllerInitialized = true;
      });
      print('VideoPlayerScreen: Direct Player initialized');
    }
  }

  @override
  void deactivate() {
    unawaited(_saveLocalPlaybackPosition());
    // Pauses video while navigating to next page.
    if (_videoPlayerController != null) {
      _videoPlayerController!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    unawaited(_saveLocalPlaybackPosition());

    try {
      final userId = _authProvider?.userId;
      if (userId != null) {
        _contentProvider?.loadContinueWatching(userId);
        _contentProvider?.loadRecommendations(userId);
      }
    } catch (e) {
      print('VideoPlayerScreen: error refreshing home data on dispose: $e');
    }

    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    _externalSubtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('VideoPlayerScreen: build called');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content.title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: ThemedLogo(height: 32),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: _buildPlayerWidget(),
          ),
          if (!_isYoutube &&
              _isControllerInitialized &&
              _videoPlayerController != null)
            _buildDirectControls(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.content.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${widget.content.viewCount} views',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        widget.content.category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.content.displayDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (widget.content.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: widget.content.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerWidget() {
    if (!_isControllerInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isYoutube && _youtubeVideoId != null) {
      return YoutubePlayerWidget(videoId: _youtubeVideoId!);
    } else if (!_isYoutube && _chewieController != null) {
      return Chewie(
        controller: _chewieController!,
      );
    } else {
      return const Center(child: Text('Error loading player'));
    }
  }

  Widget _buildDirectControls() {
    final duration = _durationSeconds <= 0 ? 1 : _durationSeconds;
    final position = _currentPosition.clamp(0, duration).toDouble();

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(_formatDuration(_currentPosition)),
                Expanded(
                  child: Slider(
                    value: position,
                    min: 0,
                    max: duration.toDouble(),
                    onChanged: (value) => _seekToSeconds(value.round()),
                  ),
                ),
                Text(_formatDuration(_durationSeconds)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Back 10 seconds',
                  onPressed: () => _seekRelative(-10),
                  icon: const Icon(Icons.replay_10),
                ),
                IconButton.filled(
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                  onPressed: _togglePlayPause,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Forward 10 seconds',
                  onPressed: () => _seekRelative(10),
                  icon: const Icon(Icons.forward_10),
                ),
                const SizedBox(width: 16),
                DropdownButton<double>(
                  value: _playbackSpeed,
                  items: PlaybackSpeedOption.options.map((option) {
                    return DropdownMenuItem<double>(
                      value: option.value,
                      child: Text(option.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _setPlaybackSpeed(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _externalSubtitleController,
                    decoration: InputDecoration(
                      labelText: _activeExternalSubtitle == null
                          ? 'External subtitle file or URL'
                          : 'Subtitle: $_activeExternalSubtitle',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyExternalSubtitle(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Apply external subtitles',
                  onPressed: _applyExternalSubtitle,
                  icon: const Icon(Icons.subtitles_outlined),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Save snapshot',
                  onPressed: _isTakingSnapshot ? null : _saveSnapshot,
                  icon: _isTakingSnapshot
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                ),
              ],
            ),
            if (_snapshotMessage != null && _snapshotMessage!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _snapshotMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleControllerUpdate() {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized || !mounted) {
      return;
    }

    final position = controller.value.position.inSeconds;
    final duration = controller.value.duration.inSeconds;
    final isPlaying = controller.value.isPlaying;
    if (position == _currentPosition &&
        duration == _durationSeconds &&
        isPlaying == _isPlaying) {
      return;
    }

    setState(() {
      _currentPosition = position;
      _durationSeconds = duration;
      _isPlaying = isPlaying;
    });
  }

  Future<void> _togglePlayPause() async {
    final controller = _videoPlayerController;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _seekRelative(int deltaSeconds) async {
    await _seekToSeconds(_currentPosition + deltaSeconds);
  }

  Future<void> _seekToSeconds(int seconds) async {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;
    final target = seconds.clamp(0, _durationSeconds);
    await controller.seekTo(Duration(seconds: target));
    await _saveLocalPlaybackPosition(positionSeconds: target);
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setPlaybackSpeed(speed);
    if (!mounted) return;
    setState(() => _playbackSpeed = speed);
  }

  Future<void> _applyExternalSubtitle() async {
    final controller = _videoPlayerController;
    final source = _externalSubtitleController.text.trim();
    if (controller == null || !controller.value.isInitialized) return;
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a subtitle file path or URL')),
      );
      return;
    }

    try {
      controller.setExternalSubtitle(source);
      controller.setSubtitleTracks(const [0]);
      if (!mounted) return;
      setState(() {
        _activeExternalSubtitle = source;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('External subtitles enabled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External subtitles unavailable: $e')),
      );
    }
  }

  Future<void> _saveSnapshot() async {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _isTakingSnapshot = true;
      _snapshotMessage = null;
    });

    try {
      final size = controller.value.size;
      final width =
          size.width.isFinite && size.width > 0 ? size.width.round() : 1280;
      final height =
          size.height.isFinite && size.height > 0 ? size.height.round() : 720;
      final rgba = await controller.snapshot(width: width, height: height);
      if (rgba == null || rgba.isEmpty) {
        throw StateError('The player did not return snapshot pixels');
      }
      final png = await _encodeRgbaPng(
        rgba: rgba,
        width: width,
        height: height,
      );
      final directory = await _snapshotDirectory();
      await directory.create(recursive: true);
      final fileName = PlaybackSnapshotPath.fileName(
        title: widget.content.title,
        capturedAt: DateTime.now(),
      );
      final path = '${directory.path}${Platform.pathSeparator}$fileName';
      await File(path).writeAsBytes(png, flush: true);

      if (!mounted) return;
      setState(() {
        _snapshotMessage = 'Snapshot saved to $path';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _snapshotMessage = 'Snapshot unavailable: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isTakingSnapshot = false);
      }
    }
  }

  Future<List<int>> _encodeRgbaPng({
    required List<int> rgba,
    required int width,
    required int height,
  }) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba is Uint8List ? rgba : Uint8List.fromList(rgba),
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Snapshot encoding failed');
    }
    return byteData.buffer.asUint8List();
  }

  Future<Directory> _snapshotDirectory() async {
    final home = Platform.environment['HOME'];
    if (home == null || home.trim().isEmpty) {
      return Directory('${Directory.systemTemp.path}/Playlizt/Snapshots');
    }
    return Directory('$home/Pictures/Playlizt');
  }

  Future<void> _saveLocalPlaybackPosition({int? positionSeconds}) async {
    final position = positionSeconds ??
        (_videoPlayerController?.value.isInitialized == true
            ? _videoPlayerController!.value.position.inSeconds
            : _currentPosition);
    if (position <= 0) return;
    await _localHistoryStore.savePosition(
      LocalPlaybackPosition(
        key: _localPlaybackKey(),
        positionSeconds: position,
        durationSeconds: _durationSeconds > 0 ? _durationSeconds : null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  String _localPlaybackKey() {
    final videoUrl = widget.content.videoUrl?.trim();
    if (videoUrl != null && videoUrl.isNotEmpty) return 'url:$videoUrl';
    return 'content:${widget.content.id}';
  }

  String _formatDuration(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final remaining = safeSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${remaining.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}
