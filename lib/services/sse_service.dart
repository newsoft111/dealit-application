import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dealit_app/models/hotdeal.dart';

class SSEService {
  static final SSEService _instance = SSEService._internal();
  factory SSEService() => _instance;
  SSEService._internal();

  StreamController<Hotdeal>? _hotdealController;
  http.Client? _client;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  // SSE 연결 상태 스트림
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  // 새로운 핫딜 스트림
  Stream<Hotdeal> get hotdealStream {
    _hotdealController ??= StreamController<Hotdeal>.broadcast();
    return _hotdealController!.stream;
  }

  // SSE 서버 URL (Next.js와 동일한 방식)
  String get _sseUrl {
    if (kReleaseMode) {
      return 'https://api.dealit.shop/api/v1/sse?event_type=hotdeal';
    } else {
      return 'http://192.168.1.234:8000/api/v1/sse?event_type=hotdeal';
    }
  }

  // SSE 연결 시작
  Future<void> connect() async {
    if (_isConnected) {
      print('SSE 이미 연결되어 있습니다.');
      return;
    }

    try {
      print('SSE 연결 시작: $_sseUrl');
      
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(_sseUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Connection'] = 'keep-alive';

      final response = await _client!.send(request);
      
      if (response.statusCode == 200) {
        _isConnected = true;
        _connectionStatusController.add(true);
        print('SSE 연결 성공');
        
        _subscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            _handleSSEMessage(line);
          },
          onError: (error) {
            print('SSE 스트림 오류: $error');
            _handleConnectionError();
          },
          onDone: () {
            print('SSE 스트림 종료');
            _handleConnectionError();
          },
        );
      } else {
        print('SSE 연결 실패: ${response.statusCode}');
        _handleConnectionError();
      }
    } catch (e) {
      print('SSE 연결 오류: $e');
      _handleConnectionError();
    }
  }

  // SSE 메시지 처리 (Next.js와 동일한 방식)
  void _handleSSEMessage(String line) {
    if (line.startsWith('data: ')) {
      final data = line.substring(6); // 'data: ' 제거
      
      if (data.trim().isNotEmpty) {
        try {
          final wrapper = json.decode(data);
          
          // Next.js와 동일한 구조: wrapper.data에 실제 데이터가 있음
          if (wrapper['data'] != null) {
            final hotdeal = Hotdeal.fromJson(wrapper['data']);
            print('새로운 핫딜 수신: ${hotdeal.productName}');
            
            // 핫딜 스트림에 추가
            _hotdealController?.add(hotdeal);
          }
        } catch (e) {
          print('SSE 메시지 파싱 오류: $e');
        }
      }
    }
  }

  // 연결 오류 처리 및 재연결
  void _handleConnectionError() {
    _isConnected = false;
    _connectionStatusController.add(false);
    
    // 기존 연결 정리
    _subscription?.cancel();
    _client?.close();
    
    // 재연결 타이머 설정 (5초 후)
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('SSE 재연결 시도...');
      connect();
    });
  }

  // SSE 연결 해제
  void disconnect() {
    print('SSE 연결 해제');
    
    _isConnected = false;
    _connectionStatusController.add(false);
    
    _subscription?.cancel();
    _client?.close();
    _reconnectTimer?.cancel();
    
    _hotdealController?.close();
    _hotdealController = null;
  }

  // 연결 상태 확인
  bool get isConnected => _isConnected;

  // 서비스 정리
  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
} 