/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 22:35
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'device_discovery_source.dart';
import 'device_models.dart';

class PlatformRendererDiscoverySource implements RendererDiscoverySource {
  const PlatformRendererDiscoverySource();

  static final InternetAddress _ssdpAddress =
      InternetAddress('239.255.255.250');
  static const int _ssdpPort = 1900;
  static const List<String> _searchTargets = [
    'urn:schemas-upnp-org:device:MediaRenderer:1',
    'urn:schemas-upnp-org:service:AVTransport:1',
    'ssdp:all',
  ];

  @override
  Future<List<PlaybackDevice>> discover({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final records = <String, _SsdpRecord>{};
    late final StreamSubscription<RawSocketEvent> subscription;

    subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      Datagram? datagram;
      while ((datagram = socket.receive()) != null) {
        final record = _SsdpRecord.parse(utf8.decode(datagram!.data));
        if (record == null) continue;
        if (!record.looksLikeRenderer) continue;
        records[record.identity] = record;
      }
    });

    for (final target in _searchTargets) {
      socket.send(utf8.encode(_searchMessage(target)), _ssdpAddress, _ssdpPort);
    }

    await Future<void>.delayed(timeout);
    await subscription.cancel();
    socket.close();

    final devices = <PlaybackDevice>[];
    final now = DateTime.now();
    final seen = <String>{};
    for (final record in records.values) {
      if (!seen.add(record.identity)) continue;
      final uri = record.location;
      final name = uri == null
          ? record.defaultName
          : await _friendlyName(uri, timeout: _halfTimeout(timeout)) ??
              record.defaultName;
      devices.add(
        PlaybackDevice(
          id: _stableRendererId(record.identity),
          name: name,
          type: PlaybackDeviceType.renderer,
          status: PlaybackDeviceStatus.available,
          uri: uri,
          capabilities: [
            'renderer',
            'casting',
            'remote control',
            'network playback',
            if (record.server != null) record.server!,
          ],
          lastSeen: now,
        ),
      );
    }

    devices
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return devices;
  }

  static String _searchMessage(String target) {
    return [
      'M-SEARCH * HTTP/1.1',
      'HOST: 239.255.255.250:1900',
      'MAN: "ssdp:discover"',
      'MX: 1',
      'ST: $target',
      '',
      '',
    ].join('\r\n');
  }

  static Duration _halfTimeout(Duration timeout) {
    return Duration(milliseconds: max(250, timeout.inMilliseconds ~/ 2));
  }

  static Future<String?> _friendlyName(
    String location, {
    required Duration timeout,
  }) async {
    final uri = Uri.tryParse(location);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final body =
          await response.transform(utf8.decoder).join().timeout(timeout);
      final match = RegExp(
        r'<friendlyName>\s*([^<]+?)\s*</friendlyName>',
        caseSensitive: false,
      ).firstMatch(body);
      return match?.group(1)?.trim();
    } finally {
      client.close(force: true);
    }
  }

  static String _stableRendererId(String identity) {
    final encoded = base64Url.encode(utf8.encode(identity)).replaceAll('=', '');
    return 'renderer-${encoded.substring(0, min(40, encoded.length))}';
  }
}

class _SsdpRecord {
  final String? location;
  final String? usn;
  final String? searchTarget;
  final String? server;

  const _SsdpRecord({
    required this.location,
    required this.usn,
    required this.searchTarget,
    required this.server,
  });

  String get identity =>
      usn ?? location ?? searchTarget ?? server ?? 'renderer';

  String get defaultName {
    final uri = location == null ? null : Uri.tryParse(location!);
    if (uri != null && uri.host.isNotEmpty) {
      return 'Renderer ${uri.host}';
    }
    if (server != null && server!.trim().isNotEmpty) {
      return server!.split(' ').first.trim();
    }
    return 'Network Renderer';
  }

  bool get looksLikeRenderer {
    final value = [
      location,
      usn,
      searchTarget,
      server,
    ].whereType<String>().join(' ').toLowerCase();
    return value.contains('mediarenderer') ||
        value.contains('avtransport') ||
        value.contains('renderer') ||
        value.contains('dlna');
  }

  static _SsdpRecord? parse(String response) {
    final headers = <String, String>{};
    for (final line in const LineSplitter().convert(response)) {
      final index = line.indexOf(':');
      if (index <= 0) continue;
      headers[line.substring(0, index).trim().toLowerCase()] =
          line.substring(index + 1).trim();
    }
    if (headers.isEmpty) return null;
    return _SsdpRecord(
      location: headers['location'],
      usn: headers['usn'],
      searchTarget: headers['st'] ?? headers['nt'],
      server: headers['server'],
    );
  }
}
