import 'package:ecommerce_flutter/screens/login_screen.dart';
import 'package:ecommerce_flutter/screens/product_detail.dart';
import 'package:ecommerce_flutter/screens/profile_screen.dart';
import 'package:ecommerce_flutter/screens/cart_screen.dart';
import 'package:ecommerce_flutter/screens/ai_screen.dart'; // Import màn hình AI
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/order_create_screen.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => AppProvider(), child: MyApp()));
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
        '/cart': (context) => CartScreen(),
        '/order':
            (context) => OrderCreateScreen(
              selectedItems: [],
              totalPrice: 0,
            ), // placeholder
        '/ai': (context) => AIScreen(), // Đường dẫn đến màn hình AI
      },
    );
  }
}
