import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _userType = 'all'; // 'all', 'vendors', 'customers'
  String _sortBy = 'name'; // 'name', 'joined', 'bookings'
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _userType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'vendors', child: Text('Vendors')),
                    DropdownMenuItem(value: 'customers', child: Text('Customers')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _userType = value!;
                    });
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                    DropdownMenuItem(value: 'joined', child: Text('Sort by Joined')),
                    DropdownMenuItem(value: 'bookings', child: Text('Sort by Bookings')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUserStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data?.docs ?? [];

                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'No Name';
                    final email = data['email'] ?? 'No Email';
                    final role = data['role'] ?? 'customer';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final formattedDate = createdAt != null
                        ? DateFormat('MMM dd, yyyy').format(createdAt)
                        : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'vendor'
                              ? Colors.deepPurple
                              : role == 'admin'
                                  ? Colors.red
                                  : Colors.blue,
                          child: Text(
                            name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            Text('Joined: $formattedDate'),
                            FutureBuilder<int>(
                              future: _getUserBookingsCount(user.id),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text('Bookings: ${snapshot.data}');
                                }
                                return const Text('Bookings: 0');
                              },
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(role.toUpperCase()),
                              backgroundColor: role == 'vendor'
                                  ? Colors.deepPurple.withValues(alpha: 0.2)
                                  : role == 'admin'
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : Colors.blue.withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (value) => _handleUserAction(value, user),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Text('View Details'),
                                ),
                                if (role != 'admin')
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Text('Make Admin'),
                                  ),
                                if (role == 'admin' && user.id != FirebaseAuth.instance.currentUser?.uid)
                                  const PopupMenuItem(
                                    value: 'remove_admin',
                                    child: Text('Remove Admin'),
                                  ),
                                if (role == 'vendor')
                                  const PopupMenuItem(
                                    value: 'make_customer',
                                    child: Text('Make Customer'),
                                  ),
                                if (role == 'customer')
                                  const PopupMenuItem(
                                    value: 'make_vendor',
                                    child: Text('Make Vendor'),
                                  ),
                                if (user.id != FirebaseAuth.instance.currentUser?.uid)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete User'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getUserStream() {
    Query query = FirebaseFirestore.instance.collection('users');

    // Apply user type filter
    if (_userType == 'vendors') {
      query = query.where('role', isEqualTo: 'vendor');
    } else if (_userType == 'customers') {
      query = query.where('role', isEqualTo: 'customer');
    }

    // Apply sorting
    if (_sortBy == 'name') {
      query = query.orderBy('name', descending: !_sortAscending);
    } else if (_sortBy == 'joined') {
      query = query.orderBy('createdAt', descending: !_sortAscending);
    }

    return query.snapshots();
  }

  Future<int> _getUserBookingsCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _handleUserAction(String action, DocumentSnapshot user) async {
    final data = user.data() as Map<String, dynamic>;
    final userId = user.id;
    final name = data['name'] ?? 'User';

    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'make_admin':
        _confirmAction(
          context,
          'Make Admin',
          'Are you sure you want to make $name an admin?',
          () => _updateUserRole(userId, 'admin'),
        );
        break;
      case 'remove_admin':
        _confirmAction(
          context,
          'Remove Admin',
          'Are you sure you want to remove admin privileges from $name?',
          () => _updateUserRole(userId, 'customer'),
        );
        break;
      case 'make_vendor':
        _confirmAction(
          context,
          'Make Vendor',
          'Are you sure you want to make $name a vendor?',
          () => _updateUserRole(userId, 'vendor'),
        );
        break;
      case 'make_customer':
        _confirmAction(
          context,
          'Make Customer',
          'Are you sure you want to make $name a customer?',
          () => _updateUserRole(userId, 'customer'),
        );
        break;
      case 'delete':
        _confirmAction(
          context,
          'Delete User',
          'Are you sure you want to delete $name? This action cannot be undone.',
          () => _deleteUser(userId),
        );
        break;
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': newRole});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user role: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      // Delete user document
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Delete user's wishlist (if exists)
      final wishlistSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();
      for (var doc in wishlistSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user's chats (if exists)
      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();
      for (var doc in chatsSnapshot.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(DocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';
    final role = data['role'] ?? 'customer';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt)
        : 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: $email'),
              const SizedBox(height: 8),
              Text('Role: ${role.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Joined: $formattedDate'),
              const SizedBox(height: 16),
              const Text(
                'Statistics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: _getUserBookingsCount(user.id),
                builder: (context, snapshot) {
                  return Text('Bookings: ${snapshot.data ?? 0}');
                },
              ),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('services')
                    .where('vendorId', isEqualTo: user.id)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('Services: ${snapshot.data!.docs.length}');
                  }
                  return const Text('Services: 0');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}