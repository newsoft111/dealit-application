import 'package:flutter/foundation.dart';
import 'package:couphago_frontend/models/category.dart';
import 'package:couphago_frontend/services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _loading = false;
  bool _error = false;

  List<Category> get categories => _categories;
  bool get loading => _loading;
  bool get error => _error;

  Future<void> fetchCategories() async {
    if (_loading) return;

    _loading = true;
    _error = false;
    notifyListeners();

    try {
      _categories = await ApiService.fetchCategories();
      _error = false;
    } catch (e) {
      _error = true;
      print('Error fetching categories: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}