import 'package:flutter/material.dart';

class DetailInboundPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailInboundPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Inbound", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF960B07),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nama Produk: ${data['nama_produk']}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("Kode Produk: ${data['kode_produk'] ?? '-'}"),
                Text("Volume Produk: ${data['volume_produk'] ?? '-'}"),
                Text("Gudang Asal: ${data['nama_gudang_asal']}"),
                Text("Gudang Tujuan: ${data['nama_gudang_tujuan']}"),
                const SizedBox(height: 12),
                Text("Tanggal Masuk: ${data['tanggal_masuk']}"),
                const SizedBox(height: 12),
                Text("Deskripsi: ${data['deskripsi'] ?? '-'}"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
