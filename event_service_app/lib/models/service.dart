import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String vendorId;
  final String serviceName;
  final String description;
  final double price;
  final String? venue360Url;
  final String? imageUrl;
  final String category;

  Service({
    required this.id,
    required this.vendorId,
    required this.serviceName,
    required this.description,
    required this.price,
    this.venue360Url,
    this.imageUrl,
    required this.category,
  });

  factory Service.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Service(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      serviceName: data['serviceName'] ?? 'Unnamed Service',
      description: data['description'] ?? '',
       price: (data['price'] as num?)?.toDouble() ?? 0.0,
       venue360Url: data['venue360Url'],
       imageUrl: data['imageUrl'],
       category: data['category'] ?? 'Uncategorized',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vendorId': vendorId,
      'serviceName': serviceName,
      'description': description,
       'price': price,
       'venue360Url': venue360Url,
       'imageUrl': imageUrl,
       'category': category,
    };
  }
}
