import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couphago_frontend/providers/hotdeal_provider.dart';
import 'package:couphago_frontend/providers/category_provider.dart';
import 'package:couphago_frontend/screens/home_screen.dart';

void main() {
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