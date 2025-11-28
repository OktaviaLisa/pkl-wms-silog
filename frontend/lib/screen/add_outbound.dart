import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AddOutboundPage extends StatefulWidget {
  @override
  _AddOutboundPageState createState() => _AddOutboundPageState();
}

class _AddOutboundPageState extends State<AddOutboundPage> {
  int? selectedProduk;
  String? selectedGudangAsal;
  final TextEditingController gudangAsalController = TextEditingController();
  final TextEditingController gudangTujuanController = TextEditingController();
  final TextEditingController tglKeluar = TextEditingController();
  final TextEditingController deskripsi = TextEditingController();
  final TextEditingController namaProdukController = TextEditingController();
  final TextEditingController volumeSatuanController = TextEditingController();

  List produkList = [];
  List gudangList = [];
  int? currentUserId;
  String? userGudangName;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id');

    if (currentUserId != null) {
      await _loadUserGudang();
    }
    await loadDropdownData();
  }

  Future<void> _loadUserGudang() async {
    try {
      final api = ApiService();
      final userGudang = await api.getUserGudang(userId: currentUserId!);
      setState(() {
        userGudangName = userGudang['nama_gudang'];
        gudangAsalController.text = userGudangName ?? '';
        selectedGudangAsal = userGudangName;
      });
    } catch (e) {
      print('Error loading user gudang: $e');
    }
  }

  @override
  void dispose() {
    gudangAsalController.dispose();
    gudangTujuanController.dispose();
    tglKeluar.dispose();
    deskripsi.dispose();
    namaProdukController.dispose();
    volumeSatuanController.dispose();
    super.dispose();
  }

  Future<void> loadDropdownData() async {
    try {
      final api = ApiService();
      final produk = await api.getProduk();
      final gudang = await api.getGudang();

      setState(() {
        produkList = produk;
        gudangList = gudang;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      tglKeluar.text = picked.toIso8601String().split('T')[0]; // YYYY-MM-DD
    }
  }

  Future<void> saveOutbound() async {
    // Validasi sederhana
    if (selectedProduk == null ||
        gudangAsalController.text.trim().isEmpty ||
        gudangTujuanController.text.trim().isEmpty ||
        tglKeluar.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Harap isi semua field")));
      return;
    }

    final data = {
      "idProduk": selectedProduk,
      "gudang_asal": gudangAsalController.text.trim(),
      "gudang_tujuan": gudangTujuanController.text.trim(),
      "tgl_keluar": tglKeluar.text.trim(),
      "deskripsi": deskripsi.text.trim(),
    };

    try {
      bool success = await ApiService().createOutbound(data);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Outbound berhasil ditambahkan")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menambah outbound")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saat menyimpan: $e")));
    }
  }

  // helper: cek apakah produkList masih kosong atau data tidak sesuai
  bool _produkHasId(int? id) {
    if (id == null) return false;
    return produkList.any((p) {
      if (p is Map) {
        if (p.containsKey('id_produk')) {
          return p['id_produk'] == id;
        }
      }
      return false;
    });
  }

  void _updateProdukInfo(int? produkId) {
    if (produkId == null) {
      namaProdukController.clear();
      volumeSatuanController.clear();
      return;
    }

    final produk = produkList.firstWhere(
      (p) => p['id_produk'] == produkId,
      orElse: () => null,
    );

    if (produk != null) {
      namaProdukController.text = produk['nama_produk'] ?? '';
      // Gabungkan volume dan satuan dalam satu field
      int volume = produk['volume'] ?? 1;
      String satuan = _getSatuanName(produk['id_satuan']);
      volumeSatuanController.text = '$volume $satuan';
    }
  }

  String _getSatuanName(int? idSatuan) {
    // Mapping sederhana untuk satuan berdasarkan id
    switch (idSatuan) {
      case 1:
        return 'Pcs';
      case 2:
        return 'Kg';
      case 3:
        return 'Liter';
      case 4:
        return 'Box';
      default:
        return 'Unit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tambah Outbound",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF960B07),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  // Input Kode Produk
                  const Text(
                    'Kode Produk *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _produkHasId(selectedProduk) ? selectedProduk : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih kode produk',
                    ),
                    items: produkList.map<DropdownMenuItem<int>>((item) {
                      final id = item['id_produk'];
                      final kode = item['kode_produk'];
                      return DropdownMenuItem<int>(
                        value: id is int ? id : int.tryParse(id.toString()),
                        child: Text(kode.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProduk = value;
                        _updateProdukInfo(value);
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Input Nama Produk (Auto-fill)
                  const Text(
                    'Nama Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: namaProdukController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Nama produk otomatis terisi',
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Volume + Satuan (Auto-fill)
                  const Text(
                    'Volume & Satuan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: volumeSatuanController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Volume dan satuan otomatis terisi',
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Gudang Asal
                  const Text(
                    'Gudang Asal (Otomatis) *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: gudangAsalController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Gudang asal otomatis terisi',
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Gudang Tujuan
                  const Text(
                    'Gudang Tujuan *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gudangTujuanController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Masukkan nama gudang tujuan',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (value) {
                          setState(() {
                            gudangTujuanController.text = value;
                          });
                        },
                        itemBuilder: (ctx) {
                          return gudangList.map((item) {
                            final name =
                                item['nama_gudang'] ??
                                item['namaGudang'] ??
                                item['nama'];
                            return PopupMenuItem<String>(
                              value: name.toString(),
                              child: Text(name.toString()),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  const Text(
                    'Tanggal Keluar *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tglKeluar,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Pilih tanggal keluar',
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                        ),
                        onPressed: pickDate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: deskripsi,
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
                    onPressed: loading ? null : saveOutbound,
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Simpan Outbound',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
