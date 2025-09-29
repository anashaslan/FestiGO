import 'package:event_service_app/screens/vendor_home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_browse_services_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'customer'; // default role
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        var role = userDoc.data()?['role'] ?? 'customer';
        
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user role: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${_userRole == 'vendor' ? 'Vendor' : 'Customer'}'),
      ),
      body: _userRole == 'customer'
          ? CustomerBrowseServicesScreen()
          : VendorHomeScreen(),
    );
  }
}
