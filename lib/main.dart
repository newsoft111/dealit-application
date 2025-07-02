import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dealit_app/providers/hotdeal_provider.dart';
import 'package:dealit_app/providers/category_provider.dart';
import 'package:dealit_app/screens/home_screen.dart';
import 'package:dealit_app/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 백그라운드 메시지 핸들러 (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 메시지 수신: ${message.notification?.title}');
  // TODO: 백그라운드에서 처리할 작업
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FCM 서비스 초기화 (권한 요청 포함)
  await FCMService().initialize();
  
  // 백그라운드 메시지 핸들러 설정
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => HotdealProvider()),
      ],
      child: MaterialApp(
        title: '딜잇',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}