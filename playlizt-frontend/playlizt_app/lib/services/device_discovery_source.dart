/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 22:35
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'device_models.dart';

abstract class RendererDiscoverySource {
  Future<List<PlaybackDevice>> discover({
    Duration timeout = const Duration(seconds: 2),
  });
}
