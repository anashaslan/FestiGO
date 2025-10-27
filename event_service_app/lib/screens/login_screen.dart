import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration_screen.dart';

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

// In lib/screens/login_screen.dart

// In lib/screens/login_screen.dart

Future<void> login() async {
  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    // Sign in user
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim());

    // After sign-in, check for user document in Firestore.
    if (userCredential.user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      final userDoc = await userDocRef.get();

      // If the document does not exist, create it with a default 'customer' role.
      if (!userDoc.exists) {
        await userDocRef.set({
          'email': userCredential.user!.email,
          'name': userCredential.user!.email?.split('@')[0] ?? 'New User', // A sensible default name
          'role': 'customer', // Default to 'customer' on login-creation
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    // Navigation: Pop the login screen since AuthenticationWrapper will handle showing the home screen
    if (mounted) {
      Navigator.of(context).pop();
    }

  } on FirebaseAuthException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Login Failed')));
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
            appBar: AppBar(
              title: Text('Login'),
              // ADDED: Allow going back to welcome screen
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
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
