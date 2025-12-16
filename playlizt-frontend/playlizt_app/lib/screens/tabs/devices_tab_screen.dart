/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:16
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';

class DevicesTabScreen extends StatelessWidget {
  const DevicesTabScreen({super.key});

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
              const Icon(Icons.devices_other, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Devices',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage sync and cast targets',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add),
                label: const Text('Add Device'),
              ),
            ],
          ),
        ),

        // Device List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _DeviceTile(
                icon: Icons.computer,
                name: 'This Device',
                type: 'Local Player',
                status: 'Active',
                isCurrent: true,
              ),
              const SizedBox(height: 8),
              _DeviceTile(
                icon: Icons.tv,
                name: 'Living Room TV',
                type: 'Cast Target',
                status: 'Offline',
                isCurrent: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String type;
  final String status;
  final bool isCurrent;

  const _DeviceTile({
    required this.icon,
    required this.name,
    required this.type,
    required this.status,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        ),
        title: Text(name),
        subtitle: Text('$type • $status'),
        trailing: isCurrent
            ? const Chip(label: Text('Current'))
            : IconButton(
                icon: const Icon(Icons.settings),
                onPressed: null,
              ),
      ),
    );
  }
}
