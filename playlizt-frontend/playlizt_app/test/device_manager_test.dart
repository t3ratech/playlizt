import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/providers/settings_provider.dart';
import 'package:playlizt_app/services/device_discovery_source.dart';
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

    test('discovers renderer devices and controls playback state', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.ensureLoaded();
      final manager = DeviceManager(
        settingsProvider: settings,
        discoverySource: _StaticRendererDiscoverySource([
          PlaybackDevice(
            id: 'renderer-living-room',
            name: 'Living Room Display',
            type: PlaybackDeviceType.renderer,
            status: PlaybackDeviceStatus.available,
            uri: 'http://192.0.2.5/device.xml',
            capabilities: const ['renderer', 'remote control'],
            lastSeen: DateTime(2026, 6, 11),
          ),
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      await manager.refreshDiscovery();
      var renderer = manager.deviceById('renderer-living-room');

      expect(renderer, isNotNull);
      expect(renderer!.type, PlaybackDeviceType.renderer);
      expect(renderer.connected, isFalse);

      await manager.connectRenderer(renderer.id);
      renderer = manager.deviceById('renderer-living-room')!;
      expect(renderer.connected, isTrue);
      expect(renderer.transportState, PlaybackTransportState.stopped);

      await manager.playOnRenderer(
        deviceId: renderer.id,
        title: 'Feature Film',
        uri: 'https://example.test/movie.mp4',
      );
      renderer = manager.deviceById('renderer-living-room')!;
      expect(renderer.status, PlaybackDeviceStatus.playing);
      expect(renderer.transportState, PlaybackTransportState.playing);
      expect(renderer.activeTitle, 'Feature Film');
      expect(renderer.activeUri, 'https://example.test/movie.mp4');

      await manager.seekRenderer(renderer.id, 75);
      await manager.setRendererVolume(renderer.id, 120);
      renderer = manager.deviceById('renderer-living-room')!;
      expect(renderer.positionSeconds, 75);
      expect(renderer.volumePercent, 100);

      await manager.pauseRenderer(renderer.id);
      renderer = manager.deviceById('renderer-living-room')!;
      expect(renderer.transportState, PlaybackTransportState.paused);
      expect(renderer.activeTitle, 'Feature Film');

      await manager.resumeRenderer(renderer.id);
      renderer = manager.deviceById('renderer-living-room')!;
      expect(renderer.transportState, PlaybackTransportState.playing);

      await manager.stopRenderer(renderer.id);
      renderer = manager.deviceById('renderer-living-room')!;
      expect(renderer.transportState, PlaybackTransportState.stopped);
      expect(renderer.activeUri, isNull);

      await manager.disconnectRenderer(renderer.id);
      renderer = manager.deviceById('renderer-living-room')!;
      expect(renderer.connected, isFalse);
    });

    test('does not run renderer discovery when setting is disabled', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.ensureLoaded();
      await settings.setRendererDiscoveryEnabled(false);
      final discovery = _StaticRendererDiscoverySource([
        PlaybackDevice(
          id: 'renderer-office',
          name: 'Office Display',
          type: PlaybackDeviceType.renderer,
          status: PlaybackDeviceStatus.available,
          lastSeen: DateTime(2026, 6, 11),
        ),
      ]);
      final manager = DeviceManager(
        settingsProvider: settings,
        discoverySource: discovery,
      );
      await Future<void>.delayed(Duration.zero);

      await manager.refreshDiscovery();

      expect(discovery.calls, 0);
      expect(manager.devices.map((device) => device.id),
          isNot(contains('renderer-office')));
    });
  });
}

class _StaticRendererDiscoverySource implements RendererDiscoverySource {
  final List<PlaybackDevice> devices;
  int calls = 0;

  _StaticRendererDiscoverySource(this.devices);

  @override
  Future<List<PlaybackDevice>> discover({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    calls++;
    return devices;
  }
}
