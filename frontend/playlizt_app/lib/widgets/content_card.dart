import 'package:flutter/material.dart';
import '../models/content.dart';

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
          onTap: () {
            // TODO: Navigate to content detail screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected: ${content.title}')),
            );
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
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content.displayDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            content.category,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
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
