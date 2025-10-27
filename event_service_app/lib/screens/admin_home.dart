import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Function to handle user logout
  Future<void> _signOut(BuildContext context) async {
    print('Admin logging out...');
    await FirebaseAuth.instance.signOut();
    print('Admin logout complete - StreamBuilder will handle navigation');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use OrientationBuilder to create a responsive layout
      body: OrientationBuilder(
        builder: (context, orientation) {
          // For horizontal layout (landscape)
          if (orientation == Orientation.landscape) {
            return _buildLandscapeLayout();
          }
          // For vertical layout (portrait)
          return _buildPortraitLayout();
        },
      ),
    );
  }

  // Builds the Horizontal (Landscape) Layout based on Page 2 of the prototype
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Sidebar
        _buildSidebar(),
        // Main content area
        Expanded(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('FestiGO'), // Changed title as requested
              backgroundColor: Colors.white,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _signOut(context),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Dashboard',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Summary Cards Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5, // Adjust aspect ratio for better look
                      children: [
                        _buildSummaryCard('Total Vendors', '250', Icons.store),
                        _buildSummaryCard('Customers', '1,450', Icons.people),
                        _buildSummaryCard('Bookings', '320', Icons.event_note),
                        _buildSummaryCard('Revenue', '\$15,200', Icons.attach_money),
                        _buildChartPlaceholder('Bookings by Category'),
                        _buildChartPlaceholder('Monthly Trends'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Builds the Vertical (Portrait) Layout based on Page 1 of the prototype
  Widget _buildPortraitLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      drawer: Drawer(child: _buildSidebar()), // Use a Drawer for the sidebar
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSummaryCard('Total Vendors', '0', Icons.store),
            _buildSummaryCard('Customers', '0', Icons.people),
            _buildSummaryCard('Bookings', '0', Icons.event_note),
            _buildSummaryCard('Revenue', '\$0', Icons.attach_money),
          ],
        ),
      ),
    );
  }

  // Reusable widget for the sidebar/navigation rail
  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: Colors.grey[100],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text(
              'FestiGO Admin',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _buildSidebarItem(Icons.dashboard, 'Dashboard', isSelected: true),
          _buildSidebarItem(Icons.store, 'Vendors'),
          _buildSidebarItem(Icons.people, 'Customers'),
          _buildSidebarItem(Icons.event_note, 'Bookings'),
          _buildSidebarItem(Icons.payment, 'Payments'),
          _buildSidebarItem(Icons.bar_chart, 'Reports'),
          const Divider(),
          _buildSidebarItem(Icons.settings, 'Settings'),
        ],
      ),
    );
  }

  // Reusable widget for individual sidebar items
  Widget _buildSidebarItem(IconData icon, String title, {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.deepPurple : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.deepPurple : Colors.black,
        ),
      ),
      tileColor: isSelected ? Colors.deepPurple.withValues(alpha: 0.1) : null,
      onTap: () {
        // Handle navigation later
      },
    );
  }

  // Reusable widget for the summary cards
  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                Icon(icon, color: Colors.deepPurple),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable widget for the chart placeholders
  Widget _buildChartPlaceholder(String title) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}