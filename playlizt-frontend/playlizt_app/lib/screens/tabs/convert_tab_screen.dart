/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:16
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';

class ConvertTabScreen extends StatefulWidget {
  const ConvertTabScreen({super.key});

  @override
  State<ConvertTabScreen> createState() => _ConvertTabScreenState();
}

class _ConvertTabScreenState extends State<ConvertTabScreen> {
  String _selectedProfile = 'MP3 (Audio Only)';
  final _profiles = [
    'MP3 (Audio Only)',
    'MP4 (720p)',
    'MP4 (1080p)',
    'Clip Segment',
  ];

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
              const Icon(Icons.switch_video, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Convert Media',
                    child: Text(
                      'Convert Media',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transcode or clip your local media files',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Conversion Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Job', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Select Input File...'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedProfile,
                          decoration: const InputDecoration(
                            labelText: 'Output Profile',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _profiles.map((p) {
                            return DropdownMenuItem(value: p, child: Text(p));
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedProfile = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_selectedProfile == 'Clip Segment') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Start Time (HH:MM:SS)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'End Time (HH:MM:SS)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: null, // Disabled until file selected
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Conversion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const Divider(),

        // Jobs Queue
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Conversion Queue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),

        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.checklist_rtl, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No active conversion jobs'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
