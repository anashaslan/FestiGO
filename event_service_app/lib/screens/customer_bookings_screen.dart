import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';

class CustomerBookingsScreen extends StatelessWidget {
  const CustomerBookingsScreen({super.key});

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

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

        if (bookings.isEmpty) {
          return const Center(
            child: Text( // Using const
              'You have no bookings yet.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = Booking.fromFirestore(bookings[index]);

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
        );
      },
    );
  }
}