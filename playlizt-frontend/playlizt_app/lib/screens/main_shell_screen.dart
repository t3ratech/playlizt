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
import '../services/conversion_models.dart';
import '../services/download_manager_platform.dart';
import '../models/content.dart';
import '../widgets/themed_logo.dart';
import 'admin_dashboard_screen.dart';
import 'creator_dashboard_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'video_player_screen.dart';
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
      final settings = Provider.of<SettingsProvider>(context, listen: false);
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
  final TextEditingController _batchUrlsController = TextEditingController();
  final TextEditingController _defaultPathController = TextEditingController();
  final TextEditingController _formatIdController = TextEditingController();
  final TextEditingController _proxyController = TextEditingController();
  final TextEditingController _rateLimitController = TextEditingController();
  final TextEditingController _cookieFileController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _retriesController = TextEditingController();
  final TextEditingController _fragmentRetriesController =
      TextEditingController();
  final TextEditingController _concurrentFragmentsController =
      TextEditingController();
  final TextEditingController _socketTimeoutController =
      TextEditingController();
  final TextEditingController _maxDownloadsController = TextEditingController();
  final TextEditingController _userAgentController = TextEditingController();
  final TextEditingController _refererController = TextEditingController();
  final TextEditingController _playlistStartController =
      TextEditingController();
  final TextEditingController _playlistEndController = TextEditingController();
  final TextEditingController _playlistItemsController =
      TextEditingController();
  final TextEditingController _matchTitleController = TextEditingController();
  final TextEditingController _rejectTitleController = TextEditingController();
  final TextEditingController _ageLimitController = TextEditingController();
  final TextEditingController _geoVerificationProxyController =
      TextEditingController();
  bool _isSubmitting = false;
  bool _isPreviewing = false;
  bool _isEditingDefaultPath = false;
  bool _audioOnly = false;
  bool _writeSubtitles = false;
  bool _writeThumbnail = false;
  bool _writeMetadata = false;
  bool _geoBypass = false;
  bool _forcePlaylist = false;
  DownloadPreview? _downloadPreview;
  String? _downloadPreviewError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _defaultPathController.text = settings.downloadDirectory;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _batchUrlsController.dispose();
    _defaultPathController.dispose();
    _formatIdController.dispose();
    _proxyController.dispose();
    _rateLimitController.dispose();
    _cookieFileController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _retriesController.dispose();
    _fragmentRetriesController.dispose();
    _concurrentFragmentsController.dispose();
    _socketTimeoutController.dispose();
    _maxDownloadsController.dispose();
    _userAgentController.dispose();
    _refererController.dispose();
    _playlistStartController.dispose();
    _playlistEndController.dispose();
    _playlistItemsController.dispose();
    _matchTitleController.dispose();
    _rejectTitleController.dispose();
    _ageLimitController.dispose();
    _geoVerificationProxyController.dispose();
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
    final urls = DownloadBatchParser.parseUrls(
      '${_urlController.text}\n${_batchUrlsController.text}',
    );
    final invalidUrls = urls.where((url) => !_isValidUrl(url)).toList();
    if (urls.isEmpty || invalidUrls.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid http/https URL')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final options = DownloadOptions(
        formatId: _emptyToNull(_formatIdController.text),
        audioOnly: _audioOnly,
        writeSubtitles: _writeSubtitles,
        writeThumbnail: _writeThumbnail,
        writeMetadata: _writeMetadata,
        proxy: _emptyToNull(_proxyController.text),
        rateLimit: _emptyToNull(_rateLimitController.text),
        cookieFile: _emptyToNull(_cookieFileController.text),
        username: _emptyToNull(_usernameController.text),
        password: _emptyToNull(_passwordController.text),
        retries: _emptyToNull(_retriesController.text),
        fragmentRetries: _emptyToNull(_fragmentRetriesController.text),
        concurrentFragments: _emptyToNull(_concurrentFragmentsController.text),
        socketTimeoutSeconds: _emptyToNull(_socketTimeoutController.text),
        maxDownloads: _emptyToNull(_maxDownloadsController.text),
        userAgent: _emptyToNull(_userAgentController.text),
        referer: _emptyToNull(_refererController.text),
        playlistStart: _emptyToNull(_playlistStartController.text),
        playlistEnd: _emptyToNull(_playlistEndController.text),
        playlistItems: _emptyToNull(_playlistItemsController.text),
        matchTitle: _emptyToNull(_matchTitleController.text),
        rejectTitle: _emptyToNull(_rejectTitleController.text),
        ageLimit: _emptyToNull(_ageLimitController.text),
        geoBypass: _geoBypass,
        geoVerificationProxy:
            _emptyToNull(_geoVerificationProxyController.text),
        forcePlaylist: _forcePlaylist,
      );

      if (settings.useDefaultDownloadLocation) {
        final newPath = _defaultPathController.text.trim();
        if (newPath.isNotEmpty && newPath != settings.downloadDirectory) {
          await settings.setDownloadDirectory(newPath);
        }
        await downloadManager.enqueueBatchDownloads(
          urls: urls,
          options: options,
        );
      } else if (urls.length == 1) {
        final saveLocation = await _promptCustomLocation(urls.single, settings);
        if (saveLocation == null) {
          return;
        }
        await downloadManager.enqueueDownload(
          url: urls.single,
          targetDirectory: saveLocation.directory,
          explicitFileName: saveLocation.fileName,
          options: options,
        );
      } else {
        final targetDirectory = await _promptCustomBatchDirectory(settings);
        if (targetDirectory == null) {
          return;
        }
        await downloadManager.enqueueBatchDownloads(
          urls: urls,
          targetDirectory: targetDirectory,
          options: options,
        );
      }

      _urlController.clear();
      _batchUrlsController.clear();
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

  Future<void> _previewDownload(DownloadManager downloadManager) async {
    final url = _urlController.text.trim();
    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid http/https URL')),
      );
      return;
    }

    setState(() {
      _isPreviewing = true;
      _downloadPreview = null;
      _downloadPreviewError = null;
    });

    try {
      final preview = await downloadManager.previewDownload(url);
      if (!mounted) return;
      setState(() {
        _downloadPreview = preview;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadPreviewError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isPreviewing = false);
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<_SaveLocation?> _promptCustomLocation(
    String url,
    SettingsProvider settings,
  ) async {
    final uri = Uri.parse(url);
    final suggestedName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'download.bin';

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

  Future<String?> _promptCustomBatchDirectory(SettingsProvider settings) async {
    final folderController =
        TextEditingController(text: settings.downloadDirectory);

    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batch Download Folder'),
          content: TextField(
            controller: folderController,
            decoration: const InputDecoration(
              labelText: 'Folder',
              hintText: '/home/user/Downloads',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final folder = folderController.text.trim();
                if (folder.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(folder);
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
                      key: const Key('download_url_input'),
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
                    key: const Key('download_submit_button'),
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
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isPreviewing
                        ? null
                        : () => _previewDownload(downloadManager),
                    icon: _isPreviewing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.manage_search),
                    label: Text(_isPreviewing ? 'Previewing' : 'Preview'),
                  ),
                ],
              ),
              if (_downloadPreview != null ||
                  _downloadPreviewError != null) ...[
                const SizedBox(height: 12),
                _DownloadPreviewPanel(
                  preview: _downloadPreview,
                  errorMessage: _downloadPreviewError,
                  onUseFormat: (formatId) {
                    setState(() {
                      _formatIdController.text = formatId;
                    });
                  },
                ),
              ],
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
                      key: const Key('download_edit_path_button'),
                      onPressed: () {
                        if (_isEditingDefaultPath) {
                          final newPath = _defaultPathController.text.trim();
                          if (newPath.isNotEmpty &&
                              newPath != settings.downloadDirectory) {
                            settings.setDownloadDirectory(newPath);
                          }
                        }
                        setState(() {
                          _isEditingDefaultPath = !_isEditingDefaultPath;
                        });
                      },
                      child: Text(_isEditingDefaultPath ? 'Done' : 'Edit path'),
                    ),
                  ],
                ),
                if (_isEditingDefaultPath) ...[
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('download_default_folder_input'),
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
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Advanced downloader options'),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Skip archived downloads'),
                    subtitle: Text(
                      '${downloadManager.archiveEntries.length} completed source'
                      '${downloadManager.archiveEntries.length == 1 ? '' : 's'}',
                    ),
                    value: settings.downloadArchiveEnabled,
                    onChanged: settings.setDownloadArchiveEnabled,
                    secondary: downloadManager.archiveEntries.isEmpty
                        ? null
                        : TextButton(
                            onPressed: downloadManager.clearDownloadArchive,
                            child: const Text('Clear'),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _batchUrlsController,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Batch URLs',
                      hintText: 'https://example.com/video.mp4',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Audio only'),
                        selected: _audioOnly,
                        onSelected: (value) {
                          setState(() => _audioOnly = value);
                        },
                      ),
                      FilterChip(
                        label: const Text('Subtitles'),
                        selected: _writeSubtitles,
                        onSelected: (value) {
                          setState(() => _writeSubtitles = value);
                        },
                      ),
                      FilterChip(
                        label: const Text('Thumbnail'),
                        selected: _writeThumbnail,
                        onSelected: (value) {
                          setState(() => _writeThumbnail = value);
                        },
                      ),
                      FilterChip(
                        label: const Text('Write metadata'),
                        selected: _writeMetadata,
                        onSelected: (value) {
                          setState(() => _writeMetadata = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _formatIdController,
                          decoration: const InputDecoration(
                            labelText: 'Format id / selector',
                            hintText: 'bestvideo+bestaudio/best',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _rateLimitController,
                          decoration: const InputDecoration(
                            labelText: 'Rate limit',
                            hintText: '2M',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _proxyController,
                    decoration: const InputDecoration(
                      labelText: 'Proxy',
                      hintText: 'socks5://127.0.0.1:1080',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _retriesController,
                          decoration: const InputDecoration(
                            labelText: 'Retries',
                            hintText: '10',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _fragmentRetriesController,
                          decoration: const InputDecoration(
                            labelText: 'Fragment retries',
                            hintText: '10',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _concurrentFragmentsController,
                          decoration: const InputDecoration(
                            labelText: 'Concurrent fragments',
                            hintText: '4',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _socketTimeoutController,
                          decoration: const InputDecoration(
                            labelText: 'Socket timeout',
                            hintText: '20',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxDownloadsController,
                          decoration: const InputDecoration(
                            labelText: 'Max downloads',
                            hintText: '25',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _userAgentController,
                          decoration: const InputDecoration(
                            labelText: 'User agent',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _refererController,
                          decoration: const InputDecoration(
                            labelText: 'Referrer',
                            hintText: 'https://example.com',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cookieFileController,
                    decoration: const InputDecoration(
                      labelText: 'Cookie file',
                      hintText: '/home/user/cookies.txt',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Force playlist'),
                        selected: _forcePlaylist,
                        onSelected: (value) {
                          setState(() => _forcePlaylist = value);
                        },
                      ),
                      FilterChip(
                        label: const Text('Geo bypass'),
                        selected: _geoBypass,
                        onSelected: (value) {
                          setState(() => _geoBypass = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _playlistStartController,
                          decoration: const InputDecoration(
                            labelText: 'Playlist start',
                            hintText: '1',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _playlistEndController,
                          decoration: const InputDecoration(
                            labelText: 'Playlist end',
                            hintText: '10',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _playlistItemsController,
                          decoration: const InputDecoration(
                            labelText: 'Playlist items',
                            hintText: '1,3,5-8',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _matchTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Match title',
                            hintText: 'regex',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _rejectTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Reject title',
                            hintText: 'regex',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ageLimitController,
                          decoration: const InputDecoration(
                            labelText: 'Age limit',
                            hintText: '18',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _geoVerificationProxyController,
                    decoration: const InputDecoration(
                      labelText: 'Geo verification proxy',
                      hintText: 'socks5://127.0.0.1:1080',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

class _DownloadPreviewPanel extends StatelessWidget {
  final DownloadPreview? preview;
  final String? errorMessage;
  final ValueChanged<String> onUseFormat;

  const _DownloadPreviewPanel({
    required this.preview,
    required this.errorMessage,
    required this.onUseFormat,
  });

  @override
  Widget build(BuildContext context) {
    final error = errorMessage?.trim();
    if (error != null && error.isNotEmpty) {
      return Text(error, style: const TextStyle(color: Colors.red));
    }

    final info = preview;
    if (info == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.video_library_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (info.extractorName != null)
                  Chip(label: Text(info.extractorName!)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (info.durationSeconds != null)
                  Chip(label: Text(_duration(info.durationSeconds!))),
                Chip(label: Text('${info.formatCount} formats')),
                Chip(label: Text('${info.subtitleCount} subtitles')),
                Chip(label: Text('${info.thumbnailCount} thumbnails')),
                if (info.isPlaylist)
                  Chip(label: Text('${info.playlistCount} playlist items')),
              ],
            ),
            if (info.uploader != null || info.uploadDate != null) ...[
              const SizedBox(height: 8),
              Text(
                [
                  if (info.uploader != null) info.uploader!,
                  if (info.uploadDate != null) info.uploadDate!,
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (info.description != null && info.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                info.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (info.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                info.warnings.join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.orange),
              ),
            ],
            if (info.formats.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Formats',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  itemCount: info.formats.take(12).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final format = info.formats[index];
                    final formatId = format.formatId;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        format.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _formatDetails(format),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: formatId == null || formatId.trim().isEmpty
                          ? null
                          : TextButton(
                              onPressed: () => onUseFormat(formatId),
                              child: const Text('Use'),
                            ),
                    );
                  },
                ),
              ),
            ],
            if (info.subtitles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Subtitles: ${info.subtitles.take(8).map(_subtitleLabel).join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (info.playlistEntries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Playlist Preview',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              ...info.playlistEntries.take(5).map((entry) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.queue_music),
                  title: Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if (entry.durationSeconds != null)
                        _duration(entry.durationSeconds!),
                      '${entry.formatCount} formats',
                      '${entry.subtitleCount} subtitles',
                    ].join(' • '),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDetails(DownloadPreviewFormat format) {
    final parts = <String>[
      if (format.formatId != null) format.formatId!,
      if (format.protocol != null) format.protocol!,
      if (format.width != null && format.height != null)
        '${format.width}x${format.height}',
      if (format.fps != null) '${format.fps!.toStringAsFixed(2)} fps',
    ];
    return parts.isEmpty ? 'Format details unavailable' : parts.join(' • ');
  }

  String _subtitleLabel(DownloadPreviewSubtitle subtitle) {
    final auto = subtitle.automatic ? ' auto' : '';
    final ext = subtitle.extension == null ? '' : ' ${subtitle.extension}';
    return '${subtitle.language}$ext$auto';
  }

  String _duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remaining = seconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${remaining.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
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
      case DownloadStatus.extracting:
        return Colors.blue;
      case DownloadStatus.downloading:
        return Theme.of(context).colorScheme.primary;
      case DownloadStatus.postProcessing:
        return Colors.purple;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.skipped:
        return Colors.teal;
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
      case DownloadStatus.extracting:
        return 'Extracting';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.postProcessing:
        return 'Post-processing';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.skipped:
        return 'Skipped';
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

    void openPlayer() {
      if (task.status != DownloadStatus.completed &&
          task.status != DownloadStatus.skipped) {
        return;
      }
      final content = Content(
        id: DateTime.now().millisecondsSinceEpoch,
        creatorId: 0,
        title: task.title ?? task.fileName,
        category: 'Downloads',
        tags: const ['downloaded'],
        thumbnailUrl: task.thumbnailUrl,
        videoUrl: task.filePath,
        durationSeconds: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: false,
        viewCount: 0,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(content: content),
        ),
      );
    }

    return GestureDetector(
      onTap: openPlayer,
      child: Card(
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
                [
                  if (task.playlistTitle != null) task.playlistTitle!,
                  if (task.playlistIndex != null && task.playlistCount != null)
                    'Item ${task.playlistIndex} of ${task.playlistCount}',
                  if (task.formatLabel != null) task.formatLabel!,
                  task.filePath,
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (task.status == DownloadStatus.skipped) ...[
                Text(task.currentStage),
              ] else if (progress != null) ...[
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% • '
                  '${task.currentStage}${_transferLabel(task)}',
                ),
              ] else ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 4),
                Text(task.currentStage),
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
                      if (task.status == DownloadStatus.downloading ||
                          task.status == DownloadStatus.extracting ||
                          task.status == DownloadStatus.postProcessing)
                        TextButton(
                          onPressed: () => manager.pauseDownload(task.id),
                          child: const Text('Pause'),
                        ),
                      if (task.status == DownloadStatus.paused ||
                          task.status == DownloadStatus.failed ||
                          task.status == DownloadStatus.skipped ||
                          task.status == DownloadStatus.cancelled)
                        TextButton(
                          onPressed: () => manager.resumeDownload(task.id),
                          child: const Text('Resume'),
                        ),
                      if (task.status == DownloadStatus.queued ||
                          task.status == DownloadStatus.downloading ||
                          task.status == DownloadStatus.extracting ||
                          task.status == DownloadStatus.postProcessing ||
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
              if (task.sidecarFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: task.sidecarFiles.map((file) {
                    return Chip(
                      avatar: Icon(_sidecarIcon(file.type), size: 18),
                      label: Text(
                        '${_sidecarLabel(file)}: ${file.fileName}',
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _transferLabel(DownloadTask task) {
    final parts = <String>[];
    final speed = task.speedBytesPerSecond;
    if (speed != null && speed > 0) {
      parts.add('${_formatBytes(speed.round())}/s');
    }
    final eta = task.etaSeconds;
    if (eta != null && eta >= 0) {
      final minutes = (eta ~/ 60).toString().padLeft(2, '0');
      final seconds = (eta % 60).toString().padLeft(2, '0');
      parts.add('ETA $minutes:$seconds');
    }
    if (parts.isEmpty) return '';
    return ' • ${parts.join(' • ')}';
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

  IconData _sidecarIcon(DownloadSidecarType type) {
    switch (type) {
      case DownloadSidecarType.subtitle:
        return Icons.subtitles_outlined;
      case DownloadSidecarType.thumbnail:
        return Icons.image_outlined;
      case DownloadSidecarType.metadata:
        return Icons.description_outlined;
    }
  }

  String _sidecarLabel(DownloadSidecarFile file) {
    switch (file.type) {
      case DownloadSidecarType.subtitle:
        return file.language == null ? 'Subtitle' : 'Subtitle ${file.language}';
      case DownloadSidecarType.thumbnail:
        return 'Thumbnail';
      case DownloadSidecarType.metadata:
        return 'Metadata';
    }
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            onPressed: () => Navigator.of(context).pop(null),
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
                            onPressed: () => Navigator.of(context).pop(null),
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
            SwitchListTile(
              title: const Text('Scan folders recursively'),
              value: settings.recursiveLibraryScan,
              onChanged: settings.setRecursiveLibraryScan,
            ),
            const Divider(),
            ListTile(
              title: const Text('Conversion output folder'),
              subtitle: Text(settings.conversionOutputDirectory),
              trailing: TextButton(
                onPressed: () async {
                  final controller = TextEditingController(
                    text: settings.conversionOutputDirectory,
                  );
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Change conversion output folder'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Folder path',
                            hintText: '/home/user/Videos/Playlizt',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(null),
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
                    await settings.setConversionOutputDirectory(result.trim());
                  }
                },
                child: const Text('Change…'),
              ),
            ),
            ListTile(
              title: const Text('Conversion file conflicts'),
              subtitle: Text(
                _collisionPolicyDescription(
                  settings.conversionOutputCollisionPolicy,
                ),
              ),
              trailing: DropdownButton<ConversionOutputCollisionPolicy>(
                value: settings.conversionOutputCollisionPolicy,
                onChanged: (value) {
                  if (value == null) return;
                  settings.setConversionOutputCollisionPolicy(value);
                },
                items: ConversionOutputCollisionPolicy.values.map((policy) {
                  return DropdownMenuItem(
                    value: policy,
                    child: Text(_collisionPolicyLabel(policy)),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: const Text('Maximum concurrent downloads'),
              subtitle: Text(settings.maxConcurrentDownloads.toString()),
              trailing: SizedBox(
                width: 140,
                child: Slider(
                  value: settings.maxConcurrentDownloads.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: settings.maxConcurrentDownloads.toString(),
                  onChanged: (value) {
                    settings.setMaxConcurrentDownloads(value.round());
                  },
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Skip archived downloads'),
              value: settings.downloadArchiveEnabled,
              onChanged: settings.setDownloadArchiveEnabled,
            ),
            SwitchListTile(
              title: const Text('Hardware acceleration'),
              value: settings.hardwareAccelerationEnabled,
              onChanged: settings.setHardwareAccelerationEnabled,
            ),
            SwitchListTile(
              title: const Text('Renderer discovery'),
              value: settings.rendererDiscoveryEnabled,
              onChanged: settings.setRendererDiscoveryEnabled,
            ),
            const Divider(),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(
                themeProvider.themeMode == ThemeMode.dark ? 'Dark' : 'Light',
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
            if (authProvider.isAuthenticated &&
                (authProvider.token?.isNotEmpty ?? false) &&
                !(authProvider.token == 'guest')) ...[
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

  String _collisionPolicyLabel(ConversionOutputCollisionPolicy policy) {
    switch (policy) {
      case ConversionOutputCollisionPolicy.keepBoth:
        return 'Keep both';
      case ConversionOutputCollisionPolicy.overwrite:
        return 'Overwrite';
      case ConversionOutputCollisionPolicy.fail:
        return 'Fail';
    }
  }

  String _collisionPolicyDescription(ConversionOutputCollisionPolicy policy) {
    switch (policy) {
      case ConversionOutputCollisionPolicy.keepBoth:
        return 'Create numbered output files';
      case ConversionOutputCollisionPolicy.overwrite:
        return 'Replace existing output files';
      case ConversionOutputCollisionPolicy.fail:
        return 'Stop before replacing a file';
    }
  }
}
