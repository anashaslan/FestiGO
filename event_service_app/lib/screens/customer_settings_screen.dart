import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? true;
          _pushNotifications = data['pushNotifications'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({key: value});
    } catch (e) {
      print('Error updating setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Account Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            subtitle: const Text('Update your name and location'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditProfileDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
          ),

          const Divider(),

          // Privacy Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Profile Visibility'),
            subtitle: const Text('Control who can see your profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Booking History Privacy'),
            subtitle: const Text('Manage your booking history visibility'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),

          const Divider(),

          // Notifications Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive updates about your bookings'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _updateSetting('notificationsEnabled', value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive booking updates via email'),
            value: _emailNotifications,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                    _updateSetting('emailNotifications', value);
                  }
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.phone_android),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push notifications on this device'),
            value: _pushNotifications,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    _updateSetting('pushNotifications', value);
                  }
                : null,
          ),

          const Divider(),

          // Security Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Security and Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Add an extra layer of security'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),

          const Divider(),

          // Support Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.report_problem),
            title: const Text('Report a Problem'),
            subtitle: const Text('Let us know if something is wrong'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showReportDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help with using FestiGO'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center opening soon')),
              );
            },
          ),

          const Divider(),

          // Legal Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Terms and Policies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showTermsDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPrivacyDialog();
            },
          ),

          const Divider(),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _signOut,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
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
          ],
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'name': nameController.text,
                  'location': locationController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && user.email != null) {
                  // Re-authenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);

                  // Update password
                  await user.updatePassword(newPasswordController.text);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully')),
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
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Problem'),
        content: TextField(
          controller: reportController,
          decoration: const InputDecoration(
            labelText: 'Describe the issue',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (reportController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please describe the issue')),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('reports').add({
                  'userId': user.uid,
                  'email': user.email,
                  'issue': reportController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'pending',
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted. We will review it shortly.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'FestiGO Terms of Service\n\n'
            '1. Acceptance of Terms\n'
            'By using FestiGO, you agree to these terms.\n\n'
            '2. User Accounts\n'
            'You are responsible for maintaining the security of your account.\n\n'
            '3. Booking Services\n'
            'All bookings are subject to vendor availability and confirmation.\n\n'
            '4. Payment\n'
            'Payment terms are agreed between customer and vendor.\n\n'
            '5. Cancellation\n'
            'Cancellation policies vary by vendor.\n\n'
            'For full terms, visit: www.festigo.com/terms',
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'FestiGO Privacy Policy\n\n'
            'We collect and process your personal data to provide our services.\n\n'
            'Data We Collect:\n'
            '• Account information (name, email)\n'
            '• Booking history\n'
            '• Communication with vendors\n\n'
            'How We Use Your Data:\n'
            '• To provide and improve our services\n'
            '• To communicate with you\n'
            '• To process bookings\n\n'
            'Data Security:\n'
            'We use industry-standard security measures to protect your data.\n\n'
            'For full privacy policy, visit: www.festigo.com/privacy',
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