import 'package:flutter/material.dart';
import '../services/api_service.dart';

// PDF Generator
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

// UNTUK DOWNLOAD PDF DI WEB
import 'dart:html' as html;

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
      result = result.where((e) => e['gudang'] == selectedWarehouse).toList();
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

  // ---------------------- GENERATE PDF (WEB VERSION) ----------------------
  Future<void> downloadPDF() async {
    final pdf = pw.Document();

    final headers = ["Gudang", "Produk", "Quantity", "Satuan"];

    final data = filteredInventories.map((item) {
      return [
        item['gudang'] ?? "-",
        item['nama_produk'] ?? "-",
        item['volume'].toString(),
        item['jenis_satuan'] ?? "-"
      ];
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Inventory Management",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                border: pw.TableBorder.all(width: 1),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF7B1E1E),
                ),
                headerStyle: pw.TextStyle(
                  color: PdfColor.fromInt(0xFFFFFFFF),
                  fontWeight: pw.FontWeight.bold,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 11),
                headerHeight: 30,
                cellHeight: 28,
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();

    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = "inventory.pdf"
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ------------------------------------------------------------------------

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
                            headingRowColor:
                                MaterialStateProperty.all(Color(0xFF7B1E1E)),
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
                            rows: List.generate(filteredInventories.length,
                                (index) {
                              final item = filteredInventories[index];
                              final isEven = index % 2 == 0;
                              return DataRow(
                                color: MaterialStateProperty.all(
                                  isEven
                                      ? Colors.white
                                      : Color(0xFFEFF4F9),
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

                  const SizedBox(height: 16),

                  // ------------------- BUTTON DOWNLOAD PDF -------------------
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1E1E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: downloadPDF,
                      icon: const Icon(Icons.download),
                      label: const Text(
                        "Download PDF",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
