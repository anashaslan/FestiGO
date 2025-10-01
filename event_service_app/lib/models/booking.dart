import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String serviceName;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.serviceName,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Booking(
      serviceName: data['serviceName'] as String? ?? 'Unknown Service',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedDate {
    // Example: 2023-10-27
    return createdAt.toLocal().toString().split(' ')[0];
  }
}
