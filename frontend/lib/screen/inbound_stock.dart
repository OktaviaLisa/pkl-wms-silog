import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'input_inbound.dart';
import 'detail_inbound.dart';

class InboundPage extends StatefulWidget {
  const InboundPage({super.key});

  @override
  State<InboundPage> createState() => _InboundPageState();
}

class _InboundPageState extends State<InboundPage> {
  final ApiService api = ApiService();
  late Future<List<dynamic>> futureInbound;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getInt('user_id');

      if (!mounted) return;

      if (currentUserId != null) {
        setState(() {
          futureInbound = api.getInbound(userId: currentUserId);
        });
      } else {
        setState(() {
          futureInbound = Future.value([]);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          futureInbound = Future.value([]);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Inbound Stock",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF960B07),
      ),

      body: FutureBuilder<List<dynamic>>(
        future: futureInbound,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Terjadi kesalahan, coba lagi"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada data inbound"));
          }

          final inboundList = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: inboundList.length,
                itemBuilder: (context, index) {
                  final item = inboundList[index];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailInboundPage(data: item),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.inventory_2,
                                      color: Color(0xFF960B07),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Kode Produk: ${item["kode_produk"]}\n"
                                        "Nama Produk: ${item["nama_produk"]}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                _infoText("Gudang Asal", item["nama_gudang_asal"]),
                                _infoText("Gudang Tujuan", item["nama_gudang_tujuan"]),
                                _infoText("Tanggal Masuk", item["tanggal_masuk"]),
                                _infoText("Deskripsi", item["deskripsi"]),
                              ],
                            ),
                          ),

                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item["status"]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(item["status"]),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF960B07),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputInboundPage()),
          );

          if (mounted && result == true) {
            _loadUserData();
          }
        },
      ),
    );
  }

  // Widget info lebih rapih & responsif
  Widget _infoText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: "$title: ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'qc':
        return Colors.orange;
      case 'inventory':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return "Pending";
      case 'qc':
        return "QC";
      case 'inventory':
        return "Inventory";
      default:
        return "Unknown";
    }
  }
}
