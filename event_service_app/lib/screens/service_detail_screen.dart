import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceDetailScreen extends StatelessWidget {
  final DocumentSnapshot serviceDoc;

  const ServiceDetailScreen({super.key, required this.serviceDoc});

  Future<String> _createOrGetChat(String vendorId, String customerId, String serviceName) async {
    // Create a consistent chat ID regardless of who starts the chat.
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

  Future<void> _bookAndChat(BuildContext context, String vendorId, String customerId, String customerEmail, String serviceName) async {
    // 1. Create the booking document
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'serviceId': serviceDoc.id,
        'vendorId': vendorId,
        'customerId': customerId,
        'customerEmail': customerEmail,
        'serviceName': serviceName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
      return; // Stop if booking fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = serviceDoc.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(service['serviceName'] ?? 'Service Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service['venue360Url'] != null && service['venue360Url'].isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  service['venue360Url'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              service['serviceName'] ?? 'Unnamed Service',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${service['category'] ?? 'Uncategorized'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Price: \$${service['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              service['description'] ?? 'No description available.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            if (service['venue360Url'] != null && service['venue360Url'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.threesixty),
                    label: const Text('View Venue 360°'),
                    onPressed: () async {
                      final url = Uri.parse(service['venue360Url']);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open 360° view')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            if (currentUser != null && currentUser.uid != service['vendorId'])
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Book & Chat with Vendor'),
                  onPressed: () async {                    
                    final vendorId = service['vendorId'];
                    final customerId = currentUser.uid;
                    final customerEmail = currentUser.email;
                    final serviceName = service['serviceName'] ?? 'Inquiry';

                    await _bookAndChat(context, vendorId, customerId, customerEmail ?? '', serviceName);
                    final chatId = await _createOrGetChat(vendorId, customerId, serviceName);

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId, serviceName: serviceName)),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}