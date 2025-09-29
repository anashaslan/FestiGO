import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/customer_home.dart';
import 'screens/vendor_home.dart';
import 'screens/admin_home.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(FestiGO());
}

class FestiGO extends StatelessWidget {
  const FestiGO({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FestiGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 153, 36, 248),
        ),
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  User? _user;
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        setState(() {
          _user = null;
          _role = null;
          _loading = false;
        });
      } else {
        // Fetch role from Firestore
        var doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          _user = user;
          _role = doc.data()?['role'] ?? 'customer';
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return LoginScreen();
    }
    switch (_role) {
      case 'vendor':
        return VendorHomeScreen();
      case 'admin':
        return AdminHomeScreen();
      default:
        return CustomerHomeScreen();
    }
  }
}