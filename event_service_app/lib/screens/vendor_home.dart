import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vendor_service_registration_screen.dart';

class VendorHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_business),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VendorServiceRegistrationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to your Vendor Dashboard'),
      ),
    );
  }
}