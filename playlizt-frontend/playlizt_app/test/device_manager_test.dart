import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/providers/settings_provider.dart';
import 'package:playlizt_app/services/device_manager.dart';
import 'package:playlizt_app/services/device_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeviceManager', () {
    test('adds and persists network stream devices', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.ensureLoaded();

      final manager = DeviceManager(settingsProvider: settings);
      await Future<void>.delayed(Duration.zero);
      final stream = await manager.addNetworkStream(
        name: 'Live Feed',
        uri: 'https://example.test/live.m3u8',
      );

      expect(stream.type, PlaybackDeviceType.networkStream);
      expect(stream.status, PlaybackDeviceStatus.available);
      expect(
          manager.devices.map((device) => device.name), contains('Live Feed'));

      final restored = DeviceManager(settingsProvider: settings);
      await Future<void>.delayed(Duration.zero);

      expect(
        restored.devices.map((device) => device.uri),
        contains('https://example.test/live.m3u8'),
      );
    });

    test('rejects unsupported stream schemes', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.ensureLoaded();
      final manager = DeviceManager(settingsProvider: settings);
      await Future<void>.delayed(Duration.zero);

      expect(
        () => manager.addNetworkStream(name: 'Bad', uri: 'file:///tmp/a.mp4'),
        throwsArgumentError,
      );
    });
  });
}
