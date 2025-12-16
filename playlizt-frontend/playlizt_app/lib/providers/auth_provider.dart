/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/26 12:59
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _token;
  String? _refreshToken;
  int? _userId;
  String? _username;
  String? _email;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  String? get token => _token;
  int? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  
  AuthProvider() {
    _loadFromStorage();
  }
  
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _userId = prefs.getInt('userId');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    
    if (_token != null) {
      _isAuthenticated = true;
      _apiService.setToken(_token!);
    }
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('token', _token!);
      await prefs.setString('refreshToken', _refreshToken!);
      await prefs.setInt('userId', _userId!);
      await prefs.setString('username', _username!);
      await prefs.setString('email', _email!);
    }
  }
  
  Future<String?> login(String email, String password, {required BuildContext context}) async {
    try {
      final response = await _apiService.login(email, password);
      
      _token = response['token'];
      _refreshToken = response['refreshToken'];
      _userId = response['userId'];
      _username = response['username'];
      _email = response['email'];
      _isAuthenticated = true;
      
      _apiService.setToken(_token!);
      await _saveToStorage();

      final settings = response['settings'];
      if (settings is Map<String, dynamic>) {
        final settingsProvider =
            Provider.of<SettingsProvider>(context, listen: false);
        await settingsProvider.applyRemoteSettings(
          downloadDirectory:
              settings['downloadDirectory'] as String? ?? '~/Downloads',
          libraryScanFolders:
              List<String>.from(settings['libraryScanFolders'] ?? const []),
          maxConcurrentDownloads:
              settings['maxConcurrentDownloads'] as int? ?? 2,
          visibleTabs: List<String>.from(settings['visibleTabs'] ?? const []),
          startupTab: settings['startupTab'] as String? ?? 'STREAMING',
        );
      }
      
      notifyListeners();
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }
  
  Future<String?> loginAsGuest({required BuildContext context}) async {
    try {
      final response = await _apiService.guestToken();

      _token = response['token'];
      // Guest sessions might not return refreshToken/userId/username/email
      _refreshToken = response['refreshToken'];
      _userId = response['userId'];
      _username = response['username'];
      _email = response['email'];
      _isAuthenticated = true; // Guest is technically authenticated with a limited token

      _apiService.setToken(_token!);
      // Don't save guest tokens to long-term storage or clear previous user data?
      // For now, we treat guest session as a session that doesn't survive restart or we do?
      // Let's not persist guest session to SharedPreferences to allow easy "logout" by restart if desired,
      // OR persist it if we want "Continue without login" to be remembered.
      // Given instructions: "Anonymous users... blocked from any operation that requires database access"
      // We'll treat it as a session.
      await _saveToStorage();

      final settings = response['settings'];
      if (settings is Map<String, dynamic>) {
        final settingsProvider =
            Provider.of<SettingsProvider>(context, listen: false);
        await settingsProvider.applyRemoteSettings(
          downloadDirectory:
              settings['downloadDirectory'] as String? ?? '~/Downloads',
          libraryScanFolders:
              List<String>.from(settings['libraryScanFolders'] ?? const []),
          maxConcurrentDownloads:
              settings['maxConcurrentDownloads'] as int? ?? 2,
          visibleTabs: List<String>.from(settings['visibleTabs'] ?? const []),
          startupTab: settings['startupTab'] as String? ?? 'STREAMING',
        );
      }

      notifyListeners();
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
      );
      
      _token = response['token'];
      _refreshToken = response['refreshToken'];
      _userId = response['userId'];
      _username = response['username'];
      _email = response['email'];
      _isAuthenticated = true;
      
      _apiService.setToken(_token!);
      await _saveToStorage();
      
      notifyListeners();
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }
  
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore errors
    }
    
    _token = null;
    _refreshToken = null;
    _userId = null;
    _username = null;
    _email = null;
    _isAuthenticated = false;
    
    _apiService.clearToken();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}
