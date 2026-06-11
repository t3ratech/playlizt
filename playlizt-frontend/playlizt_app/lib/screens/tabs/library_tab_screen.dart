/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:15
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/content.dart';
import '../../providers/settings_provider.dart';
import '../../services/library_manager_platform.dart';
import '../video_player_screen.dart';

class LibraryTabScreen extends StatelessWidget {
  const LibraryTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final library = Provider.of<LibraryManager>(context);
    final items = library.filteredItems;

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
              const Icon(Icons.library_music, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Library',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${library.items.length} items • '
                      '${library.videoCount} videos • '
                      '${library.audioCount} audio • '
                      'Last scan: ${_formatLastScan(library.lastScanAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Folders'),
                  ),
                  FilledButton.icon(
                    onPressed: library.isScanning
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final result = await library.rescan();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Scan complete: ${result.importedItems} new, '
                                    '${result.scannedFiles} scanned',
                                  ),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text('Library scan failed: $e')),
                              );
                            }
                          },
                    icon: library.isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(library.isScanning ? 'Scanning' : 'Rescan'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  enabled: library.items.isNotEmpty,
                  decoration: const InputDecoration(
                    hintText: 'Search local files...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: library.setSearchQuery,
                ),
              ),
              const SizedBox(width: 16),
              SegmentedButton<LibrarySortMode>(
                segments: const [
                  ButtonSegment(
                    value: LibrarySortMode.name,
                    label: Text('Name'),
                  ),
                  ButtonSegment(
                    value: LibrarySortMode.dateAdded,
                    label: Text('Added'),
                  ),
                  ButtonSegment(
                    value: LibrarySortMode.size,
                    label: Text('Size'),
                  ),
                ],
                selected: {library.sortMode},
                onSelectionChanged: (selection) {
                  library.setSortMode(selection.first);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: settings.libraryScanFolders.isEmpty
              ? _LibraryEmptyState(
                  icon: Icons.folder_off_outlined,
                  title: 'No scan folders configured',
                  message: 'Add folders in Settings to populate your library',
                  actionLabel: 'Open Settings',
                  onAction: () => Scaffold.of(context).openEndDrawer(),
                )
              : items.isEmpty
                  ? _LibraryEmptyState(
                      icon: Icons.music_note,
                      title: library.items.isEmpty
                          ? 'Library is empty'
                          : 'No matching media',
                      message: library.items.isEmpty
                          ? 'Click Rescan to index configured folders'
                          : 'Change the search text or sort/filter choice',
                      actionLabel: 'Rescan',
                      onAction:
                          library.isScanning ? null : () => library.rescan(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _LibraryItemTile(item: item);
                      },
                    ),
        ),
      ],
    );
  }

  String _formatLastScan(DateTime? value) {
    if (value == null) return 'Never';
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _LibraryItemTile extends StatelessWidget {
  final LibraryItem item;

  const _LibraryItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_iconForType(item.mediaType)),
        ),
        title: Text(
          item.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.mediaType.name} • ${item.source.name} • '
          '${_formatBytes(item.fileSizeBytes)}\n${item.path}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.play_arrow),
        onTap: item.mediaType == LibraryMediaType.video ||
                item.mediaType == LibraryMediaType.audio
            ? () {
                final content = Content(
                  id: DateTime.now().millisecondsSinceEpoch,
                  creatorId: 0,
                  title: item.displayTitle,
                  category: 'Library',
                  tags: [item.mediaType.name, item.source.name],
                  thumbnailUrl: item.thumbnailPath,
                  videoUrl: item.path,
                  durationSeconds: item.durationSeconds ?? 0,
                  createdAt: item.dateAdded,
                  updatedAt: item.lastSeen,
                  isPublished: false,
                  viewCount: 0,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(content: content),
                  ),
                );
              }
            : null,
      ),
    );
  }

  IconData _iconForType(LibraryMediaType type) {
    switch (type) {
      case LibraryMediaType.audio:
        return Icons.audiotrack;
      case LibraryMediaType.video:
        return Icons.movie;
      case LibraryMediaType.subtitle:
        return Icons.subtitles;
      case LibraryMediaType.image:
        return Icons.image;
      case LibraryMediaType.unknown:
        return Icons.insert_drive_file;
    }
  }

  String _formatBytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) {
      return '${(value / 1024).toStringAsFixed(1)} KB';
    }
    if (value < 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _LibraryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  const _LibraryEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
