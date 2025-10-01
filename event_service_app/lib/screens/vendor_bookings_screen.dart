import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'vendor_booking_detail_screen.dart';

class VendorBookingsScreen extends StatelessWidget {
  const VendorBookingsScreen({super.key});

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

          if (bookings.isEmpty) {
            return Center(child: Text('No bookings yet'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              final bookingId = bookings[index].id;
              final createdAt = (booking['createdAt'] as Timestamp?)?.toDate();
              final formattedDate = createdAt != null
                  ? DateFormat.yMMMd().format(createdAt)
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(booking['serviceName'] ?? 'Unknown Service'),
                  subtitle: Text(
                    'From: ${booking['customerEmail'] ?? 'N/A'}\nBooked on: $formattedDate',
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
          );
        },
      ),
    );
  }
}