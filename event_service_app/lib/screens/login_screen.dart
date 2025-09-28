import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Add this import
import 'registration_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showRegistration = false;

  Future<void> login() async {
    setState(() => _isLoading = true);
    try {
      // Sign in user
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim());

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      
      // First check if user document exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (!userDoc.exists) {
        // Only create document if it doesn't exist
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Login Failed')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void toggle() {
    setState(() {
      _showRegistration = !_showRegistration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showRegistration
        ? RegistrationScreen(onLoginClicked: toggle)
        : Scaffold(
            appBar: AppBar(title: Text('Login')),
            body: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                          labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                          labelText: 'Password', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: login,
                            child: Text('Login'),
                          ),
                    TextButton(
                        onPressed: toggle,
                        child: Text("Don't have an account? Register"))
                  ],
                )));
  }
}
