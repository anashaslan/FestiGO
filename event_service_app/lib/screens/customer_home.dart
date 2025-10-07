import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_browse_services_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_wishlist_screen.dart';
import 'customer_chats_list_screen.dart';
import 'customer_profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final int initialTabIndex;
  const CustomerHomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CustomerBrowseServicesScreen(),
    CustomerWishlistScreen(),
    CustomerChatsListScreen(),
    CustomerProfileScreen(),
  ];

  Future<void> _signOut(BuildContext context) async {
    print('Customer logging out...');
    await FirebaseAuth.instance.signOut();
    print('Customer logout complete - StreamBuilder will handle navigation');
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
