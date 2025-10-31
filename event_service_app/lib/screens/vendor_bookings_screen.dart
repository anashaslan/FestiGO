import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'vendor_booking_detail_screen.dart';

class VendorBookingsScreen extends StatefulWidget {
  const VendorBookingsScreen({super.key});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'confirmed', 'rejected'

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Prevent the query from running if the user is null.
    if (user == null) {
      return const Center(child: Text('Please log in to see your bookings.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('vendorId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          // Filter out rejected bookings older than 7 days
          final filteredBookings = bookings.where((doc) {
            final booking = doc.data() as Map<String, dynamic>;
            final status = booking['status'] ?? 'pending';
            final createdAt = (booking['createdAt'] as Timestamp?)?.toDate();
            
            if (status == 'rejected' && createdAt != null) {
              final daysDifference = DateTime.now().difference(createdAt).inDays;
              return daysDifference <= 7;
            }
            
            return true;
          }).toList();

          // Count bookings by status
          final pendingCount = filteredBookings.where((doc) {
            final booking = doc.data() as Map<String, dynamic>;
            return booking['status'] == 'pending';
          }).length;

          final confirmedCount = filteredBookings.where((doc) {
            final booking = doc.data() as Map<String, dynamic>;
            return booking['status'] == 'confirmed';
          }).length;

          final rejectedCount = filteredBookings.where((doc) {
            final booking = doc.data() as Map<String, dynamic>;
            return booking['status'] == 'rejected';
          }).length;

          // Apply status filter
          final displayBookings = filteredBookings.where((doc) {
            if (_selectedFilter == 'all') return true;
            final booking = doc.data() as Map<String, dynamic>;
            return booking['status'] == _selectedFilter;
          }).toList();

          return Column(
            children: [
              // Status count widget
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusCount('Pending', pendingCount, Colors.orange),
                    _buildStatusCount('Confirmed', confirmedCount, Colors.green),
                    _buildStatusCount('Rejected', rejectedCount, Colors.red),
                  ],
                ),
              ),
              // Filter buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterButton('All', 'all'),
                    _buildFilterButton('Pending', 'pending'),
                    _buildFilterButton('Confirmed', 'confirmed'),
                    _buildFilterButton('Rejected', 'rejected'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Bookings list or empty message
              Expanded(
                child: displayBookings.isEmpty
                    ? Center(child: Text('No ${_selectedFilter == 'all' ? '' : _selectedFilter} bookings yet'))
                    : ListView.builder(
                        itemCount: displayBookings.length,
                        itemBuilder: (context, index) {
                          final booking = displayBookings[index].data() as Map<String, dynamic>;
                          final bookingId = displayBookings[index].id;
                          final createdAt = (booking['createdAt'] as Timestamp?)?.toDate();
                          final formattedDate = createdAt != null
                              ? DateFormat.yMMMd().format(createdAt)
                              : 'N/A';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(booking['serviceName'] ?? 'Unknown Service'),
                              subtitle: Text(
                                'From: ${booking['customerName'] ?? booking['customerEmail'] ?? booking['customerId'] ?? 'Customer'}\nBooked on: $formattedDate',
                              ),
                              isThreeLine: true,
                              trailing: Chip(
                                label: Text(
                                  booking['status'] ?? 'pending',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getStatusColor(booking['status'] ?? 'pending'),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VendorBookingDetailScreen(bookingId: bookingId),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String filterValue) {
    final isSelected = _selectedFilter == filterValue;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}