import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminGudangPage extends StatefulWidget {
  const AdminGudangPage({super.key});

  @override
  State<AdminGudangPage> createState() => _AdminGudangPageState();
}

class _AdminGudangPageState extends State<AdminGudangPage> {
  final ApiService apiService = ApiService();
  List gudangList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGudang();
  }

 Future<void> fetchGudang() async {
  try {
    final data = await apiService.getGudang();

    // NORMALISASI DATA → agar idGudang tidak null
    gudangList = data.map((e) {
      return {
        "idGudang": e["idGudang"] ?? e["id_gudang"] ?? 0,
        "nama_gudang": e["nama_gudang"] ?? "",
        "alamat": e["alamat"] ?? "",
      };
    }).toList();

    // SORTING AMAN TANPA NULL
    gudangList.sort((a, b) {
      final idA = int.tryParse(a["idGudang"].toString()) ?? 0;
      final idB = int.tryParse(b["idGudang"].toString()) ?? 0;
      return idA.compareTo(idB);
    });

    setState(() => isLoading = false);
  } catch (e) {
    print("Error fetch gudang: $e");
    setState(() => isLoading = false);
  }
}

  //  EDIT GUDANG //
  void showEditGudangDialog(Map g) {
    final namaController = TextEditingController(text: g["nama_gudang"]);
    final alamatController = TextEditingController(text: g["alamat"]);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Gudang",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1E1E),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: namaController,
                  decoration: InputDecoration(
                    labelText: "Nama Gudang",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: alamatController,
                  decoration: InputDecoration(
                    labelText: "Alamat Gudang",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Batal"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1E1E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Simpan Perubahan"),
                      onPressed: () async {
                        await apiService.updateGudang(
                          idGudang: g["idGudang"],
                          namaGudang: namaController.text.trim(),
                          alamat: alamatController.text.trim(),
                        );

                        Navigator.pop(context);
                        fetchGudang();
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // TAMBAH GUDANG //
  void showCreateGudangDialog() {
    final namaController = TextEditingController();
    final alamatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Tambah Gudang Baru",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1E1E),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: namaController,
                  decoration: InputDecoration(
                    labelText: "Nama Gudang",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: alamatController,
                  decoration: InputDecoration(
                    labelText: "Alamat",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Batal"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1E1E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Simpan"),
                      onPressed: () async {
                        await apiService.createGudang(
                          namaGudang: namaController.text.trim(),
                          alamat: alamatController.text.trim(),
                        );
                        Navigator.pop(context);
                        fetchGudang();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// TABEL //
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      backgroundColor: const Color(0xFF7B1E1E),
      title: const Text("Gudang Management", style: TextStyle(color: Colors.white)),
    ),

    body: Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1600, // Lebar maksimal tabel
                ),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1400, // Lebar tabel
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(const Color(0xFF7B1E1E)),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        dataRowHeight: 65,
                        headingRowHeight: 65,
                        columnSpacing: 150,

                        columns: const [
                          DataColumn(label: Text("No")),
                          DataColumn(label: Text("Nama Gudang")),
                          DataColumn(label: Text("Alamat")),
                          DataColumn(label: Text("Aksi")),
                        ],

                        rows: List.generate(gudangList.length, (index) {
                          final g = gudangList[index];

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (states) =>
                                  index.isEven ? const Color(0xFFF3F6FA) : Colors.white,
                            ),
                            cells: [
                              DataCell(Text("${index + 1}")),
                              DataCell(Text(g["nama_gudang"] ?? "-")),
                              DataCell(Text(g["alamat"] ?? "-")),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF7B1E1E)),
                                      onPressed: () => showEditGudangDialog(g),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    ),

    floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xFF7B1E1E),
      onPressed: showCreateGudangDialog,
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
}
}