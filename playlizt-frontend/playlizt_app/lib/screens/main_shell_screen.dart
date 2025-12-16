/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 14:17
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../utils/test_bridge_stub.dart'
    if (dart.library.html) '../utils/test_bridge_web.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/download_manager_platform.dart';
import '../widgets/themed_logo.dart';
import 'admin_dashboard_screen.dart';
import 'creator_dashboard_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'tabs/convert_tab_screen.dart';
import 'tabs/devices_tab_screen.dart';
import 'tabs/library_tab_screen.dart';
import 'tabs/playlists_tab_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const int _tabsCount = 6;

  int _currentIndex = 2; // Default to Streaming

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings =
          Provider.of<SettingsProvider>(context, listen: false);
      await settings.ensureLoaded();
      if (!mounted) return;
      setState(() {
        _currentIndex = settings.startupTabIndex.clamp(0, _tabsCount - 1);
      });

      registerPlayliztTestBridge((tabIndex) {
        if (tabIndex >= 0 && tabIndex < _tabsCount) {
          _onTabSelected(tabIndex);
        }
      });
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setStartupTabIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    final tabs = <Widget>[
      const LibraryTabScreen(),
      const PlaylistsTabScreen(),
      const HomeScreen(),
      const _DownloadTabHost(),
      const ConvertTabScreen(),
      const DevicesTabScreen(),
    ];

    const labels = [
      'Library',
      'Playlists',
      'Streaming',
      'Download',
      'Convert',
      'Devices',
    ];

    const icons = <IconData>[
      Icons.library_music_outlined,
      Icons.queue_music_outlined,
      Icons.wifi_tethering,
      Icons.download_outlined,
      Icons.switch_video_outlined,
      Icons.devices_other_outlined,
    ];

    const selectedIcons = <IconData>[
      Icons.library_music,
      Icons.queue_music,
      Icons.wifi_tethering_rounded,
      Icons.download,
      Icons.switch_video,
      Icons.devices_other,
    ];

    final visibleTabs = settings.visibleTabIndices;

    // Ensure the current tab index is always one of the visible tabs
    int effectiveIndex = _currentIndex;
    if (!visibleTabs.contains(effectiveIndex)) {
      effectiveIndex = settings.startupTabIndex;
      if (!visibleTabs.contains(effectiveIndex)) {
        effectiveIndex = visibleTabs.first;
      }
      _currentIndex = effectiveIndex;
    }

    final selectedTab = tabs[_currentIndex];

    // Check if we are in guest mode and the selected tab requires auth (Streaming)
    // Actually, Streaming is public browse, but upload/analytics are restricted.
    // However, if we had restricted tabs, we would check it here.
    // Streaming IS public. Download IS public (local). Library IS public (local).
    // So all current tabs are safe for guest.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlizt'),
        centerTitle: false,
        actions: [
          Builder(
            builder: (ctx) {
              return IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Settings',
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      endDrawer: const _SettingsDrawer(),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: visibleTabs.indexOf(_currentIndex),
            onDestinationSelected: (railIndex) {
              final tabIndex = visibleTabs[railIndex];
              _onTabSelected(tabIndex);
            },
            labelType: NavigationRailLabelType.all,
            groupAlignment: -1.0,
            indicatorColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.18),
            useIndicator: true,
            destinations: visibleTabs
                .map(
                  (tabIndex) => NavigationRailDestination(
                    icon: Icon(icons[tabIndex]),
                    selectedIcon: Icon(selectedIcons[tabIndex]),
                    label: Text(labels[tabIndex]),
                  ),
                )
                .toList(),
          ),
          Expanded(child: selectedTab),
        ],
      ),
    );
  }
}

class _DownloadTabHost extends StatefulWidget {
  const _DownloadTabHost();

  @override
  State<_DownloadTabHost> createState() => _DownloadTabHostState();
}

