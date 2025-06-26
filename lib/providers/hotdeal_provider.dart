import 'package:flutter/foundation.dart';
import 'package:couphago_frontend/models/hotdeal.dart';
import 'package:couphago_frontend/services/api_service.dart';

class HotdealProvider with ChangeNotifier {
  List<Hotdeal> _hotdeals = [];
  bool _loading = false;
  bool _error = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int? _currentCategoryId;

  List<Hotdeal> get hotdeals => _hotdeals;
  bool get loading => _loading;
  bool get error => _error;
  bool get hasMorePages => _currentPage < _totalPages;

  Future<void> fetchHotdeals({int? categoryId, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hotdeals = [];
    }

    if (categoryId != _currentCategoryId) {
      _currentCategoryId = categoryId;
      _currentPage = 1;
      _hotdeals = [];
    }

    if (_loading) return;

    _loading = true;
    _error = false;
    notifyListeners();

    try {
      final result = await ApiService.fetchHotdeals(
        categoryId: categoryId,
        page: _currentPage,
        perPage: 30,
      );

      final newHotdeals = result['hotdeals'] as List<Hotdeal>;
      _totalPages = result['totalPages'];

      if (_currentPage == 1) {
        _hotdeals = newHotdeals;
      } else {
        _hotdeals.addAll(newHotdeals);
      }

      _currentPage++;
      _error = false;
    } catch (e) {
      _error = true;
      print('Error fetching hotdeals: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void addNewHotdeal(Hotdeal hotdeal) {
    // 중복 체크
    if (_hotdeals.any((existing) => existing.id == hotdeal.id)) {
      return;
    }

    // 슈퍼핫딜이거나 현재 카테고리와 일치하는 경우에만 추가
    if (hotdeal.isSuperHotdeal || 
        _currentCategoryId == null || 
        hotdeal.categoryId == _currentCategoryId) {
      _hotdeals.insert(0, hotdeal);
      notifyListeners();
    }
  }

  void clearError() {
    _error = false;
    notifyListeners();
  }
}