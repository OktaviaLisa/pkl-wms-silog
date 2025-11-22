import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'input_inbound.dart';  // sesuaikan nama file halaman input

class InboundPage extends StatefulWidget {
  const InboundPage({super.key});

  @override
  State<InboundPage> createState() => _InboundPageState();
}

class _InboundPageState extends State<InboundPage> {
  final ApiService api = ApiService();
  late Future<List<dynamic>> futureInbound;

  @override
  void initState() {
    super.initState();
    futureInbound = api.getInbound();
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

      // ================== BODY ==================
      body: FutureBuilder<List<dynamic>>(
        future: futureInbound,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Tidak ada data inbound"),
            );
          }

          final inboundList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: inboundList.length,
            itemBuilder: (context, index) {
              final item = inboundList[index];

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
                          const Icon(Icons.inventory_2, color: Color(0xFF960B07)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Nama Produk: ${item["produk"]["nama_produk"]}",
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
                      Text("Gudang Asal: ${item["gudang_asal"]["nama_gudang"]}"),
                      Text("Gudang Tujuan: ${item["gudang_tujuan"]["nama_gudang"]}"),
                      Text("Tanggal Masuk: ${item["tanggal_masuk"]}"),
                      Text("Deskripsi: ${item["deskripsi"]}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // ================== FLOATING BUTTON ==================
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF960B07),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputInboundPage()),
          );
        },
      ),
    );
  }
}
