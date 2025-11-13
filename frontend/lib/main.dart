import 'package:flutter/material.dart';
import 'screen/login.dart'; // ganti import ke login.dart
import 'services/api_service.dart';

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
      theme: ThemeData(primarySwatch: Colors.red),

      home: const LoginPage(), // ubah dari DashboardScreen() ke LoginPage()
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _serverMessage = "Belum ada respon dari server";

  @override
  void initState() {
    super.initState();
    _cekKoneksi();
  }

  Future<void> _cekKoneksi() async {
    try {
      String msg = await ApiService.pingServer();
      setState(() {
        _serverMessage = "Server bilang: $msg";
      });
    } catch (e) {
      setState(() {
        _serverMessage = "Gagal connect ke server!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(child: Text(_serverMessage)),
    );
  }
}
