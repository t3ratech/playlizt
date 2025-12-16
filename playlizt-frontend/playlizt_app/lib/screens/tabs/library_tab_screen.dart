/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:15
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class LibraryTabScreen extends StatelessWidget {
  const LibraryTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Column(
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.library_music, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Library',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '0 items • Last scan: Never',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Manage Folders'),
                  ),
                  FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rescan Now'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Search & Sort Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  enabled: false,
                  decoration: const InputDecoration(
                    hintText: 'Search local files...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'name', label: Text('Name')),
                  ButtonSegment(value: 'date', label: Text('Date Added')),
                ],
                selected: const {'name'},
                onSelectionChanged: null,
              ),
            ],
          ),
        ),

        // Content Grid/List
        Expanded(
          child: settings.libraryScanFolders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No scan folders configured',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Add folders in Settings to populate your library'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.music_note, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Library is empty. Click "Rescan Now" to index files.'),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
