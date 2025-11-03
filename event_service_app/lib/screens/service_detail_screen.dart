import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../widgets/profile_avatar.dart';

class ServiceDetailScreen extends StatefulWidget {
  final DocumentSnapshot serviceDoc;
  const ServiceDetailScreen({super.key, required this.serviceDoc});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _isInWishlist = false;
  bool _isLoadingWishlist = true;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingWishlist = false;
      });
      return;
    }

    try {
      final wishlistDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(widget.serviceDoc.id)
          .get();

      setState(() {
        _isInWishlist = wishlistDoc.exists;
        _isLoadingWishlist = false;
      });
    } catch (e) {
      print('Error checking wishlist: $e');
      setState(() {
        _isLoadingWishlist = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to use wishlist')),
      );
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(widget.serviceDoc.id);

    try {
      if (_isInWishlist) {
        await wishlistRef.delete();
        setState(() {
          _isInWishlist = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from wishlist')),
          );
        }
      } else {
        await wishlistRef.set({
          'addedAt': FieldValue.serverTimestamp(),
          'serviceId': widget.serviceDoc.id,
          'hasDiscount': false,
          'discountPercent': 0,
        });
        setState(() {
          _isInWishlist = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to wishlist')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String> _createOrGetChat(
      String vendorId, String customerId, String serviceName) async {
    final ids = [vendorId, customerId];
    ids.sort();
    final chatId = ids.join('_');
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final chatSnapshot = await chatRef.get();

    if (!chatSnapshot.exists) {
      await chatRef.set({
        'participants': [vendorId, customerId],
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessage': 'Chat created for $serviceName',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.serviceDoc.data() as Map<String, dynamic>;
    final vendorId = service['vendorId'] as String? ?? '';
    final serviceName = service['serviceName'] as String? ?? 'Service';
    final description = service['description'] as String? ?? 'No description available';
    final price = service['price'] as num? ?? 0;
    final category = service['category'] as String?;
    final imageUrl = service['imageUrl'] as String?;
    final venue360ImageUrl = service['venue360ImageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoadingWishlist)
            IconButton(
              icon: Icon(
                _isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: _isInWishlist ? Colors.red : Colors.white,
              ),
              onPressed: _toggleWishlist,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 64),
                  ),
                ),
              ),
            // Venue 360 Image
            if (venue360ImageUrl != null && venue360ImageUrl.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    venue360ImageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.view_in_ar),
                      label: const Text('360 View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (venue360ImageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Image.network(venue360ImageUrl),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 250,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: Icon(
                    Icons.event,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          serviceName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'RM ${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Vendor Info Section (Future Enhancement)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(vendorId)
                        .get(),
                    builder: (context, vendorSnapshot) {
                      if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
                        final vendorData =
                            vendorSnapshot.data!.data() as Map<String, dynamic>;
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                ProfileAvatar(
                                  imageUrl: vendorData['profileImageUrl'],
                                  fallbackText: vendorData['name'] ?? 'Vendor',
                                  radius: 30,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Vendor',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        vendorData['name'] ?? 'Vendor',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Message Button
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please log in to send messages')),
                      );
                      return;
                    }

                    final chatId = await _createOrGetChat(
                        vendorId, user.uid, serviceName);
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chatId,
                          serviceName: serviceName,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Book Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.event_available),
                  label: const Text('Book Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to book')),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance.collection('bookings').add({
                      'customerId': user.uid,
                      'vendorId': vendorId,
                      'serviceId': widget.serviceDoc.id,
                      'serviceName': serviceName,
                      'price': price,
                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking request sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