class _DownloadTabHostState extends State<_DownloadTabHost> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _defaultPathController = TextEditingController();
  bool _isSubmitting = false;
  bool _isEditingDefaultPath = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings =
          Provider.of<SettingsProvider>(context, listen: false);
      _defaultPathController.text = settings.downloadDirectory;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _defaultPathController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    return uri.isScheme('http') || uri.isScheme('https');
  }

  Future<void> _startDownload(
    SettingsProvider settings,
    DownloadManager downloadManager,
  ) async {
    final rawUrl = _urlController.text.trim();
    if (!_isValidUrl(rawUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid http/https URL')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (settings.useDefaultDownloadLocation) {
        final newPath = _defaultPathController.text.trim();
        if (newPath.isNotEmpty && newPath != settings.downloadDirectory) {
          await settings.setDownloadDirectory(newPath);
        }
        await downloadManager.enqueueDownload(url: rawUrl);
      } else {
        final saveLocation = await _promptCustomLocation(rawUrl, settings);
        if (saveLocation == null) {
          return;
        }
        await downloadManager.enqueueDownload(
          url: rawUrl,
          targetDirectory: saveLocation.directory,
          explicitFileName: saveLocation.fileName,
        );
      }

      _urlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enqueue download: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<_SaveLocation?> _promptCustomLocation(
    String url,
    SettingsProvider settings,
  ) async {
    final uri = Uri.parse(url);
    final suggestedName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'download.bin';

    final folderController =
        TextEditingController(text: settings.downloadDirectory);
    final nameController = TextEditingController(text: suggestedName);

    return showDialog<_SaveLocation?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Download As'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: folderController,
                decoration: const InputDecoration(
                  labelText: 'Folder',
                  hintText: '/home/user/Downloads',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'File name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final folder = folderController.text.trim();
                final name = nameController.text.trim();
                if (folder.isEmpty || name.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  _SaveLocation(directory: folder, fileName: name),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, DownloadManager>(
      builder: (context, settings, downloadManager, _) {
        final tasks = downloadManager.tasks;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Download from URL',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/video.mp4',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) {
                        if (!_isSubmitting) {
                          _startDownload(settings, downloadManager);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _startDownload(settings, downloadManager),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Download'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use default download location'),
                contentPadding: EdgeInsets.zero,
                value: settings.useDefaultDownloadLocation,
                onChanged: (value) {
                  settings.setUseDefaultDownloadLocation(value);
                },
              ),
              if (settings.useDefaultDownloadLocation) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saving to: ${settings.downloadDirectory}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingDefaultPath = !_isEditingDefaultPath;
                        });
                      },
                      child:
                          Text(_isEditingDefaultPath ? 'Done' : 'Edit path'),
                    ),
                  ],
                ),
                if (_isEditingDefaultPath) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _defaultPathController,
                    decoration: const InputDecoration(
                      labelText: 'Default download folder',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ] else ...[
                const Text(
                  'Each download will prompt for a folder and file name.',
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Active and recent downloads',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Text('No downloads yet'),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _DownloadListTile(task: task);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SaveLocation {
  final String directory;
  final String fileName;

  _SaveLocation({required this.directory, required this.fileName});
}

class _DownloadListTile extends StatelessWidget {
  final DownloadTask task;

  const _DownloadListTile({required this.task});

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Theme.of(context).colorScheme.primary;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.cancelled:
        return Colors.grey;
      case DownloadStatus.queued:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  String _statusLabel() {
    switch (task.status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<DownloadManager>(context, listen: false);
    final host = Uri.tryParse(task.url);
    final hostLabel = host?.host ?? '';
    final progress = task.progress;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (hostLabel.isNotEmpty)
                  Text(
                    hostLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              task.filePath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (progress != null) ...[
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ] else ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              const Text('Preparing'),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: _statusColor(context),
                  ),
                ),
                Row(
                  children: [
                    if (task.status == DownloadStatus.downloading)
                      TextButton(
                        onPressed: () => manager.pauseDownload(task.id),
                        child: const Text('Pause'),
                      ),
                    if (task.status == DownloadStatus.paused ||
                        task.status == DownloadStatus.failed ||
                        task.status == DownloadStatus.cancelled)
                      TextButton(
                        onPressed: () => manager.resumeDownload(task.id),
                        child: const Text('Resume'),
                      ),
                    if (task.status == DownloadStatus.queued ||
                        task.status == DownloadStatus.downloading ||
                        task.status == DownloadStatus.paused)
                      TextButton(
                        onPressed: () => manager.cancelDownload(task.id),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
            if (task.errorMessage != null &&
                task.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsDrawer extends StatelessWidget {
  const _SettingsDrawer();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Center(child: ThemedLogo(height: 72)),
                SizedBox(height: 12),
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Use default download location'),
              value: settings.useDefaultDownloadLocation,
              onChanged: (value) {
                settings.setUseDefaultDownloadLocation(value);
              },
            ),
            ListTile(
              title: const Text('Default download folder'),
              subtitle: Text(settings.downloadDirectory),
              trailing: TextButton(
                onPressed: () async {
                  final controller =
                      TextEditingController(text: settings.downloadDirectory);
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Change default download folder'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Folder path',
                            hintText: '/home/user/Downloads',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(null),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
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

                  if (result != null && result.isNotEmpty) {
                    await settings.setDownloadDirectory(result.trim());
                  }
                },
                child: const Text('Change…'),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Library scan folders'),
              subtitle: settings.libraryScanFolders.isEmpty
                  ? const Text('No folders configured')
                  : Wrap(
                      spacing: 4,
                      runSpacing: -8,
                      children: settings.libraryScanFolders
                          .map(
                            (folder) => Chip(
                              label: Text(folder),
                              onDeleted: () =>
                                  settings.removeLibraryScanFolder(folder),
                            ),
                          )
                          .toList(),
                    ),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final controller = TextEditingController();
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Add scan folder'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Folder path',
                            hintText: '/home/user/Music',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(null),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              final value = controller.text.trim();
                              if (value.isEmpty) return;
                              Navigator.of(context).pop(value);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );

                  if (result != null && result.isNotEmpty) {
                    await settings.addLibraryScanFolder(result);
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(
                themeProvider.themeMode == ThemeMode.dark
                    ? 'Dark'
                    : 'Light',
              ),
              onTap: () => themeProvider.toggleTheme(),
            ),
            const Divider(),
            ListTile(
              title: const Text('Startup tab'),
              subtitle: Text(
                () {
                  const labels = [
                    'Library',
                    'Playlists',
                    'Streaming',
                    'Download',
                    'Convert',
                    'Devices',
                  ];
                  final idx = settings.startupTabIndex;
                  if (idx < 0 || idx >= labels.length) return 'Streaming';
                  return labels[idx];
                }(),
              ),
              onTap: () async {
                const labels = [
                  'Library',
                  'Playlists',
                  'Streaming',
                  'Download',
                  'Convert',
                  'Devices',
                ];
                final selected = await showDialog<int>(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      title: const Text('Select startup tab'),
                      children: List.generate(labels.length, (index) {
                        return RadioListTile<int>(
                          value: index,
                          groupValue: settings.startupTabIndex,
                          title: Text(labels[index]),
                          onChanged: (value) {
                            Navigator.of(context).pop(value);
                          },
                        );
                      }),
                    );
                  },
                );

                if (selected != null) {
                  await settings.setStartupTabIndex(selected);
                }
              },
            ),
            const Divider(),
            const ListTile(
              title: Text('Visible tabs'),
              subtitle: Text(
                'Choose which tabs are shown in the navigation rail. Streaming is always enabled.',
              ),
            ),
            Column(
              children: List.generate(6, (index) {
                const labels = [
                  'Library',
                  'Playlists',
                  'Streaming',
                  'Download',
                  'Convert',
                  'Devices',
                ];

                final label = labels[index];
                final isStreaming = index == 2;
                final isWebRestricted = kIsWeb && (index == 0 || index == 5);

                final canToggle = !isStreaming && !isWebRestricted;

                String? subtitle;
                if (isStreaming) {
                  subtitle = 'Required default tab';
                } else if (isWebRestricted) {
                  subtitle = 'Not available on web';
                }

                return SwitchListTile(
                  title: Text(label),
                  subtitle: subtitle != null ? Text(subtitle) : null,
                  value: settings.isTabVisible(index),
                  onChanged: canToggle
                      ? (value) => settings.setTabVisible(index, value)
                      : null,
                );
              }),
            ),
            const Divider(),
            if (authProvider.isAuthenticated && (authProvider.token?.isNotEmpty ?? false) && !(authProvider.token == 'guest')) ...[
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Upload content'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatorDashboardScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analytics dashboard'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                subtitle: Text(authProvider.email ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await authProvider.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ] else ...[
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Limited guest mode'),
                subtitle: Text(
                  'Upload, analytics and profile actions require login.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await authProvider.logout(); // Clear guest session
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
