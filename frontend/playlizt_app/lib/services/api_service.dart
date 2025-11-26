import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  final Dio _dio;
  
  String? _token;
  
  ApiService._internal() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  void clearToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
  }
  
  // Auth APIs
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String role = 'USER',
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    }
  }
  
  // Content APIs
  Future<Map<String, dynamic>> getContent({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/content', queryParameters: {
        'page': page,
        'size': size,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getContentById(int id) async {
    try {
      final response = await _dio.get('/content/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> searchContent(String query, {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/content/search', queryParameters: {
        'q': query,
        'page': page,
        'size': size,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('/content/categories');
      return List<String>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Playback APIs
  Future<void> trackPlayback({
    required int userId,
    required int contentId,
    required int positionSeconds,
    bool completed = false,
  }) async {
    try {
      await _dio.post('/playback/track', data: {
        'userId': userId,
        'contentId': contentId,
        'positionSeconds': positionSeconds,
        'completed': completed,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getContinueWatching(int userId, {int page = 0, int size = 10}) async {
    try {
      final response = await _dio.get('/playback/continue', queryParameters: {
        'userId': userId,
        'page': page,
        'size': size,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getViewingHistory(int userId, {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/playback/history', queryParameters: {
        'userId': userId,
        'page': page,
        'size': size,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // AI APIs
  Future<List<dynamic>> getRecommendations(int userId) async {
    try {
      final response = await _dio.get('/ai/recommendations', queryParameters: {
        'userId': userId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error']['message'] ?? 'An error occurred';
      }
      return e.response!.statusMessage ?? 'An error occurred';
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}
