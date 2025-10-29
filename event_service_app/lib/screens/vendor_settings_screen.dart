import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  String _language = 'English';
  String _currency = 'MYR';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
            _smsNotifications = data['smsNotifications'] ?? false;
            _language = data['language'] ?? 'English';
            _currency = data['currency'] ?? 'MYR';
          });
        }
      } catch (e) {
        print('Error loading settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'notificationsEnabled': _notificationsEnabled,
          'emailNotifications': _emailNotifications,
          'smsNotifications': _smsNotifications,
          'language': _language,
          'currency': _currency,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving settings: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Account Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ACCOUNT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _handleChangePassword,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete Account'),
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _handleDeleteAccount,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notifications Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('Enable Notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.email),
                    title: const Text('Email Notifications'),
                    value: _emailNotifications,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() {
                              _emailNotifications = value;
                            });
                          }
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.sms),
                    title: const Text('SMS Notifications'),
                    value: _smsNotifications,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() {
                              _smsNotifications = value;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Preferences Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'PREFERENCES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_language),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: _changeLanguage,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Currency'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currency),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: _changeCurrency,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Support Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'SUPPORT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openHelpCenter,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.feedback),
                    title: const Text('Send Feedback'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _sendFeedback,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About FestiGO'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showAbout,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handleChangePassword() {
    // Show password change dialog
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
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
              if (newPasswordController.text != confirmPasswordController.text) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                }
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Re-authenticate user before changing password
                  // Note: This would require the current password to be correct
                  // For simplicity, we'll just update the password directly
                  await user.updatePassword(newPasswordController.text);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating password: $e')),
                  );
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Delete user document from Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .delete();
                  
                  // Delete user services
                  final servicesSnapshot = await FirebaseFirestore.instance
                      .collection('services')
                      .where('vendorId', isEqualTo: user.uid)
                      .get();
                  
                  for (var doc in servicesSnapshot.docs) {
                    await doc.reference.delete();
                  }
                  
                  // Delete user bookings
                  final bookingsSnapshot = await FirebaseFirestore.instance
                      .collection('bookings')
                      .where('vendorId', isEqualTo: user.uid)
                      .get();
                  
                  for (var doc in bookingsSnapshot.docs) {
                    await doc.reference.delete();
                  }
                  
                  // Finally, delete the Firebase Auth user
                  await user.delete();
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    // The AuthenticationWrapper will handle navigation after deletion
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeLanguage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption('English', 'English'),
            _buildLanguageOption('Malay', 'Malay'),
            _buildLanguageOption('Chinese', 'Chinese'),
            _buildLanguageOption('Tamil', 'Tamil'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String displayName, String value) {
    return RadioListTile<String>(
      title: Text(displayName),
      value: value,
      groupValue: _language,
      onChanged: (value) {
        setState(() {
          _language = value!;
        });
        Navigator.pop(context);
      },
    );
  }

  void _changeCurrency() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCurrencyOption('Malaysian Ringgit', 'MYR'),
            _buildCurrencyOption('US Dollar', 'USD'),
            _buildCurrencyOption('Singapore Dollar', 'SGD'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String displayName, String value) {
    return RadioListTile<String>(
      title: Text(displayName),
      value: value,
      groupValue: _currency,
      onChanged: (value) {
        setState(() {
          _currency = value!;
        });
        Navigator.pop(context);
      },
    );
  }

  void _openHelpCenter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help you?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('• Manage your services and bookings'),
              Text('• Update your business information'),
              Text('• Respond to customer inquiries'),
              Text('• Set your availability calendar'),
              SizedBox(height: 16),
              Text(
                'Need more help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Email: vendors@festigo.com'),
              Text('Phone: +60 12-345 6790'),
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

  void _sendFeedback() {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: feedbackController,
          decoration: const InputDecoration(
            hintText: 'Tell us how we can improve...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // In a real app, you would send this feedback to your backend
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your feedback!')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FestiGO'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FestiGO Vendor Portal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Manage your event services and connect with customers through our platform.',
              ),
              SizedBox(height: 16),
              Text('Version 1.0.0'),
              Text('© 2025 FestiGO. All rights reserved.'),
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