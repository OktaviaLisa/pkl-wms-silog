import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import '../services/api_service.dart';
import 'register.dart';
import 'login.dart';
import 'admin_inventory.dart';
import 'admin_gudang.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService apiService = ApiService();

  int totalUsers = 0;
  int totalProduk = 0;
  int totalGudang = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    try {
      final users = await apiService.getAllUsers();
      final produk = await apiService.getProduk();
      final gudang = await apiService.getGudang();

      setState(() {
        totalUsers = users.length;
        totalProduk = produk.length;
        totalGudang = gudang.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error dashboard: $e");
    }
  }

  // ================= METABASE CHART =================
  Widget _metabaseChart() {
    return FutureBuilder<String>(
      future: apiService.getMetabaseChartUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Memuat Chart Metabase..."),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  "Gagal memuat chart\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        // Generate unique view ID untuk iframe
        final String viewId = 'metabase-iframe-${DateTime.now().millisecondsSinceEpoch}';
        
        // Register iframe untuk Flutter Web
        ui_web.platformViewRegistry.registerViewFactory(
          viewId,
          (int id) => html.IFrameElement()
            ..src = snapshot.data!
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.borderRadius = '8px',
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: HtmlElementView(viewType: viewId),
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1E1E),
        title: const Text("Admin Panel", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          children: [
            // ================= SIDEBAR =================
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

                  _sidebarItem(Icons.dashboard, "Dashboard", () {}),

                  _sidebarItem(Icons.group, "User Management", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ).then((_) => fetchAll());
                  }),

                  _sidebarItem(Icons.domain, "Gudang", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminGudangPage(),
                      ),
                    );
                  }),

                  _sidebarItem(Icons.inventory, "Inventory", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminInventoryPage(),
                      ),
                    );
                  }),

                  const Spacer(),

                  _sidebarItem(Icons.exit_to_app, "Logout", () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  }),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(width: 32),

            // ================= CONTENT =================
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selamat Datang, Admin",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B1E1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Kelola warehouse logistik Anda secara terpusat.",
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        _infoCard("Total Users", totalUsers),
                        _infoCard("Total Produk", totalProduk),
                        _infoCard("Total Gudang", totalGudang),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ================= CHART =================
                    Container(
                      height: 520,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
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
                          const SizedBox(height: 16),
                          Expanded(child: _metabaseChart()),
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

  // ================= COMPONENT =================
  Widget _sidebarItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, int value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              isLoading ? "..." : value.toString(),
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
}
