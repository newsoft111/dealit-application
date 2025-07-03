import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dealit_app/providers/hotdeal_provider.dart';
import 'package:dealit_app/providers/category_provider.dart';
import 'package:dealit_app/providers/sse_provider.dart';
import 'package:dealit_app/screens/home_screen.dart';
import 'package:dealit_app/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dealit_app/screens/hotdeal_detail_screen.dart';

// 백그라운드 메시지 핸들러 (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 메시지 수신: ${message.notification?.title}');
  print('메시지 데이터: ${message.data}');
  
  // Firebase 초기화 (백그라운드에서 필요)
  await Firebase.initializeApp();
  
  // TODO: 백그라운드에서 처리할 작업
  // 백그라운드에서는 네비게이션이 불가능하므로, 
  // 앱이 열릴 때 메시지 데이터를 확인하여 처리
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FCM 서비스 초기화 (권한 요청 포함)
  await FCMService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  RemoteMessage? _initialMessage;

  @override
  void initState() {
    super.initState();
    
    // FCM 서비스에 네비게이터 키 설정
    FCMService().setNavigatorKey(navigatorKey);
    
    // 앱이 종료된 상태에서 알림을 탭하여 열렸을 때 처리
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    // 앱이 종료된 상태에서 알림을 탭하여 열렸는지 확인
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    
    if (initialMessage != null) {
      print('앱이 알림을 통해 열렸습니다: ${initialMessage.data}');
      setState(() {
        _initialMessage = initialMessage;
      });
      
      // 앱이 완전히 로드된 후 네비게이션 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialMessage(initialMessage);
      });
    }
  }

  void _handleInitialMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      if (message.data['type'] == 'hotdeal' && message.data['hotdeal_id'] != null) {
        final hotdealId = message.data['hotdeal_id'];
        final int? id = int.tryParse(hotdealId);
        
        if (id != null && navigatorKey.currentState != null) {
          print('초기 메시지로 핫딜 상세 페이지로 이동: $id');
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => HotdealDetailScreen(hotdealId: id),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => SSEProvider()),
        ChangeNotifierProxyProvider<SSEProvider, HotdealProvider>(
          create: (context) => HotdealProvider(),
          update: (context, sseProvider, hotdealProvider) {
            if (hotdealProvider == null) {
              hotdealProvider = HotdealProvider();
            }
            // SSE Provider와 HotdealProvider 연결
            sseProvider.setHotdealCallback(hotdealProvider.addNewHotdealFromSSE);
            return hotdealProvider;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
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