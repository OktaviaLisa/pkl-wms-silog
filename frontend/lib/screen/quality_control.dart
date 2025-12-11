import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// MODEL QC
class QualityCheck {
  final String namaProduk;
  final String kodeProduk;
  final int volume;
  final String statusQc;
  final String catatan;
  final String tanggalQc;

  QualityCheck({
    required this.namaProduk,
    required this.kodeProduk,
    required this.volume,
    required this.statusQc,
    required this.catatan,
    required this.tanggalQc,
  });

  factory QualityCheck.fromJson(Map<String, dynamic> json) {
    return QualityCheck(
      namaProduk: json['nama_produk'] ?? 'Tidak diketahui',
      kodeProduk: json['kode_produk'] ?? '-',
      volume: json['volume'] ?? 0,
      statusQc: json['statusQc'] ?? json['status_qc'] ?? '-',
      catatan: json['catatan'] ?? '-',
      tanggalQc: json['tanggal_qc'] ?? '-',
    );
  }
}

class QualityControlPage extends StatefulWidget {
  const QualityControlPage({super.key});

  @override
  State<QualityControlPage> createState() => _QualityControlPageState();
}

class _QualityControlPageState extends State<QualityControlPage> {
  final ApiService api = ApiService();
  int? gudangId;
  late Future<List<QualityCheck>> futureQC;

  @override
  void initState() {
    super.initState();
    _loadGudang();
  }

  void _loadGudang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    gudangId = prefs.getInt('role_gudang');

    if (gudangId != null) {
      setState(() {
        futureQC = _loadQC();
      });
    } else {
      setState(() {
        futureQC = Future.value([]);
      });
    }
  }

  Future<List<QualityCheck>> _loadQC() async {
    try {
      final data = await api.getQualityControl(gudangId: gudangId!);
      return data.map((item) => QualityCheck.fromJson(item)).toList();
    } catch (e) {
      print("Error QC: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quality Control",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF960B07),
      ),
      body: FutureBuilder<List<QualityCheck>>(
        future: futureQC,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data QC"));
          }

          final qcList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: qcList.length,
            itemBuilder: (context, index) {
              final item = qcList[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    item.statusQc == "pass"
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: item.statusQc == "pass"
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(
                    item.namaProduk,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kode : ${item.kodeProduk}"),
                      Text("Volume : ${item.volume}"),
                      Text("QC : ${item.statusQc.toUpperCase()}"),
                      Text("Catatan : ${item.catatan}"),
                      Text("Tanggal QC : ${item.tanggalQc}"),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
