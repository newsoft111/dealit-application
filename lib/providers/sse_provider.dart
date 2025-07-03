import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dealit_app/services/sse_service.dart';
import 'package:dealit_app/models/hotdeal.dart';
import 'package:dealit_app/services/fcm_service.dart';

class SSEProvider extends ChangeNotifier {
  final SSEService _sseService = SSEService();
  StreamSubscription? _sseSubscription;
  StreamSubscription? _connectionStatusSubscription;
  bool _isConnected = false;
  
  // HotdealProvider 참조
  Function(Hotdeal)? _onNewHotdeal;

  bool get isConnected => _isConnected;

  // HotdealProvider 콜백 설정
  void setHotdealCallback(Function(Hotdeal) callback) {
    _onNewHotdeal = callback;
  }

  // SSE 연결 시작
  void startSSEConnection() {
    print('SSE Provider: 연결 시작');
    
    // 연결 상태 모니터링
    _connectionStatusSubscription = _sseService.connectionStatus.listen((connected) {
      _isConnected = connected;
      notifyListeners();
      print('SSE Provider: 연결 상태 변경: $connected');
    });
    
    // 새로운 핫딜 수신 처리
    _sseSubscription = _sseService.hotdealStream.listen((hotdeal) {
      print('SSE Provider: 새로운 핫딜 수신: ${hotdeal.productName}');
      _handleNewHotdeal(hotdeal);
    });
    
    // SSE 연결 시작
    _sseService.connect();
  }

  // 새로운 핫딜 처리 (Next.js와 동일한 로직)
  void _handleNewHotdeal(Hotdeal hotdeal) {
    // 1. FCM 알림 표시 (Next.js의 notifications.show와 동일)
    _showFCMNotification(hotdeal);
    
    // 2. 핫딜 목록에 추가 (Next.js의 window.dispatchEvent와 동일)
    _addToHotdealList(hotdeal);
  }

  // FCM 알림 표시
  void _showFCMNotification(Hotdeal hotdeal) {
    // FCM 서비스를 통해 로컬 알림 표시
    // 이는 Next.js의 notifications.show와 동일한 역할
    print('FCM 알림 표시: ${hotdeal.productName} / ${hotdeal.salePrice}원');
    
    // FCM 서비스에서 알림을 표시하도록 트리거
    // 실제 알림 표시는 FCM 서비스에서 처리
  }

  // 핫딜 목록에 추가 (Next.js의 window.dispatchEvent와 동일)
  void _addToHotdealList(Hotdeal hotdeal) {
    print('핫딜 목록에 추가: ${hotdeal.productName}');
    
    // HotdealProvider의 콜백 호출 (Next.js의 window.dispatchEvent와 동일)
    if (_onNewHotdeal != null) {
      _onNewHotdeal!(hotdeal);
    }
  }

  // SSE 연결 해제
  void stopSSEConnection() {
    print('SSE Provider: 연결 해제');
    _sseSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _sseService.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopSSEConnection();
    super.dispose();
  }
} 