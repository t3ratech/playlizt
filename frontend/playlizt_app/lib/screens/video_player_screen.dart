import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/content.dart';
import '../widgets/themed_logo.dart';

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
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    print('VideoPlayerScreen: initState');
    
    try {
      // Extract video ID from URL if present, otherwise use videoUrl as is
      final rawUrl = widget.content.videoUrl ?? '';
      print('VideoPlayerScreen: rawUrl=$rawUrl');
      
      String videoId = '';
      if (rawUrl.isNotEmpty) {
        videoId = YoutubePlayer.convertUrlToId(rawUrl) ?? rawUrl;
      }
      print('VideoPlayerScreen: videoId=$videoId');

      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          isLive: false,
        ),
      )..addListener(_listener);
      _isControllerInitialized = true;
      print('VideoPlayerScreen: Controller initialized');
    } catch (e) {
      print('VideoPlayerScreen: Error in initState: $e');
    }
  }

  void _listener() {
    if (_isPlayerReady && mounted && _isControllerInitialized && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    if (_isControllerInitialized) {
      _controller.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (_isControllerInitialized) {
      _controller.dispose();
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
            height: 240, // Constrain height to prevent layout issues
            child: _isControllerInitialized 
              ? YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.red,
                  onReady: () {
                    print('VideoPlayerScreen: Player Ready');
                    _isPlayerReady = true;
                  },
                  topActions: [
                     const SizedBox(width: 8.0),
                     Expanded(
                       child: Text(
                         widget.content.title,
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 18.0,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                     ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
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
}
