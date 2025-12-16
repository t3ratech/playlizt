/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:16
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';

class PlaylistsTabScreen extends StatelessWidget {
  const PlaylistsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.queue_music, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Playlists',
                    child: Text(
                      'Playlists',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '0 playlists',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add),
                label: const Text('New Playlist'),
              ),
            ],
          ),
        ),

        // Empty State
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.playlist_add, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No playlists yet'),
                SizedBox(height: 8),
                Text('Create a playlist to organize your media'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
