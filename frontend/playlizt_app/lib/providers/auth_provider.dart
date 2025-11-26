import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  String? _token;
  String? _refreshToken;
  int? _userId;
  String? _username;
  String? _email;
  String? _role;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  int? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get role => _role;
  
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
    _role = prefs.getString('role');
    
    if (_token != null) {
      _isAuthenticated = true;
      _apiService.setToken(_token!);
      notifyListeners();
    }
  }
  
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('token', _token!);
      await prefs.setString('refreshToken', _refreshToken!);
      await prefs.setInt('userId', _userId!);
      await prefs.setString('username', _username!);
      await prefs.setString('email', _email!);
      await prefs.setString('role', _role!);
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
      _role = response['role'];
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
    String role = 'USER',
  }) async {
    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        role: role,
      );
      
      _token = response['token'];
      _refreshToken = response['refreshToken'];
      _userId = response['userId'];
      _username = response['username'];
      _email = response['email'];
      _role = response['role'];
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
    _role = null;
    _isAuthenticated = false;
    
    _apiService.clearToken();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}
