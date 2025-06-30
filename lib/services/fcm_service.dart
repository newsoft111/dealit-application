import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealit_app/services/api_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  // FCM 초기화
  Future<void> initialize() async {
    try {
      // Firebase 초기화
      await Firebase.initializeApp();
      
      // 알림 권한 요청
      bool hasPermission = await _requestNotificationPermission();
      
      if (hasPermission) {
        // FCM 토큰 가져오기
        await _getFCMToken();
        
        // 토큰 변경 감지
        _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
        
        // 포그라운드 메시지 핸들러 설정
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // 백그라운드 메시지 핸들러 설정
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
        
        // 앱이 종료된 상태에서 알림을 탭했을 때 핸들러 설정
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        
        print('FCM 초기화 완료');
      } else {
        print('알림 권한이 거부되었습니다.');
      }
    } catch (e) {
      print('FCM 초기화 오류: $e');
    }
  }

  // 알림 권한 요청
  Future<bool> _requestNotificationPermission() async {
    // Android 13 이상에서는 알림 권한을 별도로 요청해야 함
    if (await Permission.notification.isDenied) {
      PermissionStatus status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  // FCM 토큰 가져오기
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('FCM 토큰: $_fcmToken');
        
        // 토큰을 로컬에 저장
        await _saveFCMToken(_fcmToken!);
        
        // 서버에 토큰 전송
        await _sendTokenToServer(_fcmToken!);
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
      bool success = await ApiService.sendFCMToken(token);
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
    
    // TODO: 로컬 알림 표시 또는 UI 업데이트
    // 예: showLocalNotification(message);
  }

  // 백그라운드 메시지 핸들러 (top-level function이어야 함)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('백그라운드 메시지 수신: ${message.notification?.title}');
    
    // TODO: 백그라운드에서 처리할 작업
  }

  // 앱이 종료된 상태에서 알림을 탭했을 때 핸들러
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('알림을 탭하여 앱이 열렸습니다: ${message.notification?.title}');
    
    // TODO: 특정 화면으로 이동하거나 데이터 처리
    // 예: Navigator.pushNamed(context, '/detail', arguments: message.data);
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