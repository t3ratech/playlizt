/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 22:35
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'device_discovery_source.dart';
import 'device_models.dart';

class PlatformRendererDiscoverySource implements RendererDiscoverySource {
  const PlatformRendererDiscoverySource();

  @override
  Future<List<PlaybackDevice>> discover({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    throw UnsupportedError(
      'Renderer discovery requires desktop network socket support',
    );
  }
}
