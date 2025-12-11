import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_outbound.dart';

class DetailInventoryPage extends StatefulWidget {
  final int inventoryId;
  final String namaProduk;

  const DetailInventoryPage({
    super.key,
    required this.inventoryId,
    required this.namaProduk,
  });

  @override
  _DetailInventoryPageState createState() => _DetailInventoryPageState();
}

class _DetailInventoryPageState extends State<DetailInventoryPage> {
  Map<String, dynamic>? inventoryDetail;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadInventoryDetail();
  }

  Future<void> _loadInventoryDetail() async {
    try {
      final detail = await ApiService().getInventoryDetail(
        inventoryId: widget.inventoryId,
      );
      setState(() {
        inventoryDetail = detail;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail ${widget.namaProduk}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF960B07),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : inventoryDetail == null
          ? const Center(child: Text('Data tidak ditemukan'))
          : _buildDetailContent(),
    );
  }

  Widget _buildDetailContent() {
    final detail = inventoryDetail!;
    final riwayat = detail['riwayat'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Info Produk
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Color(0xFF960B07)),
                      const SizedBox(width: 8),
                      const Text(
                        'Informasi Produk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Kode Produk', detail['kode_produk'] ?? '-'),
                  _buildInfoRow('Nama Produk', detail['nama_produk'] ?? '-'),
                  _buildInfoRow('Jenis Satuan', detail['jenis_satuan'] ?? '-'),
                  _buildInfoRow(
                    'Volume Tersedia',
                    '${detail['volume'] ?? 0} ${detail['jenis_satuan'] ?? ''}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card Info Gudang
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warehouse, color: Color(0xFF960B07)),
                      const SizedBox(width: 8),
                      const Text(
                        'Informasi Gudang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Nama Gudang', detail['nama_gudang'] ?? '-'),
                  _buildInfoRow('Alamat', detail['alamat'] ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card Riwayat Transaksi
          if (riwayat.isNotEmpty) ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFF960B07)),
                        const SizedBox(width: 8),
                        const Text(
                          'Riwayat Transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ...riwayat.take(5).map((item) => _buildRiwayatItem(item)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF960B07),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddOutboundPage(),
                      ),
                    );
                    
                    // Refresh detail inventory jika outbound berhasil
                    if (result == true) {
                      _loadInventoryDetail();
                      // Return true ke inventory list untuk refresh juga
                      Navigator.pop(context, true);
                    }
                  },
                  icon: const Icon(Icons.output, color: Colors.white),
                  label: const Text(
                    'Buat Outbound',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatItem(Map<String, dynamic> item) {
    final isInbound = item['tipe'] == 'inbound';
    final color = isInbound ? Colors.green : Colors.red;
    final icon = isInbound ? Icons.arrow_downward : Icons.arrow_upward;
    final prefix = isInbound ? '+' : '-';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['tipe'].toString().toUpperCase()} $prefix${item['volume']}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  '${item['tanggal']} - ${item['deskripsi'] ?? 'Tidak ada deskripsi'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (isInbound)
                  Text(
                    'Dari: ${item['gudang_asal']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )
                else
                  Text(
                    'Ke: ${item['gudang_tujuan']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
