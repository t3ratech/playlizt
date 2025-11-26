import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/content.dart';

class ContentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Content> _contentList = [];
  List<Content> _continueWatching = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  
  List<Content> get contentList => _contentList;
  List<Content> get continueWatching => _continueWatching;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadContent({int page = 0, int size = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getContent(page: page, size: size);
      _contentList = (response['content'] as List)
          .map((json) => Content.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> searchContent(String query, {int page = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.searchContent(query, page: page);
      _contentList = (response['content'] as List)
          .map((json) => Content.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> loadContinueWatching(int userId) async {
    try {
      final response = await _apiService.getContinueWatching(userId);
      _continueWatching = (response['content'] as List)
          .map((json) => Content.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<Content?> getContentById(int id) async {
    try {
      final response = await _apiService.getContentById(id);
      return Content.fromJson(response);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
