import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceDetailScreen extends StatelessWidget {
  final DocumentSnapshot serviceDoc;

  ServiceDetailScreen({required this.serviceDoc});

  Future<void> bookService(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login first')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'serviceId': serviceDoc.id,
        'vendorId': serviceDoc['vendorId'],
        'customerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending'
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking requested!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = serviceDoc.data() as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(data['serviceName'] ?? 'Service Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(data['description'] ?? ''),
            SizedBox(height: 20),
            Text('Price: \$${data['price']?.toStringAsFixed(2) ?? 'N/A'}'),
            SizedBox(height: 20),
            data['venue360Url'] != null && data['venue360Url'].isNotEmpty
                ? ElevatedButton(
                    onPressed: () {
                      // TODO: Implement 360 view
                    },
                    child: Text('View Venue 360'))
                : Container(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => bookService(context),
              child: Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }
}