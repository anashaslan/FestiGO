import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_settings_screen.dart';
import 'vendor_availability_calendar_screen.dart';
import 'vendor_reviews_screen.dart';

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  Future<Map<String, dynamic>> _getVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching vendor data: $e');
    }

    return {};
  }

  Future<Map<String, int>> _getVendorStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'services': 0, 'bookings': 0};

    try {
      // Get services count
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('vendorId', isEqualTo: user.uid)
          .get();

      // Get bookings count
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('vendorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'confirmed')
          .get();

      return {
        'services': servicesSnapshot.docs.length,
        'bookings': bookingsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error fetching stats: $e');
      return {'services': 0, 'bookings': 0};
    }
  }

  int _calculateYearsOnPlatform(Timestamp? createdAt) {
    if (createdAt == null) return 0;
    final now = DateTime.now();
    final created = createdAt.toDate();
    return now.difference(created).inDays ~/ 365;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VendorSettingsScreen(), // We'll create this later
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getVendorData(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data ?? {};
          final name = userData['name'] ?? 'Vendor';
          final businessName = userData['businessName'] ?? 'Independent Vendor';
          final location = userData['location'] ?? 'Kuala Lumpur, Malaysia';
          final bio = userData['bio'] ?? 'Professional service provider on FestiGO';
          final createdAt = userData['createdAt'] as Timestamp?;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        businessName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Statistics
                FutureBuilder<Map<String, int>>(
                  future: _getVendorStats(),
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data ?? {'services': 0, 'bookings': 0};

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            context,
                            'Services',
                            stats['services'].toString(),
                            Icons.store,
                          ),
                          _buildStatCard(
                            context,
                            'Bookings',
                            stats['bookings'].toString(),
                            Icons.event_available,
                          ),
                          _buildStatCard(
                            context,
                            'Years on FestiGO',
                            _calculateYearsOnPlatform(createdAt).toString(),
                            Icons.cake,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Menu Items
                _buildMenuItem(
                  context,
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your business information',
                  onTap: () {
                    _showEditProfileDialog(context, userData);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.business,
                  title: 'Business Information',
                  subtitle: 'Manage your business details',
                  onTap: () {
                    _showBusinessInfoDialog(context, userData);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Availability Calendar',
                  subtitle: 'Set your unavailable dates',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VendorAvailabilityCalendarScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.star,
                  title: 'My Reviews',
                  subtitle: 'View customer ratings and feedback',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VendorReviewsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.photo_library,
                  title: 'Portfolio',
                  subtitle: 'Showcase your work',
                  onTap: () {
                    _showPortfolioDialog(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Account, privacy, and more',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VendorSettingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, Map<String, dynamic> userData) {
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final businessNameController = TextEditingController(text: userData['businessName'] ?? '');
    final locationController = TextEditingController(text: userData['location'] ?? '');
    final bioController = TextEditingController(text: userData['bio'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'name': nameController.text.trim(),
                    'businessName': businessNameController.text.trim(),
                    'location': locationController.text.trim(),
                    'bio': bioController.text.trim(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBusinessInfoDialog(BuildContext context, Map<String, dynamic> userData) {
    final phoneController = TextEditingController(text: userData['phone'] ?? '');
    final websiteController = TextEditingController(text: userData['website'] ?? '');
    final addressController = TextEditingController(text: userData['address'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Business Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Business Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'phone': phoneController.text.trim(),
                    'website': websiteController.text.trim(),
                    'address': addressController.text.trim(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Business information updated')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating information: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPortfolioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Portfolio Management'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Portfolio management coming soon!'),
              SizedBox(height: 16),
              Text(
                'In this section, you\'ll be able to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Upload images of your past work'),
              Text('• Organize your portfolio by categories'),
              Text('• Showcase your best projects to customers'),
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

