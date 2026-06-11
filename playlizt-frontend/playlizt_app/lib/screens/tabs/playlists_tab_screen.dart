/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:16
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/playlist.dart';
import '../../providers/playlist_provider.dart';

class PlaylistsTabScreen extends StatelessWidget {
  const PlaylistsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context);
    final playlists = provider.playlists;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.queue_music, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
                      '${playlists.length} playlists',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('New Playlist'),
              ),
            ],
          ),
        ),
        Expanded(
          child: playlists.isEmpty
              ? const Center(
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: playlists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _PlaylistTile(playlist: playlists[index]);
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    PlaylistProvider provider,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (name != null) {
      await provider.createPlaylist(name);
    }
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.queue_music)),
        title: Text(playlist.name),
        subtitle: Text(
          '${playlist.items.length} items • ${_playlistTypeLabel(playlist)}',
        ),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _PlaylistEditorDialog(playlist: playlist),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'rename') {
              await _rename(context, provider);
            } else if (value == 'duplicate') {
              await provider.duplicatePlaylist(playlist.id);
            } else if (value == 'delete') {
              await provider.deletePlaylist(playlist.id);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    PlaylistProvider provider,
  ) async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (name != null) {
      await provider.renamePlaylist(playlist.id, name);
    }
  }

  String _playlistTypeLabel(Playlist playlist) {
    final hasLocal = playlist.items.any((item) {
      final url = (item.videoUrl ?? '').toLowerCase();
      return !(url.startsWith('http://') || url.startsWith('https://'));
    });
    final hasOnline = playlist.items.any((item) {
      final url = (item.videoUrl ?? '').toLowerCase();
      return url.startsWith('http://') || url.startsWith('https://');
    });
    if (hasLocal && hasOnline) return 'Hybrid';
    if (hasOnline) return 'Online';
    return 'Local';
  }
}

class _PlaylistEditorDialog extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistEditorDialog({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        final current = provider.playlists.firstWhere(
          (item) => item.id == playlist.id,
          orElse: () => playlist,
        );

        return AlertDialog(
          title: Text(current.name),
          content: SizedBox(
            width: 520,
            height: 420,
            child: current.items.isEmpty
                ? const Center(child: Text('This playlist is empty'))
                : ReorderableListView.builder(
                    itemCount: current.items.length,
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderPlaylistItems(
                        current.id,
                        oldIndex,
                        newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final item = current.items[index];
                      return ListTile(
                        key: ValueKey('${current.id}-${item.id}-$index'),
                        leading: const Icon(Icons.drag_handle),
                        title: Text(item.title),
                        subtitle: Text(
                          item.videoUrl ?? 'Missing media URL',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
