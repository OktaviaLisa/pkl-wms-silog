import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard.dart';

// MODEL QC
class QualityCheck {
  final int idQc;
  final String namaProduk;
  final String kodeProduk;
  final int volume;
  final String statusQc;
  final String catatan;
  final String tanggalQc;

  QualityCheck({
    required this.idQc,
    required this.namaProduk,
    required this.kodeProduk,
    required this.volume,
    required this.statusQc,
    required this.catatan,
    required this.tanggalQc,
  });

  factory QualityCheck.fromJson(Map<String, dynamic> json) {
    return QualityCheck(
      idQc: json['id_qc'] ?? 0,
      namaProduk: json['nama_produk'] ?? 'Tidak diketahui',
      kodeProduk: json['kode_produk'] ?? '-',
      volume: json['volume'] ?? 0,
      statusQc: json['status_qc'] ?? '-',
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

  late Future<List<QualityCheck>> futureQC = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadGudang();
  }

  void _loadGudang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    gudangId = prefs.getInt('role_gudang');

    if (gudangId != null) {
      futureQC = _loadQC();
    } else {
      futureQC = Future.value([]);
    }

    if (mounted) setState(() {});
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

  String formatTanggal(String tanggal) {
    if (tanggal.isEmpty || tanggal.length < 10) return tanggal;
    return tanggal.substring(0, 10);
  }

  void _showQCModal(QualityCheck qc) {
    final goodController = TextEditingController();
    final badController = TextEditingController();
    final catatanController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Proses Quality Control'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Produk: ${qc.namaProduk}'),
                Text('Kode: ${qc.kodeProduk}'),
                Text('Total Volume: ${qc.volume}'),
                const SizedBox(height: 16),
                TextField(
                  controller: goodController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty Good',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setModalState(() => errorText = null),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: badController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty Bad',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setModalState(() => errorText = null),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final good = int.tryParse(goodController.text) ?? 0;
                final bad = int.tryParse(badController.text) ?? 0;

                if (good + bad != qc.volume) {
                  setModalState(() {
                    errorText = 'Total good + bad harus sama dengan ${qc.volume}';
                  });
                  return;
                }

                try {
                  await api.processQC({
                    'id_qc': qc.idQc,
                    'qty_good': good,
                    'qty_bad': bad,
                    'catatan_qc': catatanController.text,
                  });

                  Navigator.pop(context);
                  setState(() {
                    futureQC = _loadQC();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('QC berhasil diproses')),
                  );
                } catch (e) {
                  setModalState(() {
                    errorText = e.toString().replaceAll('Exception: ', '');
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF960B07),
                foregroundColor: Colors.white,
              ),
              child: const Text('Proses'),
            ),
          ],
        ),
      ),
    );
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
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          ),
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
                child: InkWell(
                  onTap: item.statusQc == 'pending' ? () => _showQCModal(item) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: const Color(0xFF960B07),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.namaProduk,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.statusQc == 'pending' ? Colors.orange : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.statusQc.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Kode : ${item.kodeProduk}"),
                        Text("Volume : ${item.volume}"),
                        Text("Catatan : ${item.catatan}"),
                        Text("Tanggal QC : ${formatTanggal(item.tanggalQc)}"),
                        if (item.statusQc == 'pending')
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              "Tap untuk proses QC",
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

