import 'package:ecommerce_flutter/screens/login_screen.dart';
import 'package:ecommerce_flutter/screens/product_detail.dart';
import 'package:ecommerce_flutter/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecommerce App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(), // Trang khởi động là HomeScreen
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/account': (context) => ProfileScreen(),
        '/product_detail': (context) => ProductDetailScreen(),
      },
    );
  }
}
