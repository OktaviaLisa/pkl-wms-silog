import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register.dart';
import 'login.dart';

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
        backgroundColor: const Color(0xFF7B1E1E),
        elevation: 2,
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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

                  _sidebarItem(Icons.inventory, 'Inventory', onTap: () {}),

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
                        fetchTotalUsers(); // refresh total user setelah kembali dari register
                      });
                    },
                  ),

                  _sidebarItem(Icons.local_shipping, 'Inbound', onTap: () {}),
                  _sidebarItem(Icons.logout, 'Outbound', onTap: () {}),

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome, Admin 👋",
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
                      _infoCard("Total Users",
                          isLoading ? "..." : totalUsers.toString()),

                      _infoCard("Total Items", "1,204"),
                      _infoCard("Inbound Today", "18"),
                      _infoCard("Outbound Today", "12"),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Sidebar Item Widget
  Widget _sidebarItem(IconData icon, String label, {required Function() onTap}) {
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
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
            )
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
}
