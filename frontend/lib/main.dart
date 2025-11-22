import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screen/dashboard.dart'; 
import 'screen/login.dart';    
import 'screen/register.dart';
import 'screen/inventory.dart';
import 'screen/inbound_stock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WMS Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 🔹 Sekarang yang pertama tampil adalah Dashboard
      home: const DashboardScreen(),
      // 🔹 Rute untuk navigasi ke halaman login
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/inventory' : (context) => const InventoryPage(),
        '/inbound_stock' : (context) => const InboundPage(),
      },
    );
  }
}