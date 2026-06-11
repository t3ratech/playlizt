/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:16
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/content.dart';
import '../../providers/settings_provider.dart';
import '../../services/device_manager.dart';
import '../../services/device_models.dart';
import '../video_player_screen.dart';

class DevicesTabScreen extends StatelessWidget {
  const DevicesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<DeviceManager>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final devices = manager.devices;

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
              const Icon(Icons.devices_other, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Devices',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${devices.length} targets • '
                      'Renderer discovery: '
                      '${settings.rendererDiscoveryEnabled ? 'On' : 'Off'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: manager.refreshDiscovery,
                    icon: const Icon(Icons.sync),
                    label: const Text('Refresh'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddStreamDialog(context, manager),
                    icon: const Icon(Icons.add_link),
                    label: const Text('Add Stream'),
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
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Renderer discovery'),
                  subtitle:
                      const Text('Search for playback targets on the network'),
                  value: settings.rendererDiscoveryEnabled,
                  onChanged: settings.setRendererDiscoveryEnabled,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hardware acceleration'),
                  subtitle: const Text('Prefer hardware decode when available'),
                  value: settings.hardwareAccelerationEnabled,
                  onChanged: settings.setHardwareAccelerationEnabled,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _DeviceTile(device: devices[index]);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddStreamDialog(
    BuildContext context,
    DeviceManager manager,
  ) async {
    final nameController = TextEditingController();
    final uriController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<({String name, String uri})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Network Stream'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: uriController,
                decoration: const InputDecoration(
                  labelText: 'Stream URL',
                  hintText: 'https://example.com/live.m3u8',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final uri = uriController.text.trim();
                if (uri.isEmpty) return;
                Navigator.of(context).pop(
                  (name: nameController.text.trim(), uri: uri),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    try {
      await manager.addNetworkStream(name: result.name, uri: result.uri);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Invalid stream: $e')));
    }
  }
}

class _DeviceTile extends StatelessWidget {
  final PlaybackDevice device;

  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<DeviceManager>(context, listen: false);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(_iconForType(device.type)),
        ),
        title: Text(device.name),
        subtitle: Text(
          [
            _typeLabel(device.type),
            _statusLabel(device.status),
            if (device.uri != null) device.uri!,
            if (device.errorMessage != null) device.errorMessage!,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (device.type == PlaybackDeviceType.networkStream)
              IconButton(
                tooltip: 'Play locally',
                icon: const Icon(Icons.play_arrow),
                onPressed: () async {
                  await manager.markPlaying(device.id);
                  final content = Content(
                    id: DateTime.now().millisecondsSinceEpoch,
                    creatorId: 0,
                    title: device.name,
                    category: 'Network Stream',
                    tags: const ['network', 'stream'],
                    videoUrl: device.uri,
                    durationSeconds: 0,
                    createdAt: device.lastSeen,
                    updatedAt: DateTime.now(),
                    isPublished: false,
                    viewCount: 0,
                  );
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(content: content),
                        ),
                      )
                      .whenComplete(() => manager.markAvailable(device.id));
                },
              ),
            if (device.type == PlaybackDeviceType.networkStream)
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => manager.removeDevice(device.id),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(PlaybackDeviceType type) {
    switch (type) {
      case PlaybackDeviceType.local:
        return Icons.computer;
      case PlaybackDeviceType.networkStream:
        return Icons.link;
      case PlaybackDeviceType.renderer:
        return Icons.cast;
    }
  }

  String _typeLabel(PlaybackDeviceType type) {
    switch (type) {
      case PlaybackDeviceType.local:
        return 'Local Player';
      case PlaybackDeviceType.networkStream:
        return 'Network Stream';
      case PlaybackDeviceType.renderer:
        return 'Renderer';
    }
  }

  String _statusLabel(PlaybackDeviceStatus status) {
    switch (status) {
      case PlaybackDeviceStatus.available:
        return 'Available';
      case PlaybackDeviceStatus.playing:
        return 'Playing';
      case PlaybackDeviceStatus.offline:
        return 'Offline';
      case PlaybackDeviceStatus.error:
        return 'Error';
    }
  }
}
