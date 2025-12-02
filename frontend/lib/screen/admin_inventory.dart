import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminInventoryPage extends StatelessWidget {
  const AdminInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> warehouses = [
      "Gudang A",
      "Gudang B",
      "Gudang C",
      "Gudang D",
      "Gudang E",
      "Gudang F",
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1E1E),
        title: const Text(
          "Inventory",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.builder(
                itemCount: warehouses.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,       
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,   
              ),

                itemBuilder: (context, index) {
                  return _warehouseCard(
                    context,
                    warehouses[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warehouseCard(BuildContext context, String warehouseName) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WarehouseInventoryPage(warehouseName: warehouseName),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
              color: const Color(0xFF7B1E1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                warehouseName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
      ),
    );
  }
}

// HALAMAN DETAIL INVENTORY GUDANG

class WarehouseInventoryPage extends StatefulWidget {
  final String warehouseName;

  const WarehouseInventoryPage({super.key, required this.warehouseName});

  @override
  State<WarehouseInventoryPage> createState() => _WarehouseInventoryPageState();
}

class _WarehouseInventoryPageState extends State<WarehouseInventoryPage> {
  final ApiService apiService = ApiService();

  bool loading = true;
  List<dynamic> inventory = [];

  // Mapping nama gudang → ID
  final Map<String, int> warehouseIdMap = {
    "Gudang A": 1,
    "Gudang B": 2,
    "Gudang C": 3,
    "Gudang D": 4,
    "Gudang E": 5,
    "Gudang F": 6,
  };

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      // ambil ID sesuai nama
      final idGudang = warehouseIdMap[widget.warehouseName] ?? 0;

      // panggil API yang benar (ID bukan nama)
      final data = await apiService.getInventoryByWarehouse(idGudang);

      setState(() {
        inventory = data;
        loading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1E1E),
        title: Text(
          widget.warehouseName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : inventory.isEmpty
              ? const Center(
                  child: Text(
                    "Inventory kosong",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: inventory.length,
                  itemBuilder: (context, index) {
                    final item = inventory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['nama_item'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Qty: ${item['quantity']}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
