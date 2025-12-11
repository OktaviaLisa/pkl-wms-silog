import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard.dart';

class ReturnItem {
  final int idReturn;
  final String namaProduk;
  final String kodeProduk;
  final int volume;
  final String alasan;
  final String tglReturn;

  ReturnItem({
    required this.idReturn,
    required this.namaProduk,
    required this.kodeProduk,
    required this.volume,
    required this.alasan,
    required this.tglReturn,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      idReturn: json['id_return'] ?? 0,
      namaProduk: json['nama_produk'] ?? 'Tidak diketahui',
      kodeProduk: json['kode_produk'] ?? '-',
      volume: json['volume'] ?? 0,
      alasan: json['alasan'] ?? '-',
      tglReturn: json['tgl_return'] ?? '-',
    );
  }
}

class ReturnPage extends StatefulWidget {
  const ReturnPage({super.key});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final ApiService api = ApiService();
  int? gudangId;
  late Future<List<ReturnItem>> futureReturns = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadGudang();
  }

  void _loadGudang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    gudangId = prefs.getInt('role_gudang');

    if (gudangId != null) {
      futureReturns = _loadReturns();
    } else {
      futureReturns = Future.value([]);
    }

    if (mounted) setState(() {});
  }

  Future<List<ReturnItem>> _loadReturns() async {
    try {
      final data = await api.getReturn(gudangId: gudangId!);
      return data.map((item) => ReturnItem.fromJson(item)).toList();
    } catch (e) {
      print("Error Return: $e");
      return [];
    }
  }

  String formatTanggal(String tanggal) {
    if (tanggal.isEmpty || tanggal.length < 10) return tanggal;
    return tanggal.substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Return Barang",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          ),
        ),
        backgroundColor: const Color(0xFF960B07),
      ),
      body: FutureBuilder<List<ReturnItem>>(
        future: futureReturns,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data return"));
          }

          final returnList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: returnList.length,
            itemBuilder: (context, index) {
              final item = returnList[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_return,
                            color: Colors.red[700],
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.namaProduk,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Kode: ${item.kodeProduk}"),
                      Text("Volume: ${item.volume}"),
                      Text("Alasan: ${item.alasan}"),
                      Text("Tanggal Return: ${formatTanggal(item.tglReturn)}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}