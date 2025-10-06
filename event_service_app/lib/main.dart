import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/customer_home.dart';
import 'screens/vendor_home.dart';
import 'screens/admin_home.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'services/global_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FestiGO());
}

class FestiGO extends StatelessWidget {
  const FestiGO({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalNavigator.navigatorKey,
      scaffoldMessengerKey: GlobalNavigator.scaffoldMessengerKey,
      title: 'FestiGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 153, 36, 248),
        ),
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ADDED: Debug logging
        print('Auth state: ${snapshot.connectionState}, Has  ${snapshot.hasData}, User: ${snapshot.data?.email}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('No user logged in, showing LoginScreen');
          return const LoginScreen();
        }

        print('User logged in: ${snapshot.data!.email}, loading role...');
        // CRITICAL FIX: Add ValueKey to force rebuild when user changes
        return RoleBasedHomeScreen(
          key: ValueKey(snapshot.data!.uid), // Forces new widget when UID changes
          userId: snapshot.data!.uid,
        );
      },
    );
  }
}

class RoleBasedHomeScreen extends StatefulWidget {
  final String userId;
  const RoleBasedHomeScreen({super.key, required this.userId});

  @override
  State<RoleBasedHomeScreen> createState() => _RoleBasedHomeScreenState();
}

class _RoleBasedHomeScreenState extends State<RoleBasedHomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await NotificationService().initNotifications();
    } catch (e) {
      print("Error initializing notification service: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not initialize notifications.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // CRITICAL FIX: Add key to force refresh when userId changes
      key: ValueKey(widget.userId),
      future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
      builder: (context, roleSnapshot) {
        print('FutureBuilder state: ${roleSnapshot.connectionState}');
        
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (roleSnapshot.hasError) {
          print('Error loading user role: ${roleSnapshot.error}');
          FirebaseAuth.instance.signOut();
          return const Scaffold(
            body: Center(child: Text('Error loading user data. Please log in again.')),
          );
        }

        if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
          print('User document does not exist for UID: ${widget.userId}');
          FirebaseAuth.instance.signOut();
          return const Scaffold(
            body: Center(child: Text('User data not found. Please log in again.')),
          );
        }

        final role = roleSnapshot.data!.get('role') as String? ?? 'customer';
        print('User role loaded: $role for UID: ${widget.userId}');
        
        switch (role) {
          case 'vendor':
            return const VendorHomeScreen();
          case 'admin':
            return const AdminHomeScreen();
          default:
            return const CustomerHomeScreen();
        }
      },
    );
  }
}