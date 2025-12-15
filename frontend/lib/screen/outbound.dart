import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class OutboundPage extends StatefulWidget {
  @override
  _OutboundPageState createState() => _OutboundPageState();
}

class _OutboundPageState extends State<OutboundPage> {
  List OutboundList = [];
  int? currentUserId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id');
    if (currentUserId != null) {
      loadOutbound();
    } else {
      print('⚠ User belum login');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadOutbound() async {
    try {
      final data = await ApiService().getOutbound(userId: currentUserId);
      setState(() {
        OutboundList = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Outbound Stock",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF960B07),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF960B07),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/addOutbound",
          ).then((_) => loadOutbound());
        },
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : OutboundList.isEmpty
          ? Center(child: Text("Tidak ada data outbound"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: OutboundList.length,
              itemBuilder: (context, index) {
                final item = OutboundList[index];

                return Card(
                  elevation: 3,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NAMA PRODUK
                        Row(
                          children: [
                            const Icon(Icons.logout, color: Color(0xFF960B07)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Nama Produk: ${item['nama_produk'] ?? 'ID: ${item['idProduk']}'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // DETAIL
                        Text(
                          "Gudang Asal: ${item['nama_gudang_asal'] ?? item['gudang_asal']}",
                        ),
                        Text(
                          "Gudang Tujuan: ${item['nama_gudang_tujuan'] ?? item['gudang_tujuan']}",
                        ),
                        Text(
                          "Tanggal Keluar: ${item['tanggal_keluar'] ?? item['tgl_keluar']}",
                        ),
                        Text("Deskripsi: ${item['deskripsi']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
