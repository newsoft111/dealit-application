import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealit_app/services/api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:dealit_app/screens/hotdeal_detail_screen.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  late final FirebaseMessaging _firebaseMessaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;
  String? _fcmToken;
  GlobalKey<NavigatorState>? _navigatorKey;

  // 네비게이터 키 설정
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  // FCM 초기화
  Future<void> initialize() async {
    try {
      print('FCM 서비스 초기화 시작...');
      
      // Firebase 초기화
      await Firebase.initializeApp();
      print('Firebase 초기화 완료');
      
      // 로컬 알림 플러그인 초기화
      await _initializeLocalNotifications();
      
      _firebaseMessaging = FirebaseMessaging.instance;
      // 알림 권한 요청
      bool hasPermission = await _requestNotificationPermission();
      print('알림 권한 상태: $hasPermission');
      
      if (hasPermission) {
        // FCM 토큰 가져오기
        await _getFCMToken();
        
        // 토큰 변경 감지
        _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
        
        // 포그라운드 메시지 핸들러 설정
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // 앱이 백그라운드에서 포그라운드로 올 때 핸들러 설정
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        
        print('FCM 초기화 완료');
      } else {
        print('알림 권한이 거부되었습니다.');
      }
    } catch (e) {
      print('FCM 초기화 오류: $e');
    }
  }

  // 로컬 알림 플러그인 초기화
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    
    // Android 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 설정
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Android 알림 채널 생성
    await _createNotificationChannel();
  }

  // Android 알림 채널 생성
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 알림 권한 요청
  Future<bool> _requestNotificationPermission() async {
    try {
      // Android 13 이상에서는 알림 권한을 별도로 요청해야 함
      if (await Permission.notification.isDenied) {
        print('알림 권한 요청 중...');
        PermissionStatus status = await Permission.notification.request();
        print('알림 권한 상태: $status');
        return status.isGranted;
      }
      return await Permission.notification.isGranted;
    } catch (e) {
      print('알림 권한 요청 오류: $e');
      return false;
    }
  }

  // FCM 토큰 가져오기
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('FCM 토큰: $_fcmToken');
        
        // 토큰을 로컬에 저장
        await _saveFCMToken(_fcmToken!);
        
        // 서버에 토큰 전송 (비동기로 처리하여 앱이 멈추지 않도록)
        _sendTokenToServer(_fcmToken!);
      }
    } catch (e) {
      print('FCM 토큰 가져오기 오류: $e');
    }
  }

  // 토큰을 로컬에 저장
  Future<void> _saveFCMToken(String token) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('FCM 토큰이 로컬에 저장되었습니다.');
    } catch (e) {
      print('FCM 토큰 저장 오류: $e');
    }
  }

  // 서버에 토큰 전송
  Future<void> _sendTokenToServer(String token) async {
    try {
      // 타임아웃 설정 (5초)
      bool success = await ApiService.sendFCMToken(token).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('서버 토큰 전송 타임아웃');
          return false;
        },
      );
      
      if (success) {
        print('서버에 FCM 토큰을 성공적으로 전송했습니다.');
      } else {
        print('서버에 FCM 토큰 전송에 실패했습니다.');
      }
    } catch (e) {
      print('서버 토큰 전송 오류: $e');
    }
  }

  // 포그라운드 메시지 핸들러
  void _handleForegroundMessage(RemoteMessage message) {
    print('포그라운드 메시지 수신: ${message.notification?.title}');
    print('메시지 데이터: ${message.data}');
    
    // 로컬 알림 표시
    _showLocalNotification(message);
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? '새 알림',
        message.notification?.body ?? '',
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
      
      print('로컬 알림이 표시되었습니다: ${message.notification?.title}');
    } catch (e) {
      print('로컬 알림 표시 오류: $e');
    }
  }

  // 알림 탭 핸들러
  void _onNotificationTapped(NotificationResponse response) {
    print('알림이 탭되었습니다: ${response.payload}');
    
    // 페이로드에서 핫딜 ID 추출
    if (response.payload != null) {
      _handleNotificationPayload(response.payload!);
    }
  }

  // 메시지 데이터에서 핫딜 ID 추출 및 네비게이션
  void _handleNotificationPayload(String payload) {
    try {
      // 페이로드 문자열을 Map으로 파싱
      // 예: "{type: hotdeal, hotdeal_id: 123}" 형태
      final data = _parsePayload(payload);
      
      if (data['type'] == 'hotdeal' && data['hotdeal_id'] != null) {
        final hotdealId = data['hotdeal_id'];
        print('핫딜 상세 페이지로 이동: $hotdealId');
        
        // 네비게이션 실행
        _navigateToHotdealDetail(hotdealId);
      }
    } catch (e) {
      print('페이로드 처리 오류: $e');
    }
  }

  // 페이로드 문자열을 Map으로 파싱
  Map<String, dynamic> _parsePayload(String payload) {
    // "{type: hotdeal, hotdeal_id: 123}" 형태를 파싱
    final Map<String, dynamic> result = {};
    
    // 중괄호 제거
    String cleanPayload = payload.replaceAll('{', '').replaceAll('}', '');
    
    // 쉼표로 분리
    final pairs = cleanPayload.split(',');
    
    for (String pair in pairs) {
      final keyValue = pair.trim().split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = keyValue[1].trim();
        
        // 따옴표 제거
        final cleanValue = value.replaceAll('"', '').replaceAll("'", '');
        result[key] = cleanValue;
      }
    }
    
    return result;
  }

  // 핫딜 상세 페이지로 네비게이션
  void _navigateToHotdealDetail(String hotdealId) {
    if (_navigatorKey?.currentState != null) {
      // String을 int로 변환
      final int? id = int.tryParse(hotdealId);
      if (id != null) {
        _navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => HotdealDetailScreen(hotdealId: id),
          ),
        );
      } else {
        print('유효하지 않은 핫딜 ID: $hotdealId');
      }
    } else {
      print('네비게이터 키가 설정되지 않았습니다.');
    }
  }

  // 앱이 종료된 상태에서 알림을 탭했을 때 핸들러
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('알림을 탭하여 앱이 열렸습니다: ${message.notification?.title}');
    print('메시지 데이터: ${message.data}');
    
    // 메시지 데이터에서 핫딜 ID 추출 및 네비게이션
    if (message.data.isNotEmpty) {
      if (message.data['type'] == 'hotdeal' && message.data['hotdeal_id'] != null) {
        final hotdealId = message.data['hotdeal_id'];
        print('핫딜 상세 페이지로 이동: $hotdealId');
        
        // 네비게이션 실행
        _navigateToHotdealDetail(hotdealId);
      }
    }
  }

  // 저장된 FCM 토큰 가져오기
  Future<String?> getSavedFCMToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print('저장된 FCM 토큰 가져오기 오류: $e');
      return null;
    }
  }

  // 알림 권한 상태 확인
  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  // 알림 설정으로 이동
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  // FCM 토큰 삭제 (앱 삭제 시 또는 알림 비활성화 시)
  Future<void> deleteFCMToken() async {
    try {
      String? savedToken = await getSavedFCMToken();
      if (savedToken != null) {
        // 서버에서 토큰 삭제
        await ApiService.deleteFCMToken(savedToken);
        
        // 로컬에서 토큰 삭제
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('fcm_token');
        
        print('FCM 토큰이 삭제되었습니다.');
      }
    } catch (e) {
      print('FCM 토큰 삭제 오류: $e');
    }
  }

  // 토큰 변경 시 호출되는 콜백
  Future<void> _onTokenRefresh(String newToken) async {
    print('FCM 토큰이 새로고침되었습니다: $newToken');
    
    // 기존 토큰 삭제
    await deleteFCMToken();
    
    // 새 토큰 저장 및 서버 전송
    _fcmToken = newToken;
    await _saveFCMToken(newToken);
    await _sendTokenToServer(newToken);
  }
} 