import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_users_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_services_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';
import '../widgets/admin_charts.dart';

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

  // Helper function to format large numbers
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
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
                    child: Column(
                      children: [
                        // Stats row
                        SizedBox(
                          height: 130,
                          child: Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'vendor').snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AdminUsersScreen(),
                                            ),
                                          );
                                        },
                                        child: _buildSummaryCard('Total Vendors', _formatNumber(snapshot.data!.docs.length), Icons.store),
                                      );
                                    }
                                    return _buildSummaryCard('Total Vendors', '0', Icons.store);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AdminUsersScreen(),
                                            ),
                                          );
                                        },
                                        child: _buildSummaryCard('Customers', _formatNumber(snapshot.data!.docs.length), Icons.people),
                                      );
                                    }
                                    return _buildSummaryCard('Customers', '0', Icons.people);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AdminBookingsScreen(),
                                            ),
                                          );
                                        },
                                        child: _buildSummaryCard('Bookings', _formatNumber(snapshot.data!.docs.length), Icons.event_note),
                                      );
                                    }
                                    return _buildSummaryCard('Bookings', '0', Icons.event_note);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collection('services').snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AdminServicesScreen(),
                                            ),
                                          );
                                        },
                                        child: _buildSummaryCard('Services', _formatNumber(snapshot.data!.docs.length), Icons.miscellaneous_services),
                                      );
                                    }
                                    return _buildSummaryCard('Services', '0', Icons.miscellaneous_services);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Charts and recent activity
                        Expanded(
                          child: Row(
                            children: [
                              // Actual chart
                              Expanded(
                                flex: 2,
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Bookings by Category',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          height: 200,
                                          child: BookingsByCategoryChart(
                                            startDate: DateTime.now().subtract(const Duration(days: 30)),
                                            endDate: DateTime.now(),
                                            title: 'Recent Bookings by Category',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Recent activity button
                              SizedBox(
                                width: 300,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showRecentActivityPopup(context),
                                  icon: const Icon(Icons.history),
                                  label: const Text('View Recent Activity'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8, // Make cards taller
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'vendor').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminUsersScreen(),
                                    ),
                                  );
                                },
                                child: _buildSummaryCard('Total Vendors', _formatNumber(snapshot.data!.docs.length), Icons.store),
                              );
                            }
                            return _buildSummaryCard('Total Vendors', '0', Icons.store);
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminUsersScreen(),
                                    ),
                                  );
                                },
                                child: _buildSummaryCard('Customers', _formatNumber(snapshot.data!.docs.length), Icons.people),
                              );
                            }
                            return _buildSummaryCard('Customers', '0', Icons.people);
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminBookingsScreen(),
                                    ),
                                  );
                                },
                                child: _buildSummaryCard('Bookings', _formatNumber(snapshot.data!.docs.length), Icons.event_note),
                              );
                            }
                            return _buildSummaryCard('Bookings', '0', Icons.event_note);
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('services').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminServicesScreen(),
                                    ),
                                  );
                                },
                                child: _buildSummaryCard('Services', _formatNumber(snapshot.data!.docs.length), Icons.miscellaneous_services),
                              );
                            }
                            return _buildSummaryCard('Services', '0', Icons.miscellaneous_services);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Chart
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Bookings by Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                              SizedBox(
                               height: 150,
                               child: BookingsByCategoryChart(
                                 startDate: DateTime.now().subtract(const Duration(days: 30)),
                                 endDate: DateTime.now(),
                                 title: 'Recent Bookings by Category',
                               ),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Recent Activity Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRecentActivityPopup(context),
                icon: const Icon(Icons.history),
                label: const Text('View Recent Activity'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
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
          _buildSidebarItem(Icons.miscellaneous_services, 'Services'),
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
        // Handle navigation
        _navigateToScreen(title);
      },
    );
  }

  // Navigation handler
  void _navigateToScreen(String title) {
    switch (title) {
      case 'Vendors':
        // Navigate to users screen with vendor filter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminUsersScreen(),
          ),
        );
        break;
      case 'Customers':
        // Navigate to users screen with customer filter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminUsersScreen(),
          ),
        );
        break;
      case 'Bookings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminBookingsScreen(),
          ),
        );
        break;
      case 'Services':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminServicesScreen(),
          ),
        );
        break;
      case 'Reports':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminReportsScreen(),
          ),
        );
        break;
      case 'Settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminSettingsScreen(),
          ),
        );
        break;
      // Other cases can be added as needed
    }
  }

  // Show recent activity in a popup
  void _showRecentActivityPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context), // Close when tapping outside
          child: Container(
            color: Colors.black.withValues(alpha: 0.4), // Semi-transparent background
            child: GestureDetector(
              onTap: () {}, // Prevent tap events from reaching the background
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header with back button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Recent activity list
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .orderBy('createdAt', descending: true)
                                .limit(20)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final bookings = snapshot.data?.docs ?? [];

                              if (bookings.isEmpty) {
                                return const Center(child: Text('No recent activity'));
                              }

                              return ListView.builder(
                                controller: scrollController,
                                itemCount: bookings.length,
                                itemBuilder: (context, index) {
                                  final booking = bookings[index];
                                  final data = booking.data() as Map<String, dynamic>;
                                  final serviceName = data['serviceName'] ?? 'Unknown Service';
                                  final status = data['status'] ?? 'pending';
                                  final customerId = data['customerId'] ?? 'Unknown';
                                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                                  final formattedDate = createdAt != null
                                      ? DateFormat('MMM dd, yyyy HH:mm').format(createdAt)
                                      : 'Unknown Date';

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: ListTile(
                                      title: Text(serviceName),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Customer: $customerId'),
                                          Text('Booked on: $formattedDate'),
                                        ],
                                      ),
                                      trailing: Chip(
                                        label: Text(status.toUpperCase()),
                                        backgroundColor: status == 'confirmed'
                                            ? Colors.green.withValues(alpha: 0.2)
                                            : status == 'rejected'
                                                ? Colors.red.withValues(alpha: 0.2)
                                                : Colors.orange.withValues(alpha: 0.2),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Reusable widget for the summary cards
  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title, 
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: Colors.deepPurple, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}