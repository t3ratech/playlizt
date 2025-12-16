/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 17:25
 * Email        : tkaviya@t3ratech.co.zw
 */

// Web-only test bridge for Playlizt Flutter web UI.
//
// Exposes a global `window.playliztNavigateToTab(index)` function that can be
// called from Playwright tests via `page.evaluate` to switch shell tabs
// without relying on DOM selectors, which are unreliable with Flutter's
// canvas-based rendering.

import 'dart:html' as html;
import 'dart:js_util' as js_util;

void registerPlayliztTestBridge(void Function(int tabIndex) onSelectTab) {
  // Safely install the bridge on the window object.
  js_util.setProperty(
    html.window,
    'playliztNavigateToTab',
    js_util.allowInterop((Object? index) {
      if (index is int) {
        onSelectTab(index);
      } else if (index is num) {
        onSelectTab(index.toInt());
      }
    }),
  );
}
