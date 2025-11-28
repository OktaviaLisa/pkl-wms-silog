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

  // Ambil username dari SharedPreferences
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username") ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== NAVBAR (Sudah diperbaiki) =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Hai, $username',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 150, 17, 7),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ===== HERO SECTION =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
              child: Row(
                children: [
                  // Teks
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
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
                          'Lorem Ipsum is simply dummy text of the printing and typesetting industry. '
                          'Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 40),

                  // Gambar warehouse
                  Expanded(
                    flex: 1,
                    child: Image.asset(
                      'lib/assets/images/warehouses.jpg',
                      width: 400,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // ===== FEATURE CARDS SECTION =====
            Container(
              width: double.infinity,
              color: const Color(0xFF960B07),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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

                  // === SINGLE ROW SCROLLABLE ===
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFeatureCard(
                          context,
                          "Inventory",
                          Icons.inventory,
                          '/inventory',
                        ),
                        const SizedBox(width: 20),

                        _buildFeatureCard(
                          context,
                          "Quality Control",
                          Icons.verified,
                          '/quality_control',
                        ),
                        const SizedBox(width: 20),

                        _buildFeatureCard(
                          context,
                          "Inbound Stock",
                          Icons.arrow_downward,
                          '/inbound_stock',
                        ),
                        const SizedBox(width: 20),

                        _buildFeatureCard(
                          context,
                          "Outbound Stock",
                          Icons.arrow_upward,
                          '/outbound_stock',
                        ),
                        const SizedBox(width: 20),

                        _buildFeatureCard(
                          context,
                          "Retur",
                          Icons.assignment_return,
                          '/retur',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== COMPONENT CARD =====
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    String routeName,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Container(
        width: 180,
        height: 160,
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
            Icon(icon, size: 45, color: const Color.fromARGB(255, 150, 17, 7)),
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
