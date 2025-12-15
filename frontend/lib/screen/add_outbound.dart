import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AddOutboundPage extends StatefulWidget {
  const AddOutboundPage({super.key});

  @override
  _AddOutboundPageState createState() => _AddOutboundPageState();
}

class _AddOutboundPageState extends State<AddOutboundPage> {
  int? selectedProduk; // id produk (id_produk or idProduk)
  String? selectedGudangAsalName;
  int? selectedGudangAsalId;
  final TextEditingController gudangAsalController = TextEditingController();
  final TextEditingController gudangTujuanController = TextEditingController();
  final TextEditingController tglKeluar = TextEditingController();
  final TextEditingController deskripsi = TextEditingController();
  final TextEditingController namaProdukController = TextEditingController();
  final TextEditingController volumeSatuanController = TextEditingController();
  final TextEditingController jenisSatuanController = TextEditingController();
  final TextEditingController volumeKeluarController = TextEditingController();

  List<dynamic> produkFromInventory =
      []; // items from inventory for this gudang
  List<dynamic> gudangList = [];
  int? currentUserId;
  int? userRoleGudangId;
  String? userGudangName;
  bool loading = true;

  // track selected product available qty and satuan
  int availableVolume = 0;
  String availableSatuan = 'Unit';

  @override
  void initState() {
    super.initState();
    _loadUserDataAndDropdowns();
  }

  Future<void> _loadUserDataAndDropdowns() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getInt('user_id');

      // Load gudang info for user (id + name)
      if (currentUserId != null) {
        final api = ApiService();
        final userGudang = await api.getUserGudang(userId: currentUserId!);
        // handler returns data with keys: 'idGudang' and 'nama_gudang'
        if (userGudang != null && userGudang is Map) {
          userRoleGudangId = (userGudang['idGudang'] is int)
              ? userGudang['idGudang']
              : (int.tryParse(userGudang['idGudang'].toString()) ?? null);
          userGudangName =
              userGudang['nama_gudang']?.toString() ??
              userGudang['namaGudang']?.toString();
        }
        // set asal
        if (userGudangName != null) {
          selectedGudangAsalName = userGudangName;
          gudangAsalController.text = userGudangName!;
        }
      }

      // Load gudang list (for tujuan). We'll filter out user's own gudang.
      final api = ApiService();
      final gudangAll = await api.getGudang();
      if (gudangAll is List) {
        // keep as dynamic list
        gudangList = gudangAll.where((g) {
          final id = _extractInt(g, ['idGudang', 'idGudang', 'id']);
          if (userRoleGudangId != null && id != null) {
            return id != userRoleGudangId;
          }
          // if we don't have role id, still show all
          return true;
        }).toList();
      }

