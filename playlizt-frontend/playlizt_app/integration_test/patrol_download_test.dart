import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:playlizt_app/main.dart' as app;
import 'package:playlizt_app/providers/settings_provider.dart';
import 'package:playlizt_app/providers/playlist_provider.dart';
import 'package:playlizt_app/services/download_manager_models.dart';
import 'package:playlizt_app/services/download_manager_platform.dart';
import 'package:playlizt_app/screens/main_shell_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> _loadDownloadTestUrls() async {
  final file = File('integration_test/.download_test_urls.local.txt');
  if (!file.existsSync()) {
    print(
      'Patrol Download Test: Skipping (missing integration_test/.download_test_urls.local.txt).',
    );
    return <String>[];
  }

  final lines = await file.readAsLines();
  final urls = <String>[];
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('#')) continue;
    urls.add(trimmed);
  }

  if (urls.isEmpty) {
    print(
      'Patrol Download Test: Skipping (no active URLs in integration_test/.download_test_urls.local.txt).',
    );
    return <String>[];
  }

  return urls;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Download, Playlist, and Playback Test (Patrol)',
    (WidgetTester tester) async {
      // Initialize PatrolTester
      final $ = PatrolTester(tester: tester, config: const PatrolTesterConfig());

      // 1. Setup Authentication and Config
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setString('token', 'test_fake_token');
      await prefs.setInt('userId', 999);
      await prefs.setString('username', 'PatrolTester');
      await prefs.setString('email', 'patrol@playlizt.local');

      // Start the app
      app.main();
      await $.tester.pump(const Duration(milliseconds: 250));

      for (int i = 0; i < 40; i++) {
        if ($(MainShellScreen).exists) {
          break;
        }
        await $.tester.pump(const Duration(milliseconds: 250));
      }

      expect($(MainShellScreen), findsOneWidget);

      // 2. Configure Download Location to /tmp
      // Navigate to Download Tab
      if ($(Icons.download_outlined).exists) {
        await $(Icons.download_outlined).tap();
      } else if ($(Icons.download).exists) {
        await $(Icons.download).tap();
      } else {
        await $('Download').tap();
      }
      await $.tester.pump(const Duration(milliseconds: 250));

      // Configure default download location
      if ($(SwitchListTile).containing('Use default download location').exists) {
        // Ensure it's checked/enabled so we can use the "Edit path" feature if hidden?
        // Actually the logic in previous test was: if unchecked, check it.
        // Let's assume we want to use the default location mechanism but change the path.
        // If "Edit path" is visible, click it.
        if (!$('Edit path').exists) {
             // Maybe it's hidden because switch is OFF?
             // Or maybe we need to find the switch and tap it.
             await $(SwitchListTile).containing('Use default download location').tap();
             await $.tester.pump(const Duration(milliseconds: 250));
        }
      }

      if ($('Edit path').exists) {
        await $('Edit path').tap();
        for (int i = 0; i < 20; i++) {
          if (find.byKey(const Key('download_default_folder_input')).evaluate().isNotEmpty) {
            break;
          }
          await $.tester.pump(const Duration(milliseconds: 250));
        }
        
        // Enter /tmp in the second TextField (first is URL input)
        await $.tester.enterText(
          find.byKey(const Key('download_default_folder_input')),
          '/tmp',
        );
        await $.tester.tap(find.byKey(const Key('download_edit_path_button')));
        await $.tester.pump();
        for (int i = 0; i < 20; i++) {
          if ($('Saving to: /tmp').exists) break;
          await $.tester.pump(const Duration(milliseconds: 250));
        }
        
        // Verify path updated
        expect($('Saving to: /tmp'), findsOneWidget);
      } else {
        print('Patrol Warning: Could not find "Edit path" button. Skipping path config.');
      }

      // 3. Process each URL
      final testUrls = await _loadDownloadTestUrls();
      if (testUrls.isEmpty) {
        return;
      }
      for (final url in testUrls) {
        print('Patrol: Testing URL: $url');

        final downloadUrlInputFinder = find.byKey(const Key('download_url_input'));
        final downloadUrlInputHitTestable = downloadUrlInputFinder.hitTestable();
        final downloadSubmitButtonFinder =
            find.byKey(const Key('download_submit_button'));

        if (downloadUrlInputHitTestable.evaluate().isEmpty) {
          if ($(Icons.download_outlined).exists) {
            await $(Icons.download_outlined).tap();
          } else if ($(Icons.download).exists) {
            await $(Icons.download).tap();
          } else {
            await $('Download').tap();
          }
          for (int i = 0; i < 40; i++) {
            if (downloadUrlInputHitTestable.evaluate().isNotEmpty) {
              break;
            }
            await $.tester.pump(const Duration(milliseconds: 250));
          }
        }

        if (downloadUrlInputHitTestable.evaluate().isEmpty) {
          throw Exception('Download URL input not available for interaction');
        }

        final preContext = $.tester.element(find.byType(MaterialApp));
        final preDownloadManager =
            Provider.of<DownloadManager>(preContext, listen: false);
        final preTaskIds = preDownloadManager.tasks.map((t) => t.id).toSet();

        // Enter URL
        // We assume the text field is empty or cleared. 
        // enterText replaces content usually.
        await $.tester.tap(downloadUrlInputHitTestable);
        await $.tester.pump();
        await $.tester.enterText(downloadUrlInputHitTestable, url);
        await $.tester.pump();
        await $.tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await $.tester.pump();

        EditableText editable = $.tester.widget<EditableText>(
          find.descendant(
            of: downloadUrlInputFinder,
            matching: find.byType(EditableText),
          ),
        );
        if (editable.controller.text.trim() != url) {
          await $.tester.tap(downloadUrlInputHitTestable);
          await $.tester.pump();
          await $.tester.enterText(downloadUrlInputHitTestable, url);
          await $.tester.pump();
          await $.tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 150));
          });
          await $.tester.pump();
          editable = $.tester.widget<EditableText>(
            find.descendant(
              of: downloadUrlInputFinder,
              matching: find.byType(EditableText),
            ),
          );
          if (editable.controller.text.trim() != url) {
            throw Exception(
              'Failed to set download URL text. Expected=$url actual=${editable.controller.text}',
            );
          }
        }

        for (int i = 0; i < 40; i++) {
          final button = $.tester.widget<ElevatedButton>(downloadSubmitButtonFinder);
          if (button.onPressed != null) {
            break;
          }
          await $.tester.pump(const Duration(milliseconds: 250));
        }

        final button = $.tester.widget<ElevatedButton>(downloadSubmitButtonFinder);
        if (button.onPressed == null) {
          throw Exception('Download button is disabled');
        }

        // Tap Download
        final downloadSubmitButtonHitTestable =
            downloadSubmitButtonFinder.hitTestable();
        if (downloadSubmitButtonHitTestable.evaluate().isEmpty) {
          throw Exception('Download button is not available for interaction');
        }

        await $.tester.tap(downloadSubmitButtonHitTestable);
        await $.pump(); // Pump once to register tap

        // Wait for extraction and download to complete
        print('Patrol: Waiting for download completion...');
        
        // Wait up to 60 seconds for the file to be ready
        // We'll monitor the file system since we can't easily see progress bar values in graybox without keys.
        // Using provider to get the expected file path.
        final context = $.tester.element(find.byType(MaterialApp));
        final downloadManager = Provider.of<DownloadManager>(context, listen: false);
        
        // Poll for task creation
        DownloadTask? task;
        for (int i = 0; i < 120; i++) {
           if (i == 0 || (i + 1) % 10 == 0) {
             print(
               'Patrol: Polling for task... (Attempt ${i + 1}) - Tasks count: ${downloadManager.tasks.length}',
             );
           }
           
           // Check for SnackBar errors
           if ($(SnackBar).exists) {
             final snackBar = $(SnackBar).evaluate().first.widget as SnackBar;
             final snackContent = snackBar.content;
             String? message;
             if (snackContent is Text) {
               message = snackContent.data;
             } else {
               message = snackContent?.toString();
             }
             print('Patrol: Found SnackBar: $message');
             if (message != null &&
                 (message.contains('Failed to enqueue download') ||
                     message.contains('Please enter a valid'))) {
               throw Exception('Download enqueue rejected: $message');
             }
           }

           try {
             final candidates =
                 downloadManager.tasks.where((t) => !preTaskIds.contains(t.id)).toList();
             if (candidates.isNotEmpty) {
               task = candidates.first;
               print('Patrol: Task found!');
               break;
             }
           } catch (_) {}

           await $.tester.runAsync(() async {
             await Future<void>.delayed(const Duration(seconds: 1));
           });
           await $.tester.pump();
        }
        
        if (task == null) {
          throw Exception('Task creation failed for $url');
        }

        final downloadStart = DateTime.now();
        var lastProgressAt = DateTime.now();
        int lastReceivedBytes = -1;
        int lastFileBytes = -1;
        const maxDownloadWait = Duration(minutes: 10);
        const stallTimeout = Duration(seconds: 45);

        while (DateTime.now().difference(downloadStart) < maxDownloadWait) {
          final refreshed = downloadManager.tasks.where((t) => t.id == task!.id);
          if (refreshed.isNotEmpty) {
            task = refreshed.first;
          }

          if (task!.status == DownloadStatus.completed) {
            break;
          }
          if (task!.status == DownloadStatus.failed) {
            throw Exception('Download failed: ${task!.errorMessage}');
          }

          final currentFile = File(task!.filePath);
          final currentFileBytes = currentFile.existsSync() ? currentFile.lengthSync() : 0;
          final receivedBytes = task!.receivedBytes;

          if (receivedBytes != lastReceivedBytes || currentFileBytes != lastFileBytes) {
            lastProgressAt = DateTime.now();
            lastReceivedBytes = receivedBytes;
            lastFileBytes = currentFileBytes;
          }

          if (DateTime.now().difference(lastProgressAt) > stallTimeout) {
            throw Exception(
              'Download appears stalled for ${stallTimeout.inSeconds}s: status=${task!.status.name} received=${task!.receivedBytes} fileBytes=$currentFileBytes path=${task!.filePath}',
            );
          }

          await $.tester.runAsync(() async {
            await Future<void>.delayed(const Duration(seconds: 1));
          });
          await $.tester.pump();
        }

        if (task!.status != DownloadStatus.completed) {
          throw Exception(
            'Download did not complete within ${maxDownloadWait.inMinutes}m: status=${task!.status.name} received=${task!.receivedBytes} path=${task!.filePath}',
          );
        }

        print('Patrol: Task id=${task!.id} url=${task!.url} file=${task!.filePath}');
        if (!task!.filePath.startsWith('/tmp/')) {
          throw Exception('Expected download in /tmp, got: ${task!.filePath}');
        }

        final file = File(task!.filePath);
        if (!file.existsSync()) {
          throw Exception('Downloaded file does not exist: ${task!.filePath}');
        }

        // Poll for file completion/size
        int retries = 0;
        bool downloadSuccess = false;
        while (retries < 60) { // 60 seconds max
          if (file.existsSync() && file.lengthSync() > 1024 * 1024) {
            downloadSuccess = true;
            break;
          }
          // Also check if task failed
          if (task.status == DownloadStatus.failed) {
             throw Exception('Download failed: ${task.errorMessage}');
          }
          
          await $.tester.runAsync(() async {
            await Future<void>.delayed(const Duration(seconds: 1));
          });
          await $.tester.pump();
          retries++;
        }

        if (!downloadSuccess) {
          if (file.existsSync()) {
             throw Exception('File size too small: ${file.lengthSync()} bytes (Expected > 1MB)');
          }
          throw Exception('File not downloaded: ${task.filePath}');
        }
        print('Patrol: File verified (${file.lengthSync()} bytes)');

        // Verify "Downloads" Playlist
        for (int i = 0; i < 30; i++) {
          final playlistProvider =
              Provider.of<PlaylistProvider>(context, listen: false);
          final downloads = playlistProvider.playlists.where((p) => p.name == 'Downloads');
          if (downloads.isNotEmpty) {
            final downloadPlaylist = downloads.first;
            final hasItem = downloadPlaylist.items.any((i) => i.videoUrl == task!.filePath);
            if (hasItem) {
              print('Patrol: Downloads playlist has ${downloadPlaylist.items.length} items');
              break;
            }
          }
          await $.tester.runAsync(() async {
            await Future<void>.delayed(const Duration(seconds: 1));
          });
          await $.tester.pump();

          if (i == 29) {
            throw Exception('Downloads playlist was not updated for ${task!.filePath}');
          }
        }

        // 4. Playback Test
        final downloadCard = $(Card).containing(task!.fileName);
        expect(downloadCard, findsOneWidget);
        await downloadCard.tap();
        await $.tester.pump(const Duration(milliseconds: 250));

        // Wait for Player to open and initialize
        print('Patrol: Waiting for player initialization...');
        for (int i = 0; i < 20; i++) {
          if ($(Chewie).exists) break;
          await $.tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 250));
          });
          await $.tester.pump();
        }

        // 5. Set Volume to 1%
        final chewieFinder = $(Chewie);
        if (chewieFinder.exists) {
           final chewieWidget = chewieFinder.evaluate().first.widget as Chewie;
           chewieWidget.controller.setVolume(0.01);
           print('Patrol: Volume set to 1% (Success)');
        } else {
           print('Patrol Warning: Chewie player not found. Skipping volume check.');
        }

        // Play for 10 seconds
        print('Patrol: Playing for 10 seconds...');
        await $.tester.runAsync(() async {
          await Future<void>.delayed(const Duration(seconds: 10));
        });
        
        // Go back
        await $.tester.pageBack();

        final downloadUrlAfterBack =
            find.byKey(const Key('download_url_input')).hitTestable();
        for (int i = 0; i < 40; i++) {
          if (downloadUrlAfterBack.evaluate().isNotEmpty) {
            break;
          }
          await $.tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 250));
          });
          await $.tester.pump();
        }
      }
    },
  );
}
