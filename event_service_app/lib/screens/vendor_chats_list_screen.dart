import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../widgets/profile_avatar.dart';

class VendorChatsListScreen extends StatelessWidget {
  const VendorChatsListScreen({super.key});

  Future<Map<String, dynamic>> _getOtherParticipantData(List<dynamic> participants) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => null);

    if (otherUserId == null) return {'name': 'Unknown User', 'profileImageUrl': null};

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
    final userData = userDoc.data() ?? {};
    return {
      'name': userData['name'] ?? 'Customer',
      'profileImageUrl': userData['profileImageUrl'],
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to see your chats.'));
    }

    return StreamBuilder<QuerySnapshot>(
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
          return const Center(
            child: Text(
              'No active chats.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final chats = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final chatData = chat.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _getOtherParticipantData(chatData['participants']),
                builder: (context, snapshot) {
                  final otherUserData = snapshot.data ?? {'name': 'Loading...', 'profileImageUrl': null};
                  return ListTile(
                    leading: ProfileAvatar(
                      imageUrl: otherUserData['profileImageUrl'],
                      fallbackText: otherUserData['name'],
                      radius: 20,
                    ),
                    title: Text(otherUserData['name']),
                    subtitle: Text(chatData['lastMessage'] ?? 'Tap to open chat'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen(chatId: chat.id, serviceName: otherUserData['name'])),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}