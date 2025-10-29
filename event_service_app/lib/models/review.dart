import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String customerId;
  final String customerName;
  final String vendorId;
  final String serviceId;
  final String serviceName;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.vendorId,
    required this.serviceId,
    required this.serviceName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Review(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Anonymous',
      vendorId: data['vendorId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? 'Unknown Service',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'vendorId': vendorId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}