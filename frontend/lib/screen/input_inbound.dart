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
  final TextEditingController kodeProdukController = TextEditingController();
  final TextEditingController namaProdukController = TextEditingController();
  final TextEditingController volumeProdukController = TextEditingController();
  final TextEditingController gudangAsalController = TextEditingController();
  final TextEditingController alamatGudangAsalController = TextEditingController();
  final TextEditingController gudangTujuanController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  
  DateTime? tanggalMasuk;
  bool isLoading = false;
  List<dynamic> gudangAsalList = [];
  List<dynamic> inventoryGudangUser = [];
  String? selectedGudangAsal;
  String? selectedAlamatGudangAsal;
  int? userRoleGudang;
  bool isManualGudang = false;
  bool isManualAlamat = false;
   bool isManualProduk= false;

  // Tambahan untuk SATUAN
  List<dynamic> satuanList = [];
  int? selectedSatuanId;

  List<dynamic> produkList = [];
  int? selectedProdukId;

  @override
  void initState() {
    super.initState();
    _loadUserGudang();
    _loadSatuan();   // ← Tambahan
    _loadProduk();
  }

  // Ambil satuan dari backend
  Future<void> _loadSatuan() async {
    try {
      final data = await api.getSatuan(); // Pastikan API ada
      setState(() {
        satuanList = data;
      });
    } catch (e) {
      print("Gagal load satuan: $e");
    }
  }

  Future<void> _loadProduk() async {
  try {
    final allProducts = await api.getProduk();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? roleGudang = prefs.getInt("role_gudang");

    if (roleGudang != null) {
      // Ambil inventory
      final inventory = await api.getInventory(gudangId: roleGudang);

      // Ambil KODE PRODUK yang sudah ada di inventory
      final existingProductCodes =
          inventory.map((inv) => inv['kode_produk']).toSet();

      print("Produk di inventory: $existingProductCodes");

      // Filter produk yang BELUM ADA di inventory
      setState(() {
        produkList = allProducts
            .where((p) => !existingProductCodes.contains(p['kode_produk']))
            .toList();
      });
    } else {
      setState(() {
        produkList = allProducts;
      });
    }
  } catch (e) {
    print("Gagal load produk: $e");
  }
}


  Future<void> _submitInbound() async {
    if (kodeProdukController.text.isEmpty ||
        namaProdukController.text.isEmpty ||
        volumeProdukController.text.isEmpty ||
        selectedSatuanId == null || // ← Tambahan validasi
        gudangAsalController.text.isEmpty ||
        alamatGudangAsalController.text.isEmpty ||
        gudangTujuanController.text.isEmpty ||
        tanggalMasuk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
  // Jika input manual → buat produk baru
  if (isManualProduk) {
    await api.createProduk(
      kodeProduk: kodeProdukController.text.trim(),
      namaProduk: namaProdukController.text.trim(),
    );
  }

  // Jika input manual untuk gudang → tambah gudang baru
  if (isManualGudang) {
    await api.createGudang(
      namaGudang: gudangAsalController.text.trim(),
      alamat_gudang: alamatGudangAsalController.text.trim(),
    );
  }

  final data = {
    "nama_produk": namaProdukController.text.trim(),
    "kode_produk": kodeProdukController.text.trim(),
    "volume": int.tryParse(volumeProdukController.text.trim()) ?? 0,
    "gudang_asal": gudangAsalController.text.trim(),
    "alamat_gudang_asal": alamatGudangAsalController.text.trim(),
    "gudang_tujuan": gudangTujuanController.text.trim(),
    "tanggal_masuk":
        "${tanggalMasuk!.year}-${tanggalMasuk!.month.toString().padLeft(2, '0')}-${tanggalMasuk!.day.toString().padLeft(2, '0')}",
    "deskripsi": deskripsiController.text.trim(),
  };
      final success = await api.createInbound(data);
      if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inbound berhasil disimpan!')),
      );

      Navigator.pop(context); // kembali ke halaman sebelumnya
      }

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => isLoading = false);
      }

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
          gudangAsalList =
              allGudang.where((g) => g['id_gudang'] != roleGudang).toList();
          
          // Debug: print struktur data gudang
          if (gudangAsalList.isNotEmpty) {
            print('📍 Data gudang asal:');
            print(gudangAsalList.first);
          }

          gudangTujuanController.text =
              gudangTujuan != null ? gudangTujuan['nama_gudang'] : "Gudang $roleGudang";
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
        title: const Text("Input Inbound Stock", style: TextStyle(color: Colors.white)),
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

    // =============================
    //        KODE PRODUK
    // =============================
    Row(
      children: [
        const Text('Kode Produk *'),
        const Spacer(),
        TextButton(
          onPressed: () {
            setState(() {
              isManualProduk = !isManualProduk;
              if (isManualProduk) {
                selectedProdukId = null;
                kodeProdukController.clear();
                namaProdukController.clear();
                selectedSatuanId = null;
              }
            });
          },
          child: Text(isManualProduk ? 'Pilih dari List' : 'Tambah Data'),
        ),
      ],
    ),

    const SizedBox(height: 8),

    isManualProduk
        ? TextField(
            controller: kodeProdukController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Masukkan kode produk baru',
            ),
          )
        : DropdownButtonFormField<int>(
            value: selectedProdukId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Pilih kode produk",
            ),
            items: produkList.map<DropdownMenuItem<int>>((produk) {
              return DropdownMenuItem<int>(
                value: produk['id_produk'],
                child: Text("${produk['kode_produk']}"),
              );
            }).toList(),
            onChanged: (value) {
              final selected = produkList.firstWhere(
                  (p) => p['id_produk'] == value);

              setState(() {
                selectedProdukId = value;
                kodeProdukController.text = selected['kode_produk'];
                namaProdukController.text = selected['nama_produk'];
              });
            },
          ),

    const SizedBox(height: 25),

    // =============================
    //        NAMA PRODUK
    // =============================
    const Text('Nama Produk *'),
    const SizedBox(height: 8),

    TextField(
      controller: namaProdukController,
      readOnly: !isManualProduk,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        filled: !isManualProduk,
        fillColor: !isManualProduk ? Colors.grey[200] : Colors.white,
        hintText:
            isManualProduk ? 'Masukkan nama produk' : 'Otomatis dari pilihan kode',
      ),
    ),


    const SizedBox(height: 25),

            // VOLUME PRODUK
            const Text('Volume Produk *'),
            const SizedBox(height: 8),
            TextField(
              controller: volumeProdukController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan volume produk',
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 DROPDOWN SATUAN BARU DI SINI
            const Text('Satuan Produk *'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: selectedSatuanId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Pilih satuan",
              ),
              items: satuanList.map<DropdownMenuItem<int>>((satuan) {
                return DropdownMenuItem<int>(
                  value: satuan['id_satuan'],
                  child: Text(satuan['jenis_satuan']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSatuanId = value;
                });
              },
            ),

            const SizedBox(height: 25),

            // ------ Lanjut input gudang (TIDAK DIUBAH) ------
            Row(
              children: [
                const Text('Gudang Asal *'),
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
                        
                        // Debug: print gudang yang dipilih
                        if (value != null) {
                          final selectedGudangData = gudangAsalList.firstWhere(
                            (g) => g['nama_gudang'] == value,
                            orElse: () => null,
                          );
                          print('📍 Gudang yang dipilih: $selectedGudangData');
                        }
                      });
                    },
                  ),

            const SizedBox(height: 20),

            // ------ Alamat Gudang Asal ------
            Row(
              children: [
                const Text('Alamat Gudang Asal *'),
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
                            .where((g) => g['nama_gudang'] == selectedGudangAsal)
                            .map<DropdownMenuItem<String>>((g) {
                              String alamat = g['alamat'] ?? 'Alamat belum diisi';
                              return DropdownMenuItem<String>(
                                value: alamat,
                                child: Text(alamat),
                              );
                            }).toList()
                        : [],
                    onChanged: (String? value) {
                      setState(() {
                        selectedAlamatGudangAsal = value;
                        alamatGudangAsalController.text = value ?? '';
                      });
                    },
                  ),

            const SizedBox(height: 20),

            // ------ Gudang Tujuan Auto ------
            const Text('Gudang Tujuan * (Auto)'),
            const SizedBox(height: 8),

            TextField(
              controller: gudangTujuanController,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                suffixIcon: Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),

            // ------ Tanggal Masuk ------
            const Text('Tanggal Masuk *'),
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

            // ------ Deskripsi ------
            const Text('Deskripsi'),
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

            // Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF960B07),
                padding: const EdgeInsets.symmetric(vertical: 16),
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
    kodeProdukController.dispose();
    namaProdukController.dispose();
    gudangAsalController.dispose();
    alamatGudangAsalController.dispose();
    gudangTujuanController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }
}
