import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorServiceRegistrationScreen extends StatefulWidget {
  @override
  _VendorServiceRegistrationScreenState createState() => _VendorServiceRegistrationScreenState();
}

class _VendorServiceRegistrationScreenState extends State<VendorServiceRegistrationScreen> {
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _venue360Controller = TextEditingController();

  bool _isSubmitting = false;

  Future<void> registerService() async {
    if (_serviceNameController.text.isEmpty || _descriptionController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in')));
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('services').add({
        'vendorId': user.uid,
        'serviceName': _serviceNameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'venue360Url': _venue360Controller.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service registered successfully')));
      _serviceNameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _venue360Controller.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registering service: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vendor Service Registration')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _serviceNameController,
                decoration: InputDecoration(labelText: 'Service Name'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _venue360Controller,
                decoration: InputDecoration(labelText: 'Venue 360 Image URL (Optional)'),
              ),
              SizedBox(height: 20),
              _isSubmitting ? CircularProgressIndicator() : ElevatedButton(
                onPressed: registerService,
                child: Text('Register Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
