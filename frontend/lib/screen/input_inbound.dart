import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InputInboundPage extends StatefulWidget {
  const InputInboundPage({super.key});

  @override
  State<InputInboundPage> createState() => _InputInboundPageState();
}

class _InputInboundPageState extends State<InputInboundPage> {
  final ApiService api = ApiService();
  final TextEditingController namaProdukController = TextEditingController();
  final TextEditingController gudangAsalController = TextEditingController();
  final TextEditingController gudangTujuanController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  
  DateTime? tanggalMasuk;
  bool isLoading = false;

  Future<void> _submitInbound() async {
    if (namaProdukController.text.isEmpty || gudangAsalController.text.isEmpty || 
        gudangTujuanController.text.isEmpty || tanggalMasuk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = {
        "nama_produk": namaProdukController.text.trim(),
        "gudang_asal": gudangAsalController.text.trim(),
        "gudang_tujuan": gudangTujuanController.text.trim(),
        "tanggal_masuk": "${tanggalMasuk!.year}-${tanggalMasuk!.month.toString().padLeft(2, '0')}-${tanggalMasuk!.day.toString().padLeft(2, '0')}",
        "deskripsi": deskripsiController.text.trim(),
      };

      final success = await api.createInbound(data);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inbound berhasil disimpan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Input Inbound Stock",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF960B07),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Input Nama Produk
            const Text('Nama Produk *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: namaProdukController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan nama produk',
              ),
            ),
            const SizedBox(height: 20),

            // Input Gudang Asal
            const Text('Gudang Asal *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: gudangAsalController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan nama gudang asal',
              ),
            ),
            const SizedBox(height: 20),

            // Input Gudang Tujuan
            const Text('Gudang Tujuan *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: gudangTujuanController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan nama gudang tujuan',
              ),
            ),
            const SizedBox(height: 20),

            // Date Picker
            const Text('Tanggal Masuk *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => tanggalMasuk = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tanggalMasuk == null
                          ? 'Pilih Tanggal Masuk'
                          : '${tanggalMasuk!.day}/${tanggalMasuk!.month}/${tanggalMasuk!.year}',
                      style: TextStyle(
                        color: tanggalMasuk == null ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Deskripsi
            const Text('Deskripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: deskripsiController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan deskripsi (opsional)',
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF960B07),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading ? null : _submitInbound,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Inbound',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    namaProdukController.dispose();
    gudangAsalController.dispose();
    gudangTujuanController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }
}