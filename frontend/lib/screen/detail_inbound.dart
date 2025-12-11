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
                    _statusRow(),
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
                    // ===================== BUTTON INVENTORY (MERAH) =====================
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isInventoryDisabled() ? Colors.grey : const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _isInventoryDisabled() ? null : () async {
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
                                      Navigator.pop(context);

                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                      final gudangId = prefs.getInt('role_gudang');

                                      final payload = {
                                        "idProduk": data['idProduk'] ?? data['id_produk'],
                                        "idGudang": gudangId,
                                        "volume": data['volume'] ?? 1,
                                        "satuan": data['satuan'],
                                      };

                                      final api = ApiService();
                                      bool addSuccess = await api.addInventory(payload);

                                      if (addSuccess) {
                                        bool updateSuccess =
                                            await api.updateOrderStatus(data['idOrders'], 'inventory');

                                        if (updateSuccess) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text("Berhasil dipindahkan ke inventory")),
                                          );
                                          Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/inventory',
                                          (route) => false,
                                        );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text("Tambah inventory berhasil tapi gagal update status")),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Gagal memindahkan data")),
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

                      // ===================== BUTTON QC (ORANGE + KONFIRMASI) =====================
                     Expanded(
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor:
          _isQCDisabled() ? Colors.grey : const Color(0xFFFB8C00),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30)),
    ),
    onPressed: _isQCDisabled()
        ? null
        : () {
            TextEditingController catatanController =
                TextEditingController();
            DateTime? selectedDate;

            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text("Input Quality Control"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: catatanController,
                            decoration: const InputDecoration(
                              labelText: "Catatan QC",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedDate == null
                                      ? "Pilih Tanggal QC"
                                      : selectedDate!
                                          .toIso8601String()
                                          .substring(0, 10),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (catatanController.text.isEmpty ||
                                selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Isi catatan & tanggal QC dulu"),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context);

                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();

                            final payload = {
                              "idOrders": data['idOrders'],
                              "catatan": catatanController.text,
                              "tgl_qc": selectedDate!
                                  .toIso8601String()
                                  .substring(0, 10), // <-- FORMAT FIX
                              "status_qc": "pending",
                            };

                            final api = ApiService();
                            bool qcSuccess =
                                await api.addQualityControl(payload);

                            if (qcSuccess) {
                              await api.updateOrderStatus(
                                  data['idOrders'], 'qc');

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Data berhasil masuk QC")),
                              );

                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/quality-control',
                                (route) => false,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Gagal menyimpan QC")),
                              );
                            }
                          },
                          child: const Text("Simpan"),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
    child: const Text(
      "Quality Control",
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
  ),
),
                    ],
                  )
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

  // Fungsi untuk cek apakah button Inventory harus disabled
  bool _isInventoryDisabled() {
    String status = data['status'] ?? 'pending';
    return status == 'qc' || status == 'processed';
  }

  // Fungsi untuk cek apakah button QC harus disabled  
  bool _isQCDisabled() {
    String status = data['status'] ?? 'pending';
    return status == 'processed' || status == 'qc';
  }

  // Widget untuk menampilkan status
  Widget _statusRow() {
    String status = data['status'] ?? 'pending';
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'qc':
        statusColor = Colors.orange;
        statusText = 'Quality Control';
        break;
      case 'processed':
        statusColor = Colors.green;
        statusText = 'Sudah di Inventory';
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Menunggu Proses';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
              width: 130,
              child: Text(
                "Status:",
                style: TextStyle(fontWeight: FontWeight.w600),
              )),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          )
        ],
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
