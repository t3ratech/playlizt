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
                      '${settings.rendererDiscoveryEnabled ? 'On' : 'Off'}'
                      '${manager.isDiscovering ? ' • Searching' : ''}'
                      '${manager.discoveryError == null ? '' : ' • Discovery error'}',
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
      child: Column(
        children: [
          ListTile(
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
                if (device.connected) 'Connected',
                if (device.activeTitle != null) device.activeTitle!,
                if (device.uri != null) device.uri!,
                if (device.errorMessage != null) device.errorMessage!,
              ].join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                if (device.type == PlaybackDeviceType.renderer)
                  IconButton(
                    tooltip: device.connected ? 'Disconnect' : 'Connect',
                    icon: Icon(
                      device.connected ? Icons.cast_connected : Icons.cast,
                    ),
                    onPressed: () => device.connected
                        ? manager.disconnectRenderer(device.id)
                        : manager.connectRenderer(device.id),
                  ),
                if (device.type == PlaybackDeviceType.networkStream)
                  IconButton(
                    tooltip: 'Play locally',
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () async {
                      await manager.markPlaying(device.id);
                      if (!context.mounted) return;
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
                              builder: (_) =>
                                  VideoPlayerScreen(content: content),
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
          if (device.type == PlaybackDeviceType.renderer)
            _RendererControls(device: device),
        ],
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

class _RendererControls extends StatelessWidget {
  final PlaybackDevice device;

  const _RendererControls({required this.device});

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<DeviceManager>(context, listen: false);
    final connected = device.connected;
    final hasMedia = device.activeUri != null;
    final isPlaying = device.transportState == PlaybackTransportState.playing;
    final position = Duration(seconds: device.positionSeconds);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hasMedia
                      ? '${device.activeTitle} • ${_formatDuration(position)}'
                      : 'No media loaded',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton(
                tooltip: 'Cast URL',
                icon: const Icon(Icons.open_in_browser),
                onPressed: connected
                    ? () => _showCastDialog(context, manager, device)
                    : null,
              ),
              IconButton(
                tooltip: isPlaying ? 'Pause' : 'Resume',
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: connected && hasMedia
                    ? () => isPlaying
                        ? manager.pauseRenderer(device.id)
                        : manager.resumeRenderer(device.id)
                    : null,
              ),
              IconButton(
                tooltip: 'Stop',
                icon: const Icon(Icons.stop),
                onPressed: connected && hasMedia
                    ? () => manager.stopRenderer(device.id)
                    : null,
              ),
              IconButton(
                tooltip: 'Seek forward',
                icon: const Icon(Icons.forward_10),
                onPressed: connected && hasMedia
                    ? () => manager.seekRenderer(
                          device.id,
                          device.positionSeconds + 10,
                        )
                    : null,
              ),
            ],
          ),
          Row(
            children: [
              Icon(device.muted ? Icons.volume_off : Icons.volume_up),
              Expanded(
                child: Slider(
                  value: device.volumePercent.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${device.volumePercent}%',
                  onChanged: connected
                      ? (value) =>
                          manager.setRendererVolume(device.id, value.round())
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCastDialog(
    BuildContext context,
    DeviceManager manager,
    PlaybackDevice device,
  ) async {
    final titleController = TextEditingController();
    final uriController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<({String title, String uri})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cast URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: uriController,
                decoration: const InputDecoration(
                  labelText: 'Media URL',
                  hintText: 'https://example.com/movie.mp4',
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
                  (title: titleController.text.trim(), uri: uri),
                );
              },
              child: const Text('Cast'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    try {
      await manager.playOnRenderer(
        deviceId: device.id,
        title: result.title,
        uri: result.uri,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Cast failed: $e')));
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
