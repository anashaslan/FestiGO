import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('customerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data?.docs ?? [];

          // Count bookings by status
          final pendingCount = bookings.where((doc) {
            final booking = Booking.fromFirestore(doc);
            return booking.status == 'pending';
          }).length;

          final confirmedCount = bookings.where((doc) {
            final booking = Booking.fromFirestore(doc);
            return booking.status == 'confirmed';
          }).length;

          final rejectedCount = bookings.where((doc) {
            final booking = Booking.fromFirestore(doc);
            return booking.status == 'rejected';
          }).length;

          // Apply status filter
          final displayBookings = bookings.where((doc) {
            if (_selectedFilter == 'all') return true;
            final booking = Booking.fromFirestore(doc);
            return booking.status == _selectedFilter;
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
                          final booking = Booking.fromFirestore(displayBookings[index]);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(booking.serviceName),
                              subtitle: Text(
                                'Booked on: ${booking.formattedDate}',
                              ),
                              trailing: Chip(
                                label: Text(
                                  booking.status,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getStatusColor(booking.status),
                              ),
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