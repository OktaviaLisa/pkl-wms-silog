import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Dashboard',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Users',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Inventory',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          children: [
            // Sidebar
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
                  _sidebarItem(Icons.dashboard, 'Dashboard'),
                  _sidebarItem(Icons.inventory, 'Inventory'),
                  _sidebarItem(Icons.group, 'User Management'),
                  _sidebarItem(Icons.local_shipping, 'Inbound'),
                  _sidebarItem(Icons.logout, 'Outbound'),
                ],
              ),
            ),

            const SizedBox(width: 32),

            // Content Area
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
                      _infoCard("Total Users", "24"),
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

  // Sidebar item
  Widget _sidebarItem(IconData icon, String label) {
    return Padding(
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
    );
  }

  // Card info widget
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
