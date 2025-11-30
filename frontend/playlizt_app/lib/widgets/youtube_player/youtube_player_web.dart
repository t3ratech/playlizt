import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class YoutubePlayerWidget extends StatelessWidget {
  final String videoId;
  const YoutubePlayerWidget({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final String viewType = 'youtube-iframe-$videoId-${DateTime.now().millisecondsSinceEpoch}';
    
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement();
      iframe.src = 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0';
      iframe.style.border = 'none';
      iframe.allow = 'autoplay; encrypted-media; picture-in-picture';
      iframe.allowFullscreen = true;
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      return iframe;
    });

    return HtmlElementView(viewType: viewType);
  }
}
