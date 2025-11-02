import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class VendorServiceRegistrationScreen extends StatefulWidget {
  const VendorServiceRegistrationScreen({super.key});

  @override
  _VendorServiceRegistrationScreenState createState() => _VendorServiceRegistrationScreenState();
}

class _VendorServiceRegistrationScreenState extends State<VendorServiceRegistrationScreen> {
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  XFile? _serviceImage;
  XFile? _venue360Image;

  final List<String> _categories = [
    'COMMUNITY AND PUBLIC',
    'CORPORATE & BUSINESS',
    'EDUCATION & SCHOOL',
    'ENTERTAINMENT & STAGES',
    'PERSONAL & FAMILY',
    'OTHERS & CUSTOM'
  ];
  String _selectedCategory = 'COMMUNITY AND PUBLIC';
  bool _isSubmitting = false;

  Future<void> _pickServiceImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _serviceImage = pickedFile;
      });
    }
  }

  Future<void> _pickVenue360Image() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _venue360Image = pickedFile;
      });
    }
  }

  Future<String?> _uploadImage(XFile image, String path) async {
    try {
      print('Uploading image to $path');
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      print('Uploaded image, URL: $url');
      return url;
    } catch (e) {
      print('Failed to upload image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
    }
  }

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
      String? serviceImageUrl;
      String? venue360ImageUrl;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final uploadTasks = <Future<String?>>[];
      if (_serviceImage != null) {
        uploadTasks.add(_uploadImage(_serviceImage!, 'services/${user.uid}/${timestamp}_service.jpg'));
      }
      if (_venue360Image != null) {
        uploadTasks.add(_uploadImage(_venue360Image!, 'services/${user.uid}/${timestamp}_360.jpg'));
      }

      final results = await Future.wait(uploadTasks);
      int index = 0;
      if (_serviceImage != null) {
        serviceImageUrl = results[index++];
      }
      if (_venue360Image != null) {
        venue360ImageUrl = results[index++];
      }

      print('Service Image URL: $serviceImageUrl');
      print('Venue 360 Image URL: $venue360ImageUrl');

      await FirebaseFirestore.instance.collection('services').add({
        'vendorId': user.uid,
        'serviceName': _serviceNameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'imageUrl': serviceImageUrl,
        'venue360ImageUrl': venue360ImageUrl,
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service registered successfully')));
      _serviceNameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      setState(() {
        _serviceImage = null;
        _venue360Image = null;
      });

      // Add this navigation code
      Navigator.of(context).pop(); // This will return to the vendor dashboard

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registering service: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
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
                  });
                },
              ),
              SizedBox(height: 10),
              


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
               Text('Service Image (Optional)'),
               SizedBox(height: 5),
               Row(
                 children: [
                   ElevatedButton(
                     onPressed: _pickServiceImage,
                     child: Text('Pick Service Image'),
                   ),
                   SizedBox(width: 10),
                   if (_serviceImage != null)
                     Expanded(
                       child: Text(
                         _serviceImage!.name,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                 ],
               ),
               if (_serviceImage != null) ...[
                 SizedBox(height: 10),
                 Image.file(
                   File(_serviceImage!.path),
                   height: 100,
                   width: 100,
                   fit: BoxFit.cover,
                 ),
               ],
               SizedBox(height: 10),
               Text('Venue 360 Image (Optional)'),
               SizedBox(height: 5),
               Row(
                 children: [
                   ElevatedButton(
                     onPressed: _pickVenue360Image,
                     child: Text('Pick 360 Image'),
                   ),
                   SizedBox(width: 10),
                   if (_venue360Image != null)
                     Expanded(
                       child: Text(
                         _venue360Image!.name,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                 ],
               ),
               if (_venue360Image != null) ...[
                 SizedBox(height: 10),
                 Image.file(
                   File(_venue360Image!.path),
                   height: 100,
                   width: 100,
                   fit: BoxFit.cover,
                 ),
               ],
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
