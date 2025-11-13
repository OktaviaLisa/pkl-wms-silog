import 'package:flutter/material.dart';
import 'screen/login.dart'; // ganti import ke login.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warehouse Management System',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const LoginPage(), // ubah dari DashboardScreen() ke LoginPage()
    );
  }
}
