import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorServiceRegistrationScreen extends StatefulWidget {
  const VendorServiceRegistrationScreen({super.key});

  @override
  _VendorServiceRegistrationScreenState createState() => _VendorServiceRegistrationScreenState();
}

class _VendorServiceRegistrationScreenState extends State<VendorServiceRegistrationScreen> {
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _venue360Controller = TextEditingController();

  final List<String> _categories = [
    'Photography/Videography',
    'Pelamin',
    'Bunga Telor',
    'Kad Jemputan',
    'Kompang',
    'Baju Pengantin',
    'Emcee',
    'Catering',
    'Others'
  ];
  String _selectedCategory = 'Photography/Videography';
  final _otherCategoryController = TextEditingController();
  bool _showOtherCategory = false;

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
        'category': _selectedCategory == 'Others' ? _otherCategoryController.text : _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service registered successfully')));
      _serviceNameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _venue360Controller.clear();
      _otherCategoryController.clear();

      // Add this navigation code
      Navigator.of(context).pop(); // This will return to the vendor dashboard

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registering service: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _otherCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vendor Service Registration')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                    _showOtherCategory = newValue == 'Others';
                  });
                },
              ),
              SizedBox(height: 10),
              
              if (_showOtherCategory)
                TextField(
                  controller: _otherCategoryController,
                  decoration: InputDecoration(
                    labelText: 'Specify Category',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (_showOtherCategory) SizedBox(height: 10),

              TextField(
                controller: _serviceNameController,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _venue360Controller,
                decoration: InputDecoration(
                  labelText: 'Venue 360 Image URL (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              _isSubmitting 
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
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
