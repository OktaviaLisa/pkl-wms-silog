import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'register.dart';
import 'login.dart';
import 'admin_inventory.dart';
import 'admin_gudang.dart';
import 'detail_chart.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService apiService = ApiService();

  int totalUsers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTotalUsers();
  }

  Future<void> fetchTotalUsers() async {
    try {
      final users = await apiService.getAllUsers();
      setState(() {
        totalUsers = users.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetch users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF7B1E1E),
        elevation: 2,
        title: const Text(
          'Admin Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          children: [
            // Sidebar ---------------------------------------------------------
            Container(
              width: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF8B2323),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  _sidebarItem(Icons.dashboard, 'Dashboard', onTap: () {}),

                  // FITUR MASTER ADMIN //
                  _sidebarItem(
                    Icons.group,
                    'User Management',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      ).then((_) {
                        fetchTotalUsers();
                      });
                    },
                  ),

                  _sidebarItem(
                    Icons.door_back_door,
                    'Gudang',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminGudangPage(),
                        ),
                      );
                    },
                  ),

                  _sidebarItem(
                    Icons.inventory,
                    'Inventory',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminInventoryPage(),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  _sidebarItem(
                    Icons.exit_to_app,
                    'Logout',
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (c) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(width: 32),

            // Content ----------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome, Admin",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B1E1E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Manage your warehouse and users from this dashboard.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        _infoCard(
                          "Total Users",
                          isLoading ? "..." : totalUsers.toString(),
                        ),
                        _infoCard("Total Inventory", "1,204"),
                        _infoCard("Inbound Today", "18"),
                        _infoCard("Outbound Today", "12"),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Container(
                      height: 520, // ← naikkan tinggi container
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        20,
                      ), // ← kurangi padding bawah
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Statistik Transaksi Bulanan",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B1E1E),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: apiService.getTransactionChart(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: Text("Tidak ada data chart"),
                                  );
                                }

                                final chartData =
                                    snapshot.data!['data'] as List;
                                return Column(
                                  children: [
                                    _buildLegend(chartData),
                                    const SizedBox(height: 20),
                                    Expanded(child: _buildChart(chartData)),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sidebar Item Widget
  Widget _sidebarItem(
    IconData icon,
    String label, {
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Card Info
  Widget _infoCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<dynamic> data) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(data),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response != null &&
                response.spot != null) {
              final groupIndex = response.spot!.touchedBarGroupIndex;
              final rodIndex = response.spot!.touchedRodDataIndex;

              final monthIndex = groupIndex; // 0=Jan, 1=Feb, dst
              final type = rodIndex == 0 ? 'inbound' : 'outbound';

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetailChart(monthIndex: monthIndex, type: type),
                ),
              );
            }
          },
        ),

        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32, // ← tambahin ini
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < 12) {
                  return Text(
                    months[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (item['inbound'] ?? 0).toDouble(),
                color: Colors.blue,
                width: 12,
              ),
              BarChartRodData(
                toY: (item['outbound'] ?? 0).toDouble(),
                color: Colors.orange,
                width: 12,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(List<dynamic> data) {
    // Hitung total inbound dan outbound
    int totalInbound = 0;
    int totalOutbound = 0;

    for (var item in data) {
      totalInbound += (item['inbound'] ?? 0) as int;
      totalOutbound += (item['outbound'] ?? 0) as int;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.blue, "Inbound", totalInbound),
        const SizedBox(width: 30),
        _legendItem(Colors.orange, "Outbound", totalOutbound),
      ],
    );
  }

  Widget _legendItem(Color color, String label, int total) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "$label: $total",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  double _getMaxY(List<dynamic> data) {
    double max = 0;
    for (var item in data) {
      final inbound = (item['inbound'] ?? 0).toDouble();
      final outbound = (item['outbound'] ?? 0).toDouble();
      if (inbound > max) max = inbound;
      if (outbound > max) max = outbound;
    }
    return max + 5; // Tambah margin
  }
}
