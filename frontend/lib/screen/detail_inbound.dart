import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailInboundPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailInboundPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Detail Inbound",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF960B07),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ===== CARD =====
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nama Produk: ${data['nama_produk']}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),

                    _infoRow("Kode Produk", data['kode_produk']),
                    _infoRow("Volume Produk", "${data['volume'] ?? '-'}"),
                    _infoRow("Gudang Asal", data['nama_gudang_asal']),
                    _infoRow("Gudang Tujuan", data['nama_gudang_tujuan']),
                    _infoRow("Tanggal Masuk", data['tanggal_masuk']),
                    const SizedBox(height: 12),

                    const Text(
                      "Deskripsi:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(data['deskripsi'] ?? '-'),

                    const SizedBox(height: 25),

                    // ===== BUTTONS (SEKARANG ADA DI DALAM CARD) =====
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Konfirmasi"),
                                    content: const Text("Data akan disimpan ke inventory. Lanjutkan?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Batal"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context); // tutup dialog
                                          
                                          // Simpan ke inventory
                                          SharedPreferences prefs = await SharedPreferences.getInstance();
                                          final gudangId = prefs.getInt('role_gudang');

                                          print('🔍 Debug data: $data');
                                          print('🔍 Debug gudangId: $gudangId');

                                          final payload = {
                                            "idProduk": data['idProduk'] ?? data['id_produk'],
                                            "idGudang": gudangId,
                                            "volume": data['volume'] ?? 1,
                                            "satuan": data['satuan'],
                                          };

                                          print('🔍 Debug payload: $payload');

                                          final api = ApiService();
                                          
                                          // 1. Tambah ke inventory
                                          bool addSuccess = await api.addInventory(payload);
                                          
                                          if (addSuccess) {
                                            // 2. Update status inbound_stock menjadi 'processed'
                                            bool updateSuccess = await api.updateOrderStatus(data['idOrders'], 'processed');

                                            
                                            if (updateSuccess) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Berhasil dipindahkan ke inventory"))
                                              );

                                              // pindah ke halaman inventory
                                              Navigator.pushNamed(context, '/inventory');  
                                            }
                                            else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Data ditambahkan ke inventory tapi gagal update status"))
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Gagal memindahkan data"))
                                            );
                                          }
                                        },
                                        child: const Text("Lanjutkan"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text(
                              "Inventory",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () async {
                              SharedPreferences prefs = await SharedPreferences.getInstance();

                              final gudangId = prefs.getInt('role_gudang');

                              final payload = {
                                "idProduk": data['id_produk'],
                                "idGudang": gudangId,
                                "volume": data['volume'],
                              };

                              final api = ApiService();
                              bool success = await api.addInventory(payload);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Berhasil menambahkan ke inventory"))
                                );

                                Navigator.pushNamed(context, '/inventory');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Gagal menambahkan data"))
                                );
                              }
                            },
                            child: const Text(
                              "QC",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // Widget kecil untuk merapikan baris informasi
  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(
                "$title:",
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
          Expanded(
            child: Text(value?.toString() ?? "-"),
          )
        ],
      ),
    );
  }
}
