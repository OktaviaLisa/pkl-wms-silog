import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screen/dashboard.dart';
import 'screen/login.dart';
import 'screen/admin.dart';
import 'screen/register.dart';
import 'screen/inventory.dart';
import 'screen/inbound_stock.dart';
import 'screen/outbound.dart';
import 'screen/add_outbound.dart';
import 'screen/quality_control.dart';
import 'screen/detail_inventory.dart';
import 'screen/return_page.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),

      home: const LoginPage(),
      // 🔹 Rute untuk navigasi ke halaman login
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/dashboard_user': (context) => const DashboardScreen(),
        '/inventory': (context) => const InventoryPage(),
        '/inbound_stock': (context) => const InboundPage(),
        '/outbound_stock': (context) => OutboundPage(),
        '/addOutbound': (context) => AddOutboundPage(),
        '/quality-control': (context) => const QualityControlPage(),
        '/retur': (context) => const ReturnPage(),
      },
    );
  }
}