      // Load inventory for this user's gudang so product dropdown shows only available products
      if (userRoleGudangId != null) {
        // Use API getInventory (which expects gudang_id param) — returns items with kode_produk, nama_produk, volume, jenis_satuan
        final inventory = await api.getInventory(gudangId: userRoleGudangId!);
        // store inventory items for dropdown
        if (inventory is List) {
          produkFromInventory = inventory;
        }
      } else {
        // if we don't know user's gudang id, fallback: load all produk
        final produk = await ApiService().getProduk();
        if (produk is List) {
          // Convert produk list to similar shape as inventory minimal fields
          produkFromInventory = produk.map((p) {
            return {
              'id_produk': _extractInt(p, ['id_produk', 'idProduk', 'id']),
              'kode_produk': p['kode_produk'] ?? p['kodeProduk'] ?? p['kode'],
              'nama_produk': p['nama_produk'] ?? p['namaProduk'] ?? p['nama'],
              'volume': p['volume'] ?? 0,
              'jenis_satuan': p['jenis_satuan'] ?? null,
              'id_satuan': p['id_satuan'] ?? p['idSatuan'] ?? null,
            };
          }).toList();
        }
      }
    } catch (e) {
      // ignore — we'll show what we have and allow user to continue
      print("Error load dropdowns: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  int? _extractInt(dynamic mapLike, List<String> keys) {
    if (mapLike == null) return null;
    for (final k in keys) {
      try {
        if (mapLike is Map && mapLike.containsKey(k)) {
          final v = mapLike[k];
          if (v is int) return v;
          if (v is String) return int.tryParse(v);
          if (v is double) return v.toInt();
        }
      } catch (_) {}
    }
    return null;
  }

  String? _extractString(dynamic mapLike, List<String> keys) {
    if (mapLike == null) return null;
    for (final k in keys) {
      try {
        if (mapLike is Map && mapLike.containsKey(k)) {
          final v = mapLike[k];
          if (v == null) return null;
          return v.toString();
        }
      } catch (_) {}
    }
    return null;
  }

  void _onProdukChanged(int? produkId) {
    if (produkId == null) {
      setState(() {
        selectedProduk = null;
        namaProdukController.clear();
        volumeSatuanController.clear();
        jenisSatuanController.clear();
        availableVolume = 0;
        availableSatuan = 'Unit';
      });
      return;
    }

    final produk = produkFromInventory.firstWhere(
      (p) =>
          _extractInt(p, ['id_produk', 'idProduk', 'id']) == produkId ||
          _extractInt(p, ['idProduk', 'id_produk', 'id']) == produkId ||
          false,
      orElse: () => null,
    );

    if (produk != null) {
      final nama = _extractString(produk, [
        'nama_produk',
        'namaProduk',
        'nama',
      ]);
      final vol = _extractInt(produk, ['volume', 'qty', 'stock']) ?? 0;
      String sat =
          _extractString(produk, ['jenis_satuan', 'jenisSatuan']) ??
          _getSatuanName(_extractInt(produk, ['id_satuan', 'idSatuan']));

      setState(() {
        selectedProduk = produkId;
        namaProdukController.text = nama ?? '';
        availableVolume = vol;
        availableSatuan = sat;
        volumeSatuanController.text = '$availableVolume $availableSatuan';
        jenisSatuanController.text = sat;
        // clear volume keluar previous value
        volumeKeluarController.text = '';
      });
    } else {
      // fallback - clear
      setState(() {
        selectedProduk = produkId;
        namaProdukController.clear();
        volumeSatuanController.clear();
        jenisSatuanController.clear();
        availableVolume = 0;
        availableSatuan = 'Unit';
      });
    }
  }

  String _getSatuanName(int? idSatuan) {
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

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        tglKeluar.text = picked.toIso8601String().split('T')[0]; // YYYY-MM-DD
      });
    }
  }

  Future<void> saveOutbound() async {
    // Validations
    if (selectedProduk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kode produk terlebih dahulu')),
      );
      return;
    }
    if (gudangAsalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gudang asal tidak ditemukan')),
      );
      return;
    }
    if (gudangTujuanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih gudang tujuan')));
      return;
    }
    if (tglKeluar.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih tanggal keluar')));
      return;
    }
    if (volumeKeluarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan volume keluar')));
      return;
    }

    final int? volKeluar = int.tryParse(volumeKeluarController.text.trim());
    if (volKeluar == null || volKeluar <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Volume keluar harus angka > 0')),
      );
      return;
    }
    if (volKeluar > availableVolume) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Volume keluar ($volKeluar) melebihi stok tersedia ($availableVolume)',
          ),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Simpan'),
        content: Text(
          'Apakah Anda yakin ingin menambahkan outbound ini?\n\n'
          'Produk: ${namaProdukController.text}\n'
          'Volume: $volKeluar $availableSatuan\n'
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

    // Build request payload; backend expects idProduk (int) and volume (int)
    final data = {
      "idProduk": selectedProduk,
      "gudang_asal": gudangAsalController.text.trim(),
      "gudang_tujuan": gudangTujuanController.text.trim(),
      "tgl_keluar": tglKeluar.text.trim(),
      "deskripsi": deskripsi.text.trim(),
      "volume": volKeluar,
    };

    setState(() => loading = true);
    try {
      final response = await ApiService().createOutbound(data);
      if (response == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Outbound berhasil ditambahkan! Stok inventory telah diperbarui.',
            ),
          ),
        );
        // Return true untuk trigger refresh di halaman sebelumnya
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambah outbound'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => loading = false);
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
    jenisSatuanController.dispose();
    volumeKeluarController.dispose();
    super.dispose();
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
                  // KODE PRODUK (from inventory filtered by user's gudang)
                  const Text(
                    'Kode Produk *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: selectedProduk,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih kode produk',
                    ),
                    items: produkFromInventory.map<DropdownMenuItem<int>>((
                      item,
                    ) {
                      final id = _extractInt(item, [
                        'id_produk',
                        'idProduk',
                        'id',
                      ]);
                      final kode = _extractString(item, [
                        'kode_produk',
                        'kodeProduk',
                        'kode',
                      ]);
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(kode ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (v) => _onProdukChanged(v),
                  ),
                  const SizedBox(height: 20),

                  // NAMA PRODUK (auto)
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

                  // JENIS SATUAN (auto)
                  const Text(
                    'Jenis Satuan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: jenisSatuanController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Jenis satuan otomatis terisi',
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // VOLUME TERSEDIA
                  const Text(
                    'Volume Tersedia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: volumeSatuanController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Volume tersedia otomatis terisi',
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // VOLUME KELUAR (input user)
                  const Text(
                    'Volume Keluar *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: volumeKeluarController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText:
                          'Masukkan volume yang akan dikeluarkan (max: $availableVolume)',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // GUDANG ASAL (auto)
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

                  // GUDANG TUJUAN (select from list)
                  const Text(
                    'Gudang Tujuan *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: gudangTujuanController.text.isEmpty ? null : gudangTujuanController.text,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih gudang tujuan',
                    ),
                    items: gudangList.map<DropdownMenuItem<String>>((gudang) {
                      final name = _extractString(gudang, [
                        'nama_gudang',
                        'namaGudang',
                        'nama',
                      ]);
                      return DropdownMenuItem<String>(
                        value: name ?? '',
                        child: Text(name ?? '-'),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        gudangTujuanController.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Tanggal Keluar
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

                  // Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF960B07),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: saveOutbound,
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
}
