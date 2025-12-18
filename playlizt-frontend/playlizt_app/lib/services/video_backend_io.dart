import 'dart:io';

import 'package:fvp/fvp.dart' as fvp;

void registerVideoBackend() {
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    return;
  }

  fvp.registerWith(options: {
    'platforms': ['linux', 'windows', 'macos'],
  });
}
