import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service_detail_screen.dart';

class CustomerWishlistScreen extends StatelessWidget {
  const CustomerWishlistScreen({super.key});

  Future<void> _removeFromWishlist(String serviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(serviceId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your wishlist'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .snapshots(),
        builder: (context, wishlistSnapshot) {
          if (wishlistSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!wishlistSnapshot.hasData || wishlistSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Your wishlist is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add services you love to see them here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final wishlistItems = wishlistSnapshot.data!.docs;

          return ListView.builder(
            itemCount: wishlistItems.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final wishlistItem = wishlistItems[index];
              final serviceId = wishlistItem.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('services')
                    .doc(serviceId)
                    .get(),
                builder: (context, serviceSnapshot) {
                  if (!serviceSnapshot.hasData || !serviceSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final service =
                      serviceSnapshot.data!.data() as Map<String, dynamic>;
                  final wishlistData =
                      wishlistItem.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceDetailScreen(
                                serviceDoc: serviceSnapshot.data!),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Service Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                               child: service['imageUrl'] != null &&
                                       (service['imageUrl'] as String).isNotEmpty
                                   ? Image.network(
                                       service['imageUrl'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: Icon(
                                        Icons.event,
                                        size: 40,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),

                            // Service Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['serviceName'] ?? 'Unnamed Service',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (wishlistData['hasDiscount'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Up to ${wishlistData['discountPercent']}% off',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'RM ${service['price']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Remove Button
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () async {
                                await _removeFromWishlist(serviceId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Removed from wishlist'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
