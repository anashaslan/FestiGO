import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VendorBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const VendorBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<VendorBookingDetailScreen> createState() =>
      _VendorBookingDetailScreenState();
}

class _VendorBookingDetailScreenState extends State<VendorBookingDetailScreen> {
  Future<void> _updateBookingStatus(String status) async {
    if (!mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking has been $status.')),
      );
      // Refresh the UI after updating
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Booking not found.'));
          }

          final booking = snapshot.data!.data()!;
          final createdAt = (booking['createdAt'] as Timestamp?)?.toDate();
          final formattedDate = createdAt != null
              ? DateFormat.yMMMd().add_jm().format(createdAt)
              : 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['serviceName'] ?? 'Unknown Service',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text('From: ${booking['customerEmail'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Booked on: $formattedDate'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Status: '),
                    Chip(
                      label: Text(
                        booking['status'] ?? 'pending',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          _getStatusColor(booking['status'] ?? 'pending'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (booking['status'] == 'pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _updateBookingStatus('confirmed'),
                        icon: const Icon(Icons.check),
                        label: const Text('Confirm'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _updateBookingStatus('rejected'),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

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
}

