import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/content.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
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
  
  bool _isYoutube = false;
  String? _youtubeVideoId;
  bool _isPlayerReady = false;
  bool _isControllerInitialized = false;
  
  Timer? _playbackTimer;
  int _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    print('VideoPlayerScreen: initState');
    _initializePlayer();
    _startPlaybackTracking();
  }

  void _startPlaybackTracking() {
    // Delay slightly to ensure context is valid if needed, though Provider.of with listen:false is safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId == null) return;
      
      // Report initial start
      _reportPlayback(authProvider.userId!, 0);
      
      // Report progress every 10 seconds
      _playbackTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        int position = _currentPosition;
        
        if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
           position = _videoPlayerController!.value.position.inSeconds;
        } else {
           // For YouTube or other players where we might not have direct position access easily
           // We simulate progress for history tracking purposes
           position += 10;
        }
        
        _currentPosition = position;
        _reportPlayback(authProvider.userId!, position);
      });
    });
  }

  Future<void> _reportPlayback(int userId, int position) async {
    try {
      if (widget.content.id == null) return;
      
      await ApiService().trackPlayback(
        userId: userId,
        contentId: widget.content.id!,
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
          _isPlayerReady = true;
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
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    
    await _videoPlayerController!.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
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
        _isPlayerReady = true;
      });
      print('VideoPlayerScreen: Direct Player initialized');
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    if (_videoPlayerController != null) {
      _videoPlayerController!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
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
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
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
}
