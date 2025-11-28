import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class Inventory {
  final String namaBarang;
  final String kodeProduk;
  final int volume;
  final String satuan;

  Inventory({
    required this.namaBarang,
    required this.kodeProduk,
    required this.volume,
    required this.satuan,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      namaBarang: json['nama_produk'] ?? 'Tidak diketahui',
      kodeProduk: json['kode_produk'] ?? 'Tidak diketahui',
      volume: json['volume'] ?? 0,
      satuan: json['jenis_satuan'] ?? 'Unit',
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final ApiService api = ApiService();
  int? currentUserId;
  int? currentGudangId; // untuk menampung id_gudang user
  late Future<List<Inventory>> futureInventory;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id');
    currentGudangId = prefs.getInt('role_gudang'); // ambil role_gudang user

    if (currentUserId != null && currentGudangId != null) {
      print('🔍 Loading inventory untuk user ID: $currentUserId, gudang ID: $currentGudangId');
      
      setState(() {
        futureInventory = _loadInventoryData();
      });
    } else {
      print('⚠️ User belum login atau tidak ada gudang, tampilkan pesan kosong');
      setState(() {
        futureInventory = Future.value([]);
      });
    }
  }

  Future<List<Inventory>> _loadInventoryData() async {
    try {
      final data = await api.getInventory(gudangId: currentGudangId!);
      return data.map((item) => Inventory.fromJson(item)).toList();
    } catch (e) {
      print('Error loading inventory: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Inventory",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF960B07),
        elevation: 0,
      ),
      body: FutureBuilder<List<Inventory>>(
        future: futureInventory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada inventory di gudang ini'));
          } else {
            final inventoryList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: inventoryList.length,
              itemBuilder: (context, index) {
                final item = inventoryList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.inventory, color: Color(0xFF960B07)),
                    title: Text(item.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kode: ${item.kodeProduk}'),
                        Text('Volume: ${item.volume}'),
                        Text('Satuan: ${item.satuan}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
