import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SettingsProvider applies and persists remote settings', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.ensureLoaded();

    await settings.applyRemoteSettings(
      downloadDirectory: '/tmp/playlizt-downloads',
      libraryScanFolders: const ['/media/videos'],
      maxConcurrentDownloads: 3,
      visibleTabs: const ['STREAMING', 'DOWNLOAD'],
      startupTab: 'DOWNLOAD',
    );

    expect(settings.downloadDirectory, '/tmp/playlizt-downloads');
    expect(settings.libraryScanFolders, const ['/media/videos']);
    expect(settings.maxConcurrentDownloads, 3);
    expect(settings.visibleTabIndices, contains(2));
    expect(settings.visibleTabIndices, contains(3));
    expect(settings.startupTabIndex, 3);

    final restored = SettingsProvider();
    await restored.ensureLoaded();

    expect(restored.downloadDirectory, '/tmp/playlizt-downloads');
    expect(restored.libraryScanFolders, const ['/media/videos']);
    expect(restored.maxConcurrentDownloads, 3);
    expect(restored.startupTabIndex, 3);
  });
}
