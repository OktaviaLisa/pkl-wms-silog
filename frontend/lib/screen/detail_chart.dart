import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

/// =======================
/// MODEL
/// =======================
class Transaction {
  final int idOrders;
  final String tanggal;
  final String status;
  final int volume;
  final String produk;
  final String gudangAsalDb;
  final String gudangTujuanDb;

  Transaction({
    required this.idOrders,
    required this.tanggal,
    required this.status,
    required this.volume,
    required this.produk,
    required this.gudangAsalDb,
    required this.gudangTujuanDb,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      idOrders: json['idOrders'],
      tanggal: json['tanggal'],
      status: json['status'] ?? '',
      volume: json['volume'],
      produk: json['produk_obj']?['nama_produk'] ?? '-',
      gudangAsalDb: json['gudang_asal_obj']?['nama_gudang'] ?? '-',
      gudangTujuanDb: json['gudang_tujuan_obj']?['nama_gudang'] ?? '-',
    );
  }

  String get gudangAsal => status == 'outbound' ? gudangTujuanDb : gudangAsalDb;

  String get gudangTujuan =>
      status == 'outbound' ? gudangAsalDb : gudangTujuanDb;
}

/// =======================
/// PAGE
/// =======================
class DetailChart extends StatefulWidget {
  final int monthIndex;
  final String type;

  const DetailChart({super.key, required this.monthIndex, required this.type});

  @override
  State<DetailChart> createState() => _DetailChartState();
}

class _DetailChartState extends State<DetailChart> {
  late Future<List<Transaction>> transactionsFuture;

  @override
  void initState() {
    super.initState();
    transactionsFuture = fetchTransactions();
  }

  Future<List<Transaction>> fetchTransactions() async {
    final api = ApiService();

    final list = await api.getTransactionDetail(
      monthIndex: widget.monthIndex,
      type: widget.type,
    );

    return list.map((e) => Transaction.fromJson(e)).toList();
  }

  String formatTanggal(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year}";
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final titleText =
        "${widget.type.toUpperCase()} ${months[widget.monthIndex].toUpperCase()}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF960B07),
        elevation: 0,
        title: const Text(
          "Detail Transaksi",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Transaction>>(
          future: transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            final data = snapshot.data ?? [];

            if (data.isEmpty) {
              return const Center(child: Text("Tidak ada transaksi"));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // MARGIN ATAS
                const SizedBox(height: 25),

                // JUDUL
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF960B07),
                  ),
                ),

                // SUBTITLE / INFO
                const SizedBox(height: 2), // jarak lebih rapat
                Text(
                  "Total ${data.length} transaksi ${widget.type}",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 6), // jarak ke tabel
                // TABLE
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowColor: MaterialStateProperty.all(
                            const Color(0xFF960B07),
                          ),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          columns: const [
                            DataColumn(label: Text("No")),
                            DataColumn(label: Text("Tanggal")),
                            DataColumn(label: Text("Produk")),
                            DataColumn(label: Text("Gudang Asal")),
                            DataColumn(label: Text("Gudang Tujuan")),
                            DataColumn(label: Text("Volume")),
                          ],
                          rows: List.generate(data.length, (index) {
                            final trx = data[index];
                            return DataRow(
                              cells: [
                                DataCell(Text("${index + 1}")),
                                DataCell(
                                  Text(
                                    formatTanggal(trx.tanggal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(Text(trx.produk)),
                                DataCell(Text(trx.gudangAsal)),
                                DataCell(Text(trx.gudangTujuan)),
                                DataCell(Text(trx.volume.toString())),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
