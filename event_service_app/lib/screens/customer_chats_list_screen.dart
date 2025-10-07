import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class CustomerChatsListScreen extends StatelessWidget {
  const CustomerChatsListScreen({super.key});

  Future<Map<String, dynamic>> _getOtherUserData(List<dynamic> participants) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => null,
    );

    if (otherUserId == null) {
      return {'name': 'Unknown User', 'role': 'unknown'};
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          'name': data['name'] ?? 'Unknown User',
          'role': data['role'] ?? 'user',
          'email': data['email'] ?? '',
        };
      }
    } catch (e) {
      print('Error fetching user  $e');
    }

    return {'name': 'Unknown User', 'role': 'unknown'};
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view messages'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start chatting with vendors to see messages here',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final participants = chat['participants'] as List<dynamic>;

              return FutureBuilder<Map<String, dynamic>>(
                future: _getOtherUserData(participants),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                    );
                  }

                  final otherUser = userSnapshot.data!;
                  final isVendor = otherUser['role'] == 'vendor';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isVendor
                            ? Colors.purple.shade100
                            : Colors.blue.shade100,
                        child: Icon(
                          isVendor ? Icons.store : Icons.person,
                          color: isVendor ? Colors.purple : Colors.blue,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUser['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVendor)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Vendor',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        chat['lastMessage'] ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Text(
                        _formatTimestamp(chat['lastMessageTimestamp'] as Timestamp?),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              serviceName: otherUser['name'] as String,
                            ),
                          ),
                        );
                      },
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
