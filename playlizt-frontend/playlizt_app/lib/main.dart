/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/26 12:59
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/content_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'services/download_manager_platform.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';

late final SemanticsHandle _playliztSemanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _playliztSemanticsHandle = SemanticsBinding.instance.ensureSemantics();
  runApp(const PlayliztApp());
}

class PlayliztApp extends StatelessWidget {
  const PlayliztApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (ctx) => DownloadManager(
            settingsProvider: Provider.of<SettingsProvider>(ctx, listen: false),
          ),
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          return MaterialApp(
            title: 'Playlizt',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                primary: Colors.black,
                onPrimary: Colors.white,
                secondary: Colors.black87,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: ThemeData(
              colorScheme: const ColorScheme.dark(
                primary: Colors.white,
                onPrimary: Colors.black,
                secondary: Colors.white70,
                surface: Colors.black,
                onSurface: Colors.white,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              scaffoldBackgroundColor: Colors.black,
            ),
            home: authProvider.isAuthenticated 
                ? const MainShellScreen() 
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
