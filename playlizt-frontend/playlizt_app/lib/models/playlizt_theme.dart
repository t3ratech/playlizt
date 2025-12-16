/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 10:52
 * Email        : tkaviya@t3ratech.co.zw
 */
enum PlayliztTheme {
  dark,
  light,
  system,
}

PlayliztTheme? playliztThemeFromId(String id) {
  switch (id.toUpperCase()) {
    case 'DARK':
      return PlayliztTheme.dark;
    case 'LIGHT':
      return PlayliztTheme.light;
    case 'SYSTEM':
      return PlayliztTheme.system;
  }
  return null;
}

String playliztThemeId(PlayliztTheme theme) {
  switch (theme) {
    case PlayliztTheme.dark:
      return 'DARK';
    case PlayliztTheme.light:
      return 'LIGHT';
    case PlayliztTheme.system:
      return 'SYSTEM';
  }
}
