import 'dart:io';

import 'package:fvp/fvp.dart' as fvp;

import 'playback_models.dart';

void registerVideoBackend({
  PlaybackEngineConfiguration configuration =
      const PlaybackEngineConfiguration(),
}) {
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    return;
  }

  fvp.registerWith(
    options: configuration.toFvpOptions(
      platforms: const ['linux', 'windows', 'macos'],
    ),
  );
}
