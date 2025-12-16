/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 10:52
 * Email        : tkaviya@t3ratech.co.zw
 */
enum PlayliztTab {
  library,
  playlists,
  streaming,
  download,
  convert,
  devices,
}

PlayliztTab? playliztTabFromId(String id) {
  switch (id.toUpperCase()) {
    case 'LIBRARY':
      return PlayliztTab.library;
    case 'PLAYLISTS':
      return PlayliztTab.playlists;
    case 'STREAMING':
      return PlayliztTab.streaming;
    case 'DOWNLOAD':
      return PlayliztTab.download;
    case 'CONVERT':
      return PlayliztTab.convert;
    case 'DEVICES':
      return PlayliztTab.devices;
  }
  return null;
}

String playliztTabId(PlayliztTab tab) {
  switch (tab) {
    case PlayliztTab.library:
      return 'LIBRARY';
    case PlayliztTab.playlists:
      return 'PLAYLISTS';
    case PlayliztTab.streaming:
      return 'STREAMING';
    case PlayliztTab.download:
      return 'DOWNLOAD';
    case PlayliztTab.convert:
      return 'CONVERT';
    case PlayliztTab.devices:
      return 'DEVICES';
  }
}
