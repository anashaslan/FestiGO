import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_browse_services_screen.dart';
import 'customer_bookings_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FestiGO'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'Browse'),
              Tab(icon: Icon(Icons.history), text: 'My Bookings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [CustomerBrowseServicesScreen(), CustomerBookingsScreen()],
        ),
      ),
    );
  }
}