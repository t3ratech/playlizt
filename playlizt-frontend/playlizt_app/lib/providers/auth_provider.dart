import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

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
  
  Future<String?> login(String email, String password) async {
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
