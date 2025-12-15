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
  final TextEditingController satuanController = TextEditingController();
  
  DateTime? tanggalMasuk;
  bool isLoading = false;
  List<dynamic> gudangAsalList = [];
  List<dynamic> inventoryGudangUser = [];
  String? selectedGudangAsal;
  String? selectedAlamatGudangAsal;
  int? userRoleGudang;
  bool isManualGudang = false;
  bool isManualAlamat = false;
  bool isManualProduk = false;

  List<dynamic> produkList = [];
  int? selectedProdukId;

  @override
  void initState() {
    super.initState();
    _loadUserGudang();
    _loadProduk();
  }

  Future<void> _loadProduk() async {
  try {
    final allProducts = await api.getProduk();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? roleGudang = prefs.getInt("role_gudang");

    if (roleGudang != null) {
      // Ambil inventory dan quality control
      final inventory = await api.getInventory(gudangId: roleGudang);
      final qualityControl = await api.getQualityControl(gudangId: roleGudang);

      // Ambil KODE PRODUK yang sudah ada di inventory
      final inventoryProductCodes = inventory.map((inv) => inv['kode_produk']).toSet();
      
      // Ambil KODE PRODUK yang sudah ada di quality control
      final qcProductCodes = qualityControl.map((qc) => qc['kode_produk']).toSet();
      
      // Gabungkan kedua set
      final excludedProductCodes = {...inventoryProductCodes, ...qcProductCodes};

      print("Produk di inventory: $inventoryProductCodes");
      print("Produk di QC: $qcProductCodes");
      print("Total produk yang dikecualikan: $excludedProductCodes");

      // Filter produk yang BELUM ADA di inventory dan QC
      setState(() {
        produkList = allProducts
            .where((p) => !excludedProductCodes.contains(p['kode_produk']))
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
        satuanController.text.isEmpty ||
        gudangAsalController.text.isEmpty ||
        alamatGudangAsalController.text.isEmpty ||
        gudangTujuanController.text.isEmpty ||
        tanggalMasuk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Simpan'),
        content: Text(
          'Apakah Anda yakin ingin menambahkan inbound ini?\n\n'
          'Produk: ${namaProdukController.text}\n'
          'Volume: ${volumeProdukController.text} ${satuanController.text}\n'
          'Dari: ${gudangAsalController.text}\n'
          'Ke: ${gudangTujuanController.text}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF960B07),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
  String finalKodeProduk = kodeProdukController.text.trim();
  String finalNamaProduk = namaProdukController.text.trim();
  
  
  // Jika input manual → buat produk baru dan dapatkan data yang benar
  if (isManualProduk) {
    print("Membuat produk baru dengan kode: $finalKodeProduk");
    
    final newProduk = await api.createProduk(
      kodeProduk: finalKodeProduk,
      namaProduk: finalNamaProduk,
    );
    
    print("Response dari createProduk: $newProduk");
    
    // Pastikan menggunakan kode produk yang benar dari input user
    if (newProduk != null && newProduk is Map<String, dynamic>) {
      // Validasi bahwa kode produk tersimpan sesuai input
      final savedKode = newProduk['kode_produk'];
      if (savedKode != finalKodeProduk) {
        print("WARNING: Kode produk berubah dari $finalKodeProduk menjadi $savedKode");
      }
      finalKodeProduk = savedKode ?? finalKodeProduk;
      finalNamaProduk = newProduk['nama_produk'] ?? finalNamaProduk;
    }
    
    print("Kode produk yang akan digunakan: $finalKodeProduk");
    
    // Refresh list produk setelah menambah produk baru
    await _loadProduk();
  }

  // Jika input manual untuk gudang → tambah gudang baru
  if (isManualGudang) {
    final newGudang = await api.createGudang(
      namaGudang: gudangAsalController.text.trim(),
      alamat: alamatGudangAsalController.text.trim(),
    );
    
    if (newGudang != null) {
      print("Gudang baru berhasil dibuat: $newGudang");
    }
  }

  final data = {
    "nama_produk": finalNamaProduk,
    "kode_produk": finalKodeProduk,
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

      Navigator.pop(context, true); // kirim signal refresh ke halaman sebelumnya
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
          (g) => g['idGudang'] == roleGudang,
          orElse: () => null,
        );

        setState(() {
          gudangAsalList =
              allGudang.where((g) => g['idGudang'] != roleGudang).toList();
          
          // Debug: print struktur data gudang
          if (gudangAsalList.isNotEmpty) {
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
      if (selectedGudangAsal != null &&
          !gudangAsalList.any((g) => g['nama_gudang'] == selectedGudangAsal)) {
        selectedGudangAsal = null;
      }

      if (selectedAlamatGudangAsal != null && selectedGudangAsal != null) {
        final gudang = gudangAsalList.firstWhere(
          (g) => g['nama_gudang'] == selectedGudangAsal,
          orElse: () => null,
        );

        if (gudang == null || gudang['alamat'] != selectedAlamatGudangAsal) {
          selectedAlamatGudangAsal = null;
        }
      }
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
                satuanController.clear();
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
                // Auto-fill satuan berdasarkan produk yang dipilih
                satuanController.text = selected['jenis_satuan'] ?? 'Belum ada satuan';
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

            // SATUAN AUTO-FILL
            const Text('Satuan Produk *'),
            const SizedBox(height: 8),
            TextField(
              controller: satuanController,
              readOnly: !isManualProduk,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: !isManualProduk,
                fillColor: !isManualProduk ? Colors.grey[200] : Colors.white,
                hintText: isManualProduk ? 'Masukkan satuan (kg, pcs, liter, dll)' : 'Otomatis dari produk yang dipilih',
                suffixIcon: const Icon(Icons.scale, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 25),

            // =============================
            //        Gudang Asal
            // =============================
            const Text('Gudang Asal *'),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
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

                  // Auto fill alamat berdasarkan gudang yang dipilih
                  final selected = gudangAsalList.firstWhere(
                    (g) => g['nama_gudang'] == value,
                  );

                  alamatGudangAsalController.text = selected['alamat'] ?? 'Alamat belum terdaftar';
                });
              },
            ),

            const SizedBox(height: 20),

            // =============================
            //    Alamat Gudang Asal
            // =============================
            const Text('Alamat Gudang Asal *'),
            const SizedBox(height: 8),

            TextField(
              controller: alamatGudangAsalController,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFEFEFEF), // agar terlihat disabled
                hintText: 'Alamat otomatis terisi berdasarkan gudang',
              ),
            ),

            const SizedBox(height: 25),

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _submitInbound,
                    child: const Text(
                      'Simpan Outbound',
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
    satuanController.dispose();
    super.dispose();
  }
}
