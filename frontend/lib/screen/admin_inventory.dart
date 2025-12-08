import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  final ApiService apiService = ApiService();

  List<dynamic> allInventories = [];
  List<dynamic> filteredInventories = [];

  bool loading = true;
  String searchQuery = "";
  String? selectedWarehouse;

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      final data = await apiService.getAllInventory();

      setState(() {
        allInventories = data;
        filteredInventories = data;
        loading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => loading = false);
    }
  }

  void applyFilter() {
    List<dynamic> result = allInventories;

    if (selectedWarehouse != null && selectedWarehouse!.isNotEmpty) {
      result =
          result.where((e) => e['gudang'] == selectedWarehouse).toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result
          .where((e) => e['nama_produk']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    setState(() => filteredInventories = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1E1E),
        title: const Text(
          "Inventory",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // -------------------- SEARCH + FILTER BAR --------------------
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: (v) {
                            searchQuery = v;
                            applyFilter();
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: "Cari nama produk...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: selectedWarehouse,
                          onChanged: (value) {
                            selectedWarehouse = value;
                            applyFilter();
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Filter Gudang",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text("Semua Gudang"),
                            ),
                            ...allInventories
                                .map((e) => e['gudang'])
                                .toSet()
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ))
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // -------------------- TABEL DATA --------------------
                  Expanded(
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Color(0xFF7B1E1E)),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          dataRowHeight: 56,
          columnSpacing: 60,
          dividerThickness: .5,
          columns: const [
            DataColumn(label: Text("Gudang")),
            DataColumn(label: Text("Produk")),
            DataColumn(label: Text("Quantity")),
            DataColumn(label: Text("Satuan")),
          ],
          rows: List.generate(filteredInventories.length, (index) {
            final item = filteredInventories[index];
            final isEven = index % 2 == 0;
            return DataRow(
              color: MaterialStateProperty.all(
                isEven ? Colors.white : Color(0xFFEFF4F9),
              ),
              cells: [
              DataCell(Text(item['gudang'] ?? "-")),
              DataCell(Text(item['nama_produk'] ?? "-")),
              DataCell(Text(item['volume'].toString())),
              DataCell(Text(item['jenis_satuan'] ?? "-")),
                            ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
    );
  }
}
