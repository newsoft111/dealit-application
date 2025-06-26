import 'package:flutter/foundation.dart';
import 'package:dealit_app/models/category.dart' as models;
import 'package:dealit_app/services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  List<models.Category> _categories = [];
  bool _loading = false;
  bool _error = false;

  List<models.Category> get categories => _categories;
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