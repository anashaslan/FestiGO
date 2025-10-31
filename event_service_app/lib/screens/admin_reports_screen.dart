import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_charts.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _reportType = 'summary';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Report filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _selectDate(context, isStart: true),
                      child: Text('From: ${DateFormat('MM/dd/yyyy').format(_startDate)}'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _selectDate(context, isStart: false),
                      child: Text('To: ${DateFormat('MM/dd/yyyy').format(_endDate)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: _reportType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'summary', child: Text('Summary Report')),
                    DropdownMenuItem(
                        value: 'bookings', child: Text('Bookings Report')),
                    DropdownMenuItem(
                        value: 'revenue', child: Text('Revenue Report')),
                    DropdownMenuItem(
                        value: 'users', child: Text('User Growth Report')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _reportType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          // Report content
          Expanded(
            child: _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_reportType) {
      case 'summary':
        return _buildSummaryReport();
      case 'bookings':
        return _buildBookingsReport();
      case 'revenue':
        return _buildRevenueReport();
      case 'users':
        return _buildUserGrowthReport();
      default:
        return _buildSummaryReport();
    }
  }

  Widget _buildSummaryReport() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Key metrics cards
            FutureBuilder<Map<String, dynamic>>(
              future: _getSummaryData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final data = snapshot.data ?? {};

                return Column(
                  children: [
                    // Metrics grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        _buildMetricCard('Total Users', (data['totalUsers'] as int?)?.toString() ?? '0', Icons.people),
                        _buildMetricCard('Total Vendors', (data['totalVendors'] as int?)?.toString() ?? '0', Icons.store),
                        _buildMetricCard('Total Bookings', (data['totalBookings'] as int?)?.toString() ?? '0', Icons.event),
                        _buildMetricCard('Total Revenue', '\$${(data['totalRevenue'] as double?)?.toStringAsFixed(2) ?? '0.00'}', Icons.attach_money),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Charts placeholders
                    const Text(
                      'Charts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Use SizedBox with fixed height instead of Expanded
                    SizedBox(
                      height: 250,
                      child: BookingsByCategoryChart(
                        startDate: _startDate,
                        endDate: _endDate,
                        title: 'Bookings by Category',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: MonthlyRevenueChart(
                        startDate: _startDate,
                        endDate: _endDate,
                        title: 'Monthly Revenue Trend',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: UserGrowthChart(
                        startDate: _startDate,
                        endDate: _endDate,
                        title: 'User Growth Over Time',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsReport() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bookings Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('createdAt',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
                  .where('createdAt',
                      isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final bookings = snapshot.data?.docs ?? [];

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final data = booking.data() as Map<String, dynamic>;
                    final serviceName = data['serviceName'] ?? 'Unknown Service';
                    final status = data['status'] ?? 'pending';
                    final price = data['price'] ?? 0.0;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final formattedDate = createdAt != null
                        ? DateFormat('MMM dd, yyyy').format(createdAt)
                        : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(serviceName),
                        subtitle: Text('Booked on $formattedDate'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${price.toStringAsFixed(2)}'),
                            const SizedBox(width: 16),
                            Chip(
                              label: Text(status),
                              backgroundColor: status == 'confirmed'
                                  ? Colors.green
                                  : status == 'rejected'
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ],
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
  }

  Widget _buildRevenueReport() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<double>(
              future: _getTotalRevenue(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final totalRevenue = snapshot.data ?? 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Revenue: \$${totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: MonthlyRevenueChart(
                        startDate: _startDate,
                        endDate: _endDate,
                        title: 'Monthly Revenue Trend',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: BookingsByCategoryChart(
                        startDate: _startDate,
                        endDate: _endDate,
                        title: 'Bookings by Category',
                      ),
                    ),
                  ],
                );
              }),
        ],
      ),
    );
  }

  Widget _buildUserGrowthReport() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Growth Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, int>>(
              future: _getUserGrowthData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final data = snapshot.data ?? {};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Users: ${data['total'] ?? 0}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vendors: ${data['vendors'] ?? 0}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Customers: ${data['customers'] ?? 0}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: UserGrowthChart(
                        startDate: _startDate,
                        endDate: _endDate,
                        title: 'User Growth Over Time',
                      ),
                    ),
                  ],
                );
              }),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getSummaryData() async {
    try {
      // Get total users (excluding admins)
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();
      
      final vendorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'vendor')
          .get();
      
      // Total users = customers + vendors (excluding admins)
      final totalUsers = customersSnapshot.docs.length + vendorsSnapshot.docs.length;
      
      // Get bookings in date range
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();
      
      // Calculate total revenue
      double totalRevenue = 0;
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'confirmed') {
          totalRevenue += (data['price'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      return {
        'totalUsers': totalUsers,
        'totalVendors': vendorsSnapshot.docs.length,
        'totalBookings': bookingsSnapshot.docs.length,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'totalVendors': 0,
        'totalBookings': 0,
        'totalRevenue': 0.0,
      };
    }
  }

  Future<double> _getTotalRevenue() async {
    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();
      
      double totalRevenue = 0;
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'confirmed') {
          totalRevenue += (data['price'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      return totalRevenue;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, int>> _getUserGrowthData() async {
    try {
      final vendorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'vendor')
          .get();
      
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();
      
      // Total users = customers + vendors (excluding admins)
      final totalUsers = vendorsSnapshot.docs.length + customersSnapshot.docs.length;
      
      return {
        'total': totalUsers,
        'vendors': vendorsSnapshot.docs.length,
        'customers': customersSnapshot.docs.length,
      };
    } catch (e) {
      return {
        'total': 0,
        'vendors': 0,
        'customers': 0,
      };
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
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
                Icon(icon, color: Theme.of(context).colorScheme.primary),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}