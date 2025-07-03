import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dealit_app/models/hotdeal.dart';
import 'package:dealit_app/services/api_service.dart';
import 'package:dealit_app/providers/sse_provider.dart';

class HotdealProvider with ChangeNotifier {
  List<Hotdeal> _hotdeals = [];
  bool _loading = false;
  bool _error = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int? _currentCategoryId;
  
  // SSE Provider 참조
  SSEProvider? _sseProvider;

  List<Hotdeal> get hotdeals => _hotdeals;
  bool get loading => _loading;
  bool get error => _error;
  bool get hasMorePages => _currentPage <= _totalPages;
  int? get currentCategoryId => _currentCategoryId;

  // SSE Provider 설정
  void setSSEProvider(SSEProvider sseProvider) {
    _sseProvider = sseProvider;
    _listenToNewHotdeals();
  }

  // 새로운 핫딜 수신 리스너 설정
  void _listenToNewHotdeals() {
    if (_sseProvider != null) {
      // SSE Provider의 새로운 핫딜 스트림을 구독
      // 실제로는 SSE Provider에서 직접 호출하도록 구현
    }
  }

  // SSE Provider에서 호출되는 메서드 (Next.js의 window.addEventListener와 동일)
  void addNewHotdealFromSSE(Hotdeal hotdeal) {
    print('HotdealProvider: SSE에서 새로운 핫딜 수신: ${hotdeal.productName}');
    
    // Next.js와 동일한 로직:
    // 슈퍼핫딜인 경우: 카테고리 ID가 null이거나 카테고리가 일치하는 경우
    if (hotdeal.isSuperHotdeal) {
      if (_currentCategoryId == null || hotdeal.categoryId == _currentCategoryId) {
        _addNewHotdeal(hotdeal);
      }
    }
    // 일반 핫딜인 경우: 카테고리가 일치하는 경우에만
    else if (hotdeal.categoryId == _currentCategoryId) {
      _addNewHotdeal(hotdeal);
    }
  }

  // 새로운 핫딜 추가 (내부 메서드)
  void _addNewHotdeal(Hotdeal hotdeal) {
    // 이미 존재하는 핫딜인지 확인
    if (_hotdeals.any((existing) => existing.id == hotdeal.id)) {
      return;
    }

    // 새 핫딜을 맨 앞에 추가 (Next.js와 동일)
    _hotdeals.insert(0, hotdeal);
    notifyListeners();
    print('새로운 핫딜이 목록에 추가되었습니다: ${hotdeal.productName}');
  }

  Future<void> fetchHotdeals({int? categoryId, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hotdeals = [];
    }

    // 카테고리 ID가 전달되고 현재 카테고리와 다른 경우에만 리셋
    if (categoryId != _currentCategoryId) {
      _currentCategoryId = categoryId;
      _currentPage = 1;
      _hotdeals = [];
    }

    // 슈퍼핫딜인 경우 categoryId를 null로 설정
    int? requestCategoryId = categoryId;
    if (categoryId == null) {
      requestCategoryId = null; // 슈퍼핫딜
    }

    if (_loading) return;

    _loading = true;
    _error = false;
    notifyListeners();

    try {
      print('API 요청 - 페이지: $_currentPage, 카테고리: $requestCategoryId');
      
      final result = await ApiService.fetchHotdeals(
        categoryId: requestCategoryId, // null이면 슈퍼핫딜 요청
        page: _currentPage,
        perPage: 30,
      );

      final newHotdeals = result['hotdeals'] as List<Hotdeal>;
      _totalPages = result['totalPages'];
      
      print('API 응답 - 받은 핫딜 수: ${newHotdeals.length}, 총 페이지: $_totalPages, 현재 페이지: $_currentPage');

      if (_currentPage == 1) {
        _hotdeals = newHotdeals;
      } else {
        _hotdeals.addAll(newHotdeals);
      }

      _currentPage++;
      _error = false;
      
      print('페이지 업데이트 완료 - 다음 페이지: $_currentPage, 더 로드할 페이지 있음: $hasMorePages');
    } catch (e) {
      _error = true;
      print('Error fetching hotdeals: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = false;
    notifyListeners();
  }
}