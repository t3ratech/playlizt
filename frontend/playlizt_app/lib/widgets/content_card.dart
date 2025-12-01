import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/content.dart';
import '../providers/content_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/video_player_screen.dart';

class ContentCard extends StatelessWidget {
  final Content content;
  final double? width;

  const ContentCard({
    super.key,
    required this.content,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: InkWell(
          onTap: () async {
            print('ContentCard: Tapped content ${content.id} - ${content.title}');
            try {
              // Increment view count
              Provider.of<ContentProvider>(context, listen: false).incrementView(content.id);
            } catch (e) {
              print('ContentCard: Error incrementing view: $e');
            }
            
            // Show SnackBar for UI Test
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected: ${content.title}'),
                duration: const Duration(seconds: 1),
              ),
            );
            
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(content: content),
              ),
            );

            // Refresh Continue Watching on return
            if (context.mounted) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
               if (authProvider.userId != null) {
                   Provider.of<ContentProvider>(context, listen: false).loadContinueWatching(authProvider.userId!);
               }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              AspectRatio(
                aspectRatio: 16 / 9,
                child: content.thumbnailUrl != null
                    ? Image.network(
                        content.thumbnailUrl!,
                        semanticLabel: 'Video: ${content.title}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, size: 48),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, size: 48),
                      ),
              ),
              
              // Content Info
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[800] 
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            content.category,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        if (content.aiContentRating != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              content.aiContentRating!,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        if (content.aiSentiment != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              content.aiSentiment!,
                              style: const TextStyle(fontSize: 10, color: Colors.blue),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (content.formattedDuration.isNotEmpty)
                          Text(
                            content.formattedDuration,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.visibility, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${content.viewCount} views',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
