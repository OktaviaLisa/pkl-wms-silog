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
      setState(() {
        gudangList = data;

        gudangList.sort((a, b) =>
            int.parse(a["id_gudang"].toString())
                .compareTo(int.parse(b["id_gudang"].toString())));

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetch gudang: $e");
    }
  }

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
                          alamat_gudang: alamatController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1E1E),
        title: const Text("Gudang Management", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : gudangList.isEmpty
                ? const Center(child: Text("Belum ada gudang"))
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(const Color(0xFF7B1E1E)),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        dataRowHeight: 55,
                        headingRowHeight: 60,
                        columnSpacing: 60,

                        border: TableBorder(
                          top: BorderSide.none,
                          bottom: BorderSide.none,
                          left: BorderSide.none,
                          right: BorderSide.none,
                          horizontalInside: BorderSide.none,
                          verticalInside: BorderSide.none,
                        ),

                        columns: const [
                          DataColumn(label: Text("No")),
                          DataColumn(label: Text("Nama Gudang")),
                          DataColumn(label: Text("Alamat")),
                        ],
                        rows: List.generate(gudangList.length, (index) {
                          final g = gudangList[index];

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                return index.isEven
                                    ? const Color(0xFFF3F6FA)
                                    : Colors.white;
                              },
                            ),
                            cells: [
                              DataCell(Center(child: Text("${index + 1}"))),

                              // FIX: ambil field yang benar
                              DataCell(Text(g["nama_gudang"] ?? "-")),
                              DataCell(Text(g["alamat"] ?? "-")),
                            ],
                          );
                        }),
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
