import 'dart:io';
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:4080/api/v1'
  );
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  final Dio _dio;
  
  ApiService._internal() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  void clearToken() {
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
  
  Future<void> incrementViewCount(int contentId) async {
    try {
      await _dio.post('/content/$contentId/view');
    } catch (e) {
      // Ignore errors for view counting to not block user experience
      print('Failed to increment view count: $e');
    }
  }
  
  Future<Map<String, dynamic>> uploadFile(File file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });
    
    try {
      final response = await _dio.post('/content/upload', data: formData);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createContent({
    required String title,
    required String description,
    required String category,
    required int creatorId,
    String? videoUrl,
    String? thumbnailUrl,
    List<String> tags = const [],
    int durationSeconds = 0,
  }) async {
    try {
      final response = await _dio.post('/content', data: {
        'title': title,
        'description': description,
        'category': category,
        'creatorId': creatorId,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'tags': tags,
        'durationSeconds': durationSeconds,
      });
      return Map<String, dynamic>.from(response.data);
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
  
  Future<Map<String, dynamic>> getPlatformAnalytics() async {
    try {
      final response = await _dio.get('/playback/analytics/platform');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map) {
        // Check for top-level message
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
        // Check for nested error object
        if (data.containsKey('error')) {
          if (data['error'] is Map && data['error'].containsKey('message')) {
            return data['error']['message'].toString();
          }
          if (data['error'] is String) {
            return data['error'];
          }
        }
      }
      return e.response!.statusMessage ?? 'An error occurred';
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}
