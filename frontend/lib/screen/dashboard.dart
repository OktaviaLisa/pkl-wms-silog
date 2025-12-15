import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String username = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username") ?? "User";
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(top: 90),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ================= HERO SECTION =================
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 60,
                        vertical: 20,
                      ),
                      child: isMobile
                          ? Column(
                              children: [
                                _buildHeroText(),
                                const SizedBox(height: 20),
                                _buildHeroImage(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _buildHeroText()),
                                const SizedBox(width: 40),
                                Expanded(child: _buildHeroImage()),
                              ],
                            ),
                    ),

                    const SizedBox(height: 40),

                    // ================= FEATURE SECTION =================
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF960B07),
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 20),
                      child: Column(
                        children: [
                          const Text(
                            'Warehouses Management System',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // MOBILE = GRID  
                          // DESKTOP = SCROLL HORIZONTAL
                          isMobile
                              ? Wrap(
                                  spacing: 15,
                                  runSpacing: 15,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildFeatureCard(
                                        context,
                                        "Inventory",
                                        Icons.inventory,
                                        '/inventory'),
                                    _buildFeatureCard(
                                        context,
                                        "Quality Control",
                                        Icons.verified,
                                        '/quality-control'),
                                    _buildFeatureCard(
                                        context,
                                        "Inbound Stock",
                                        Icons.arrow_downward,
                                        '/inbound_stock'),
                                    _buildFeatureCard(
                                        context,
                                        "Outbound Stock",
                                        Icons.arrow_upward,
                                        '/outbound_stock'),
                                    _buildFeatureCard(
                                        context,
                                        "Retur",
                                        Icons.assignment_return,
                                        '/retur'),
                                  ],
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildFeatureCard(
                                          context,
                                          "Inventory",
                                          Icons.inventory,
                                          '/inventory'),
                                      const SizedBox(width: 20),
                                      _buildFeatureCard(
                                          context,
                                          "Quality Control",
                                          Icons.verified,
                                          '/quality-control'),
                                      const SizedBox(width: 20),
                                      _buildFeatureCard(
                                          context,
                                          "Inbound Stock",
                                          Icons.arrow_downward,
                                          '/inbound_stock'),
                                      const SizedBox(width: 20),
                                      _buildFeatureCard(
                                          context,
                                          "Outbound Stock",
                                          Icons.arrow_upward,
                                          '/outbound_stock'),
                                      const SizedBox(width: 20),
                                      _buildFeatureCard(
                                          context,
                                          "Retur",
                                          Icons.assignment_return,
                                          '/retur'),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ================= NAVBAR =================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF960B07),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hai, $username',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: logout,
                        icon:
                            const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ====================== HERO TEXT ======================
  Widget _buildHeroText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warehouses Management\nSystem',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 150, 17, 7),
          ),
        ),
        SizedBox(height: 15),
        Text(
          'Sistem Manajemen Gudang terintegrasi untuk membantu mengelola stok, proses penerimaan dan pengeluaran barang secara efisien dan real-time.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ====================== HERO IMAGE ======================
  Widget _buildHeroImage() {
    return Image.asset(
      'lib/assets/images/warehouses.jpg',
      width: 400,
      height: 300,
      fit: BoxFit.contain,
    );
  }

  // ================= FEATURE CARD ======================
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    String routeName,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Container(
        width: 160,
        height: 150,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 45, color: const Color.fromARGB(255, 150, 17, 7)),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 150, 17, 7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
