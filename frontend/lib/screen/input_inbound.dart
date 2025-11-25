import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InputInboundPage extends StatefulWidget {
  const InputInboundPage({super.key});

  @override
  State<InputInboundPage> createState() => _InputInboundPageState();
}

class _InputInboundPageState extends State<InputInboundPage> {
  final ApiService api = ApiService();
  final TextEditingController namaProdukController = TextEditingController();
  final TextEditingController gudangAsalController = TextEditingController();
  final TextEditingController alamatGudangAsalController = TextEditingController();
  final TextEditingController gudangTujuanController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  
  DateTime? tanggalMasuk;
  bool isLoading = false;
  List<dynamic> gudangAsalList = [];
  String? selectedGudangAsal;
  String? selectedAlamatGudangAsal;
  int? userRoleGudang;
  bool isManualGudang = false;
  bool isManualAlamat = false;



  Future<void> _submitInbound() async {
    if (namaProdukController.text.isEmpty || gudangAsalController.text.isEmpty || 
        alamatGudangAsalController.text.isEmpty || gudangTujuanController.text.isEmpty || tanggalMasuk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Jika input manual, simpan gudang baru ke database
      if (isManualGudang) {
        await api.createGudang(
          namaGudang: gudangAsalController.text.trim(),
          alamatGudang: alamatGudangAsalController.text.trim(),
        );
      }

      final data = {
        "nama_produk": namaProdukController.text.trim(),
        "gudang_asal": gudangAsalController.text.trim(),
        "alamat_gudang_asal": alamatGudangAsalController.text.trim(),
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
  void initState() {
    super.initState();
    _loadUserGudang();
  }

  Future<void> _loadUserGudang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? roleGudang = prefs.getInt("role_gudang");
    userRoleGudang = roleGudang;

    if (roleGudang != null && roleGudang > 0) {
      try {
        final allGudang = await api.getGudang();
        
        final gudangTujuan = allGudang.firstWhere(
          (g) => g['id_gudang'] == roleGudang,
          orElse: () => null,
        );
        
        setState(() {
          // Filter gudang asal (semua kecuali gudang tujuan user)
          gudangAsalList = allGudang.where((g) => g['id_gudang'] != roleGudang).toList();
          
          // Set gudang tujuan
          gudangTujuanController.text = gudangTujuan != null ? gudangTujuan['nama_gudang'] : "Gudang $roleGudang";
        });
      } catch (e) {
        setState(() {
          gudangTujuanController.text = "Gudang $roleGudang";
        });
      }
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

            // Gudang Asal dengan opsi manual
            Row(
              children: [
                const Text('Gudang Asal *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isManualGudang = !isManualGudang;
                      if (isManualGudang) {
                        selectedGudangAsal = null;
                        gudangAsalController.clear();
                      }
                    });
                  },
                  child: Text(isManualGudang ? 'Pilih dari List' : 'Tambah Data'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            isManualGudang
                ? TextField(
                    controller: gudangAsalController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan nama gudang baru',
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedAlamatGudangAsal = null;
                        alamatGudangAsalController.clear();
                        isManualAlamat = true;
                      });
                    },
                  )
                : DropdownButtonFormField<String>(
                    value: selectedGudangAsal,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih gudang asal',
                    ),
                    items: gudangAsalList.map<DropdownMenuItem<String>>((gudang) {
                      return DropdownMenuItem<String>(
                        value: gudang['nama_gudang'],
                        child: Text(gudang['nama_gudang']),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedGudangAsal = value;
                        gudangAsalController.text = value ?? '';
                        selectedAlamatGudangAsal = null;
                        alamatGudangAsalController.text = '';
                        isManualAlamat = false;
                      });
                    },
                  ),
            const SizedBox(height: 20),

            // Alamat Gudang Asal dengan opsi manual
            Row(
              children: [
                const Text('Alamat Gudang Asal *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (!isManualGudang)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isManualAlamat = !isManualAlamat;
                        if (isManualAlamat) {
                          selectedAlamatGudangAsal = null;
                          alamatGudangAsalController.clear();
                        }
                      });
                    },
                    child: Text(isManualAlamat ? 'Pilih dari List' : 'Tambah Data'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            (isManualGudang || isManualAlamat)
                ? TextField(
                    controller: alamatGudangAsalController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan alamat gudang',
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: selectedAlamatGudangAsal,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih alamat gudang asal',
                    ),
                    items: selectedGudangAsal != null 
                      ? gudangAsalList
                          .where((gudang) => gudang['nama_gudang'] == selectedGudangAsal)
                          .map<DropdownMenuItem<String>>((gudang) {
                            return DropdownMenuItem<String>(
                              value: gudang['alamat'],
                              child: Text(gudang['alamat'] ?? 'Alamat tidak tersedia'),
                            );
                          }).toList()
                      : [],
                    onChanged: selectedGudangAsal != null ? (String? value) {
                      setState(() {
                        selectedAlamatGudangAsal = value;
                        alamatGudangAsalController.text = value ?? '';
                      });
                    } : null,
                  ),
            const SizedBox(height: 20),

            // Input Gudang Tujuan (Auto-generated)
            const Text('Gudang Tujuan * (Auto)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: gudangTujuanController,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Gudang tujuan akan terisi otomatis',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                suffixIcon: Icon(Icons.lock_outline, color: Colors.grey),
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
    alamatGudangAsalController.dispose();
    gudangTujuanController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }
}
   